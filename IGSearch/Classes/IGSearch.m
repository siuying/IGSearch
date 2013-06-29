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
    BOOL succeed = [self.database executeUpdate:@"delete from ig_search where doc_id = ?", documentId];
    if (!succeed) {
        NSLog(@"failed delete: %@", [self.database lastError]);
    }

    [document enumerateKeysAndObjectsUsingBlock:^(NSString* field, NSString* value, BOOL *stop) {
        NSAssert([field isKindOfClass:[NSString class]], @"document field should be string");
        NSAssert([value isKindOfClass:[NSString class]], @"document value should be string");

        BOOL succeed = [self.database executeUpdate:@"insert into ig_search (doc_id, field, value) values (?, ?, ?)", documentId, field, value];
        if (!succeed) {
            NSLog(@"failed update: %@", [self.database lastError]);
        }
    }];
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
    
}

-(NSArray*) searchWithFields:(NSDictionary*)fields {
    
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

@end
