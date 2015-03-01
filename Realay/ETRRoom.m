//
//  Room.m
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRRoom.h"
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
@synthesize location;

+ (ETRRoom *)roomFromJSONDictionary:(NSDictionary *)JSONDict {
    
    ETRRoom *room = [[ETRRoom alloc] init];
    
    id idObject = [JSONDict objectForKey:@"r"];
    if (!idObject) {
        NSLog(@"ERROR: Could not find remote ID in JSON Room object.");
        return nil;
    }
    long remoteID = [[JSONDict objectForKey:@"r"] longValue];
    [room setRemoteID:[NSNumber numberWithLong:remoteID]];
    
    [room setTitle:[JSONDict objectForKey:@"tt"]];
    [room setSummary:[JSONDict objectForKey:@"ds"]];
    [room setPassword:[JSONDict objectForKey:@"pw"]];
    if ([[JSONDict objectForKey:@"ad"] isMemberOfClass:[NSString class]]) {
        [room setAddress:[JSONDict objectForKey:@"ad"]];
    }
    [room setRadius:[NSNumber numberWithShort:[[JSONDict objectForKey:@"rd"] shortValue]]];
    
    [room setQueryUserCount:[NSNumber numberWithLong:[[JSONDict objectForKey:@"ucn"] shortValue]]];
    [room setImageID:[NSNumber numberWithLong:[[JSONDict objectForKey:@"i"] longValue]]];
    
    NSInteger startTimestamp = [[JSONDict objectForKey:@"st"] integerValue];
    if (startTimestamp > 1000000000) {
        [room setStartTime:[NSDate dateWithTimeIntervalSince1970:startTimestamp]];
    }
    NSInteger endTimestamp = [[JSONDict objectForKey:@"et"] integerValue];
    if (endTimestamp > 1000000000) {
        [room setEndTime:[NSDate dateWithTimeIntervalSince1970:startTimestamp]];
    }
    
    // We query the database with km values and only use metre integer precision.
    NSInteger distance = [[JSONDict objectForKey:@"dst"] doubleValue] * 1000;
    [room setQueryDistance:[NSNumber numberWithInteger:distance]];
    
    [room setLatitude:[NSNumber numberWithLong:[[JSONDict objectForKey:@"lat"] floatValue]]];
    [room setLongitude:[NSNumber numberWithLong:[[JSONDict objectForKey:@"lng"] floatValue]]];
    
    return room;
}

- (NSString *)address {
    if ([self address]) return [self address];
    
    NSString *coordinates = [NSString stringWithFormat:@"%f,%f", [[self latitude] floatValue], [[self longitude] floatValue]];
    [self setAddress:coordinates];
    return coordinates;
}

- (NSString *)formattedSize {
    return [ETRChatObject lengthFromMetres:[[self radius] integerValue]];
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
    if (self.location) return self.location;
    
    CGFloat latitude = [[self latitude] floatValue];
    CGFloat longitude = [[self longitude] floatValue];
    [self setLocation:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude]];
    
    return self.location;
}

- (void)setLatitude:(NSNumber *)latitude {
    self.latitude = latitude;
    [self setLocation:nil];
}

- (void)setLongitude:(NSNumber *)longitude {
    self.longitude = longitude;
    [self setLocation:nil];
}

@end
