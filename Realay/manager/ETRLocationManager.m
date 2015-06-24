//
//  ETRLocationManager.m
//  Realay
//
//  Created by Michel S on 05.05.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRLocationManager.h"

#import "ETRActionManager.h"
#import "ETRAlertViewFactory.h"
#import "ETRBouncer.h"
#import "ETRDefaultsHelper.h"
#import "ETRReadabilityHelper.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"

static CFTimeInterval const ETRScheduleInterval = 10.0 * 60.0;

static ETRLocationManager * SharedInstance;


@interface ETRLocationManager()

@property (nonatomic) BOOL doUpdateFast;

@property (nonatomic) BOOL isInSessionRegion;

@end


@implementation ETRLocationManager

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
          @"New Location: %g, %g, %g, %g",
          _location.coordinate.latitude,
          _location.coordinate.longitude,
          [_location horizontalAccuracy],
          [_location verticalAccuracy]
          );
#endif
    
    if ([ETRDefaultsHelper doUpdateRoomListAtLocation:_location]) {
#ifdef DEBUG
        NSLog(@"%@: Updating Rooms.", [self class]);
#endif
        [ETRServerAPIHelper updateRoomListWithCompletionHandler:nil];
    }
    
    [self stopUpdatingLocation];
    [self startMonitoringSignificantLocationChanges];
    
    if ([[ETRSessionManager sharedManager] didStartSession]) {
        // If a Session has been started, monitor entering and exiting the Room radius.
        [self updateSessionRegionDistance];
        [[ETRActionManager sharedManager] fetchUpdatesWithCompletionHandler:nil];
    }
}

+ (BOOL)isInSessionRegion {
    return [[ETRLocationManager sharedManager] updateSessionRegionDistance];
}

- (BOOL)updateSessionRegionDistance {
    BOOL wasInSessionRegion = _isInSessionRegion;
    
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    
    if (sessionRoom && [ETRLocationManager didAuthorizeWhenInUse]) {
        int roomDistance = [self distanceToRoom:sessionRoom];
        _isInSessionRegion = roomDistance < 10;
        if (roomDistance > 4500) {
            [[ETRBouncer sharedManager] kickForReason:ETRKickReasonLocation calledBy:@"farAway"];
            return NO;
        }
    } else {
        _isInSessionRegion = NO;
    }
        
    if (wasInSessionRegion != _isInSessionRegion) {
        if (_isInSessionRegion) {
            [[ETRBouncer sharedManager] cancelLocationWarnings];
        } else {
            [[ETRBouncer sharedManager] warnForReason:ETRKickReasonLocation];
        }
    }
    
    return _isInSessionRegion;
}

+ (BOOL)didAuthorizeAlways {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        return YES;
    } else {
        return NO;
    }
}

+ (BOOL)didAuthorizeWhenInUse {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    return status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways;
}

- (void)launch:(NSTimer *)timer {
    if (![ETRLocationManager didAuthorizeAlways]) {
        if ([self respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [self requestWhenInUseAuthorization];
        }
        
        if ([self respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [self requestAlwaysAuthorization];
        }
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
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"ERROR: LocationManager failed: %@", [error description]);
}

/**
 Distance in _metres_ between the outer _radius_ of a given Room, not the central point,
 and the current device location;
 Uses the server API / query distance value, if the device location is unknown;
 Values below 10 are handled as 0 to avoid unnecessary precision
 */
- (int)distanceToRoom:(ETRRoom *)room {
    if (!room) {
        return 7715;
    }
    
    int distanceToCenter;
    if (![self location]) {
        distanceToCenter = (int) [[room queryDistance] integerValue];
    } else {
        distanceToCenter = (int) [[self location] distanceFromLocation:[room location]];
    }
    
    int distanceToRadius = distanceToCenter - (int) [[room radius] integerValue];
    if (distanceToRadius < 10) {
        return 0;
    } else {
        return distanceToRadius;
    }
    
//    NSInteger value = [[self location] distanceFromLocation:[room location]];
//    value -= [[room radius] integerValue];
//    if (value < 10) return 0;
//    else return value;
}

@end
