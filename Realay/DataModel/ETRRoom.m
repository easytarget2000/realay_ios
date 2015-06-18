//
//  Room.m
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRRoom.h"

#import "ETRLocationManager.h"
#import "ETRReadabilityHelper.h"
#import "ETRUser.h"

@interface ETRRoom()

@property (nonatomic, retain, readwrite) CLLocation * location;

@end

@implementation ETRRoom

@dynamic address;
@dynamic createdBy;
@dynamic endDate;
@dynamic imageID;
@dynamic latitude;
@dynamic longitude;
@dynamic password;
@dynamic queryDistance;
@dynamic queryUserCount;
@dynamic radius;
@dynamic remoteID;
@dynamic startTime;
@dynamic summary;
@dynamic title;
@dynamic actions;
@dynamic users;
@dynamic conversations;

@synthesize location = _location;

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@", [self remoteID], [self title]];
}

//- (NSString *)formattedCoordinates {
//    NSString *coordinates = [NSString stringWithFormat:@"%f,%f",
//                   [[self latitude] floatValue],
//                   [[self longitude] floatValue]];
//    [self setAddress:coordinates];
//    return coordinates;
//}

- (NSString *)hours {
    NSString * start;
    if ([self hasStarted]) {
        start = NSLocalizedString(@"Ongoing", @"Started");
    } else {
        start = [ETRReadabilityHelper formattedDate:[self startTime]];
    }
    
    NSString * end;
    if (![self endDate]) {
        end = NSLocalizedString(@"No_time_restriction", @"Does not end");
    } else {
        end = [ETRReadabilityHelper formattedDate:[self endDate]];
    }
    
    return [NSString stringWithFormat:@"%@\n%@", start, end];
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

- (BOOL)hasStarted {
    if (![self startTime]) {
        return YES;
    } else {
        return [[self startTime] compare:[NSDate date]] == NSOrderedAscending;
    }
}

@end