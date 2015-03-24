//
//  ETRPreferenceHelper.m
//  Realay
//
//  Created by Michel on 15/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRPreferenceHelper.h"

@implementation ETRPreferenceHelper

+ (BOOL)doUseMetricSystem {
    NSLocale *locale = [NSLocale currentLocale];
    
    id localeMeasurement = [locale objectForKey:NSLocaleUsesMetricSystem];
    if (localeMeasurement && [localeMeasurement isKindOfClass:[NSNumber class]]) {
        return [localeMeasurement boolValue];
    }
    
    return YES;
}

@end
