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

- (BOOL)showPendingAlertViewsInViewController:(UIViewController *)viewController;

- (void)didEnterBackground;

- (void)kickForReason:(short)reason calledBy:(NSString *)caller;

- (void)warnForReason:(short)reason;

- (void)cancelLocationWarnings;

#pragma mark -
#pragma mark Connection

- (void)acknowledgeConnection;

- (void)acknowledgeFailedConnection;

@end
