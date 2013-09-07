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

    describe(@"-search:withField:fetchIdOnly: families", ^{
        beforeEach(^{
            [search indexDocument:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} withId:@"1"];
            [search indexDocument:@{@"title": @"Mega Man", @"system": @"Mega Drive"} withId:@"2"];

            [search indexDocument:@{@"title": @"當然，也許一個是印度人，沒錯！"} withId:@"3"];
            [search indexDocument:@{@"title": @"這一個月是訂出標準，對豪宅短期買賣，你口中只講冰冷的數字，在短時間內，嘉蘭部落的需求原為70戶，開放大陸觀光客來台，它在這部分是負責監理工作，哪怕是捅了馬蜂窩，主計長不是今天才做的。"} withId:@"4"];
            [search indexDocument:@{@"title": @"還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴！"} withId:@"5"];
        });

        describe(@"-search:withField:fetchIdOnly:", ^{
            it(@"should return only ID if the fetchIdOnly is YES", ^{
                NSArray* results = [search search:@"Street" withField:@"title" fetchIdOnly:YES];
                [[results should] haveCountOf:1];
                [[results[0] should] beKindOfClass:[NSString class]];
                [[results[0] should] equal:@"1"];
            });
            
            it(@"should return a dictionary if the fetchIdOnly is NO", ^{
                NSArray* results = [search search:@"Street" withField:@"title" fetchIdOnly:NO];
                [[results should] haveCountOf:1];
                [[results[0] should] beKindOfClass:[NSDictionary class]];
                [[results[0][@"system"] should] equal:@"Xbox 360"];
            });

            it(@"should search CJK document", ^{
                NSArray* results = [search search:@"印度人" withField:@"title" fetchIdOnly:NO];
                [[results shouldNot] beNil];
                [[results should] haveCountOf:1];
                [[results[0][@"title"] should] equal:@"當然，也許一個是印度人，沒錯！"];
                
                results = [search search:@"還不賴" withField:@"title" fetchIdOnly:NO];
                [[results shouldNot] beNil];
                [[results should] haveCountOf:1];
                [[results[0][@"title"] should] equal:@"還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴！"];
            });
        });

        describe(@"-search:withField:fetchIdOnly:block:", ^{
            it(@"should return only ID if the fetchIdOnly is YES", ^{
                __block NSArray* results = nil;
                [search search:@"Street" withField:@"title" fetchIdOnly:YES block:^(NSArray *documents) {
                    results = documents;
                }];
                [[expectFutureValue(results) shouldEventually] haveCountOf:1];
                [[results[0] should] beKindOfClass:[NSString class]];
                [[results[0] should] equal:@"1"];
            });
            
            it(@"should return a dictionary if the fetchIdOnly is NO", ^{
                __block NSArray* results = nil;
                [search search:@"Street" withField:@"title" fetchIdOnly:NO block:^(NSArray *documents) {
                    results = documents;
                }];
                [[expectFutureValue(results) shouldEventually] haveCountOf:1];
                [[results[0] should] beKindOfClass:[NSDictionary class]];
                [[results[0][@"system"] should] equal:@"Xbox 360"];
            });
            
            it(@"should search CJK document", ^{
                __block NSArray* results = nil;
                [search search:@"印度人" withField:@"title" fetchIdOnly:NO block:^(NSArray* documents){
                    results = documents;
                }];
                [[expectFutureValue(results) shouldEventually] haveCountOf:1];
                [[results[0][@"title"] should] equal:@"當然，也許一個是印度人，沒錯！"];

                [search search:@"還不賴" withField:@"title" fetchIdOnly:NO block:^(NSArray* documents){
                    results = documents;
                }];
                [[expectFutureValue(results) shouldEventually] haveCountOf:1];
                [[results[0][@"title"] should] equal:@"還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴，還不賴！"];
            });
        });
    });
    
    describe(@"-documentWithId: families", ^{
        __block NSDictionary* document1;
        __block NSDictionary* document2;
        
        beforeEach(^{
            document1 = @{@"title": @"Street Fighter 4", @"system": @"Xbox 360"};
            document2 = @{@"title": @"Mega Man", @"system": @"Mega Drive"};
            
            [search indexDocument:document1 withId:@"1"];
            [search indexDocument:document2 withId:@"2"];
        });
        
        describe(@"-documentWithId:", ^{
            it(@"should return the document with specified ID", ^{
                NSDictionary* document = [search documentWithId:@"1"];
                [[document should] equal:document1];
            });
            
            it(@"should return nil if document not found", ^{
                NSDictionary* document = [search documentWithId:@"3"];
                [[document should] beNil];
            });
        });
        
        describe(@"-documentWithId:block:", ^{
            it(@"should return the document with specified ID", ^{
                __block NSDictionary* document = nil;
                [search documentWithId:@"1" block:^(NSDictionary *d) {
                    document = d;
                }];
                [[expectFutureValue(document) shouldEventually] equal:document1];
            });
            
            it(@"should return nil if document not found", ^{
                __block NSDictionary* document = @{};
                [search documentWithId:@"3" block:^(NSDictionary *d) {
                    document = d;
                }];
                [[expectFutureValue(document) shouldEventually] beNil];
            });
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
    
    describe(@"-count families", ^{
        beforeEach(^{
            [search indexDocument:@{@"title": @"Street Fighter 4", @"system": @"Xbox 360"} withId:@"1"];
            [search indexDocument:@{@"title": @"Mega Man", @"system": @"Mega Drive"} withId:@"2"];
        });
        
        describe(@"-count", ^{
            it(@"should count documents", ^{
                [[theValue([search count]) should] equal:theValue(2)];
            });
        });

        describe(@"-countWithBlock:", ^{
            it(@"should count documents", ^{
                __block NSUInteger count = 0;
                [search countWithBlock:^(NSUInteger _count) {
                    count = _count;
                }];
                [[expectFutureValue(theValue(count)) shouldEventually] equal:theValue(2)];
            });
        });
    });
});

SPEC_END