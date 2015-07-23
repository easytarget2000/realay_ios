//
//  ETRActionManager.h
//  Realay
//
//  Created by Michel on 11/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

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

- (void)didEnterBackground;

- (void)fetchUpdatesWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

- (BOOL)doSendPing;

- (void)ackknowledgeActionID:(long)remoteActionID;

- (void)setForegroundPartnerID:(NSNumber *)foregroundPartnerID;

#pragma mark -
#pragma mark Notifications

- (void)cancelAllNotifications;

@end
