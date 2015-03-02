//
//  ETRLocationManager.m
//  Realay
//
//  Created by Michel S on 05.05.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRLocationHelper.h"

#import "ETRRoom.h"
#import "ETRSession.h"
#import "ETRAlertViewBuilder.h"

#define kMethodEnumDist 0
#define kMethodEnumAccu 1
#define kMethodEnumRadi 2

static ETRLocationHelper *sharedInstance;

@interface ETRLocationHelper()

@property (nonatomic) BOOL doUpdateFast;

@end

@implementation ETRLocationHelper

@synthesize doUpdateFast = _doUpdateFast;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[ETRLocationHelper alloc] init];
    }
}

+ (ETRLocationHelper *)sharedManager {
    return sharedInstance;
}

+ (CLLocation *)location {
    return [sharedInstance location];
}

+ (NSInteger)distanceToRoom:(ETRRoom *)room {
    if (!sharedInstance || ![sharedInstance location]) {
        return [[room queryDistance] integerValue];
    } else {
        return [[sharedInstance location] distanceFromLocation:[room location]];
    }
}

+ (NSString *)formattedDistanceToRoom:(ETRRoom *)room {
    return [ETRChatObject formattedLength:[self distanceToRoom:room]];
}

- (void)launch {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        [self startMonitoringSignificantLocationChanges];
        [super startUpdatingLocation];
        return;
    }
    
    if ([self respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self requestWhenInUseAuthorization];
    } else {
        [self startMonitoringSignificantLocationChanges];
        [super startUpdatingLocation];
    }
    
    if ([self respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self requestAlwaysAuthorization];
    } else {
        [self startMonitoringSignificantLocationChanges];
        [super startUpdatingLocation];
    }
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self launch];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *newLocation = locations[0];
    
    NSLog(@"didUpdateLocations: Interval: %g", [[[self location] timestamp] timeIntervalSinceDate:[newLocation timestamp]]);
}

/*
 Distance in _metres_ between the outer _radius_ of a given Room, not the central point,
 and the current device location;
 values below 10 are handled as 0 to avoid unnecessary precision
 */
- (NSInteger)distanceToRoom:(ETRRoom *)room {
    if (![self location]) return 2744;
    if (!room) return 2644;
    
    NSInteger value = [[self location] distanceFromLocation:[room location]];
    value -= [[room radius] integerValue];
    if (value < 10) return 0;
    else return value;
}

- (NSString *)formattedDistanceToRoom:(ETRRoom *)room {
    return [ETRChatObject formattedLength:[self distanceToRoom:room]];
}

@end
