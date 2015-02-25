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

- (CGFloat)distanceToRoom:(ETRRoom *)room;
- (NSString *)readableDistanceToRoom:(ETRRoom *)room;
- (NSString *)readableLength:(CGFloat)length;
- (NSString *)readableLocationAccuracy;
- (NSString *)readableRadiusOfSessionRoom;

@end
