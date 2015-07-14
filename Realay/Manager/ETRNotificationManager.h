//
//  ETRNotificationManager.h
//  Realay
//
//  Created by Michel on 21/06/15.
//  Copyright © 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ETRAction;


@interface ETRNotificationManager : NSObject

/**
 
 */
@property (nonatomic) BOOL didAllowNotifs;

/**
 
 */
@property (nonatomic) BOOL didAllowAlerts;

/**
 
 */
@property (nonatomic) BOOL didAllowBadges;


/**
 
 */
+ (ETRNotificationManager *)sharedManager;

/**
 
 */
- (void)updateAllowedNotificationTypes;

/**
 
 */
- (void)addSoundToNotification:(UILocalNotification *)notification;

@end
