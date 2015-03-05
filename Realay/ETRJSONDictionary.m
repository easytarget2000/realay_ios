//
//  ETRJSONDictionary.m
//  Realay
//
//  Created by Michel on 05/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRJSONDictionary.h"

@implementation ETRJSONDictionary

- (NSString *)stringForKey:(id)key {
    id object = [self objectForKey:key];
    
    if (object && [object isKindOfClass:[NSString class]]) {
        return (NSString *)object;
    } else {
        return nil;
    }
}

- (NSNumber *)longNumberForKey:(id)key withFallbackValue:(long)fallbackValue {
    NSString *value = [self stringForKey:key];
    if (value) {
        return @((long) [value longLongValue]);
    } else {
        return @(fallbackValue);
    }
}

- (NSNumber *)shortNumberForKey:(id)key withFallbackValue:(short)fallbackValue {
    NSString *value = [self stringForKey:key];
    if (value) {
        return @((short) [value integerValue]);
    } else {
        return @(fallbackValue);
    }
}

@end
