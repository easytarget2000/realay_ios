//
//  ETRPreferenceHelper.m
//  Realay
//
//  Created by Michel on 15/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRPreferenceHelper.h"


static NSString *const ETRDefaultsKeyAuthID = @"auth_id";


@implementation ETRPreferenceHelper

+ (BOOL)doUseMetricSystem {
    NSLocale *locale = [NSLocale currentLocale];
    
    id localeMeasurement = [locale objectForKey:NSLocaleUsesMetricSystem];
    if (localeMeasurement && [localeMeasurement isKindOfClass:[NSNumber class]]) {
        return [localeMeasurement boolValue];
    }
    
    return YES;
}

+ (NSString *)authID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Check that the user ID exists.
    NSString * userID = [defaults stringForKey:ETRDefaultsKeyAuthID];
    
    if (!userID) {
        if ([[UIDevice currentDevice] respondsToSelector:@selector(identifierForVendor)]) {
            // IOS 6 new Unique Identifier implementation, IFA
            userID = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        } else {
            userID = [NSString stringWithFormat:@"%@-%ld", [[UIDevice currentDevice] systemVersion], random()];
        }
        
        [defaults setObject:userID forKey:ETRDefaultsKeyAuthID];
        [defaults synchronize];
    }
    
    return userID;
}

@end
