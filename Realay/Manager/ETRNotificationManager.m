//
//  ETRNotificationManager.m
//  Realay
//
//  Created by Michel on 21/06/15.
//  Copyright © 2015 Easy Target. All rights reserved.
//

#import "ETRNotificationManager.h"

#import "ETRAction.h"


static ETRNotificationManager * sharedInstance = nil;


@interface ETRNotificationManager ()

/**
 
 */
@property (nonatomic) BOOL didAllowSounds;

@end


@implementation ETRNotificationManager

#pragma mark -
#pragma mark Singleton Instantiation

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[ETRNotificationManager alloc] init];
    }
}

+ (ETRNotificationManager *)sharedManager {
    return sharedInstance;
}

#pragma mark -
#pragma mark Notification Accessories

- (void)updateAllowedNotificationTypes {
    UIUserNotificationType types;
    types = [[[UIApplication sharedApplication] currentUserNotificationSettings] types];
    
    _didAllowNotifs = (types != UIUserNotificationTypeNone);
    _didAllowAlerts = (types & UIUserNotificationTypeAlert) != 0;
    _didAllowBadges = (types & UIUserNotificationTypeBadge) != 0;
    _didAllowSounds = (types & UIUserNotificationTypeSound) != 0;
}

/**
 
 */
- (void)addSoundToNotification:(UILocalNotification *)notification {
    if (_didAllowSounds) {
        [notification setSoundName:UILocalNotificationDefaultSoundName];
    }
}

@end
