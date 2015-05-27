//
//  ETRPasswordViewController.m
//  Realay
//
//  Created by Michel S on 17.03.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRPasswordViewController.h"

#import "ETRAlertViewFactory.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRLoginViewController.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"


static NSString *const ETRSeguePasswordToLogin = @"PasswordToLogin";


@implementation ETRPasswordViewController

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [[self passwordTextField] setDelegate:self];
    [[self passwordTextField] setText:@""];
    [self setTitle:[[ETRSessionManager sessionRoom] title]];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[[self navigationController] navigationBar] setTranslucent:NO];
    [[self navigationController] setToolbarHidden:YES];
}

#pragma mark - IBAction

- (IBAction)joinButtonPressed:(id)sender {
#ifdef DEBUG_JOIN
    [self verifyPasswordAndJoin];
#else
    // Only perform a join action, if the user did not join yet.
    if (![[ETRSessionManager sharedManager] didBeginSession]) {
        // Show the password prompt, if the device location is inside the region.
        if ([ETRLocationManager isInSessionRegion]) {
           [self verifyPasswordAndJoin];
        } else {
          [ETRAlertViewFactory showRoomDistanceAlert];
        }
    }
#endif
}

#pragma mark - UITextFieldDelegate

// Press the OK button of the password prompt, when the return key is hit.
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [self verifyPasswordAndJoin];
    return YES;
}

- (void)verifyPasswordAndJoin {        
    // Hide the keyboard.
    [[self passwordTextField] resignFirstResponder];
    
    // Get the password values.
    NSString * typedPassword = [[self passwordTextField] text];
    NSString * password = [[[ETRSessionManager sharedManager] room] password];
    
#ifdef DEBUG_JOIN
    typedPassword = password;
#endif
    
    if([typedPassword isEqualToString:password]) {
        // The right password was given.
        // If the user is already registered, attempt to join the room.
        // Otherwise let the user create a profile first.
        if ([ETRLocalUserManager userID] > 10) {
            [super pushToJoinViewController];
        } else {
            [self performSegueWithIdentifier:ETRSeguePasswordToLogin
                                      sender:self];
        }
    } else {
        [ETRAlertViewFactory showWrongPasswordAlertView];
    }
    
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id destination = [segue destinationViewController];
    
    if ([destination isKindOfClass:[ETRLoginViewController class]]) {
        ETRLoginViewController *loginViewController;
        loginViewController = (ETRLoginViewController *)[segue destinationViewController];
        [destination startSessionOnLogin];
    }
}

@end
