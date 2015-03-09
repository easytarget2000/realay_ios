//
//  ETRUtil.h
//  Realay
//
//  Created by Michel S on 04.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETRAlertViewFactory : NSObject

/*
 Displays a dialog in an alert view that asks to confirm a block action.
 The delegate will handle the YES button click.
 */
+(void)showBlockConfirmViewWithDelegate:(id)delegate;

/*
 Displays an alert view that gives the reason why the user was kicked from the room.
 */
+ (void)showKickWithMessage:(NSString *)message;

/*
 Displays a warning in an alert view that says the user left the session region
 and how many minutes he has to return.
 */
+ (void)showDidExitRegionAlertViewWithMinutes:(NSInteger)minutes;

/*
 Displays a dialog in an alert view if the user wants to leave the room.
 The delegate will handle the OK button click.
 */
+ (void)showLeaveConfirmViewWithDelegate:(id)delegate;

/*
 Displays a warning in an alert view saying that the device location cannot be found
 and how many minutes are left.
 */
+ (void)showNoLocationAlertViewWithMinutes:(NSInteger)minutes;

/*
 Displays an alert view that says the user cannot join the room
 until stepping inside the region.
 */
+ (void)showDistanceLeftAlertView;

/*
 Displays an alert view that says the typed name is not long enough to be used.
 */
+ (void)showTypedNameTooShortAlert;

/*
 Displays an alert view that says the entered room password is wrong.
 */
+ (void)showWrongPasswordAlertView;

+ (void)showGeneralErrorAlert;

@end
