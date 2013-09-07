//
//  IGSearchTests.m
//  IGSearchTests
//
//  Created by Chong Francis on 13年6月30日.
//  Copyright (c) 2013年 Ignition Soft. All rights reserved.
//

#import "IGSearch.h"
#import "Kiwi.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

SPEC_BEGIN(IGSearchSpec)

describe(@"IGSearch", ^{
    __block IGSearch* search;
    
    beforeAll(^{
        [DDLog addLogger:[DDASLLogger sharedInstance]];
        [DDLog addLogger:[DDTTYLogger sharedInstance]];
    });
    
    beforeEach(^{
       search = [[IGSearch alloc] initWithPath:@":memory:"]; 
    });

    describe(@"-indexDocument:withId:", ^{
        it(@"should index document", ^{
            [[theValue([search count]) should] equal:theValue(0)];
            [search indexDocument:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} withId:@"1"];
            [[theValue([search count]) should] equal:theValue(1)];
        });
    
        it(@"should raise exception when doc id is nil", ^{
            [[theBlock(^{
                [search indexDocument:@{@"title": @"Zelda"} withId:nil];
            }) should] raise];
            [[theValue([search count]) should] equal:theValue(0)];
        });

        it(@"should raise exception when input document key or value is not string", ^{
            [[theBlock(^{
                [search indexDocument:@{@"title": @[]} withId:@"1"];
            }) should] raise];

            [[theBlock(^{
                [search indexDocument:@{@[]: @"title"} withId:@"1"];
            }) should] raise];
            
            [[theBlock(^{
                [search indexDocument:@{@"title": @"Mario", @"system": @[]} withId:@"1"];
            }) should] raise];
            
            [[theValue([search count]) should] equal:theValue(0)];
        });
        
        it(@"should find only one object even two fields matched", ^{
            [search indexDocument:@{@"title": @"Mega Man 10", @"system": @"Mega Drive"} withId:@"1"];
            NSArray* results = [search search:@"Mega"];
            [[theValue([results count]) should] equal:theValue(1)];
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
    
    describe(@"-search:withField:fetchIdOnly:", ^{
        it(@"should return only ID if the fetchIdOnly is YES", ^{
            [search indexDocument:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} withId:@"1"];
            [search indexDocument:@{@"title": @"Mega Man", @"system": @"Mega Drive"} withId:@"2"];

            NSArray* results = [search search:@"Street" withField:@"title" fetchIdOnly:YES];
            [[results should] haveCountOf:1];
            [[results[0] should] beKindOfClass:[NSString class]];
            [[results[0] should] equal:@"1"];
            
            results = [search search:@"Mega" withField:nil fetchIdOnly:YES];
            [[results should] haveCountOf:1];
            [[results[0] should] beKindOfClass:[NSString class]];
            [[results[0] should] equal:@"2"];
        });

        it(@"should return a dictionary if the fetchIdOnly is NO", ^{
            [search indexDocument:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} withId:@"1"];
            
            NSArray* results = [search search:@"Street" withField:@"title" fetchIdOnly:NO];
            [[results should] haveCountOf:1];
            [[results[0] should] beKindOfClass:[NSDictionary class]];
            [[results[0][@"system"] should] equal:@"Xbox 360"];
        });
    });
    
    describe(@"-documentWithId:", ^{
        __block NSDictionary* document1;
        __block NSDictionary* document2;
        
        beforeEach(^{
            document1 = @{@"title": @"Street Fighter 4", @"system": @"Xbox 360"};
            document2 = @{@"title": @"Mega Man", @"system": @"Mega Drive"};
            
            [search indexDocument:document1 withId:@"1"];
            [search indexDocument:document2 withId:@"2"];
        });
        
        it(@"should return the document with specified ID", ^{
            NSDictionary* document = [search documentWithId:@"1"];
            [[document should] equal:document1];
        });
        
        it(@"should return nil if document not found", ^{
            NSDictionary* document = [search documentWithId:@"3"];
            [[document should] beNil];
        });
    });
    
    describe(@"-deleteDocumentWithId:", ^{
        __block NSDictionary* document1;
        __block NSDictionary* document2;
        
        beforeEach(^{
            document1 = @{@"title": @"Street Fighter 4", @"system": @"Xbox 360"};
            document2 = @{@"title": @"Mega Man", @"system": @"Mega Drive"};
            
            [search indexDocument:document1 withId:@"1"];
            [search indexDocument:document2 withId:@"2"];
        });

        it(@"should delete the document with specified ID", ^{
            NSDictionary* document = [search documentWithId:@"1"];
            [[document shouldNot] beNil];

            [search deleteDocumentWithId:@"1"];
            
            document = [search documentWithId:@"1"];
            [[document should] beNil];
        });
    });
    
    
});

SPEC_END