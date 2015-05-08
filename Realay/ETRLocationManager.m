//
//  ETRLocationManager.m
//  Realay
//
//  Created by Michel S on 05.05.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRLocationManager.h"

#import "ETRAlertViewFactory.h"
#import "ETRDefaultsHelper.h"
#import "ETRReadabilityHelper.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"

static CFTimeInterval const ETRScheduleInterval = 10.0 * 60.0;

static ETRLocationManager * SharedInstance;


@interface ETRLocationManager()

@property (nonatomic) BOOL doUpdateFast;

@property (nonatomic) BOOL didAuthorize;

@end


@implementation ETRLocationManager

@synthesize didAuthorize = _didAuthorize;
@synthesize doUpdateFast = _doUpdateFast;
@synthesize location = _location;

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        SharedInstance = [[ETRLocationManager alloc] init];
        [SharedInstance setDelegate:SharedInstance];
        [SharedInstance launch:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSTimer scheduledTimerWithTimeInterval:ETRScheduleInterval
                                             target:SharedInstance
                                           selector:@selector(launch:)
                                           userInfo:nil
                                            repeats:YES];
        });
    }
}

+ (ETRLocationManager *)sharedManager {
    return SharedInstance;
}

+ (CLLocation *)location {
    ETRLocationManager * managerInstance;
    managerInstance = [ETRLocationManager sharedManager];
    
    CLLocation * location = [managerInstance location];
    if (!location) {
        location = [ETRDefaultsHelper lastUpdateLocation];
        [managerInstance launch:nil];
    }
    return location;
}

- (void)setLocation:(CLLocation *)location {
    _location = location;
    
#ifdef DEBUG
    NSLog(
          @"DEBUG: New Location: %g, %g, %g, %g",
          _location.coordinate.latitude,
          _location.coordinate.longitude,
          [_location horizontalAccuracy],
          [_location verticalAccuracy]
          );
#endif
    
    if ([ETRDefaultsHelper doUpdateRoomListAtLocation:_location]) {
        [ETRServerAPIHelper updateRoomListWithCompletionHandler:nil];
    }
    
    [self stopUpdatingLocation];
    [self startMonitoringSignificantLocationChanges];
}

+ (BOOL)isInSessionRegion {
    if ([ETRLocationManager didAuthorize]) {
        ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
        return [[ETRLocationManager sharedManager] distanceToRoom:sessionRoom] < 10;
    } else {
        return NO;
    }
}

+ (BOOL)didAuthorize {
//    return YES;
    return [[ETRLocationManager sharedManager] didAuthorize];
}

- (void)launch:(NSTimer *)timer {
//    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
//        [self startMonitoringSignificantLocationChanges];
//        [super startUpdatingLocation];
//        return;
//    }
    
    if ([self respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self requestWhenInUseAuthorization];
    }
    
    if ([self respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self requestAlwaysAuthorization];
    }
    
    [super startUpdatingLocation];
}

#pragma mark -
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self launch:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (!locations || ![locations count]) {
        NSLog(@"ERROR: Received empty Locations Array.");
        return;
    }
    
    [self setLocation:locations[0]];
    
    NSLog(@"didUpdateLocations: Interval: %g", [[NSDate date] timeIntervalSinceDate:[_location timestamp]]);
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
