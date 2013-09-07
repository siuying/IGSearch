//
//  IGSearch.h
//  IGSearch
//
//  Created by Chong Francis on 13年6月30日.
//  Copyright (c) 2013年 Ignition Soft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

#ifndef IGSEARCH_LOG_LEVEL
#define IGSEARCH_LOG_LEVEL LOG_LEVEL_OFF
#endif

@interface IGSearch : NSObject

@property (nonatomic, strong, readonly) FMDatabase *database;

/**
 Create a search engine by supply a path to the database.
 @param path document path to the database
 */
-(id) initWithPath:(NSString*) path;

/**
 Close the database.
 */
-(BOOL) close;

/**
 Index a doucment.
 @param document The document. Must be a dictionary with key and values as String.
 @param docId A string key represent the document.
 @note The index is done asynchronously. It is safe to use indexDocument:withId: concurrently with any other methods.
 */
-(void) indexDocument:(NSDictionary*)document withId:(NSString*)docId;

/**
 Count number of document was indexed.
*/
-(NSUInteger) count;

/**
 Search the database with string on any fields sorted by match rank.
 @param query the search query
 @return NSArray* array of document indexed, having fields contain the string, sorted by rank.
 */
-(NSArray*) search:(NSString*)query;

/**
 Search the database with string on specific field sorted by match rank.
 @param query The search query.
 @param field The field to search. if nil, search all fields, otherwise only search on specific field.
 @return NSArray* array of document indexed, having fields contain the string, sorted by rank.
 */
-(NSArray*) search:(NSString*)query withField:(NSString*)field;

/**
 Search the database with string on specific field sorted by match rank, optionally only return the doc ID.
 @param query The search query.
 @param field The field to search. if nil, search all fields, otherwise only search on specific field.
 @param fetchIdOnly Only return the doc id of result. If YES, only fetch the ID. otherwise, return whole document.
 @return NSArray* If fetchIdOnly is YES, return array of document IDs. Otherwise, return array of documents.
 */
-(NSArray*) search:(NSString*)query withField:(NSString*)field fetchIdOnly:(BOOL)fetchIdOnly;

/**
 Find document with specific ID.
 
 @param docId the ID of the document to find
 @return the document, or nil if such document cannot be found
 */
-(NSDictionary*) documentWithId:(NSString*)docId;

/**
 Delete document with specified docId

 @param docId the ID of the document to be deleted
 */
-(void) deleteDocumentWithId:(NSString*)docId;

@end
