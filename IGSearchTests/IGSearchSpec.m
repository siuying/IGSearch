//
//  IGSearchTests.m
//  IGSearchTests
//
//  Created by Chong Francis on 13年6月30日.
//  Copyright (c) 2013年 Ignition Soft. All rights reserved.
//

#import "IGSearch.h"
#import "Kiwi.h"

SPEC_BEGIN(IGSearchSpec)

describe(@"IGSearch", ^{
    __block IGSearch* search;
    
    beforeEach(^{
       search = [[IGSearch alloc] initWithPath:@":memory:"]; 
    });

    describe(@"-indexDocument:withId:", ^{
        it(@"should index document", ^{
            [[theValue([search count]) should] equal:theValue(0)];
            [search indexDocument:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} withId:@"1"];
            [[theValue([search count]) should] equal:theValue(1)];
        });
    });
});

SPEC_END