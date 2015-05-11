//
//  ETRBouncer.m
//  Realay
//
//  Created by Michel on 11/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRBouncer.h"


static ETRBouncer * sharedInstance = nil;


@implementation ETRBouncer

#pragma mark -
#pragma mark Singleton Instantiation

+ (void)initialize {
    if (!sharedInstance) {
        sharedInstance = [[ETRBouncer alloc] init];
    }
}

+ (ETRBouncer *)sharedManager {
    return sharedInstance;
}

@end
