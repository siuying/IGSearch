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

void sqlite3Fts3PorterTokenizerModule(sqlite3_tokenizer_module const**ppModule);

@implementation IGSearch

+(void) initialize {
    // run the custom rank function
    rank_init(1);
}

-(id) initWithPath:(NSString*) path {
    self = [super init];
    if (self) {
        self.database = [FMDatabase databaseWithPath:path];
        if (![self.database open]) {
            NSLog(@"Failed open database");
        }

        [self setupFullTextSearch];
        [self createTableIfNeeded];
    }
    return self;
}

-(BOOL) close {
    return [self.database close];
}

-(void) indexDocument:(NSDictionary*)document withId:(NSString*)documentId {
    if (!documentId) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"documentId cannot be nil"
                               userInfo:nil] raise];
    }
    [self.database beginTransaction];

    [self.database executeUpdate:@"delete from ig_search where doc_id = ?", documentId];
    
    @try {
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

            [self.database executeUpdate:@"insert into ig_search (doc_id, field, value) values (?, ?, ?)", documentId, field, value];
        }];
        [self.database commit];
    }
    @catch (NSException *exception) {
        [self.database rollback];
        @throw(exception);
    }
}

-(NSUInteger) count {
    FMResultSet* rs = [self.database executeQuery:@"select count(distinct doc_id) as count from ig_search"];
    if ([rs next]) {
        return [rs intForColumn:@"count"];
    } else {
        return 0;
    }
}

-(NSArray*) search:(NSString*)query {
    return [self search:query withField:nil];
}

-(NSArray*) search:(NSString*)query withField:(NSString*)field {
    if (!query) {
        [[NSException exceptionWithName:NSInvalidArgumentException
                                 reason:@"search query cannot be nil"
                               userInfo:nil] raise];
    }

    FMResultSet* rs = nil;
    if (field == nil) {
        rs = [self.database executeQuery:@"SELECT doc_id, field, value FROM ig_search JOIN (\
              SELECT doc_id, rank(matchinfo(ig_search), 1) AS rank \
              FROM ig_search \
              WHERE value MATCH ? \
              ORDER BY rank DESC \
              ) AS ranktable USING(doc_id)\
              ORDER BY ranktable.rank DESC", query];
    } else {
        rs = [self.database executeQuery:@"SELECT doc_id, field, value FROM ig_search JOIN (\
             SELECT doc_id, rank(matchinfo(ig_search), 1) AS rank \
             FROM ig_search \
             WHERE value MATCH ? AND field = ? \
             ORDER BY rank DESC \
             ) AS ranktable USING(doc_id)\
             ORDER BY ranktable.rank DESC", query, field];

    }
    return [self resultWithResultSet:rs];
}

#pragma mark - Private

-(void) setupFullTextSearch {
    const static sqlite3_tokenizer_module* module;
    sqlite3Fts3PorterTokenizerModule(&module);
    NSAssert(module, @"module cannot be nil");
    
    NSData *moduleData = [NSData dataWithBytes:&module length:sizeof(module)];
    FMResultSet* rs = [self.database executeQuery:@"SELECT fts3_tokenizer(\"mozporter\", ?)", moduleData];
    while([rs next]) {
        NSLog(@"module data = %@", [rs resultDictionary]);
    }
}

-(void) createTableIfNeeded {
    BOOL result = [self.database executeUpdate:@"CREATE VIRTUAL TABLE IF NOT EXISTS ig_search USING FTS4 (id, doc_id, field, value, tokenize=mozporter)", nil];
    if (!result) {
        NSLog(@"failed create db: %@", [self.database lastError]);
    }
}

-(NSArray*) resultWithResultSet:(FMResultSet*)resultSet {
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

@end
