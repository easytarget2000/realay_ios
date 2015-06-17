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
#import "ETRCoreDataHelper.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRDefaultsHelper.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"


static ETRSessionManager * sharedInstance = nil;

static CFTimeInterval const ETRUserListRefreshInterval = 10.0 * 60.0;


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
    
    // Consider the join successful so far and start the Action Manager.
    [[ETRActionManager sharedManager] startSession];
    _didBeginSession = YES;
    [ETRDefaultsHelper storeSession:[_room remoteID]];
    return YES;
}

- (void)endSession; {
    [ETRServerAPIHelper endSession];
    
    _room = nil;
    [ETRDefaultsHelper removeSession];
    
    _didBeginSession = NO;
    
    // Remove all public Actions from the local DB.
    [ETRCoreDataHelper clearPublicActions];
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
    
    if ([self didBeginSession]) {
        [self endSession];
        NSLog(@"ERROR: Room set during running session.");
        return;
    }
    
    // TODO: Only query user ID here?
    _room = room;
    
    // Adjust the location manager for a higher accuracy.
    // TODO: Increase location update speed?
}

#pragma mark -
#pragma mark Regular User List Update

/*
 
 */
- (void)acknowledegeUserListUpdate {
    _lastUserListUpdate = CFAbsoluteTimeGetCurrent();
}

/*
 
 */
- (BOOL)doUpdateUserList {
    return CFAbsoluteTimeGetCurrent() - _lastUserListUpdate > ETRUserListRefreshInterval;
}

@end
