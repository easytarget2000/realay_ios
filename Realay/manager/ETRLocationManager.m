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
#import "ETRCoreDataHelper.h"
#import "ETRBouncer.h"
#import "ETRDefaultsHelper.h"
#import "ETRFormatter.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"

static CFTimeInterval const ETRScheduleInterval = 10.0 * 60.0;

static ETRLocationManager * SharedInstance;


@interface ETRLocationManager()

@property (nonatomic) BOOL isUpdatingLocation;

@property (nonatomic) BOOL isMonitoringSignificantLocationChanges;

@end


@implementation ETRLocationManager

@synthesize location = _location;

+ (void)initialize {
//    static BOOL initialized = NO;
    if (!SharedInstance) {
//        initialized = YES;
        SharedInstance = [[ETRLocationManager alloc] init];
        [SharedInstance setDelegate:SharedInstance];
        
        dispatch_async(
                       dispatch_get_main_queue(),
                       ^{
                           [SharedInstance launch:nil];
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
//    CLLocationCoordinate2D coordinate;
//    coordinate.latitude = 52.561404;
//    coordinate.longitude = 13.214341;
//    return [[CLLocation alloc] initWithCoordinate:coordinate
//                                         altitude:50.0
//                               horizontalAccuracy:50.0
//                                 verticalAccuracy:50.0
//                                        timestamp:[NSDate date]];
    
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
    BOOL didStartSession = [[ETRSessionManager sharedManager] didStartSession];
    if (didStartSession) {
        [[ETRActionManager sharedManager] fetchUpdatesWithCompletionHandler:nil];
    }
    
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
        NSLog(@"Updating Rooms, new Location.");
#endif
        [ETRServerAPIHelper updateRoomListWithCompletionHandler:nil];
    } else {
        // Update the distance to the known Rooms.
        BOOL didChangeDistance = NO;
        for (ETRRoom * room in [ETRCoreDataHelper rooms]) {
            // Distance in _metres_ between the outer _radius_ of a given Room, not the central point,
            // and the current device location.
            int newDistance = [self distanceToRoom:room];
            
            int difference = (int) [[room distance] integerValue] - newDistance;
            
            if (difference > 10 || difference < -10) {
                [room setDistance:@(newDistance)];
                didChangeDistance = YES;
            }
        }
        if (didChangeDistance) {
            [ETRCoreDataHelper saveContext];
        }
    }
    
    // If a Session has been started, monitor entering and exiting the Room radius.
    if (didStartSession) {
        [self updateSessionRegionDistance];
        
        if (!_isUpdatingLocation) {
            [self startUpdatingLocation];
            _isUpdatingLocation = YES;
            _isMonitoringSignificantLocationChanges = NO;
        }
    } else {
        if (_isUpdatingLocation) {
            [self stopUpdatingLocation];
            _isUpdatingLocation = NO;
        }
        
        if (!_isMonitoringSignificantLocationChanges) {
            [self startMonitoringSignificantLocationChanges];
            _isMonitoringSignificantLocationChanges = YES;
        }
    }
}

- (int)distanceToRoom:(ETRRoom *)room {
    int distanceToCenter = (int) [_location distanceFromLocation:[room location]];
    int distance = distanceToCenter - (int) [[room radius] integerValue];
    if (distance < 5) {
      return 0;
    } else {
      return distance;
    }
}

+ (BOOL)isInSessionRegion {
    return [[ETRLocationManager sharedManager] updateSessionRegionDistance];
}

- (BOOL)updateSessionRegionDistance {
    //    BOOL wasInSessionRegion = _isInSessionRegion;
    BOOL isInSessionRegion;
    
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    
    if (sessionRoom && [ETRLocationManager didAuthorizeWhenInUse]) {
        int roomDistance = (int) [[sessionRoom distance] integerValue];
        if (roomDistance > 2000 && [[ETRSessionManager sharedManager] didStartSession]) {
            [[ETRBouncer sharedManager] kickForReason:ETRKickReasonLocation calledBy:@"farAway"];
            return NO;
        }
        isInSessionRegion = roomDistance < 10;
    } else {
        isInSessionRegion = NO;
    }
    
    if (isInSessionRegion) {
        [[ETRBouncer sharedManager] cancelLocationWarnings];
    } else {
        [[ETRBouncer sharedManager] warnForReason:ETRKickReasonLocation
                                   allowDuplicate:NO];
    }
    
    return isInSessionRegion;
}

+ (BOOL)didAuthorizeAlways {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        return YES;
    } else {
        return NO;
    }
    
//    return [ETRLocationManager didAuthorizeWhenInUse];
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
    
    if ([ETRDefaultsHelper doUpdateRoomListAtLocation:_location]) {
#ifdef DEBUG
        NSLog(@"Updating Rooms, LocationManager relaunch.");
#endif
        [ETRServerAPIHelper updateRoomListWithCompletionHandler:nil];
    }
    
    _isUpdatingLocation = YES;
    [self startUpdatingLocation];
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
    if (![ETRLocationManager didAuthorizeWhenInUse]) {
#ifdef DEBUG
        NSLog(@"Location Manager failed because Authorization was revoked.");
#endif
        // Authorization "When In Use" is required for endless sessions.
        [[ETRBouncer sharedManager] warnForReason:ETRKickReasonLocation allowDuplicate:NO];
    } else {
        NSLog(@"ERROR: Location Manager failed: %@", [error description]);
    }
}

- (void)locationManagerDidPauseLocationUpdates:(nonnull CLLocationManager *)manager {
#ifdef DEBUG
    NSLog(@"locationManagerDidPauseLocationUpdates:");
#endif
}

- (void)locationManagerDidResumeLocationUpdates:(nonnull CLLocationManager *)manager {
#ifdef DEBUG
    NSLog(@"locationManagerDidResumeLocationUpdates:");
#endif
}

@end
