//
//  ETRLocationManager.m
//  Realay
//
//  Created by Michel S on 05.05.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRLocationManager.h"

#import "ETRAlertViewFactory.h"
#import "ETRReadabilityHelper.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"

static ETRLocationManager *sharedInstance;

@interface ETRLocationManager()

@property (nonatomic) BOOL doUpdateFast;

@property (nonatomic) BOOL didAuthorize;

@end

@implementation ETRLocationManager

@synthesize didAuthorize = _didAuthorize;
@synthesize doUpdateFast = _doUpdateFast;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[ETRLocationManager alloc] init];
    }
}

+ (ETRLocationManager *)sharedManager {
    return sharedInstance;
}

+ (CLLocation *)location {
    return [[ETRLocationManager sharedManager] location];
}

+ (BOOL)isInSessionRegion {
    if ([ETRLocationManager didAuthorize]) {
        ETRRoom *sessionRoom = [[ETRSessionManager sharedManager] room];
        return [[ETRLocationManager sharedManager] distanceToRoom:sessionRoom] < 10;
    } else {
        return NO;
    }
}

+ (BOOL)didAuthorize {
    // DEBUG:
    return YES;
//    return [[ETRLocationManager sharedManager] didAuthorize];
}

- (void)launch {    
//    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
//        [self startMonitoringSignificantLocationChanges];
//        [super startUpdatingLocation];
//        return;
//    }
    
    if ([self respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self requestWhenInUseAuthorization];
    } else {
        [self startMonitoringSignificantLocationChanges];
    }
    
    if ([self respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self requestAlwaysAuthorization];
    } else {
        [self startMonitoringSignificantLocationChanges];
    }
    
    [super startUpdatingLocation];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self launch];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!locations || ![locations count]) {
        NSLog(@"ERROR: Received empty Locations Array.");
        return;
    }
    
    CLLocation *newLocation = locations[0];
    
    NSLog(@"didUpdateLocations: Interval: %g", [[[self location] timestamp] timeIntervalSinceDate:[newLocation timestamp]]);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"LocationManager didFailWithError: %@", [error description]);
}

/*
 Distance in _metres_ between the outer _radius_ of a given Room, not the central point,
 and the current device location;
 Uses the server API / query distance value, if the device location is unknown;
 Values below 10 are handled as 0 to avoid unnecessary precision
 */
- (NSInteger)distanceToRoom:(ETRRoom *)room {
    if (!room) {
        return 7715;
    }
    
    NSInteger distanceToCenter;
    if (![self location]) {
        distanceToCenter = [[room queryDistance] integerValue];
    } else {
        distanceToCenter = [[self location] distanceFromLocation:[room location]];
    }
    
    NSInteger distanceToRadius = distanceToCenter - [[room radius] integerValue];
    if (distanceToRadius < 10) {
        return 0;
    } else {
        return distanceToRadius;
    }
    
    NSInteger value = [[self location] distanceFromLocation:[room location]];
    value -= [[room radius] integerValue];
    if (value < 10) return 0;
    else return value;
}

@end
