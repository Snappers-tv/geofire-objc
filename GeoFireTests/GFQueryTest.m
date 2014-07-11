//
//  GFQueryTest.m
//  GeoFire
//
//  Created by Jonny Dimond on 7/9/14.
//  Copyright (c) 2014 Firebase. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "GFRealDataTest.h"

@interface GFQueryTest : GFRealDataTest

@end

@implementation GFQueryTest

#define C(x,y) CLLocationCoordinate2DMake(x,y)
#define L(x,y) [[CLLocation alloc] initWithLatitude:x longitude:y]
#define SETLOC(k,x,y) [self.geoFire setLocation:C(x,y) forKey:k]
#define L2S(l) [NSString stringWithFormat:@"[%f, %f]", (l).coordinate.latitude, (l).coordinate.longitude]

- (void)testKeyEntered
{
    SETLOC(@"0", 0, 0);
    SETLOC(@"1", 37.0000, -122.0000);
    SETLOC(@"2", 37.0001, -122.0001);
    SETLOC(@"3", 37.1000, -122.0000);
    SETLOC(@"4", 37.0002, -121.9998);
    GFQuery *query = [self.geoFire queryAtLocation:C(37,-122) withRadius:500];
    NSMutableDictionary *actual = [NSMutableDictionary dictionary];
    WAIT_SIGNALS(3, ^(dispatch_semaphore_t barrier) {
        [query observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
            if ([actual objectForKey:key] == nil) {
                actual[key] = L2S(location);
            } else {
                XCTFail(@"Key entered twice!");
            }
            dispatch_semaphore_signal(barrier);
        }];
    });
    NSDictionary *expected = @{ @"1": L2S(L(37,-122)), @"2": L2S(L(37.0001, -122.0001)), @"4": L2S(L(37.0002, -121.9998)) };
    XCTAssertEqualObjects(actual, expected);
    [query removeAllObservers];
}

- (void)testKeyExited
{
    SETLOC(@"0", 0, 0);
    SETLOC(@"1", 37.0000, -122.0000);
    SETLOC(@"2", 37.0001, -122.0001);
    SETLOC(@"3", 37.1000, -122.0000);
    SETLOC(@"4", 37.0002, -121.9998);
    GFQuery *query = [self.geoFire queryAtLocation:C(37,-122) withRadius:500];
    NSMutableSet *actual = [NSMutableSet set];
    WAIT_SIGNALS(2, ^(dispatch_semaphore_t barrier) {
        [query observeEventType:GFEventTypeKeyExited withBlock:^(NSString *key, CLLocation *location) {
            XCTAssertNil(location);
            if (![actual containsObject:key]) {
                [actual addObject:key];
            } else {
                XCTFail(@"Key exited twice!");
            }
            dispatch_semaphore_signal(barrier);
        }];
        [self.geoFire setLocation:C(0,0) forKey:@"0"]; // not in query
        [self.geoFire setLocation:C(0,0) forKey:@"1"]; // exited
        [self.geoFire setLocation:C(0,0) forKey:@"2"]; // exited
        [self.geoFire setLocation:C(2,0) forKey:@"3"]; // not in query
        [self.geoFire setLocation:C(3,0) forKey:@"0"]; // not in query
        [self.geoFire setLocation:C(4,0) forKey:@"1"]; // not in query
        [self.geoFire setLocation:C(5,0) forKey:@"2"]; // not in query
    });
    NSSet *expected = [NSSet setWithArray:@[@"1", @"2"]];
    XCTAssertEqualObjects(actual, expected);
    [query removeAllObservers];
}

- (void)testKeyMoved
{
    SETLOC(@"0", 0, 0);
    SETLOC(@"1", 37.0000, -122.0000);
    SETLOC(@"2", 37.0001, -122.0001);
    SETLOC(@"3", 37.1000, -122.0000);
    SETLOC(@"4", 37.0002, -121.9998);
    GFQuery *query = [self.geoFire queryAtLocation:C(37,-122) withRadius:500];
    NSMutableArray *actual = [NSMutableArray array];
    WAIT_SIGNALS(4, ^(dispatch_semaphore_t barrier) {
        [query observeEventType:GFEventTypeKeyMoved withBlock:^(NSString *key, CLLocation *location) {
            [actual addObject:key];
            [actual addObject:L2S(location)];
            dispatch_semaphore_signal(barrier);
        }];
        SETLOC(@"0", 1, 1); // outside of query
        SETLOC(@"1", 37.0001, -122.0000); // moved
        SETLOC(@"2", 37.0001, -122.0001); // location stayed the same
        SETLOC(@"4", 37.0002, -122.0000); // moved
        SETLOC(@"3", 37.0000, -122.0000); // entered
        SETLOC(@"3", 37.0003, -122.0003); // moved
        SETLOC(@"2", 0, 0); // exited
        SETLOC(@"2", 37.0000, -122.0000); // entered
        SETLOC(@"2", 37.0001, -122.0001); // moved
    });
    NSArray *expected = @[ @"1", L2S(L(37.0001, -122.0000)),
                           @"4", L2S(L(37.0002, -122.0000)),
                           @"3", L2S(L(37.0003, -122.0003)),
                           @"2", L2S(L(37.0001, -122.0001))];

    XCTAssertEqualObjects(actual, expected);
    [query removeAllObservers];
}

- (void)testUpdateTriggersKeyEntered
{
    SETLOC(@"0", 0, 0);
    SETLOC(@"1", 37.0000, -122.0000);
    SETLOC(@"2", 37.0001, -122.0001);
    SETLOC(@"3", 37.1000, -122.0000);
    SETLOC(@"4", 37.0002, -121.9998);
    GFQuery *query = [self.geoFire queryAtLocation:C(37,-122) withRadius:500];
    __block NSMutableDictionary *actual = [NSMutableDictionary dictionary];
    [query observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
        if ([actual objectForKey:key] == nil) {
            actual[key] = L2S(location);
        } else {
            XCTFail(@"Key entered twice!");
        }
    }];
    WAIT_FOR(actual.count == 3);
    actual = [NSMutableDictionary dictionary];
    query.center = CLLocationCoordinate2DMake(37.1000, -122.0000);
    WAIT_FOR(actual.count == 1);

    NSDictionary *expected = @{ @"3": L2S(L(37.1000,-122.0000)) };
    XCTAssertEqualObjects(actual, expected);
    [query removeAllObservers];
}

- (void)testUpdateTriggersKeyExited
{
    SETLOC(@"0", 0, 0);
    SETLOC(@"1", 37.0000, -122.0000);
    SETLOC(@"2", 37.0001, -122.0001);
    SETLOC(@"3", 37.1000, -122.0000);
    SETLOC(@"4", 37.0002, -121.9998);
    GFQuery *query = [self.geoFire queryAtLocation:C(37,-122) withRadius:500];
    NSMutableSet *actual = [NSMutableSet set];
    __block NSUInteger count = 0;
    [query observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
        count++;
    }];
    WAIT_FOR(count == 3);
    [query observeEventType:GFEventTypeKeyExited withBlock:^(NSString *key, CLLocation *location) {
        if (![actual containsObject:key]) {
            [actual addObject:key];
        } else {
            XCTFail(@"Key exited twice!");
        }
    }];
    query.center = CLLocationCoordinate2DMake(37.1000, -122.0000);
    WAIT_FOR(actual.count == 3);

    NSSet *expected = [NSSet setWithArray:@[@"1", @"2", @"4"]];
    XCTAssertEqualObjects(actual, expected);
    [query removeAllObservers];
}

- (void)testUpdateDoesNotTriggerKeyMoved
{
    SETLOC(@"0", 0, 0);
    SETLOC(@"1", 37.0000, -122.0000);
    SETLOC(@"2", 37.0001, -122.0001);
    SETLOC(@"3", 37.1000, -122.0000);
    SETLOC(@"4", 37.0002, -121.9998);
    GFQuery *query = [self.geoFire queryAtLocation:C(37,-122) withRadius:500];
    __block NSUInteger count = 0;
    [query observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
        count++;
    }];
    [query observeEventType:GFEventTypeKeyMoved withBlock:^(NSString *key, CLLocation *location) {
        XCTFail(@"Key moved!");
    }];
    WAIT_FOR(count == 3);
    query.center = CLLocationCoordinate2DMake(37.0010, -122.0000);
    query.radius = 400;
    [NSThread sleepForTimeInterval:0.1];
    query.center = CLLocationCoordinate2DMake(37.1000, -122.0000);
    query.radius = 10000;
    [NSThread sleepForTimeInterval:0.1];
    query.center = CLLocationCoordinate2DMake(0,0);
    [NSThread sleepForTimeInterval:0.1];

    [query removeAllObservers];
}

- (void)testRemoveSingleObserver
{
    SETLOC(@"0", 0, 0);
    SETLOC(@"1", 37.0000, -122.0000);
    SETLOC(@"2", 37.0001, -122.0001);
    SETLOC(@"3", 37.1000, -122.0000);
    SETLOC(@"4", 37.0002, -121.9998);
    GFQuery *query = [self.geoFire queryAtLocation:C(37,-122) withRadius:500];
    __block NSUInteger keyEnteredEvents = 0;
    __block NSUInteger keyExitedEvents = 0;
    __block NSUInteger keyMovedEvents = 0;
    __block BOOL shouldIgnore = YES;
    [query observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
        keyEnteredEvents++;
    }];
    FirebaseHandle handleEntered = [query observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
        if (!shouldIgnore) {
            XCTFail(@"Event triggered for removed observer!");
        }
    }];
    [query observeEventType:GFEventTypeKeyMoved withBlock:^(NSString *key, CLLocation *location) {
        keyMovedEvents++;
    }];
    FirebaseHandle handleMoved = [query observeEventType:GFEventTypeKeyMoved withBlock:^(NSString *key, CLLocation *location) {
        if (!shouldIgnore) {
            XCTFail(@"Event triggered for removed observer!");
        }
    }];
    [query observeEventType:GFEventTypeKeyExited withBlock:^(NSString *key, CLLocation *location) {
        keyExitedEvents++;
    }];
    FirebaseHandle handleExited = [query observeEventType:GFEventTypeKeyExited withBlock:^(NSString *key, CLLocation *location) {
        if (!shouldIgnore) {
            XCTFail(@"Event triggered for removed observer!");
        }
    }];
    WAIT_FOR(keyEnteredEvents == 3);
    [query removeObserverWithFirebaseHandle:handleEntered];
    [query removeObserverWithFirebaseHandle:handleMoved];
    [query removeObserverWithFirebaseHandle:handleExited];
    shouldIgnore = NO;
    keyEnteredEvents = 0;
    keyExitedEvents = 0;
    keyMovedEvents = 0;

    SETLOC(@"0", 37.0000, -122.0000);
    SETLOC(@"1", 0, 0);
    SETLOC(@"2", 37.0000, -122.0001);
    WAIT_FOR(keyExitedEvents == 1);
    WAIT_FOR(keyEnteredEvents == 1);
    WAIT_FOR(keyMovedEvents == 1);
    [query removeAllObservers];
}

- (void)testRemoveAllObservers
{
    SETLOC(@"0", 0, 0);
    SETLOC(@"1", 37.0000, -122.0000);
    SETLOC(@"2", 37.0001, -122.0001);
    SETLOC(@"3", 37.1000, -122.0000);
    SETLOC(@"4", 37.0002, -121.9998);
    GFQuery *query = [self.geoFire queryAtLocation:C(37,-122) withRadius:500];
    __block BOOL shouldIgnore = YES;
    __block NSUInteger countEntered = 0;
    [query observeEventType:GFEventTypeKeyEntered withBlock:^(NSString *key, CLLocation *location) {
        if (!shouldIgnore) {
            XCTFail(@"Callback triggered!");
        } else {
            countEntered++;
        }
    }];
    [query observeEventType:GFEventTypeKeyMoved withBlock:^(NSString *key, CLLocation *location) {
        if (!shouldIgnore) {
            XCTFail(@"Callback triggered!");
        }
    }];
    [query observeEventType:GFEventTypeKeyExited withBlock:^(NSString *key, CLLocation *location) {
        if (!shouldIgnore) {
            XCTFail(@"Callback triggered!");
        }
    }];
    WAIT_FOR(countEntered == 3);
    [query removeAllObservers];
    shouldIgnore = NO;

    SETLOC(@"1", 37.0001, -122.0001);
    SETLOC(@"0", 37.0000, -122.0000);
    query.center = CLLocationCoordinate2DMake(37.0010, -122.0000);
    query.radius = 400;
    [NSThread sleepForTimeInterval:0.1];
    query.center = CLLocationCoordinate2DMake(37.1000, -122.0000);
    query.radius = 10000;
    [NSThread sleepForTimeInterval:0.1];
    query.center = CLLocationCoordinate2DMake(0,0);
    [NSThread sleepForTimeInterval:0.1];
}


@end