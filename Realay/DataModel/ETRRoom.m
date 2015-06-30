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
@dynamic distance;
@dynamic queryUserCount;
@dynamic radius;
@dynamic remoteID;
@dynamic startDate;
@dynamic summary;
@dynamic title;
@dynamic actions;
@dynamic users;
@dynamic conversations;

@synthesize location = _location;

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: %@, %@ until %@, %@ users.",
            [self remoteID],
            [self title],
            [self startDate],
            [self endDate],
            [self queryUserCount]];
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
