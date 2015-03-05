//
//  ETRJSONDictionary.h
//  Realay
//
//  Created by Michel on 05/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETRJSONDictionary : NSDictionary

- (NSString *)stringForKey:(id)key;

- (NSNumber *)longNumberForKey:(id)key withFallbackValue:(long)fallbackValue;

- (NSNumber *)shortNumberForKey:(id)key withFallbackValue:(short)fallbackValue;

@end
