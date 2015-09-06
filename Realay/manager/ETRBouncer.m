//
//  ETRBouncer.m
//  Realay
//
//  Created by Michel on 11/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRBouncer.h"

#import "ETRDefaultsHelper.h"
#import "ETRMapViewController.h"
#import "ETRNotificationManager.h"
#import "ETRFormatter.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"


static ETRBouncer * sharedInstance = nil;

static CFAbsoluteTime KickTime;

static NSTimeInterval const ETRTimeIntervalFiveMinutes = 5.0 * 60.0;

static NSTimeInterval const ETRTimeIntervalTenMinutes = 10.0 * 60.0;

static CFTimeInterval const ETRTimeIntervalTimeout = ETRTimeIntervalTenMinutes * 3.0;

/**
 Number of last Public Messages that will be stored for spam checks.
 See: - (void)isSpam:(NSString *)
 */
static NSInteger const ETRSpamWatchStorageSize = 10;

/**
 See: - (void)isSpam:(NSString *)
 */
static short const ETRSpamWatchLimit = 5;


@interface ETRBouncer () <UIAlertViewDelegate>

@property (strong, nonatomic) UIViewController * viewController;

@property (nonatomic) BOOL hasPendingKick;

@property (nonatomic) BOOL hasPendingAlertView;

@property (strong, nonatomic) NSTimer * warnTimer;

@property (nonatomic) short numberOfWarnings;

@property (nonatomic) NSInteger lastReason;

@property (strong, nonatomic) NSString * sessionEnd;

@property (nonatomic) CFAbsoluteTime lastConnectionTime;

/**
 Couple of last outgoing messages. Used for crude spam check in Public Conversations.
 See: - (void)isSpam:(NSString *)
 */
@property (strong, nonatomic) NSMutableArray * sentPublicMessages;

/**
 Current positing in _sentPublicMessages Array.
 See: - (void)isSpam:(NSString *)
 */
@property (nonatomic) short sentPublicMessagesPos;

/**
 Last Bouncer-related Notification that has been sent.
 Stored for cancelation/replacement.
 No more than one warning or kick Notification should appear in the Notification Center at once.
 */
@property (strong, nonatomic) UILocalNotification * lastNotification;

@end


@implementation ETRBouncer

#pragma mark -
#pragma mark Singleton Instantiation

+ (void)initialize {
    if (!sharedInstance) {
        sharedInstance = [[ETRBouncer alloc] init];
    }
}

+ (ETRBouncer *)sharedManager {
    return sharedInstance;
}

#pragma mark -
#pragma mark Runtime Constants

+ (NSArray *)warningIntervals {
//    return [NSArray arrayWithObjects:
//            @(30.0),
//            @(30.0),
//            @(30.0),
//            @(30.0),
//            nil];
    
    return [NSArray arrayWithObjects:
            @(ETRTimeIntervalFiveMinutes),
            @(ETRTimeIntervalFiveMinutes),
            @(ETRTimeIntervalFiveMinutes),
            @(ETRTimeIntervalFiveMinutes),
            nil];
}

#pragma mark -
#pragma mark Session Lifecycle

- (void)resetSession {
    [_warnTimer invalidate];
    _numberOfWarnings = 0;
    _hasPendingKick = NO;
    _lastConnectionTime = CFAbsoluteTimeGetCurrent();
    _sentPublicMessages = nil;
    KickTime = 0.0;
}

- (void)acknowledgeConnection {
    _lastConnectionTime = CFAbsoluteTimeGetCurrent();
}

- (void)acknowledgeFailedConnection {
    if (CFAbsoluteTimeGetCurrent() -  _lastConnectionTime > ETRTimeIntervalTimeout) {
        [self kickForReason:ETRTimeIntervalTimeout calledBy:@"NoConnection"];
    }
}

- (BOOL)isSpam:(NSString *)outgoingMessage {
    if (!_sentPublicMessages) {
        _sentPublicMessages = [NSMutableArray arrayWithCapacity:ETRSpamWatchStorageSize];
        _sentPublicMessagesPos = -1;
    }
 
    // Look for matching Strings.
    short spamCount = 0;
    for (NSString * message in _sentPublicMessages) {
        if ([message containsString:outgoingMessage]) {
            spamCount++;
        } else if ([outgoingMessage containsString:message]) {
            spamCount++;
        }
    }
    
    // Place the given message at the next position in the short array,
    // going back to index 0 if the top has been reached.
    _sentPublicMessagesPos++;
    if (_sentPublicMessagesPos > ETRSpamWatchStorageSize) {
        _sentPublicMessagesPos = 0;
    }
    
    [_sentPublicMessages setObject:outgoingMessage atIndexedSubscript:_sentPublicMessagesPos];
    
    if (spamCount >= ETRSpamWatchLimit) {
        [[ETRBouncer sharedManager] warnForReason:ETRKickReasonSpam allowDuplicate:YES];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark -
#pragma mark App Foreground/Background

- (BOOL)showPendingAlertViewInViewController:(UIViewController *)viewController {
    if (_hasPendingAlertView) {
        [self notifyUserAndForceAlertView:YES];
        _hasPendingAlertView = NO;
        return YES;
    } else {
        return NO;
    }
}

#pragma mark -
#pragma mark Warnings & Kicks

- (void)warnForReason:(short)reason allowDuplicate:(BOOL)doAllowDuplicate{
    if (!doAllowDuplicate && _lastReason == reason) {
        return;
    }
    
    if (![[ETRSessionManager sharedManager] didStartSession]) {
        return;
    }
    
    // Check if the app has been offline or not updating for a while.
    // If so, any warning is a kick.
    if (CFAbsoluteTimeGetCurrent() -  _lastConnectionTime > ETRTimeIntervalTimeout) {
        [self kickForReason:reason calledBy:@"NoConnection"];
        return;
    }
    
    // A warning is also a kick, if the Session has ended a long time ago.
    NSDate * endDate = [[ETRSessionManager sessionRoom] endDate];
    if (endDate) {
        if ([endDate timeIntervalSinceNow] < -1800) {
            [self kickForReason:reason calledBy:@"SessionEndDueLong"];
            return;
        }
    }
    
    
    NSArray * intervals = [ETRBouncer warningIntervals];
    
    _lastReason = reason;
    
    if (_numberOfWarnings < [intervals count] && [self absoluteKickTime] > CFAbsoluteTimeGetCurrent()) {
#ifdef DEBUG
        NSLog(@"Bouncer warning: %d/3 - %d.", _numberOfWarnings, reason);
#endif
        
        [self notifyUserAndForceAlertView:NO];
        
        if (_lastReason == ETRKickReasonLocation || _lastReason == ETRKickReasonClosed) {
            // Set a timer for certain warnings to repeat until getting kicked.
            NSTimeInterval interval;
            interval = [[intervals objectAtIndex:_numberOfWarnings] doubleValue];
            _warnTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(triggerNextWarning:)
                                                        userInfo:nil
                                                         repeats:NO];
        }
    } else {
        [self kickForReason:reason calledBy:@"Warning Limit reached."];
    }
    _numberOfWarnings++;
}

- (void)kickForReason:(short)reason calledBy:(NSString *)caller {
    if (_hasPendingKick) {
        return;
    }
    
#ifdef DEBUG
    NSLog(@"Kicking. Reason: %d, Caller: %@", reason, caller);
#endif
    
    _hasPendingKick = YES;
    _lastReason = reason;

    [[ETRSessionManager sharedManager] endSessionWithNotificaton:NO];
    [self notifyUserAndForceAlertView:NO];
}

- (void)cancelLocationWarnings {
    if (_lastReason == ETRKickReasonLocation) {
        [self resetSession];
        if (_lastNotification) {
            [[UIApplication sharedApplication] cancelLocalNotification:_lastNotification];
        }
    }
}

- (void)triggerNextWarning:(NSTimer *)timer {
    [self warnForReason:_lastReason allowDuplicate:YES];
}

#pragma mark -
#pragma mark Notificiations & AlertViews

- (void)notifyUserAndForceAlertView:(BOOL)doForceAlertView  {
    
    if (_lastNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:_lastNotification];
        _lastNotification = nil;
    }
    
    _hasPendingAlertView = YES;
    
    NSString * title;
    NSString * message;
    NSString * firstButton;
    NSString * secondButton;
    
    if (_hasPendingKick) {
        title = NSLocalizedString(@"Session_Terminated", @"Kicked");
    }
    
    switch (_lastReason) {
        case ETRKickReasonLocation:
            if (_hasPendingKick) {
                message = NSLocalizedString(@"Stay_in_area", @"Do not leave radius.");
            } else {
                title = NSLocalizedString(@"Where_Are_You", @"Location Note");

                NSString * messageFormat;
                messageFormat = NSLocalizedString(@"Return_until", @"Come back until %@");
                message = [NSString stringWithFormat:messageFormat, [self formattedKickTime]];
                
                firstButton = NSLocalizedString(@"Map", @"Session Map");
                secondButton = NSLocalizedString(@"Location_Settings", @"Preferences");
            }
            break;
            
        case ETRKickReasonClosed:
            if (_hasPendingKick) {
                message = NSLocalizedString(@"Event_ended", @"Closing hour reached");
            } else {
                NSString * messageFormat;
                messageFormat = NSLocalizedString(@"Part_of_event", @"Event ended at %@. Stay until %@");
                message = [NSString stringWithFormat:messageFormat,
                           [self sessionEnd],
                           [self formattedKickTime]];
            }
            break;
            
        case ETRKickReasonSpam:
            if (!_hasPendingKick) {
                title = NSLocalizedString(@"Advise", @"Serious Note");
            }
            message = NSLocalizedString(@"No_spam", @"Please don't spam.");
            break;
            
        case ETRKickReasonTimeout:
            if ([ETRDefaultsHelper didAllowBackgroundUpdates]) {
                message = NSLocalizedString(@"Timeout_occurred", @"Connection timeout");
            } else {
                message = NSLocalizedString(@"Background_updates_disabled", @"Enable background updates");
                firstButton = NSLocalizedString(@"Background_Updates", @"Same wording as in System Settings");
            }
            break;
        
        case ETRKickReasonDataOff:
            title = NSLocalizedString(@"Something_wrong", @"Error happened");
            message = NSLocalizedString(@"Sorry", @"");
            break;
            
        case ETRKickReasonKick:
            message = NSLocalizedString(@"Requested_to_leave", @"You got kicked");
            break;
            
        default:
            return;
    }
    

    

    // Show the AlertView directly if a ViewController has been given,
    // which means the app is in the foreground.
    // Otherwise try to show a notification.
    UIApplicationState appState = [[UIApplication sharedApplication] applicationState];
    if (appState == UIApplicationStateActive || doForceAlertView) {
        UIAlertView * alert;
        alert = [[UIAlertView alloc] initWithTitle:title
                                           message:message
                                          delegate:self
                                 cancelButtonTitle:NSLocalizedString(@"OK", @"OK")
                                 otherButtonTitles:firstButton, secondButton, nil];
        [alert setTag:_lastReason];
        [alert show];
        _hasPendingAlertView = NO;
    } else {
        [[ETRNotificationManager sharedManager] updateAllowedNotificationTypes];
        
        if ([[ETRNotificationManager sharedManager] didAllowAlerts]) {
            _lastNotification = [[UILocalNotification alloc] init];
            [_lastNotification setAlertTitle:title];
            [_lastNotification setAlertBody:message];
            
            [[ETRNotificationManager sharedManager] addSoundToNotification:_lastNotification];
            [[UIApplication sharedApplication] presentLocalNotificationNow:_lastNotification];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1 && _viewController) {
        // Map button:
        if (_viewController) {
            UIStoryboard * storyBoard = [_viewController storyboard];
            ETRMapViewController * conversationViewController;
            conversationViewController = [storyBoard instantiateViewControllerWithIdentifier:ETRViewControllerIDMap];
            [[_viewController navigationController] pushViewController:conversationViewController
                                                              animated:YES];
        }
        
        
    } else if (buttonIndex == 2){
        // Settings button:
        NSString * settingsURL = UIApplicationOpenSettingsURLString;
        if (settingsURL) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:settingsURL]];
        }
    }
}

#pragma mark -
#pragma mark Date Helper

- (NSString *)locationKickTime {
    if (_lastReason == ETRKickReasonLocation) {
        return [self formattedKickTime];
    } else {
        return nil;
    }
}

/**
 * Uses the warning intervals to calculate when the final warning will be displayed
 */
- (CFAbsoluteTime)absoluteKickTime {
    if (KickTime < 1000.0) {
        CFTimeInterval warningIntervalSum = 0.0;
        for (NSNumber * interval in [ETRBouncer warningIntervals]) {
            warningIntervalSum += [interval doubleValue];
        }
        
        KickTime = CFAbsoluteTimeGetCurrent() + warningIntervalSum;
    }
    return KickTime;
}

- (NSString *)formattedKickTime {
    NSDate * kickDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[self absoluteKickTime]];
                         return [ETRFormatter formattedDate:kickDate];
}

/**
 
 */
- (NSString *)sessionEnd {
    ETRRoom * sessionRoom = [ETRSessionManager sessionRoom];
    if ([sessionRoom endDate]) {
        return [ETRFormatter formattedDate:[sessionRoom endDate]];
    } else {
        return @"-";
    }
}

@end
