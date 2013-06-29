//
//  IGSearch.h
//  IGSearch
//
//  Created by Chong Francis on 13年6月30日.
//  Copyright (c) 2013年 Ignition Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

@interface IGSearch : NSObject

@property (nonatomic, strong) FMDatabase *database;

-(id) initWithPath:(NSString*) path;

/*
 Close the database.
 */
-(BOOL) close;

/* 
 Index a doucment.
 @param document The document. Must be a dictionary with key and values as String.
 @param docId A string key repredent the document.
 */
-(BOOL) indexDocument:(NSDictionary*)document withId:(NSString*)docId;

/*
 Count number of document was indexed.
*/
-(NSUInteger) count;

/*
 Search the database with string on any fields.
 @param query the search query
 @return NSArray* array of document indexed, having fields contain the string, sorted by rank.
 */
-(NSArray*) search:(NSString*)string;

/*
 Search the database with string on specific field.
 @param query The search query.
 @param field The field to search.
 @return NSArray* array of document indexed, having fields contain the string, sorted by rank.
 */
-(NSArray*) search:(NSString*)string withField:(NSString*)field;

@end
