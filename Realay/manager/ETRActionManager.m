//
//  ETRActionManager.m
//  Realay
//
//  Created by Michel on 11/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRActionManager.h"

#import "ETRAction.h"
#import "ETRBouncer.h"
#import "ETRCoreDataHelper.h"
#import "ETRDefaultsHelper.h"
#import "ETRNotificationManager.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"
#import "ETRUser.h"
#import "ETRUserListViewController.h"


static ETRActionManager * sharedInstance = nil;

static CFTimeInterval const ETRQueryIntervalFastest = 1.5;

static CFTimeInterval const ETRQueryIntervalMaxJitter = 1.2;

static CFTimeInterval const ETRQueryIntervalSlowest = 8.0;

static CFTimeInterval const ETRQueryIntervalIdle = 45.0;

static CFTimeInterval const ETRWaitIntervalToIdleQueries = 4.0 * 60.0;

static CFTimeInterval const ETRPingInterval = 40.0;

static CFTimeInterval const ETRTimeIntervalTimeout = 2.0 * 60.0;


@interface ETRActionManager ()

/*
 Last ID of received actions
 */
@property (nonatomic) long lastActionID;

/*
 
 */
@property (nonatomic) CFTimeInterval queryInterval;

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
@property (strong, nonatomic) NSMutableDictionary * notificationCounters;


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
#pragma mark Session Life Cycle

- (void)startSession {
    // Consider the join successful and start the query timer.
    _lastActionTime = CFAbsoluteTimeGetCurrent();
//    [[ETRNotificationManager sharedManager] cancelAllNotifications];

    [self dispatchQueryTimerWithResetInterval:YES];
    
    return;
}

- (void)endSession {
    _lastActionID = 0L;
//    [[ETRNotificationManager sharedManager] cancelAllNotifications];
}

- (void)dispatchQueryTimerWithResetInterval:(BOOL)doResetInterval {
    if (doResetInterval || _queryInterval < ETRQueryIntervalFastest) {
        _queryInterval = ETRQueryIntervalFastest;
        _lastActionTime = CFAbsoluteTimeGetCurrent();
#ifdef DEBUG
        NSLog(@"New query Timer interval: %g", _queryInterval);
#endif
    } else if (_queryInterval > ETRQueryIntervalSlowest) {
        if (CFAbsoluteTimeGetCurrent() - _lastActionTime > ETRWaitIntervalToIdleQueries) {
            _queryInterval = ETRQueryIntervalIdle;
#ifdef DEBUG
            NSLog(@"New query Timer interval: %g", _queryInterval);
#endif
        }
    } else {
        CFTimeInterval random = drand48();
        _queryInterval += random * ETRQueryIntervalMaxJitter;
#ifdef DEBUG
        NSLog(@"New query Timer interval: %g", _queryInterval);
#endif
    }
    
    dispatch_async(
                   dispatch_get_main_queue(),
                   ^{
                       [NSTimer scheduledTimerWithTimeInterval:_queryInterval
                                                        target:self
                                                      selector:@selector(fetchUpdates:)
                                                      userInfo:nil
                                                       repeats:NO];
                   });
}

- (void)fetchUpdates:(NSTimer *)timer {
    if (CFAbsoluteTimeGetCurrent() - _lastActionTime < ETRTimeIntervalTimeout) {
        [self fetchUpdatesWithCompletionHandler:nil];
    } else {
        [[ETRBouncer sharedManager] kickForReason:ETRKickReasonTimeout calledBy:[[self class] description]];
    }
}

- (void)fetchUpdatesWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (![[ETRSessionManager sharedManager] didBeginSession]) {
        NSLog(@"WARNING: %@: Attempted to query Actions outside of Session.", [self class]);
        
        if (completionHandler) {
            completionHandler(UIBackgroundFetchResultFailed);
        }
        return;
    }
    
    BOOL isInitial = _lastActionID < 100L;
    
    [ETRServerAPIHelper getActionsAndPerform:^(id<NSObject> receivedObject) {
        BOOL didReceiveNewData = NO;
        
        if ([receivedObject isKindOfClass:[NSArray class]]) {
            NSArray *jsonActions = (NSArray *) receivedObject;
            for (NSObject *jsonAction in jsonActions) {
                if ([jsonAction isKindOfClass:[NSDictionary class]]) {
                    ETRAction * action;
                    action = [ETRCoreDataHelper addActionFromJSONDictionary:(NSDictionary *)jsonAction];
                    if (action && !isInitial) {
                        [self dispatchNotificationForAction:action];
                    }
                    
                    didReceiveNewData = YES;
                }
            }
        }
        
        [self dispatchQueryTimerWithResetInterval:didReceiveNewData];
        
        if (completionHandler) {
            UIBackgroundFetchResult result;
            result = didReceiveNewData ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData;
            completionHandler(result);
        }
    }];
}

- (BOOL)doSendPing {
    return CFAbsoluteTimeGetCurrent() - _lastPingTime > ETRPingInterval;
}

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
        // A Private Conversation has been opened.
        // Cancel its Notifications and reset its unread message count.
        
        [_notificationCounters removeObjectForKey:foregroundPartnerID];
        if (_internalNotificationHandler) {
            dispatch_async(
                           dispatch_get_main_queue(),
                           ^{
                               [_internalNotificationHandler setPrivateMessagesBadgeNumber:[self numberOfPrivateNotifs]];
                           });
        }
        [self updateBadgeNumber];
    } else if (idValue == ETRActionPublicUserID) {
        // The Public Conversation has been opened.
        // Cancel all other Notifications.
        
        [_notificationCounters removeObjectForKey:@(ETRActionPublicUserID)];
        [self updateBadgeNumber];
    }
}

#pragma mark -
#pragma mark Notifications

- (void)setInternalNotificationHandler:(id<ETRInternalNotificationHandler>)internalNotificationHandler {
    _internalNotificationHandler = internalNotificationHandler;
    if (_internalNotificationHandler) {
        dispatch_async(
                       dispatch_get_main_queue(),
                       ^{
                           [_internalNotificationHandler setPrivateMessagesBadgeNumber:[self numberOfPrivateNotifs]];
                       });
    }
}

- (void)dispatchNotificationForAction:(ETRAction *)action {
    if (!action) {
        return;
    }
    
    BOOL isMessage = [action isValidMessage] || [action isPhotoMessage];
    if ([action isSentAction] || !isMessage) {
        return;
    }
    
    // Count the number of unread messages.
    // Even if actual Notifications are disabled,
    // this is needed for in-app counters.
    
    if (!_notificationCounters) {
        _notificationCounters = [NSMutableDictionary dictionary];
    }
    
    BOOL isPublicAction = [action isPublicAction];
    
    NSNumber * counterKey;
    if (isPublicAction) {
        counterKey = @(ETRActionPublicUserID);
    } else {
        counterKey = [[action sender] remoteID];
    }
    
    NSNumber * numberOfNotifs = [_notificationCounters objectForKey:counterKey];
    if (!numberOfNotifs) {
        numberOfNotifs = @(1);
    } else {
        NSInteger oldNumberOfNotifs = [numberOfNotifs integerValue];
        numberOfNotifs = @(++oldNumberOfNotifs);
    }
    
    [_notificationCounters setObject:numberOfNotifs forKey:counterKey];
    
    
    if (!isPublicAction && _internalNotificationHandler) {
        dispatch_async(
                       dispatch_get_main_queue(),
                       ^{
                           [_internalNotificationHandler setPrivateMessagesBadgeNumber:[self numberOfPrivateNotifs]];
                       });
    }
    
    // Update the App Badge and in turn the Notification settings
    // before showing the desired and appropriate information.
    [self updateBadgeNumber];
    
    if (![[ETRNotificationManager sharedManager] didAllowAlerts]) {
        return;
    }
    
    UILocalNotification * notification = [[UILocalNotification alloc] init];
    
    if ([[ETRNotificationManager sharedManager] didAllowAlerts]) {
        
        // TODO: Implement admin/other mesage notifications.
        
        [notification setAlertTitle:[[action sender] name]];
        
        NSString * alertSuffix;
        if ([action isPublicAction]) {
            if ([ETRDefaultsHelper doShowPublicNotifs]) {
                alertSuffix = NSLocalizedString(@"Public_Message", @"Public Message");
            } else {
                // Do not prepare this type of Notification any further,
                // if public message notifications have been disabled in the Settings.
                return;
            }
        } else if ([action isPrivateMessage]){
            
            if ([ETRDefaultsHelper doShowPrivateNotifs]) {
                alertSuffix = NSLocalizedString(@"Private_Message", @"Private Message");
            } else {
                // Do not prepare this type of Notification any further,
                // if private message notifications have been disabled in the Settings.
                return;
            }
        } else {
            alertSuffix = @"n/a";
        }
        NSString * alertBody;
        alertBody = [NSString stringWithFormat:@"%@:\n%@", alertSuffix, [action messageContent]];
        
        [notification setAlertBody:alertBody];
    }
    
    [[ETRNotificationManager sharedManager] playSoundForNotification:notification];
    
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}

- (void)updateBadgeNumber {
    [[ETRNotificationManager sharedManager] updateAllowedNotificationTypes];
    if (![[ETRNotificationManager sharedManager] didAllowBadges]) {
        NSInteger number = [self numberOfPrivateNotifs] + [self numberOfOtherNotifs];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:number];
    }
}

- (NSInteger)numberOfPrivateNotifs {
    if (!_notificationCounters) {
        return 0;
    }
    
    NSArray * counterKeys = [_notificationCounters allKeys];
    if (!counterKeys || ![counterKeys count]) {
        return 0;
    } else {
        NSInteger numberOfPrivateNotifs = 0;
        
        // Count all objects in the counter dictionary
        // that have a key of class User.
        // Public messages are stored with a NSNumber key: @(-10).
        for (id counterKey in counterKeys) {
            //            if ([counterKey isKindOfClass:[ETRUser class]]) {
            NSNumber * count = [_notificationCounters objectForKey:counterKey];
            numberOfPrivateNotifs += [count integerValue];
            //            }
        }
        
        return numberOfPrivateNotifs;
    }
}

- (NSInteger)numberOfOtherNotifs {
    if (!_notificationCounters) {
        return 0;
    }
    
    id numberOfOtherNotifs = [_notificationCounters objectForKey:@(ETRActionPublicUserID)];
    if (numberOfOtherNotifs && [numberOfOtherNotifs isKindOfClass:[NSNumber class]]) {
        return [((NSNumber *)numberOfOtherNotifs) integerValue];
    } else {
        return 0;
    }
}

- (void)cancelAllNotifications {
    _notificationCounters = nil;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
}

@end
