//
//  ETRUtil.h
//  Realay
//
//  Created by Michel S on 04.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ETRAction;
@class ETRUser;


@interface ETRAlertViewFactory : NSObject

#pragma mark -
#pragma mark Settings/Authorization

/*
 
 */
@property (strong, nonatomic, readonly) UIAlertView * existingSettingsAlert;

/*
 
 */
- (void)showSettingsAlert;

#pragma mark -
#pragma mark Session Exit

/*
 Displays a dialog in an alert view if the user wants to leave the room.
 The delegate will handle the OK button click.
 */
- (void)showLeaveConfirmView;

/*
 Displays an alert view that gives the reason why the user was kicked from the room.
 */
+ (void)showKickWithMessage:(NSString *)message;

/*
 Displays a warning in an alert view saying that the device location cannot be found
 and how many minutes are left.
 */
+ (void)showLocationWarningWithKickDate:(NSDate *)kickDate;

#pragma mark -
#pragma mark User Interaction

/*
 
 */
- (void)showMenuForMessage:(ETRAction *)message
    calledByViewController:(UIViewController *)viewController;

/*
 
 */
+ (void)showHasLeftViewForUser:(ETRUser *)user;

#pragma mark -
#pragma mark General

/*
 
 */
+ (void)showGeneralErrorAlert;

/*
 Displays an alert view that says the user cannot join the room
 until stepping inside the region.
 */
+ (void)showRoomDistanceAlert;

/*
 Displays an alert view that says the typed name is not long enough to be used.
 */
+ (void)showTypedNameTooShortAlert;

/*
 Displays an alert view that says the entered room password is wrong.
 */
+ (void)showWrongPasswordAlertView;


@end
