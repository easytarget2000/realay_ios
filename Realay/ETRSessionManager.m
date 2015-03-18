//
//  ETRInsideRoomHandler.m
//  Realay
//
//  Created by Michel S on 02.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRSessionManager.h"

#import "ETRAction.h"
#import "ETRAlertViewFactory.h"
#import "ETRCoreDataHelper.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"

#define kTickInterval           3

#define kFontSizeMsgSender      15
#define kFontSizeMsgText        15

#define kTimeReturnKick         10
#define kTimeReturnWarning1     5
#define kTimeReturnWarning2     8

#define kUserDefNotifPrivate    @"userDefaultsNotifcationPrivate"
#define kUserDefNotifPublic     @"userDefaultsNotificationPublic"
#define kUserDefNotifOther      @"userDefaultsNotificationOther"

static ETRSessionManager *sharedInstance = nil;

@implementation ETRSessionManager {
    NSMutableDictionary     *_allMyChats;           // All chat objects. key = chatID
    NSMutableSet            *_blockedUsers;         // Users that have been blocked
    NSInvocation            *_invocation;           // Invocation for action query timer.
    NSInteger               _lastActionID;          // Last ID of received actions
    NSDate                  *_leftRegionDate;       // Time at which the user left the region
    UINavigationController  *_navCon;               // Navigation Controller for quit-pops
    NSInteger               _numberOfLocWarnings;   // Number of left-region warnings
    NSTimer                 *_updateTimer;          // Action query update timer
}

#pragma mark - Singleton Sharing

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[ETRSessionManager alloc] init];
    }
}

+ (ETRSessionManager *)sharedManager {
    return sharedInstance;
}

+ (ETRRoom *)sessionRoom {
    return [sharedInstance room];
}

- (void)didReceiveMemoryWarning {
    //TODO: Implementation
}

#pragma mark - Session State

- (BOOL)startSession {
    //TODO: Handle errors
    if (![self room]) {
        NSLog(@"ERROR: No room object given before starting a session.");
        return NO;
    }
    
    if ([_room endDate]) {
        if ([[_room endDate] compare:[NSDate date]] != 1) {
            NSLog(@"ERROR: Room was already closed.");
            //TODO: Display error message.
            return NO;
        }
    }
    
    // Prepare the invocation for the timer that queries new actions from the DB.
    NSMethodSignature *tickSignature = [self methodSignatureForSelector:@selector(tick)];
    _invocation = [NSInvocation invocationWithMethodSignature:tickSignature];
    [_invocation setTarget:self];
    [_invocation setSelector:@selector(tick)];
    
    // Register for background fetches.
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Consider the join successful and start the tick timer.
    _didBeginSession = YES;
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:kTickInterval
                                                invocation:_invocation
                                                   repeats:YES];
    
    return YES;
}

- (void)endSession {
    
    // Unregister from background fetches.
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    
    if ([self didBeginSession]) {
        //TODO: update_user_in_room.php
    }
    
    _room = nil;
    [_updateTimer invalidate];
    _updateTimer = nil;
    _lastActionID = 50;
    _didBeginSession = NO;
    
    
    // Pop to room list.
    NSInteger listControllerIndex = [self roomListControllerIndex];
    UINavigationController *navc = [self navigationController];
    if (listControllerIndex >= 0 && navc) {
        UIViewController *listController;
        listController = [[navc viewControllers] objectAtIndex:listControllerIndex];
        
        [navc popToViewController:listController animated:YES];
    } else {
        NSLog(@"ERROR: No room list view controller on stack.");
        [navc popToRootViewControllerAnimated:YES];
    }
    
    // Remove all public Actions from the local DB.
    [ETRCoreDataHelper clearPublicActions];
}

- (void)prepareSessionInRoom:(ETRRoom *)room
        navigationController:(UINavigationController *)navigationController {
    
    [self setNavigationController:navigationController];
    
    if ([self didBeginSession]) {
        [self endSession];
        NSLog(@"ERROR: Room set during running session.");
        return;
    }
    
    // TODO: Only query user ID here?
    _room = room;
    _locationUpdateFails = 0;
    _numberOfLocWarnings = 0;
    _leftRegionDate = nil;
    
    // Adjust the location manager for a higher accuracy.
    // TODO: Increase location update speed?
}

/*
 Read the user settings.
 */
- (void)refreshGUIAttributes  {
    _msgSenderFont = [UIFont boldSystemFontOfSize:kFontSizeMsgSender];
    _msgTextFont = [UIFont systemFontOfSize:kFontSizeMsgText];
}

/*
 Used when app moves to the background.
 */
- (void)switchToBackgroundSession {
//    if ([self didBeginSession]) {
//        [[self locationManager] startMonitoringSignificantLocationChanges];
//    } else {
//        [[self locationManager] stopMonitoringSignificantLocationChanges];
//        [[self locationManager] stopUpdatingLocation];
//    }
}

/*
 Used when the app moves back to the foreground.
 */
- (void)switchToForegroundSession {
//    if ([self room]) {
//        [[self locationManager] startUpdatingLocation];
//    } else {
//        [[self locationManager] startMonitoringSignificantLocationChanges];
//    }
}

#pragma mark - In-Session

#pragma mark - Tick

/*
 Check the user status and get all new actions from the server.
 */
- (void)tick {
    
    // Request the JSON update data.
    NSDictionary *requestJSON;
    
    /*
     Process all the actions.
     */
    NSMutableArray *notifications = [NSMutableArray array];
    NSArray *actionsJSON = [requestJSON objectForKey:@"actions"];
    long localUserID = [ETRLocalUserManager userID];
    for (NSDictionary *action in actionsJSON) {
            // Action Type: MESSAGE
            
            ETRAction *message;
            
            // TODO: Do no process messages any further if they have been sent by a blocked user.
            
            // Create a notification.
            // Notification test:
            UILocalNotification *testNotif = [[UILocalNotification alloc] init];
            [testNotif setFireDate:[NSDate date]];
            [testNotif setTimeZone:[NSTimeZone localTimeZone]];
            NSString *notifAction   = @"View Message";    //TODO: Localization
            NSString *notifBody     = [message messageContent];
            [testNotif setAlertAction:notifAction];
            [testNotif setAlertBody:notifBody];
            [testNotif setSoundName:UILocalNotificationDefaultSoundName];
            [testNotif setApplicationIconBadgeNumber:15];
            [notifications addObject:testNotif];
    }
    
    // Display all new notifications.
    for (UILocalNotification *localNotif in notifications) {
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    }
}

- (BOOL)validateLocationTime {
    /*
     Check if the user location was updated recently enough.
     */
    NSInteger leftRegionSeconds = [_leftRegionDate timeIntervalSinceNow];
#ifdef DEBUG
    NSLog(@"INFO: Left region %ld s ago.", leftRegionSeconds);
#endif
    if (leftRegionSeconds < (-kTimeReturnKick * 60)) {
        NSString *reason;
        if (_locationUpdateFails == 0) {
            reason = NSLocalizedString(@"Do_not_leave", @"'Do not leave' warning");
        } else {
            reason = NSLocalizedString(@"Regular_location_updates", @"'Location updates' advise");
        }
        
        // Show the alert and leave the room.
        [ETRAlertViewFactory showKickWithMessage:reason];
        [self endSession];
        return NO;
        
    } else if (leftRegionSeconds < (-kTimeReturnWarning1 * 60) && _numberOfLocWarnings < 3) {
        // It is AT LEAST time for the first warning.
        NSInteger minutes = kTimeReturnKick;
        
        if (leftRegionSeconds < (-kTimeReturnWarning2 * 60)) {
            // If two warnings were sent and the time until a second warning passed, show it.
            minutes -= kTimeReturnWarning2;
        } else if (_numberOfLocWarnings < 2) {
            // After one warning and it is not yet time for the second warning, show the first one.
            minutes -= kTimeReturnWarning1;
        } else {
            return YES;
        }
        
        // Display different warnings depending on the location manager state.
        if ([self locationUpdateFails]) {
//            [ETRAlertViewFactory showNoLocationAlertViewWithMinutes:minutes];
        } else {
//            [ETRAlertViewFactory showDidExitRegionAlertViewWithMinutes:minutes];
        }
        
        // A warning was displayed.
        _numberOfLocWarnings++;
    }
    
    return YES;
}

// TODO: Move content of LocationManagerDelegate implementation to LocationHelper & Bouncer.

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    
    /* TODO:
     Display the first warning if the user has joined a room
     and left the region for the first time.
     */
    if (!_leftRegionDate && [self didBeginSession] && _numberOfLocWarnings < 1) {
        _leftRegionDate = [NSDate date];
//        [ETRAlertViewFactory showDidExitRegionAlertViewWithMinutes:kTimeReturnKick];
        _numberOfLocWarnings = 1;
    }
    
#ifdef DEBUG
    NSLog(@"WARNING: Region EXIT");
#endif
}

// An error occured trying to get the device location.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    /*
     Display the first warning if the user has joined a room
     and left the region for the first time.
     */
    if (!_leftRegionDate && [self didBeginSession] && _numberOfLocWarnings < 1) {
        _leftRegionDate = [NSDate date];
//        [ETRAlertViewFactory showNoLocationAlertViewWithMinutes:kTimeReturnKick];
        _numberOfLocWarnings = 1;
    }
    
    NSLog(@"ERROR: LocationManager (%ld): %@", _locationUpdateFails, error);
}


/*
 Reset the location manager, so the room list can be queried.
 */
- (void)resetLocationManager {
//    
//    if (![self locationManager]) {
//        _locationManager = [[ETRLocationHelper alloc] init];
//    }
//    [[self locationManager] setDelegate:nil];
//    [[self locationManager] setDistanceFilter:30];
//    [[self locationManager] setDesiredAccuracy:kCLLocationAccuracyKilometer];
//    //    [[[ETRSession sharedSession] locationManager] startMonitoringSignificantLocationChanges];
//    [[self locationManager] startUpdatingLocation];
    
}

@end
