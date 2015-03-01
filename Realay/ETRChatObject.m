//
//  ETRChatObject.m
//  Realay
//
//  Created by Michel on 26/02/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRChatObject.h"

#define kYardInMetre 1.09361f

#define kMileInMetre 0.000621371f

#define kMaxShowDecimalMile 6000

#define kMaxShowMetre 2500

#define kMaxShowYard 500

@implementation ETRChatObject

@dynamic remoteID;
@dynamic imageID;
@synthesize lowResImage;

// TODO: Use default formats.
+ (NSString *)readableStringForDate:(NSDate *)date {
    if (!date) {
        return @"18:00";
    }
        
    NSMutableString *returnString = [NSMutableString stringWithFormat:@""];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    // Split the current datetime into its components.
    NSDate *currentDate = [NSDate date];
    NSDateComponents *currentCompontents;
    currentCompontents = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
                                     fromDate:currentDate];
    
    // Split the given datetime into its components.
    NSDateComponents *givenComponents;
    givenComponents = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay
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

/*
 Takes a value in metres and returns a human readable text,
 depending on the value and the system locale:
 100 returns "100 m" or "109 yd"
 15000 returns "15 km" or "8 mi"
 */
+ (NSString *)lengthFromMetres:(NSInteger)metres {
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        if (metres < kMaxShowMetre) {
            NSString *unit = @"m";
            return [NSString stringWithFormat:@"%ld %@", metres, unit];
        } else {
            NSString *unit = @"km";
            return [NSString stringWithFormat:@"%d %@", (int) (metres / 1000), unit];
        }
    } else {
        if (metres < kMaxShowYard) {
            NSString *unit = @"yd";
            return [NSString stringWithFormat:@"%d %@", (int) (metres * kYardInMetre), unit];
        } else if (metres < kMaxShowDecimalMile) {
            NSString *unit = @"mi";
            return [NSString stringWithFormat:@"%.1f %@", (metres * kMileInMetre), unit];
        } else {
            NSString *unit = @"mi";
            return [NSString stringWithFormat:@"%d %@", (int) (metres * kMileInMetre), unit];
        }
    }
}

- (NSString *)imageIDWithHiResFlag:(BOOL)doLoadHiRes {
    return [NSString stringWithFormat:@"%ld%s", [[self imageID] longValue], doLoadHiRes ? "" : "s"];
}


@end
