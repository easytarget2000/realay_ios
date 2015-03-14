//
//  ETRReadabilityHelper.m
//  Realay
//
//  Created by Michel on 14/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRReadabilityHelper.h"

#define kYardInMetre 1.09361f

#define kMileInMetre 0.000621371f

#define kMaxShowDecimalMile 6000

#define kMaxShowMetre 2500

#define kMaxShowYard 500

static NSTimeInterval const maxIntervalToday = 12.0 * 60.0 * 60.0;

@implementation ETRReadabilityHelper

/*
 Takes any Date timestamp and turns it into a reasonably long text,
 read: as short as possible;
 Today's timestamps only show the hours and minutes;
 Anything within 8 hours in the past and 8 hours in the future
 is considered "today", no matter the actual day;
 Beyond that, days and months are shown;
 Years are only used, if the Date is not in the current year
 */
+ (NSString *)formattedDate:(NSDate *)date {
    if (!date) {
        return @"--:--";
    }
    
    
    NSTimeInterval interval = [date timeIntervalSinceNow];
    if (interval < maxIntervalToday && interval > -maxIntervalToday) {
        return [ETRReadabilityHelper hoursAndMinutesFromDate:date];
    }
    
    
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
    
    BOOL isSameMonth = [givenComponents month] == [currentCompontents month];
    BOOL isSameDay = [givenComponents day] == [currentCompontents day];
    if (isSameMonth && isSameDay) {
        // The Date is several hours old but still today.
        return [ETRReadabilityHelper hoursAndMinutesFromDate:date];
    }
    
    // TODO: Use Localization for Date formats.
    
    // Display the complete the date, if it is not the current year.
    if ([givenComponents year] != [currentCompontents year]) {
        [timeFormat setDateFormat:@"dd MMM YYYY, HH:mm"];
        return [timeFormat stringFromDate:date];
    }
    
    // The Date is within the current year but not today.
    [timeFormat setDateFormat:@"dd MMM HH:mm"];
    return [timeFormat stringFromDate:date];
}

+ (NSString *)hoursAndMinutesFromDate:(NSDate *)date{
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    
    return [timeFormat stringFromDate:date];
}

/*
 Creates a stylised text which describes a time span
 between two, optional Date objects;
 Either Date may be nil
 */
+ (NSString *)timeSpanForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate {    
    NSString *start;
    if (!startDate) {
        start = NSLocalizedString(@"Ongoing", @"Event has started");
    } else {
        if ([startDate timeIntervalSinceNow] > 0) {
            start = [ETRReadabilityHelper formattedDate:startDate];
        } else {
            start = NSLocalizedString(@"Ongoing", @"Event has started");
        }
    }
    
    if (!endDate) {
        return start;
    } else {
        NSString *until = NSLocalizedString(@"until", @"From ... until ...");
        NSString *end = [ETRReadabilityHelper formattedDate:endDate];
        return [NSString stringWithFormat:@"%@ %@ %@", start, until, end];
    }
}

/*
 Takes a value in metres and returns a human readable text,
 depending on the value and the system locale:
 100 returns "100 m" or "109 yd"
 15000 returns "15 km" or "8 mi"
 */
+ (NSString *)formattedIntegerLength:(NSInteger)meters {
    if ([[[NSLocale systemLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        if (meters < kMaxShowMetre) {
            NSString *unit = NSLocalizedString(@"unit_metre", @"m");
            return [NSString stringWithFormat:@"%ld %@", meters, unit];
        } else {
            NSString *unit = NSLocalizedString(@"unit_kilometre", @"km");
            return [NSString stringWithFormat:@"%d %@", (int) (meters / 1000), unit];
        }
    } else {
        if (meters < kMaxShowYard) {
            NSString *unit = NSLocalizedString(@"unit_yard", @"yd");
            return [NSString stringWithFormat:@"%d %@", (int) (meters * kYardInMetre), unit];
        } else if (meters < kMaxShowDecimalMile) {
            NSString *unit = NSLocalizedString(@"unit_mile", @"mi");
            return [NSString stringWithFormat:@"%.1f %@", (meters * kMileInMetre), unit];
        } else {
            NSString *unit = NSLocalizedString(@"unit_mile", @"mi");
            return [NSString stringWithFormat:@"%d %@", (int) (meters * kMileInMetre), unit];
        }
    }
}

/*
 Takes a value in metres and returns a human readable text,
 depending on the value and the system locale:
 100 returns "100 m" or "109 yd"
 15000 returns "15 km" or "8 mi";
 A value of 0 meters is assumed, if nil is given
 */
+ (NSString *)formattedLength:(NSNumber *)meters {
    if (meters) {
        return [ETRReadabilityHelper formattedIntegerLength:[meters integerValue]];
    } else {
        return [ETRReadabilityHelper formattedIntegerLength:0];
    }
}

@end
