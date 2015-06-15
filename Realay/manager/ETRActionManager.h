//
//  ETRActionManager.h
//  Realay
//
//  Created by Michel on 11/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ETRAction;
@class ETRUserListViewController;

#pragma mark -
#pragma mark ETRInternalNotificationHandler Protocol

@protocol ETRInternalNotificationHandler

- (void)setPrivateMessagesBadgeNumber:(NSInteger)number;

@end

#pragma mark -
#pragma mark Interface

@interface ETRActionManager : NSObject

@property (nonatomic, readonly) long lastActionID;

@property (nonatomic, readonly) NSNumber * foregroundPartnerID;

@property (strong, nonatomic) id<ETRInternalNotificationHandler> internalNotificationHandler;

+ (ETRActionManager *)sharedManager;

#pragma mark -
#pragma mark Session Life Cycle

- (void)startSession;

- (void)endSession;

- (void)fetchUpdatesWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

- (BOOL)doSendPing;

- (void)ackknowledgeActionID:(long)remoteActionID;

#pragma mark -
#pragma mark Notifications

- (void)dispatchNotificationForAction:(ETRAction *)action;

- (void)setForegroundPartnerID:(NSNumber *)foregroundPartnerID;

- (NSInteger)numberOfPrivateNotifs;

@end
