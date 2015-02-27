//
//  ETRLocationManager.h
//  Realay
//
//  Created by Michel S on 05.05.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "ETRRoom.h"

@interface ETRLocationManager : CLLocationManager

/*
 Distance in _metres_ between the outer _radius_ of a given Room, not the central point,
 and the current device location;
 values below 10 are handled as 0 to avoid unnecessary precision
 */
- (NSInteger)distanceToRoom:(ETRRoom *)room ;

- (NSString *)readableDistanceToRoom:(ETRRoom *)room;

@end
