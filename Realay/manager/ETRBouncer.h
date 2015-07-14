//
//  ETRBouncer.h
//  Realay
//
//  Created by Michel on 11/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(NSInteger, ETRKickReason) {
    ETRKickReasonClosed = 8918,
    ETRKickReasonDataOff = 3213,
    ETRKickReasonKick = 8181,
    ETRKickReasonLocation = 4441,
    ETRKickReasonSpam = 7777,
    ETRKickReasonTimeout = 5577
};


@interface ETRBouncer : NSObject

+ (ETRBouncer *)sharedManager;

#pragma mark -
#pragma mark Session Lifecycle
- (void)resetSession;

- (void)acknowledgeConnection;

- (void)acknowledgeFailedConnection;

#pragma mark -
#pragma mark App Foreground/Background

- (void)didEnterBackground;

- (BOOL)showPendingAlertViewsInViewController:(UIViewController *)viewController;

#pragma mark -
#pragma mark Warnings & Kicks

- (void)kickForReason:(short)reason calledBy:(NSString *)caller;

- (void)warnForReason:(short)reason allowDuplicate:(BOOL)doAllowDuplicate;

- (void)cancelLocationWarnings;

- (NSString *)locationKickTime;

@end
