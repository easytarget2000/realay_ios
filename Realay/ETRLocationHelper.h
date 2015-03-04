//
//  ETRLocationManager.h
//  Realay
//
//  Created by Michel S on 05.05.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@class ETRRoom;

@interface ETRLocationHelper : CLLocationManager <CLLocationManagerDelegate>

+ (ETRLocationHelper *)sharedManager;

+ (CLLocation *)location;

@property (atomic, readonly) BOOL didAuthorize;

- (void)launch;

- (BOOL)isInSessionRegion;

@end
