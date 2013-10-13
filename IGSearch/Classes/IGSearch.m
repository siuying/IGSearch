//
//  IGSearch.m
//  IGSearch
//
//  Created by Chong Francis on 13年6月30日.
//  Copyright (c) 2013年 Ignition Soft. All rights reserved.
//

#import "IGSearch.h"
#import "fts3_tokenizer.h"
#import "sqlite3.h"
#import "rank.h"
#import "DDLog.h"

static const int ddLogLevel = IGSEARCH_LOG_LEVEL;

void sqlite3Fts3PorterTokenizerModule(sqlite3_tokenizer_module const**ppModule);

@interface IGSearch()
@property (nonatomic, strong) FMDatabaseQueue *database;
@end

@implementation IGSearch

+(void) initialize {
    // run the custom rank function
    rank_init(1);
}

-(id) initWithPath:(NSString*) path {
    self = [super init];
    if (self) {
        _database = [FMDatabaseQueue databaseQueueWithPath:path];
        [self.database inDatabase:^(FMDatabase *db) {
            if (![db open]) {
                DDLogError(@"Failed open database: %@", path);
            }
            db.shouldCacheStatements = YES;
        }];

        [self setupFullTextSearch];
        [self createTableIfNeeded];
    }
    return self;
}

-(BOOL) close {
    return YES;
}

-(void) dealloc {

}

-(void) indexDocument:(NSDictionary*)document withId:(NSString*)documentId {
    if (!documentId) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"documentId cannot be nil"
                               userInfo:nil] raise];
    }

    // perform validation
    [document enumerateKeysAndObjectsUsingBlock:^(NSString* field, NSString* value, BOOL *stop) {
        if (![field isKindOfClass:[NSString class]]) {
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"document field must be a String"
                                   userInfo:nil] raise];
        }
        
        if (![value isKindOfClass:[NSString class]]) {
            NSLog(@"document value must be a String");
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"document value must be a String"
                                   userInfo:nil] raise];
        }
    }];

    [self.database inTransaction:^(FMDatabase *db, BOOL *rollback) {
        __block BOOL succeed = NO;
        [db executeUpdate:@"delete from ig_search where doc_id = ?", documentId];
        [document enumerateKeysAndObjectsUsingBlock:^(NSString* field, NSString* value, BOOL *stop) {
            succeed = [db executeUpdate:@"insert into ig_search (doc_id, field, value) values (?, ?, ?)", documentId, field, value];
            if (!succeed) {
                *stop = YES;
            }
        }];
        if (!succeed) {
            *rollback = YES;
        }
    }];
}

-(void) countWithBlock:(void(^)(NSUInteger count))block {
    [self.database inDatabase:^(FMDatabase *db) {
        NSUInteger count;
        FMResultSet* rs = [db executeQuery:@"select count(distinct doc_id) as count from ig_search"];
        if ([db hadError]) {
            DDLogError(@"sqlite error: %@", [db lastErrorMessage]);
        }
        if ([rs next]) {
            count = [rs intForColumn:@"count"];
        } else {
            count = 0;
        }
        block(count);
    }];
}

-(void) search:(NSString*)query block:(void(^)(NSArray* documents))block {
    [self search:query withField:nil fetchIdOnly:NO block:block];
}

-(void) search:(NSString*)query withField:(NSString*)field block:(void(^)(NSArray* documents))block {
    [self search:query withField:field fetchIdOnly:NO block:block];
}

-(void) search:(NSString*)query withField:(NSString*)field fetchIdOnly:(BOOL)fetchIdOnly block:(void(^)(NSArray* documents))block {
    if (!query) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"search query cannot be nil"
                               userInfo:nil] raise];
    }

    NSMutableString* sql = [NSMutableString string];
    if (fetchIdOnly) {
        [sql appendString:@"SELECT doc_id FROM ig_search "];
    } else {
        [sql appendString:@"SELECT doc_id, field, value FROM ig_search "];
    }
    
    if (fetchIdOnly) {
        [sql appendString:@"JOIN (\
         SELECT distinct doc_id, rank(matchinfo(ig_search), 1) AS rank \
         FROM ig_search "];
        
    } else {
        [sql appendString:@"JOIN (\
         SELECT doc_id, rank(matchinfo(ig_search), 1) AS rank \
         FROM ig_search "];
        
    }

    if (field == nil) {
        [sql appendString:@"WHERE value MATCH ? "];
    } else {
        [sql appendString:@"WHERE field = ? AND value MATCH ? "];
    }

    [sql appendString:@"ORDER BY rank DESC ) AS ranktable USING(doc_id) "];
    [sql appendString:@"ORDER BY ranktable.rank DESC "];

    [self.database inDatabase:^(FMDatabase *db) {
        FMResultSet* rs = nil;
        if (field == nil) {
            DDLogVerbose(@"SQL = %@, query = %@", sql, query);
            rs = [db executeQuery:sql, query];
        } else {
            DDLogVerbose(@"SQL = %@, field = %@, query = %@", sql, field, query);
            rs = [db executeQuery:sql, field, query];
        }
        
        if ([db hadError]) {
            DDLogError(@"sqlite error: %@", [db lastErrorMessage]);
        }
        NSArray* result = nil;
        if (fetchIdOnly) {
            result = [self documentIdsWithResultSet:rs];
        } else {
            result = [self documentsWithResultSet:rs];
        }
        block(result);
    }];
}

-(void) documentWithId:(NSString*)docId block:(void(^)(NSDictionary* document))block {
    [self.database inDatabase:^(FMDatabase *db) {
        FMResultSet* rs = [db executeQuery:@"SELECT field, value FROM ig_search WHERE doc_id = ?", docId];
        if ([db hadError]) {
            DDLogError(@"sqlite error: %@", [db lastErrorMessage]);
            block(nil);
            
        } else {
            NSDictionary* document = [self documentWithResultSet:rs];
            block(document);
        }
    }];
}

-(void) deleteDocumentWithId:(NSString*)docId {
    [self.database inDatabase:^(FMDatabase *db) {
        [db executeUpdate:@"DELETE FROM ig_search WHERE doc_id = ?", docId];
    }];
}

#pragma mark - Private

-(void) setupFullTextSearch {
    [self.database inDatabase:^(FMDatabase *db) {
        const static sqlite3_tokenizer_module* module;
        sqlite3Fts3PorterTokenizerModule(&module);
        NSAssert(module, @"module cannot be nil");
        
        NSData *moduleData = [NSData dataWithBytes:&module length:sizeof(module)];
        FMResultSet* rs = [db executeQuery:@"SELECT fts3_tokenizer(\"mozporter\", ?)", moduleData];
        while([rs next]) {
            DDLogVerbose(@"module data = %@", [rs resultDictionary]);
        }
    }];
}

-(void) createTableIfNeeded {
    [self.database inDatabase:^(FMDatabase *db) {
        BOOL result = [db executeUpdate:@"CREATE VIRTUAL TABLE IF NOT EXISTS ig_search USING FTS4 (id, doc_id, field, value, tokenize=mozporter)", nil];
        if (!result) {
            DDLogError(@"failed create db: %@", [db lastError]);
        }
    }];
}

-(NSDictionary*) documentWithResultSet:(FMResultSet*)resultSet {
    NSMutableDictionary* document = nil;
    while ([resultSet next]) {
        if (!document) {
            document = [NSMutableDictionary dictionary];
        }
        NSString* field = [resultSet stringForColumn:@"field"];
        NSString* value = [resultSet stringForColumn:@"value"];
        [document setObject:value forKey:field];
    }
    return [document copy];
}

-(NSArray*) documentsWithResultSet:(FMResultSet*)resultSet {
    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    while ([resultSet next]) {
        NSString* docId = [resultSet stringForColumn:@"doc_id"];
        NSString* field = [resultSet stringForColumn:@"field"];
        NSString* value = [resultSet stringForColumn:@"value"];
        
        NSMutableDictionary* doc = [results objectForKey:docId];
        if (!doc) {
            doc = [NSMutableDictionary dictionary];
            [results setObject:doc forKey:docId];
        }
        [doc setObject:value forKey:field];
    }
    return [results allValues];
}

-(NSArray*) documentIdsWithResultSet:(FMResultSet*)resultSet {
    NSMutableSet* results = [NSMutableSet set];
    while ([resultSet next]) {
        NSString* docId = [resultSet stringForColumn:@"doc_id"];
        [results addObject:docId];
        DDLogVerbose(@" doc_id = %@", docId);
    }
    return [results allObjects];
}

@end

@implementation IGSearch (Synchronous)

-(NSUInteger) count {
    __block NSUInteger count = 0;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [self countWithBlock:^(NSUInteger _count) {
        count = _count;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return count;
}

-(NSArray*) search:(NSString*)query {
    return [self search:query withField:nil fetchIdOnly:NO];
}

-(NSArray*) search:(NSString*)query withField:(NSString*)field {
    return [self search:query withField:field fetchIdOnly:NO];
}

-(NSArray*) search:(NSString*)query withField:(NSString*)field fetchIdOnly:(BOOL)fetchIdOnly {
    if (!query) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"search query cannot be nil"
                               userInfo:nil] raise];
    }
    
    __block NSArray* result = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self search:query withField:field fetchIdOnly:fetchIdOnly block:^(NSArray *documents) {
        result = documents;
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return result;
}

-(NSDictionary*) documentWithId:(NSString*)docId {
    __block NSDictionary* document = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [self documentWithId:docId block:^(NSDictionary *_document) {
        document = _document;
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return document;
}

@end
