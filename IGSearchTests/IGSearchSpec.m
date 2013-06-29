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

        it(@"should search CJK document", ^{
            [search indexDocument:@{@"title": @"當然，也許一個是印度人，沒錯！"} withId:@"1"];
            [search indexDocument:@{@"title": @"這一個月是訂出標準，對豪宅短期買賣，你口中只講冰冷的數字，在短時間內，嘉蘭部落的需求原為70戶，開放大陸觀光客來台，它在這部分是負責監理工作，哪怕是捅了馬蜂窩，主計長不是今天才做的。"} withId:@"2"];
            [search indexDocument:@{@"title": @"還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴！"} withId:@"3"];
            
            NSArray* results = [search search:@"印度人"];
            [[results shouldNot] beNil];
            [[results should] haveCountOf:1];
            [[results[0][@"title"] should] equal:@"當然，也許一個是印度人，沒錯！"];
            
            results = [search search:@"還不賴"];
            [[results shouldNot] beNil];
            [[results should] haveCountOf:1];
            [[results[0][@"title"] should] equal:@"還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴！"];
        });
    });
    
    describe(@"-search:withField:", ^{
        it(@"should search document", ^{
            [search indexDocument:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} withId:@"1"];
            [search indexDocument:@{@"title": @"Super Mario Bros", @"system": @"NES"} withId:@"2"];
            [search indexDocument:@{@"title": @"Sonic", @"system": @"Mega Drive"} withId:@"3"];
            [search indexDocument:@{@"title": @"Mega Man", @"system": @"NES"} withId:@"4"];

            NSArray* games = [search search:@"Mega" withField:@"system"];
            [[games shouldNot] beNil];
            [[games should] haveCountOf:1];
            [[games[0][@"title"] should] equal:@"Sonic"];
            
            games = [search search:@"Mega" withField:@"title"];
            [[games shouldNot] beNil];
            [[games should] haveCountOf:1];
            [[games[0][@"title"] should] equal:@"Mega Man"];
        });
        
        it(@"should search CJK document", ^{
            [search indexDocument:@{@"title": @"當然，也許一個是印度人，沒錯！"} withId:@"1"];
            [search indexDocument:@{@"title": @"這一個月是訂出標準，對豪宅短期買賣，你口中只講冰冷的數字，在短時間內，嘉蘭部落的需求原為70戶，開放大陸觀光客來台，它在這部分是負責監理工作，哪怕是捅了馬蜂窩，主計長不是今天才做的。"} withId:@"2"];
            [search indexDocument:@{@"title": @"還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴！"} withId:@"3"];
            
            NSArray* results = [search search:@"印度人" withField:@"title"];
            [[results shouldNot] beNil];
            [[results should] haveCountOf:1];
            [[results[0][@"title"] should] equal:@"當然，也許一個是印度人，沒錯！"];
            
            results = [search search:@"還不賴" withField:@"title"];
            [[results shouldNot] beNil];
            [[results should] haveCountOf:1];
            [[results[0][@"title"] should] equal:@"還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴！"];
        });
    });
});

SPEC_END