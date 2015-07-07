    //
//  ETRReadabilityHelper.m
//  Realay
//
//  Created by Michel on 14/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRFormatter.h"

#import "ETRDefaultsHelper.h"

static CGFloat const kYardInMetre = 1.09361f;

static CGFloat const kMileInMetre = 0.000621371f;

static int const kMaxShowDecimalMile = 6000;

static int const kMaxShowMetre = 2500;

static int const kMaxShowYard = 500;

static NSTimeInterval const ETRTimeIntervalToday = 12.0 * 60.0 * 60.0;

static NSTimeInterval const ETRTimeIntervalYear = 180.0 * 20.0 * 60.0 * 60.0;

@implementation ETRFormatter

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
    
    NSString * formatString;
    NSTimeInterval interval = [date timeIntervalSinceNow];
    if (interval < ETRTimeIntervalToday && interval > -ETRTimeIntervalToday) {
        // The date is within a few hours from now. Only show HH:mm.
        formatString = [NSDateFormatter dateFormatFromTemplate:@"jmm"
                                                                 options:0
                                                                  locale:[NSLocale currentLocale]];
    } else if (interval < ETRTimeIntervalYear && interval > -ETRTimeIntervalYear){
        // The Date is within the current year but not today.
        formatString = [NSDateFormatter dateFormatFromTemplate:@"ddMMMjmm"
                                                       options:0
                                                        locale:[NSLocale currentLocale]];
    } else {
        // Display the complete date, if it is not the current year.
        // [timeFormat setDateFormat:@"dd MMM YYYY, HH:mm"];
        formatString = [NSDateFormatter dateFormatFromTemplate:@"ddMMMYYYYjmm"
                                                       options:0
                                                        locale:[NSLocale currentLocale]];
    }
    
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formatString];
    return [dateFormatter stringFromDate:date];
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
            start = [ETRFormatter formattedDate:startDate];
        } else {
            start = NSLocalizedString(@"Ongoing", @"Event has started");
        }
    }
    
    if (!endDate) {
        return start;
    } else {
        NSString * until = NSLocalizedString(@"until", @"From ... until ...");
        NSString * end = [ETRFormatter formattedDate:endDate];
        return [NSString stringWithFormat:@"%@\n%@ %@", start, until, end];
    }
}

/**
 Takes a value in metres and returns a human readable text,
 depending on the value and the system locale:
 100 returns "100 m" or "109 yd"
 15000 returns "15 km" or "8 mi"
 */
+ (NSString *)formattedIntLength:(int)meters {
    if ([ETRDefaultsHelper doUseMetricSystem]) {
        if (meters < kMaxShowMetre) {
            NSString *unit = NSLocalizedString(@"unit_metre", @"m");
            return [NSString stringWithFormat:@"%d %@", meters, unit];
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
        return [ETRFormatter formattedIntLength:(int)[meters integerValue]];
    } else {
        return [ETRFormatter formattedIntLength:0];
    }
}

@end
