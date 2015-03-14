//
//  ETRLocationManager.h
//  Realay
//
//  Created by Michel S on 05.05.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@class ETRRoom;

@interface ETRLocationManager : CLLocationManager <CLLocationManagerDelegate>

+ (ETRLocationManager *)sharedManager;

+ (CLLocation *)location;

+ (BOOL)isInSessionRegion;

- (NSInteger)distanceToRoom:(ETRRoom *)room;

@property (atomic, readonly) BOOL didAuthorize;

- (void)launch;

@end
