//
//  ETRActionManager.h
//  Realay
//
//  Created by Michel on 11/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ETRAction;


@interface ETRActionManager : NSObject

@property (nonatomic, readonly) long lastActionID;

@property (nonatomic) long foregroundPartnerID;

+ (ETRActionManager *)sharedManager;

- (void)startSession;

- (void)queryUpdates:(NSTimer *)timer;

- (void)ackActionID:(long)remoteActionID;

- (void)dispatchNotificationForAction:(ETRAction *)action;

- (void)setForegroundPartnerID:(long)foregroundPartnerID;

@end
