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

@property (nonatomic, readonly) NSNumber * foregroundPartnerID;

/*
 
 */
@property (nonatomic, readonly) NSInteger numberOfOtherNotifs;

//@property (readonly, nonatomic) BOOL didFirstQuery;

+ (ETRActionManager *)sharedManager;

- (void)startSession;

- (void)endSession;

- (void)queryUpdates:(NSTimer *)timer;

- (void)ackknowledgeActionID:(long)remoteActionID;

- (void)dispatchNotificationForAction:(ETRAction *)action;

- (void)setForegroundPartnerID:(NSNumber *)foregroundPartnerID;

- (BOOL)doSendPing;

@end
