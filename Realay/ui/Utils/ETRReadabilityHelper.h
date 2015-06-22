//
//  ETRReadabilityHelper.h
//  Realay
//
//  Created by Michel on 14/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//


#import <UIKit/UIKit.h>


@interface ETRReadabilityHelper : NSObject

/**
 Takes any Date timestamp and turns it into a reasonably long text,
 read: as short as possible;
 Today's timestamps only show the hours and minutes;
 Anything within 8 hours in the past and 8 hours in the future
 is considered "today", no matter the actual day;
 Beyond that, days and months are shown;
 Years are only used, if the Date is not in the current year
 */
+ (NSString *)formattedDate:(NSDate *)date;

/**
 Creates a stylised text which describes a time span
 between two, optional Date objects;
 Either Date may be nil
 */
+ (NSString *)timeSpanForStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

/**
 Takes a value in metres and returns a human readable text,
 depending on the value and the system locale:
 100 returns "100 m" or "109 yd"
 15000 returns "15 km" or "8 mi";
 A value of 0 meters is assumed, if nil is given
 */
+ (NSString *)formattedLength:(NSNumber *)meters;


/**
 Takes a value in metres and returns a human readable text,
 depending on the value and the system locale:
 100 returns "100 m" or "109 yd"
 15000 returns "15 km" or "8 mi"
 */
+ (NSString *)formattedIntLength:(int)meters;

@end
