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

-(BOOL) indexDocument:(NSDictionary*)document withId:(NSString*)documentId {
    NSAssert(documentId, @"documentId should not be nil");
    [self.database beginTransaction];

    [self.database executeUpdate:@"delete from ig_search where doc_id = ?", documentId];
    
    __block BOOL failure = NO;
    [document enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* value, BOOL *stop) {
        if (![key isKindOfClass:[NSString class]]) {
            NSLog(@"document key must be a String");
            failure = YES;
            *stop = YES;
        }
        if (![value isKindOfClass:[NSString class]]) {
            NSLog(@"document value must be a String");
            failure = YES;
            *stop = YES;
        }
        
        if (![self.database executeUpdate:@"insert into ig_search (doc_id, key, value) values (?, ?, ?)", documentId, key, value]) {
            NSLog(@"error inserting row: %@", [self.database lastError]);
            failure = YES;
            *stop = YES;
        }
    }];
    
    if (!failure) {
        [self.database commit];
        return YES;
    } else {
        [self.database rollback];
        return NO;
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

-(NSArray*) search:(NSString*)string {
    // Returns search by rank
    FMResultSet* rs = [self.database executeQuery:@"SELECT doc_id, key, value FROM ig_search JOIN (\
                               SELECT doc_id, rank(matchinfo(ig_search), 1) AS rank \
                               FROM ig_search \
                               WHERE value MATCH ? \
                               ORDER BY rank DESC \
                       ) AS ranktable USING(doc_id)\
                       ORDER BY ranktable.rank DESC", string];

    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    while ([rs next]) {
        NSString* docId = [rs stringForColumn:@"doc_id"];
        NSString* field = [rs stringForColumn:@"key"];
        NSString* value = [rs stringForColumn:@"value"];

        NSMutableDictionary* doc = [results objectForKey:docId];
        if (!doc) {
            doc = [NSMutableDictionary dictionary];
            [results setObject:doc forKey:docId];
        }
        [doc setObject:value forKey:field];
    }
    return [results allValues];
}

-(NSArray*) searchWithFields:(NSDictionary*)fields {
    return nil;    
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
    BOOL result = [self.database executeUpdate:@"CREATE VIRTUAL TABLE IF NOT EXISTS ig_search USING FTS4 (id, doc_id, key, value, tokenize=mozporter)", nil];
    if (!result) {
        NSLog(@"failed create db: %@", [self.database lastError]);
    }
}

@end
