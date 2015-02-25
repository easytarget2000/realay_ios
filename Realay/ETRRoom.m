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
    [room setRoomID:[[JSONDict objectForKey:@"r"] integerValue]];
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
    CGFloat distance = [[JSONDict objectForKey:@"distance"] doubleValue] * 1000.0;
    [room setQueryDistance:distance];
    
    // Get the room's position from the JSON data.
    CGFloat latitude = [[JSONDict objectForKey:@"latitude"] floatValue];
    CGFloat longitude = [[JSONDict objectForKey:@"longitude"] floatValue];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    [room setLocation:location];
    
#ifdef DEBUG
    NSLog(@"INFO: Added room to return array: %ld, Distance: %f",
          [room roomID], [room queryDistance]);
#endif
    
    return room;
}

# pragma mark - Instance Methods

//- (void)setStartTimeFromSQLString:(NSString *)dateString {
//    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
//    [timeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    
//    [self setBeginDateTime:[timeFormat dateFromString:dateString]];
//}
//
//- (void)setEndTimeFromSQLString:(NSString *)dateString {
//    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
//    [timeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    
//    [self setEndDateTime:[timeFormat dateFromString:dateString]];
//}

#pragma mark - String Builders
- (NSString *)timeSpanString {
    // TODO: Localization
    NSString *untilString = @"until";
    
    return [NSString stringWithFormat:@"%@ %@ %@",
            [self readableStringForDate:[self startDate]],
            untilString,
            [self readableStringForDate:[self endDate]]];
}

- (NSString *)readableStringForDate:(NSDate *)date {
    NSMutableString *returnString = [NSMutableString stringWithFormat:@""];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // Split the current datetime into its components.
    NSDate *currentDate = [NSDate date];
    NSDateComponents *currentCompontents;
    currentCompontents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                     fromDate:currentDate];
    
    // Split the given datetime into its components.
    NSDateComponents *givenComponents;
    givenComponents = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                                  fromDate:date];
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    
    // Display the year if it is not the current year.
    if ([givenComponents year] != [currentCompontents year]) {
        [timeFormat setDateFormat:@"dd MMM YYYY HH:mm"];
    } else {
        // Write "today" if it is the current date.
        if ([givenComponents month] == [currentCompontents month]
            && [givenComponents day] == [currentCompontents day]) {
            //TODO: Localization
            [returnString appendString:@"Today "];
            [timeFormat setDateFormat:@"HH:mm"];
        } else {
            // The DEFAULT format is 01 Jan 12:59.
            [timeFormat setDateFormat:@"dd MMM HH:mm"];
        }
    }
    [returnString appendString:[timeFormat stringFromDate:date]];
    
    return returnString;
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
