//
//  ETRActionManager.m
//  Realay
//
//  Created by Michel on 11/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRActionManager.h"

#import "ETRAction.h"

static ETRActionManager *sharedInstance = nil;

@implementation ETRActionManager

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

- (void)setForegroundPartnerID:(long)foregroundPartnerID {
    _foregroundPartnerID = foregroundPartnerID;
    // TODO: Cancel Notifications from this foreground Conversation.
}

- (void)handleReceivedAction:(ETRAction *)receivedAction {
    if (!receivedAction) {
        return;
    }
    
    long remoteID = [[receivedAction remoteID] longValue];
    if (remoteID > _lastActionID) {
        _lastActionID = remoteID;
    }
    
    switch ([[receivedAction code] shortValue]) {
        default:
            break;
    }
}

@end
