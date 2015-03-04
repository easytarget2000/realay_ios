//
//  Room.m
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRRoom.h"

#import "ETRLocationHelper.h"
#import "User.h"

@interface ETRRoom()

@property (nonatomic, retain, readwrite) CLLocation * location;

@end

@implementation ETRRoom

@dynamic address;
@dynamic createdBy;
@dynamic endTime;
@dynamic latitude;
@dynamic longitude;
@dynamic password;
@dynamic queryDistance;
@dynamic radius;
@dynamic startTime;
@dynamic summary;
@dynamic title;
@dynamic queryUserCount;
@dynamic users;
@dynamic actions;
@dynamic imageID;

@synthesize location = _location;

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@", [self remoteID], [self title]];
}

- (NSString *)address {
    if ([self address]) return [self address];
    
    NSString *coordinates = [NSString stringWithFormat:@"%f,%f", [[self latitude] floatValue], [[self longitude] floatValue]];
    [self setAddress:coordinates];
    return coordinates;
}

/*
 Distance in _metres_ between the outer _radius_ of a given Room, not the central point,
 and the current device location;
 Takes current device location from the LocationManager;
 Uses the server API / query distance value, if the device location is unknown;
 Values below 10 are handled as 0 to avoid unnecessary precision
 */
- (NSInteger)distance; {
    CLLocation *roomLocation = [self location];
    if (!roomLocation) {
        return 8424;
    }
    
    CLLocation *deviceLocation = [ETRLocationHelper location];
    NSInteger distanceToCenter;
    if (deviceLocation) {
        distanceToCenter = [deviceLocation distanceFromLocation:roomLocation];
    } else {
        distanceToCenter = [[self queryDistance] integerValue];
    }
    
    NSInteger distanceToRadius = distanceToCenter - [[self radius] integerValue];
    if (distanceToRadius < 10) {
        return 0;
    } else {
        return distanceToRadius;
    }
}

- (NSString *)formattedDistance {
    return [ETRChatObject formattedLength:[self distance]];
}

- (NSString *)formattedSize {
    return [ETRChatObject formattedLength:[[self radius] integerValue]];
}

- (NSString *)timeSpan {
    // TODO: Localization
    NSString *ongoing = @"Ongoing";
    
    NSString *start;
    if (![self startTime]) {
        start = ongoing;
    } else {
        if ([[self startTime] compare:[NSDate date]] > 0) {
            start = [ETRChatObject readableStringForDate:[self startTime]];
        } else {
            start = ongoing;
        }
    }
    
    
    if (![self endTime]) {
        return start;
    } else {
        NSString *until = @"until";
        NSString *end = [ETRChatObject readableStringForDate:[self endTime]];
        return [NSString stringWithFormat:@"%@ %@ %@", start, until, end];
    }
}

- (NSString *)userCount {
    // TODO: Count users in CoreData.
    return [NSString stringWithFormat:@"%d", [[self queryUserCount] shortValue]];
}

- (CLLocation *)location {
    if (_location) {
        return _location;
    }
    
    CGFloat latitude = [[self latitude] floatValue];
    CGFloat longitude = [[self longitude] floatValue];
    _location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    return _location;
}

@end
