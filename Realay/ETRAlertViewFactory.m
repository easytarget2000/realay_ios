//
//  ETRUtil.m
//  Realay
//
//  Created by Michel S on 04.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRAlertViewFactory.h"

#import "ETRLocationManager.h"
#import "ETRReadabilityHelper.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"
#import "ETRUser.h"

@implementation ETRAlertViewFactory

+ (void)showGeneralErrorAlert {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Something_wrong", @"Something wrong.")
                                message:NSLocalizedString(@"Sorry", "General appology")
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                      otherButtonTitles:nil] show];
}

/*
 Displays a dialog in an alert view that asks to confirm a block action.
 The delegate will handle the YES button click.
 */
+ (void)showBlockConfirmViewForUser:(ETRUser *)user withDelegate:(id)delegate {
    if (!user) {
        return;
    }
    
    NSString *titleFormat = NSLocalizedString(@"Want_block", @"Want block %@?");
    NSString *userName = [user name];
    
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:titleFormat, userName]
                                message:NSLocalizedString(@"Blocking_hides", @"Hidden user")
                               delegate:delegate
                      cancelButtonTitle:NSLocalizedString(@"No", "Negative")
                      otherButtonTitles:NSLocalizedString(@"Yes", "Positive"), nil] show];
}

/*
 Displays an alert view that gives the reason why the user was kicked from the room.
 */
+ (void)showKickWithMessage:(NSString *)message {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Session_terminated", @"Got kicked")
                                message:message
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                      otherButtonTitles:nil] show];
}

/*
 Displays a warning in an alert view saying that the user left the session region.
 */
+ (void)showLocationWarningWithKickDate:(NSDate *)kickDate {
    if (!kickDate) {
        return;
    }
    
    ETRRoom *sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom) {
        return;
    }
    
    NSString *titleFormat = NSLocalizedString(@"Left_region", @"Left region of Realay %@");
    NSString *roomTitle = [sessionRoom title];
    NSString *msgFormat = NSLocalizedString(@"Return_to_area", @"Return until %@");
    
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:titleFormat, roomTitle]
                                message:[NSString stringWithFormat:msgFormat, kickDate]
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                      otherButtonTitles:nil] show];
}

/*
 Displays a dialog in an alert view if the user wants to leave the room.
 The delegate will handle the OK button click.
 */
+ (void)showLeaveConfirmViewWithDelegate:(id)delegate {
    NSString *titleFormat = NSLocalizedString(@"Want_leave", @"Want to leave %@?");
    
    NSString *roomTitle;
    if ([[ETRSessionManager sharedManager] room]) {
        roomTitle = [[[ETRSessionManager sharedManager] room] title];
    } else {
        roomTitle = @"";
    }
    
    [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:titleFormat, roomTitle]
                                message:nil
                               delegate:delegate
                      cancelButtonTitle:NSLocalizedString(@"No", "Negative")
                      otherButtonTitles:NSLocalizedString(@"Yes", "Positive"), nil] show];
}

/*
 Displays a warning in an alert view saying that the device location cannot be found.
 */
+ (void)showNoLocationAlertViewWithMinutes:(NSInteger)minutes {
    NSString *msg;
    
    // TODO: Use different way of handling unknown locations.

    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unknown_location", @"Unknown device location")
                                message:msg
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                      otherButtonTitles:nil] show];
}

/*
 Displays an alert view that says the user cannot join the room
 until stepping inside the region.
 */
+ (void)showDistanceLeftAlertView {
    ETRRoom *sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom) {
        return;
    }
    
    NSString *distanceFormat;
    distanceFormat = NSLocalizedString(@"Current_distance", @"Current distance: %@");
    NSInteger distanceValue = [[ETRLocationManager sharedManager] distanceToRoom:sessionRoom];
    NSString *distance = [ETRReadabilityHelper formattedIntegerLength:distanceValue];
    NSString *title = [NSString stringWithFormat:distanceFormat, distance];
    NSString *message = NSLocalizedString(@"Before_join", @"Before you can join, enter");
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                      otherButtonTitles:nil] show];
}

/*
 Displays an alert view that says the typed name is not long enough to be used.
 */
+ (void)showTypedNameTooShortAlert {
    // TODO: Replace with warning icon.
}

/*
 Displays an alert view that says the entered room password is wrong.
 */
+ (void)showWrongPasswordAlertView {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Wrong_Password", "Incorrect password")
                                message:nil
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                      otherButtonTitles:nil] show];
}

@end
