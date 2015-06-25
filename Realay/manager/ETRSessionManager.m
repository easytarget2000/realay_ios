//
//  ETRInsideRoomHandler.m
//  Realay
//
//  Created by Michel S on 02.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRSessionManager.h"

#import "ETRAction.h"
#import "ETRActionManager.h"
#import "ETRAlertViewFactory.h"
#import "ETRBouncer.h"
#import "ETRCoreDataHelper.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRDefaultsHelper.h"
#import "ETRReadabilityHelper.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"


static ETRSessionManager * sharedInstance = nil;

static CFTimeInterval const ETRTimeIntervalDeepUpdate = 10.0 * 60.0;


@interface ETRSessionManager()

@property (nonatomic) CFAbsoluteTime lastUserListUpdate;

@end


@implementation ETRSessionManager

#pragma mark -
#pragma mark Singleton Sharing

+ (void)initialize {
    static BOOL initialized = NO;
    if (!initialized) {
        initialized = YES;
        sharedInstance = [[ETRSessionManager alloc] init];
        [sharedInstance setLastUserListUpdate:0.0];
    }
}

+ (ETRSessionManager *)sharedManager {
    return sharedInstance;
}

+ (ETRRoom *)sessionRoom {
    return [sharedInstance room];
}

#pragma mark -
#pragma mark Session Lifecycle

- (BOOL)startSession {
//    NSLog(@"Starting Session. Called by %@.", caller);
    
    if (![self room]) {
        NSLog(@"ERROR: No room object given before starting a session.");
        return NO;
    }
    
    if ([self didReachEndDate]) {
        NSString * messageFormat = NSLocalizedString(@"Closed_at", @"%@ closed at %@.");
        NSString * endDate = [ETRReadabilityHelper formattedDate:[_room endDate]];
        NSString * message = [NSString stringWithFormat:messageFormat, [_room title], endDate];
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Too_Late", @"Cannot Join Anymore")
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                          otherButtonTitles:nil] show];
        return NO;
    }
    
    // Consider the join successful so far and start the Action Manager.
    [[ETRActionManager sharedManager] startSession];
    _didStartSession = YES;
    [ETRDefaultsHelper storeSession:[_room remoteID]];
    [[ETRBouncer sharedManager] resetSession];
    
    [self startDeepUpdateTimer];
    return YES;
}

- (void)endSession; {
    [ETRServerAPIHelper endSession];
    
    _room = nil;
    [ETRDefaultsHelper removeSession];
    
    _didStartSession = NO;
    
    // Remove all public and queued Actions from the local DB.
    [ETRCoreDataHelper cleanActions];
    [[ETRActionManager sharedManager] endSession];
    [ETRDefaultsHelper removePublicMessageInputTexts];
    [_navigationController popToRootViewControllerAnimated:YES];
}

/*
 Attempts to restore the last Session Room from Defaults;
 Does not start the Session;
 Start the Join View Controller to continue, if returning YES.
 
 Return: YES, if the Room has been restored
 */
- (BOOL)restoreSession {
    _room = [ETRDefaultsHelper restoreSession];
    return _room != nil;
}

- (void)prepareSessionInRoom:(ETRRoom *)room
        navigationController:(UINavigationController *)navigationController {
    
    [self setNavigationController:navigationController];
    
    if ([self didStartSession]) {
        [self endSession];
        NSLog(@"ERROR: Room set during running session.");
        return;
    }
    _room = room;
}

- (BOOL)didReachEndDate {
    if ([_room endDate]) {
        return [[_room endDate] compare:[NSDate date]] != 1;
    } else {
        return NO;
    }
}

#pragma mark -
#pragma mark Deep Updates

/**
 
 */
- (void)startDeepUpdateTimer {
    dispatch_async(
                   dispatch_get_main_queue(),
                   ^{
                       [NSTimer scheduledTimerWithTimeInterval:ETRTimeIntervalDeepUpdate
                                                        target:self
                                                      selector:@selector(performDeepUpdate:)
                                                      userInfo:nil
                                                       repeats:NO];
                   });
}

/**
 
 */
- (void)performDeepUpdate:(NSTimer *)timer {
    if (!_didStartSession) {
        return;
    }
    
#ifdef DEBUG
    NSLog(@"Deep Update.");
#endif
    [ETRServerAPIHelper getSessionUsersWithCompletionHandler:nil];
    
    if ([self didReachEndDate]) {
        [[ETRBouncer sharedManager] warnForReason:ETRKickReasonClosed];
    }
    
    [self startDeepUpdateTimer];
}

@end
