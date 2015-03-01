//
//  ETRLocationManager.m
//  Realay
//
//  Created by Michel S on 05.05.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRLocationManager.h"

#import "ETRSession.h"
#import "ETRAlertViewBuilder.h"

#define kMethodEnumDist 0
#define kMethodEnumAccu 1
#define kMethodEnumRadi 2

@implementation ETRLocationManager

/*
 Distance in _metres_ between the outer _radius_ of a given Room, not the central point,
 and the current device location;
 values below 10 are handled as 0 to avoid unnecessary precision
 */
- (NSInteger)distanceToRoom:(ETRRoom *)room {
    if (!room) return 0;
    
    NSInteger value = [[self location] distanceFromLocation:[room location]];
    value -= [[room radius] integerValue];
    if (value < 10) return 0;
    else return value;
}

- (NSString *)formattedDistanceToRoom:(ETRRoom *)room {
    return [ETRChatObject lengthFromMetres:[self distanceToRoom:room]];
}

#pragma mark - StartUpdating overrides

- (void)startUpdatingLocation {
    [self verifyLocationAuthorization];
    [super startUpdatingLocation];
}

- (void)startMonitoringSignificantLocationChanges {
    [self verifyLocationAuthorization];
    [super startMonitoringSignificantLocationChanges];
}

- (void)verifyLocationAuthorization {
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        [super startUpdatingLocation];
        return;
    }
    
    if ([self respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self requestWhenInUseAuthorization];
    }
    
    if ([self respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self requestAlwaysAuthorization];
    }
}

@end
