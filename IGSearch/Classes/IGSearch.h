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

-(BOOL) close;

// Index a document
-(void) indexDocument:(NSDictionary*)document withId:(NSString*)identifier;

// count number of document was indexed
-(NSUInteger) count;

-(NSArray*) search:(NSString*)string;

-(NSArray*) searchWithFields:(NSDictionary*)fields;

@end
