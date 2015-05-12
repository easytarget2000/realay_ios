//
//  ETRActionManager.m
//  Realay
//
//  Created by Michel on 11/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRActionManager.h"

#import "ETRAction.h"
#import "ETRCoreDataHelper.h"
#import "ETRDefaultsHelper.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"
#import "ETRUser.h"


static ETRActionManager * sharedInstance = nil;

static NSTimeInterval const ETRFastestInterval = 2.5;

static NSTimeInterval const ETRSlowestInterval = 10.0;

static CFTimeInterval const ETRTimeIntervalToIdle = 120.0;

static NSTimeInterval const ETRIdleInterval = 40.0;

static NSTimeInterval const ETRMaxIntervalDifference = 2.0;

static CFTimeInterval const ETRPingInterval = 40.0;


@interface ETRActionManager ()

//@property (strong, nonatomic) NSInvocation * invocation;           // Invocation for action query timer.

/*
 Last ID of received actions
 */
@property (nonatomic) long lastActionID;

/*
 
 */
@property (nonatomic) NSTimeInterval queryInterval;

/*
 
 */
@property (strong, nonatomic) UINavigationController * navCon;               // Navigation Controller for quit-pops

/*
 
 */
@property (nonatomic) CFAbsoluteTime lastActionTime;

/*
 
 */
@property (nonatomic) CFAbsoluteTime lastPingTime;

/*
 
 */
@property (nonatomic) BOOL didAllowNotifs;

/*
 
 */
@property (nonatomic) BOOL didAllowAlerts;

/*
 
 */
@property (nonatomic) BOOL didAllowBadges;

/*
 
 */
@property (nonatomic) BOOL didAllowSounds;

/*
 
 */
@property (nonatomic) NSInteger numberOfPrivateNotifs;

@end


@implementation ETRActionManager

#pragma mark -
#pragma mark Singleton Instantiation

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[ETRActionManager alloc] init];
    }
}

+ (ETRActionManager *)sharedManager {
    return sharedInstance;
}

#pragma mark -
#pragma mark Session Lifecycle

- (void)startSession {
    // Consider the join successful and start the query timer.
    _lastActionTime = CFAbsoluteTimeGetCurrent();
    [self cancelAllNotifications];
    
    [self dispatchQueryTimerWithResetInterval:YES];
    
    return;
}

- (void)endSession {
    _lastActionID = 0L;
    [self cancelAllNotifications];
    // TODO: Cancel notifications here.
}

- (void)dispatchQueryTimerWithResetInterval:(BOOL)doResetInterval {
    if (doResetInterval || _queryInterval < ETRFastestInterval) {
        _queryInterval = ETRFastestInterval;
        _lastActionTime = CFAbsoluteTimeGetCurrent();
        NSLog(@"DEBUG: New query Timer interval: %g", _queryInterval);
    } else if (_queryInterval > ETRSlowestInterval) {
        if (CFAbsoluteTimeGetCurrent() - _lastActionTime > ETRTimeIntervalToIdle) {
            _queryInterval = ETRIdleInterval;
            NSLog(@"DEBUG: New query Timer interval: %g", _queryInterval);
        }
    } else {
        NSTimeInterval random = drand48();
        _queryInterval += random * ETRMaxIntervalDifference;
        NSLog(@"DEBUG: New query Timer interval: %g", _queryInterval);
    }
    
    dispatch_async(
                   dispatch_get_main_queue(),
                   ^{
                       [NSTimer scheduledTimerWithTimeInterval:_queryInterval
                                                        target:self
                                                      selector:@selector(queryUpdates:)
                                                      userInfo:nil
                                                       repeats:NO];
                   });
    
//    
//    dispatch_after(
//                   _queryInterval,
//                   dispatch_get_main_queue(),
//                   ^{
//                       [self queryUpdates:nil];
//                   });
}

- (void)queryUpdates:(NSTimer *)timer {
    if (![[ETRSessionManager sharedManager] didBeginSession]) {
        NSLog(@"DEBUG: Attempted to query Actions outside of Session.");
        return;
    }
    
    BOOL isInitial = _lastActionID < 100L;
    
    [ETRServerAPIHelper getActionsAndPerform:^(id<NSObject> receivedObject) {
        BOOL doResetInterval = NO;
        if ([receivedObject isKindOfClass:[NSArray class]]) {
            NSArray *jsonActions = (NSArray *) receivedObject;
            for (NSObject *jsonAction in jsonActions) {
                if ([jsonAction isKindOfClass:[NSDictionary class]]) {
                    ETRAction * action;
                    action = [ETRCoreDataHelper actionFromDictionary:(NSDictionary *)jsonAction];
                    if (action) {
                        [self setLastActionID:[[action remoteID] longValue]];
                        if (!isInitial) {
                            [self dispatchNotificationForAction:action];
                        }
                    }
                    
                    doResetInterval = YES;
                }
            }
        }
        
        [self dispatchQueryTimerWithResetInterval:doResetInterval];
    }];
}

- (BOOL)doSendPing {
    return CFAbsoluteTimeGetCurrent() - _lastPingTime > ETRPingInterval;
}

#pragma mark -
#pragma mark Action Processing

- (void)ackknowledgeActionID:(long)remoteActionID {
    if (_lastActionID < remoteActionID) {
        _lastActionID = remoteActionID;
    }
    _lastActionTime = CFAbsoluteTimeGetCurrent();
}

- (void)setForegroundPartnerID:(NSNumber *)foregroundPartnerID {
    _foregroundPartnerID = foregroundPartnerID;
    
    long idValue = [foregroundPartnerID longValue];
    if (idValue > 10L) {
        _numberOfPrivateNotifs = 0;
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_numberOfOtherNotifs];
    } else if (idValue == ETRActionPublicUserID) {
        _numberOfOtherNotifs = 0;
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:_numberOfPrivateNotifs];
    }
    // TODO: Cancel Notifications _only_ from this foreground Conversation.
}

- (void)dispatchNotificationForAction:(ETRAction *)action {
    if (!action) {
        return;
    }
    
    BOOL isMessage = [action isValidMessage] || [action isPhotoMessage];
    if ([action isSentAction] || !isMessage) {
        return;
    }
    
    [self updateAllowedNotificationTypes];
    if (!_didAllowNotifs) {
        return;
    }
    
    
    UILocalNotification * notification = [[UILocalNotification alloc] init];
    
//    if (_didAllowNotifs)
//    {
////        [notification setFireDate:[NSDate date]];
//    }
    
    
    if (_didAllowAlerts) {
        
        // TODO: Implement admin/other mesage notifications.
        
        [notification setAlertTitle:[[action sender] name]];
        
        NSString * alertSuffix;
        if ([action isPublicAction]) {
            if ([ETRDefaultsHelper doShowPublicNotifs]) {
                alertSuffix = NSLocalizedString(@"Public_Message", @"Public Message");
                _numberOfOtherNotifs++;
            } else {
                // Do not prepare this type of Notification any further,
                // if public message notifications have been disabled in the Settings.
                return;
            }
        } else if ([action isPrivateMessage]){
            if ([ETRDefaultsHelper doShowPrivateNotifs]) {
                alertSuffix = NSLocalizedString(@"Private_Message", @"Private Message");
                _numberOfPrivateNotifs++;
            } else {
                // Do not prepare this type of Notification any further,
                // if private message notifications have been disabled in the Settings.
                return;
            }
        } else {
            alertSuffix = @"n/a";
            _numberOfOtherNotifs++;
        }
        NSString * alertBody;
        alertBody = [NSString stringWithFormat:@"%@:\n%@", alertSuffix, [action messageContent]];
        
        [notification setAlertBody:alertBody];
    }
    
    if (_didAllowBadges) {
        NSInteger badgeSum = _numberOfOtherNotifs + _numberOfPrivateNotifs;
        [notification setApplicationIconBadgeNumber:badgeSum];
    }
    
    if (_didAllowSounds) {
        [notification setSoundName:UILocalNotificationDefaultSoundName];
    }
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)cancelAllNotifications {
    _numberOfOtherNotifs = 0;
    _numberOfPrivateNotifs = 0;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

- (void)updateAllowedNotificationTypes {
    UIUserNotificationType types;
    types = [[[UIApplication sharedApplication] currentUserNotificationSettings] types];
    
    _didAllowNotifs = (types != UIUserNotificationTypeNone);
    _didAllowAlerts = (types & UIUserNotificationTypeAlert) != 0;
    _didAllowBadges = (types & UIUserNotificationTypeBadge) != 0;
    _didAllowSounds = (types & UIUserNotificationTypeSound) != 0;
}

@end
