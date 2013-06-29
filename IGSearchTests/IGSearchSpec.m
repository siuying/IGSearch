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
    
        it(@"should raise error when doc id is nil", ^{
            [[theBlock(^{
                [search indexDocument:@{@"title": @"Zelda"} withId:nil];
            }) should] raise];
            [[theValue([search count]) should] equal:theValue(0)];
        });

        it(@"should raise error when input document key or value is not string", ^{
            BOOL succeed = [search indexDocument:@{@"title": @[]} withId:@"1"];
            [[theValue(succeed) should] equal:theValue(NO)];
            
            succeed = [search indexDocument:@{@[]: @"title"} withId:@"1"];
            [[theValue(succeed) should] equal:theValue(NO)];

            succeed = [search indexDocument:@{@"title": @"Mario", @"system": @[]} withId:@"1"];
            [[theValue(succeed) should] equal:theValue(NO)];

            [[theValue([search count]) should] equal:theValue(0)];
        });
    });

    describe(@"-search:", ^{
        it(@"should search document", ^{
            [search indexDocument:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} withId:@"1"];
            [search indexDocument:@{@"title": @"Super Mario Bros", @"system": @"NES"} withId:@"2"];
            [search indexDocument:@{@"title": @"Sonic", @"system": @"Megadrive"} withId:@"3"];

            NSArray* games = [search search:@"Street"];
            [[games shouldNot] beNil];
            [[games should] haveCountOf:1];
            [[games[0] should] equal:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"}];
        });
    });
});

SPEC_END