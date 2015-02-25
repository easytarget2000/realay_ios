//
//  ETRUtil.m
//  Realay
//
//  Created by Michel S on 04.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRAlertViewBuilder.h"

#import "ETRSession.h"

@implementation ETRAlertViewBuilder

/*
 Displays a dialog in an alert view that asks to confirm a block action.
 The delegate will handle the YES button click.
 */
+(void)showBlockConfirmViewWithDelegate:(id)delegate {
    NSString *title = @"Do you really want to block this user?";
    NSString *msg   = @"Blocking keeps a person from writing you and hides their public messages";
    
    [[[UIAlertView alloc] initWithTitle:title
                                message:msg
                               delegate:delegate
                      cancelButtonTitle:@"No"
                      otherButtonTitles:@"Yes", nil] show];
}

/*
 Displays an alert view that gives the reason why the user was kicked from the room.
 */
+ (void)showKickWithMessage:(NSString *)message {
    NSString *title = @"You had to leave this Realay.";
    
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

/*
 Displays a warning in an alert view saying that the user left the session region.
 */
+ (void)showDidExitRegionAlertViewWithMinutes:(NSInteger)minutes {
    NSString *title = @"You have left the region of this Realay.";
    
    if (minutes < 0) minutes = -minutes;
    NSString *msgFormat = @"Please return in the next %d minutes. Use the map for more information.";
    NSString *msg = [NSString stringWithFormat:msgFormat, minutes];
    
    [[[UIAlertView alloc] initWithTitle:title
                                message:msg
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

/*
 Displays a dialog in an alert view if the user wants to leave the room.
 The delegate will handle the OK button click.
 */
+ (void)showLeaveConfirmViewWithDelegate:(id)delegate {
    NSString *title = @"Do you want to leave this Realay?";
    [[[UIAlertView alloc] initWithTitle:title
                                message:nil
                               delegate:delegate
                      cancelButtonTitle:@"No"
                      otherButtonTitles:@"Yes", nil] show];
}

/*
 Displays a warning in an alert view saying that the device location cannot be found.
 */
+ (void)showNoLocationAlertViewWithMinutes:(NSInteger)minutes {
    NSString *title = @"Your location cannot be found.";
    NSString *msg;
    
    if (minutes != 0) {
        if (minutes < 0) minutes = -minutes;
        NSString *msgFormat = @"Please make sure your device finds your location in the next %d minutes.";
        msg = [NSString stringWithFormat:msgFormat, minutes];
    } else {
        msg = @"Please make sure your device finds your location.";
    }

    [[[UIAlertView alloc] initWithTitle:title
                                message:msg
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

/*
 Displays an alert view that says the user cannot join the room
 until stepping inside the region.
 */
+ (void)showOutsideRegionAlertView {
    NSString *title = @"Outside of this Realay's region.";
    NSString *message = @"Please move inside the circle to join.";
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

/*
 Displays an alert view that says the typed name is not long enough to be used.
 */
+ (void)showTypedNameTooShortAlert {
    // Show "too short" alert.
    // TODO: Localization
    NSString *title = @"Entered name too short";
    NSString *message = @"Please use a name that is a little longer.";
    NSString *alertOk = @"OK";
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:title
                                                   message:message
                                                  delegate:nil
                                         cancelButtonTitle:alertOk
                                         otherButtonTitles:nil];
    [alert show];
}

/*
 Displays an alert view that says the entered room password is wrong.
 */
+ (void)showWrongPasswordAlertView {
    [[[UIAlertView alloc] initWithTitle:@"Wrong Password"
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

@end
