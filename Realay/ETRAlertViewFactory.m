//
//  ETRUtil.m
//  Realay
//
//  Created by Michel S on 04.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRAlertViewFactory.h"

#import "ETRAction.h"
#import "ETRConversationViewController.h"
#import "ETRDetailsViewController.h"
#import "ETRLocationManager.h"
#import "ETRReadabilityHelper.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"
#import "ETRUser.h"

typedef NS_ENUM(NSInteger, ETRAlertViewTag) {
    ETRAlertViewTagLeave = 66,
    ETRAlertViewTagMessageMenu = 68,
    ETRAlertViewTagBlock = 70,
    ETRAlertViewTagSettings = 72
};


@interface ETRAlertViewFactory () <UIAlertViewDelegate>

@property (strong, nonatomic) ETRUser * selectedUser;

@property (strong, nonatomic) ETRAction * selectedMessage;

@property (strong, nonatomic) UIViewController * viewController;

@end


@implementation ETRAlertViewFactory

#pragma mark -
#pragma mark Settings/Authorization

/*
 
 */
- (void)showSettingsAlert {
    _existingSettingsAlert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"For_an_uninterrupted", @"Required settings explained")
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:NSLocalizedString(@"Settings", @"Preferences"), nil];
    [_existingSettingsAlert setTag:ETRAlertViewTagSettings];
    [_existingSettingsAlert setDelegate:self];
    [_existingSettingsAlert show];
}

#pragma mark -
#pragma mark Session Exit

/*
 Displays a dialog in an alert view if the user wants to leave the room.
 The delegate will handle the OK button click.
 */
- (void)showLeaveConfirmView {
    NSString * titleFormat = NSLocalizedString(@"Want_leave", @"Want to leave %@?");
    
    NSString * roomTitle;
    if ([[ETRSessionManager sharedManager] room]) {
        roomTitle = [[[ETRSessionManager sharedManager] room] title];
    } else {
        roomTitle = @"";
    }
    
    UIAlertView * alertView;
    alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:titleFormat, roomTitle]
                                           message:nil
                                          delegate:self
                                 cancelButtonTitle:NSLocalizedString(@"No", "Negative")
                                 otherButtonTitles:NSLocalizedString(@"Yes", "Positive"), nil];
    [alertView setTag:ETRAlertViewTagLeave];
    [alertView show];
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

#pragma mark -
#pragma mark User Interaction

/*
 
 */
- (void)showMenuForMessage:(ETRAction *)message calledByViewController:(UIViewController *)viewController {
    // Do not show a menu, if the Action is an outgoing Media Action.
    if (!message || ([message isSentAction] && [message isPhotoMessage])) {
        return;
    }
    
    _selectedMessage = message;
    _viewController = viewController;
    
    NSString * copyMessage = NSLocalizedString(@"Copy_Message", @"Copy message to clipboard");
    
    NSMutableArray * buttonTitles = [NSMutableArray arrayWithObjects:copyMessage, nil];
    
    if (![_selectedMessage isSentAction] && [_selectedMessage isPublicAction]) {
        [buttonTitles addObject:NSLocalizedString(@"Private_Conversation", @"Open Private Chat")];
        [buttonTitles addObject:NSLocalizedString(@"Show_Profile", @"User Details")];
    }
    
    UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:nil
                                                         message:nil
                                                        delegate:self
                                               cancelButtonTitle:NSLocalizedString(@"Cancel", "Negative")
                                               otherButtonTitles:nil];
    
    for (NSString * title in buttonTitles)  {
        [alertView addButtonWithTitle:title];
    }
    
    [alertView setTag:ETRAlertViewTagMessageMenu];
    [alertView show];
}

/*
 
 */
+ (void)showHasLeftViewForUser:(ETRUser *)user {
    NSString * message;
    message = [NSString stringWithFormat:NSLocalizedString(@"has_left", @"%User has left %Room."),
               [user name],
               [[ETRSessionManager sessionRoom] title]];
    
    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                               delegate:self
                      cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                      otherButtonTitles:nil] show];
}

/*
 Displays a dialog in an alert view that asks to confirm a block action.
 The delegate will handle the YES button click.
 */
- (void)showBlockConfirmViewForUser:(ETRUser *)user {
    _selectedUser = user;
    if (!_selectedUser) {
        return;
    }
    
    NSString *titleFormat = NSLocalizedString(@"Want_block", @"Want block %@?");
    NSString *userName = [_selectedUser name];
    
    NSString * blockReport  = NSLocalizedString(@"Block_Report", "Block & Send Report");
    NSString * blockOnly    = NSLocalizedString(@"Block", "Only block");
    
    UIAlertView * alertView;
    alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:titleFormat, userName]
                                           message:NSLocalizedString(@"Blocking_hides", @"Hidden user")
                                          delegate:self
                                 cancelButtonTitle:NSLocalizedString(@"Cancel", "Negative")
                                 otherButtonTitles:blockReport, blockOnly, nil];
    [alertView setTag:ETRAlertViewTagBlock];
    [alertView show];
}

#pragma mark -
#pragma mark General

+ (void)showGeneralErrorAlert {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Something_wrong", @"Something wrong.")
                                message:NSLocalizedString(@"Sorry", "General appology")
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", @"Understood")
                      otherButtonTitles:nil] show];
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
+ (void)showRoomDistanceAlert {
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

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    
    switch ([alertView tag]) {
        case ETRAlertViewTagBlock:
            if (buttonIndex == 0) {
                return;
            }
            
            if (_selectedUser) {
                NSLog(@"ERROR: Cannot perform next blocking step. User reference lost.");
            } else {
                [_selectedUser setIsBlocked:@(YES)];
            }
            break;
            
        case ETRAlertViewTagLeave:
            if (buttonIndex == 0) {
                return;
            }
            
            [[ETRSessionManager sharedManager] endSession];
            break;
            
        case ETRAlertViewTagMessageMenu:
            if (!_selectedMessage || buttonIndex == 0) {
                return;
            }
            
            BOOL isPhotoMessage = [_selectedMessage isPhotoMessage];
            
            // Photo Messages do not have the first entry "Copy Message".
            
            if ((buttonIndex == 1 && !isPhotoMessage)) {
                [[UIPasteboard generalPasteboard] setString:[_selectedMessage messageContent]];
            } else if ((buttonIndex == 1 && isPhotoMessage) || buttonIndex == 2) {
                // Open the private conversation.
                
                ETRUser * user = [_selectedMessage sender];
                if (!_viewController || ![_selectedMessage sender]) {
                    break;
                }
                
                ETRRoom * sessionRoom = [ETRSessionManager sessionRoom];
                
                if ([[user inRoom] isEqual:sessionRoom]) {
                    UIStoryboard * storyBoard = [_viewController storyboard];
                    ETRConversationViewController * conversationViewController;
                    conversationViewController = [storyBoard instantiateViewControllerWithIdentifier:ETRViewControllerIDConversation];
                    
                    [conversationViewController setPartner:user];
                    [[_viewController navigationController] pushViewController:conversationViewController
                                                                      animated:YES];
                } else {
                    [ETRAlertViewFactory showHasLeftViewForUser:user];
                }
            } else if ((buttonIndex == 2 && isPhotoMessage) || buttonIndex == 3) {
                // Show User profile.
                
                if (!_viewController || ![_selectedMessage sender]) {
                    break;
                }
                
                UIStoryboard * storyBoard = [_viewController storyboard];
                ETRDetailsViewController * profileViewController;
                profileViewController = [storyBoard instantiateViewControllerWithIdentifier:ETRViewControllerIDDetails];
                
                [profileViewController setUser:[_selectedMessage sender]];
                [[_viewController navigationController] pushViewController:profileViewController
                                                                  animated:YES];
            }
            break;
            
        case ETRAlertViewTagSettings: {
            NSString * settingsURL = UIApplicationOpenSettingsURLString;
            if (settingsURL) {
               [[UIApplication sharedApplication] openURL:[NSURL URLWithString:settingsURL]];
            }
        }
            // TODO: Open App settings.
            
    }
}

@end
