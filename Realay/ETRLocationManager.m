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

- (CGFloat)distanceToRoom:(ETRRoom *)room {
    CGFloat value = [[self location] distanceFromLocation:[room location]];
    value -= [room radius];
    if (value < 0) return 0;
    else return value;
}

- (NSString *)readableDistanceToRoom:(ETRRoom *)room {
    return [self readableLength:[self distanceToRoom:room]];
}

- (NSString *)readableLength:(CGFloat)length {
    
    // Return something other than 0, if length is 0.
    if (length <= 0) {
        return @"\u2713";
    }
    
    // Return the appropriate string depending on locale settings and distance.
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        // Above 2000m show as km.
        if (length > 2000) {
            length /= 1000;
            return [NSString stringWithFormat:@"%.1f km", length];
        } else {
            return [NSString stringWithFormat:@"%d m", (int) length];
        }
    } else {
        //TODO: Figure out useful value at which feet are used instead of miles.
        if (length > 20) {
            length /= 1609;
            return [NSString stringWithFormat:@"%.2f mi", length];
        } else {
            length *= 3.281;
            return [NSString stringWithFormat:@"%d ft", (int) length];
        }
    }
    
}

- (NSString *)readableLocationAccuracy {
    CGFloat value = [[self location] horizontalAccuracy];
    return [self readableLength:value];
}

- (NSString *)readableRadiusOfSessionRoom {
    CGFloat value = [[[ETRSession sharedSession] room] radius];
    return [self readableLength:value];
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
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
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
