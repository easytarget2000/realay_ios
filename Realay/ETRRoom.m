//
//  Room.m
//  Realay
//
//  Created by Michel on 13.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRRoom.h"

#import "ETRSession.h"
#import "ETRUser.h"
#import "ETRHTTPHandler.h"
//#import "SharedMacros.h"

@implementation ETRRoom

#pragma mark - Factory Methods
+ (ETRRoom *)roomFromJSONDictionary:(NSDictionary *)JSONDict {
    
    ETRRoom *room = [[ETRRoom alloc] init];
    
    // Get the room information from the JSON key array.
    [room setIden:[[JSONDict objectForKey:@"r"] integerValue]];
    [room setTitle:[JSONDict objectForKey:@"tt"]];
    [room setInfo:[JSONDict objectForKey:@"ds"]];
    [room setPassword:[JSONDict objectForKey:@"pw"]];
    if ([[JSONDict objectForKey:@"ad"] isMemberOfClass:[NSString class]]) {
        [room setAddress:[JSONDict objectForKey:@"ad"]];
    }
    [room setRadius:[[JSONDict objectForKey:@"rd"] floatValue]];
    
    [room setUserCount:[[JSONDict objectForKey:@"ucn"] integerValue]];
    [room setImageID:[[JSONDict objectForKey:@"i"] integerValue]];
    
    NSInteger startTimestamp = [[JSONDict objectForKey:@"st"] integerValue];
    if (startTimestamp > 1000000000) {
        [room setStartDate:[NSDate dateWithTimeIntervalSince1970:startTimestamp]];
    }
    NSInteger endTimestamp = [[JSONDict objectForKey:@"et"] integerValue];
    if (endTimestamp > 1000000000) {
        [room setEndDate:[NSDate dateWithTimeIntervalSince1970:startTimestamp]];
    }
    
    // We query the database with km values.
    CGFloat distance = [[JSONDict objectForKey:@"dst"] doubleValue] * 1000.0;
    [room setQueryDistance:distance];
    
    // Get the room's position from the JSON data.
    CGFloat latitude = [[JSONDict objectForKey:@"lat"] floatValue];
    CGFloat longitude = [[JSONDict objectForKey:@"lng"] floatValue];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    [room setLocation:location];
    
#ifdef DEBUG
    NSLog(@"INFO: Added room to return array: %ld, Distance: %f",
          [room iden], [room queryDistance]);
#endif
    
    return room;
}

- (NSString *)timeSpan {
    // TODO: Localization
    NSString *ongoing = @"Ongoing";
    
    NSString *start;
    if (![self startDate]) {
        start = ongoing;
    } else {
        if ([[self startDate] compare:[NSDate date]] > 0) {
            start = [ETRChatObject readableStringForDate:[self startDate]];
        } else {
            start = ongoing;
        }
    }
    
    
    if (![self endDate]) {
        return start;
    } else {
        NSString *until = @"until";
        NSString *end = [ETRChatObject readableStringForDate:[self endDate]];
        return [NSString stringWithFormat:@"%@ %@ %@", start, until, end];
    }
}

- (NSString *)size {
    return [ETRChatObject lengthFromMetres:[self radius]];
}

- (NSString *)coordinateString {
    NSString *coordinateString;
    
    if ([self location]) {
        coordinateString = [NSString stringWithFormat:@"%f, %f",
                            self.location.coordinate.latitude,
                            self.location.coordinate.longitude];
    } else {
        coordinateString = @"Location unknown";
    }
    
    return coordinateString;
}

- (NSString *)amountOfUsersString {
    NSString *unitString;
    
    //TODO: Localize "users".
    if ([self userCount] < 2) {
        unitString = @"user at the moment";
    } else {
        unitString = @"users at the moment";
    }
    
    return [NSString stringWithFormat:@"%ld %@", [self userCount], unitString];
}


- (NSString *)infoString {
    NSMutableString *infoString = [[NSMutableString alloc] init];
    [infoString appendString:[NSString stringWithFormat:@"%ld", [self userCount]]];
    [infoString appendString:@" user"];
    [infoString appendString:@"\n\n"];
    [infoString appendString:[self info]];
    
    return infoString;
}

@end
