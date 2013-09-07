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
 Index a doucment asynchronously.

 @param document The document. Must be a dictionary with key and values as String.
 @param docId A string key represent the document.
 @note The index is done asynchronously. It is safe to use indexDocument:withId: concurrently with any other methods.
 */
-(void) indexDocument:(NSDictionary*)document withId:(NSString*)docId;

/**
 Count number of document asynchronously.
*/
-(void) countWithBlock:(void(^)(NSUInteger count))block;

/**
 Search the database asynchronously, with string on any fields sorted by match rank.
 @param query the search query
 @param block when the search result is available, documents is invoked.
 */
-(void) search:(NSString*)query block:(void(^)(NSArray* documents))block;

/**
 Search the database asynchronously, with string on any fields sorted by match rank.
 @param query The search query.
 @param field The field to search. if nil, search all fields, otherwise only search on specific field.
 @param block when the search result is available, documents is invoked.
 */
-(void) search:(NSString*)query withField:(NSString*)field block:(void(^)(NSArray* documents))block;

/**
 Search the database asynchronously, with string on any fields sorted by match rank.
 @param query The search query.
 @param field The field to search. if nil, search all fields, otherwise only search on specific field.
 @param fetchIdOnly Only return the doc id of result. If YES, only fetch the ID. otherwise, return whole document.
 @param block when the search result is available, documents is invoked.
 */
-(void) search:(NSString*)query withField:(NSString*)field fetchIdOnly:(BOOL)fetchIdOnly block:(void(^)(NSArray* documents))block;

/**
 Find document with specific ID asynchronously.
 
 @param docId the ID of the document to find
 */
-(void) documentWithId:(NSString*)docId block:(void(^)(NSDictionary* document))block;

/**
 Delete document with specified docId asynchronously.

 @param docId the ID of the document to be deleted
 */
-(void) deleteDocumentWithId:(NSString*)docId;

@end

@interface IGSearch (Synchronous)
/**
 Synchronously Count number of document.
 */
-(NSUInteger) count;

/**
 Synchronously search the database with string on any fields sorted by match rank.
 @param query the search query
 @return NSArray* array of document indexed, having fields contain the string, sorted by rank.
 */
-(NSArray*) search:(NSString*)query;

/**
 Synchronously search the database with string on specific field sorted by match rank.
 @param query The search query.
 @param field The field to search. if nil, search all fields, otherwise only search on specific field.
 @return NSArray* array of document indexed, having fields contain the string, sorted by rank.
 */
-(NSArray*) search:(NSString*)query withField:(NSString*)field;

/**
 Synchronously search the database with string on specific field sorted by match rank, optionally only return the doc ID.

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

@end
