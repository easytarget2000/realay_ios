//
//  ETRInsideRoomHandler.m
//  Realay
//
//  Created by Michel S on 02.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRSession.h"

#import "ETRServerAPIHelper.h"
#import "ETRAlertViewBuilder.h"

#import "ETRSharedMacros.h"

#define kTickInterval           3

#define kFontSizeMsgSender      15
#define kFontSizeMsgText        15

#define kPHPInsertUserInRoom    @"insert_user_in_room"
#define kPHPSelectActions       @"select_actions"
#define kPHPSelectUserList      @"select_users_in_room"

#define kTimeReturnKick         10
#define kTimeReturnWarning1     5
#define kTimeReturnWarning2     8

#define kUserDefNotifPrivate    @"userDefaultsNotifcationPrivate"
#define kUserDefNotifPublic     @"userDefaultsNotificationPublic"
#define kUserDefNotifOther      @"userDefaultsNotificationOther"

static ETRSession *sharedInstance = nil;

@implementation ETRSession {
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
        sharedInstance = [[ETRSession alloc] init];
    }
}

+ (ETRSession *)sharedManager {
    return sharedInstance;
}

+ (User *)publicDummyUser {
    return nil;
}

- (void)didReceiveMemoryWarning {
    //TODO: Implementation
}

#pragma mark - Session State

- (void)beginSession {
    
    //TODO: Handle errors
    if (![self room]) {
        NSLog(@"ERROR: No room object given before starting a session.");
        return;
    }
    
    if ([[[self room] endTime] compare:[NSDate date]] != 1) {
        NSLog(@"ERROR: Room was already closed.");
        //TODO: Display error message.
        return;
    }
    
//    if (![ETRServerAPIHelper startSession]) {
//        return;
//    }
    
    _allMyChats = [NSMutableDictionary dictionary];
    _sortedChatKeys = [NSMutableArray array];
    
    // Prepare the invocation for the timer that queries new actions from the DB.
    NSMethodSignature *tickSignature = [self methodSignatureForSelector:@selector(tick)];
    _invocation = [NSInvocation invocationWithMethodSignature:tickSignature];
    [_invocation setTarget:self];
    [_invocation setSelector:@selector(tick)];
    
    // Register for background fetches.
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    // Get the initial array of users.
    [self queryUserList];
    
    // Start the first tick.
    [self tick];
    
    // Consider the join successful and start the tick timer.
    _didBeginSession = YES;
    _updateTimer = [NSTimer scheduledTimerWithTimeInterval:kTickInterval
                                                invocation:_invocation
                                                   repeats:YES];
    
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
    _isInRegion = NO;
    _locationUpdateFails = 0;
    _numberOfLocWarnings = 0;
    _leftRegionDate = nil;
    
    // Adjust the location manager for a higher accuracy.
    [[self locationManager] setDesiredAccuracy:kCLLocationAccuracyBest];
    [[self locationManager] setDistanceFilter:10];
    [[self locationManager] setDelegate:self];
    [[self locationManager] startUpdatingLocation];
    [self determineRegionState];
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
    if ([self didBeginSession]) {
        [[self locationManager] startMonitoringSignificantLocationChanges];
    } else {
        [[self locationManager] stopMonitoringSignificantLocationChanges];
        [[self locationManager] stopUpdatingLocation];
    }
}

/*
 Used when the app moves back to the foreground.
 */
- (void)switchToForegroundSession {
    if ([self room]) {
        [[self locationManager] startUpdatingLocation];
    } else {
        [[self locationManager] startMonitoringSignificantLocationChanges];
    }
}

#pragma mark - In-Session

#pragma mark - Tick

/*
 Check the user status and get all new actions from the server.
 */
- (void)tick {
    if (![self validateLocationTime]) return;
    
    // Request the JSON update data.
    NSDictionary *requestJSON;
    
    /*
     Process all the actions.
     */
    NSMutableArray *notifications = [NSMutableArray array];
    NSArray *actionsJSON = [requestJSON objectForKey:@"actions"];
    long localUserID = [[ETRLocalUserManager sharedManager] userID];
    for (NSDictionary *action in actionsJSON) {
        
        // Read the ID of this action and store the highest processed ID.
        NSInteger actionID = [[action objectForKey:@"action_id"] integerValue];
        if (actionID > _lastActionID) _lastActionID = actionID;
        
        // Get the user key/ID and action code of this action.
        NSString *actionCode    = [action objectForKey:@"code"];
        
        long userID = [[action objectForKey:@"u"] longValue];
        
        // Process the action according to its code
        // and wether this is an action from or, in case of admin actions, for me.
        BOOL isMyAction = userID == localUserID;
        if ([actionCode isEqualToString:@"KICK"] && isMyAction) {
            // Action Type: KICK this user
            //TODO: Kick.
        } else if ([actionCode isEqualToString:@"WARN"] && isMyAction) {
            // Action Type: WARNING this user
        } else if ([actionCode isEqualToString:@"MSG"]) {
            // Action Type: MESSAGE
            
            ETRAction *message = [ETRAction actionFromJSONDictionary:action];
            
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
            
            
        } else if ([actionCode isEqualToString:@"JOIN"] && !isMyAction) {
            // Action type: A user JOINED the room.
            
            // Only if this user is not known yet, do something.
            if (![_users containsObject:[NSNumber numberWithLong:userID]]) {
                // Create the new user object and add it to the dictionary of users.
                // TODO: Make use of UsersCache. Let Cache notify Lists.
                [_users addObject:[NSNumber numberWithLong:userID]];
            }
            
        } else if ([actionCode isEqualToString:@"UPDATE"] && !isMyAction) {
            // Action type: A user changed his PROFILE data.
            
            // Re-download the entire user object.
            // TODO: Make use of UsersCache.
            
        } else if ([actionCode isEqualToString:@"LEAVE"] && !isMyAction) {
            // Action type: A user LEFT the room.
            [_users removeObject:[NSNumber numberWithLong:userID]];
            // TODO: Notify changes.
            
        } else if ([actionCode isEqualToString:@"LEAVE"] && isMyAction) {
            /*
             Something went wrong. A kicked user should get a kick message.
             A leaving user should not receive any action updates.
             */
            
        }
        
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
        //TODO: Localization
        NSString *reason;
        if (_locationUpdateFails == 0) {
            reason = @"Please do not leave the region of a Realay permanently.";
        } else {
            reason = @"Please make sure your device regularly updates your location.";
        }
        
        // Show the alert and leave the room.
        [ETRAlertViewBuilder showKickWithMessage:reason];
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
            [ETRAlertViewBuilder showNoLocationAlertViewWithMinutes:minutes];
        } else {
            [ETRAlertViewBuilder showDidExitRegionAlertViewWithMinutes:minutes];
        }
        
        // A warning was displayed.
        _numberOfLocWarnings++;
    }
    
    return YES;
}

#pragma mark - CLLocationManagerDelegate

/*
 Call the delegate methods without any specific values, so the GUI is asked to reload data.
 */
- (void)callLocationManagerDelegates {
    [[self locationDelegate] sessionDidUpdateLocationManager:[self locationManager]];
}

/*
 Own way monitoring the region enter/exit.
 */
- (void)determineRegionState {
    CGFloat deltaDistanceRadius = [[self locationManager] distanceToRoom:[self room]];
    if (deltaDistanceRadius < [[_locationManager location] horizontalAccuracy]) {
        // Only notify if we were not in the region a moment ago.
        if (!_isInRegion) [self locationManager:nil didEnterRegion:nil];
        _isInRegion = YES;
    } else {
        // Only notify if we were in the region a moment ago.
        if (_isInRegion) [self locationManager:nil didExitRegion:nil];
        _isInRegion = NO;
    }
}

//- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region {
//    if (state == CLRegionStateInside) {
//        _isInRegion = YES;
//        _leftRegionDate = nil;
//    } else {
//        _isInRegion = NO;
//    }
//}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    _isInRegion = NO;
    
    /*
     Display the first warning if the user has joined a room
     and left the region for the first time.
     */
    if (!_leftRegionDate && [self didBeginSession] && _numberOfLocWarnings < 1) {
        _leftRegionDate = [NSDate date];
        [ETRAlertViewBuilder showDidExitRegionAlertViewWithMinutes:kTimeReturnKick];
        _numberOfLocWarnings = 1;
    }
    
#ifdef DEBUG
    NSLog(@"WARNING: Region EXIT");
#endif
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    _isInRegion = YES;
    
    // Reset everything warning related.
    _leftRegionDate = nil;
    _numberOfLocWarnings = 0;
    
#ifdef DEBUG
    NSLog(@"INFO: Region ENTRY");
#endif
}

// An error occured trying to get the device location.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    _locationUpdateFails++;
    _isInRegion = NO;
    
    /*
     Display the first warning if the user has joined a room
     and left the region for the first time.
     */
    if (!_leftRegionDate && [self didBeginSession] && _numberOfLocWarnings < 1) {
        _leftRegionDate = [NSDate date];
        [ETRAlertViewBuilder showNoLocationAlertViewWithMinutes:kTimeReturnKick];
        _numberOfLocWarnings = 1;
    }
    
    NSLog(@"ERROR: LocationManager (%ld): %@", _locationUpdateFails, error);
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
#ifdef DEBUG
    NSLog(@"INFO: locationManagerDidPauseLocationUpdates");
#endif
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
#ifdef DEBUG
    NSLog(@"INFO: didStartMonitoringForRegion");
#endif
}

// This method will be called when the location was updated successfully.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    _locationUpdateFails = 0;
    
#ifdef DEBUG
    NSLog(@"INFO: Device coordinates: %f %f",
          manager.location.coordinate.latitude,
          manager.location.coordinate.longitude);
#endif
    [self determineRegionState];
    
    // Give the new values to the GUI.
    [[self locationDelegate] sessionDidUpdateLocationManager:[self locationManager]];
}


/*
 Reset the location manager, so the room list can be queried.
 */
- (void)resetLocationManager {
    
    if (![self locationManager]) {
        _locationManager = [[ETRLocationManager alloc] init];
    }
    [[self locationManager] setDelegate:nil];
    [[self locationManager] setDistanceFilter:30];
    [[self locationManager] setDesiredAccuracy:kCLLocationAccuracyKilometer];
    //    [[[ETRSession sharedSession] locationManager] startMonitoringSignificantLocationChanges];
    [[self locationManager] startUpdatingLocation];
    
}

@end
