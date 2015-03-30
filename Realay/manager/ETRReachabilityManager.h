//
//  ETRReachabilityManager.h
//  Realay
//
//  Created by Michel on 27/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETRReachabilityManager : NSObject

#pragma mark -
#pragma mark Shared Manager

+ (ETRReachabilityManager *)sharedManager;

#pragma mark -
#pragma mark Class Methods

+ (BOOL)isReachable;

//+ (BOOL)isReachableViaWWAN;
//
//+ (BOOL)isReachableViaWiFi;

@end
