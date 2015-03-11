//
//  ETRPasswordViewController.m
//  Realay
//
//  Created by Michel S on 17.03.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRPasswordViewController.h"

#import "ETRChatViewController.h"
#import "ETRLoginViewController.h"
#import "ETRAlertViewFactory.h"

#import "ETRSharedMacros.h"

#define DEBUG_NO_PW_CHECK       1

#define kSegueToChat            @"passwordToJoinSegue"
#define kSegueToCreateProfile   @"passwordToCreateProfileSegue"

@implementation ETRPasswordViewController {
    UIActivityIndicatorView *_activityIndicator;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // The join process takes a while.
    // Show an activity indicator (spinning circle).
    _activityIndicator = [[UIActivityIndicatorView alloc]
                         initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [_activityIndicator setCenter:[[self view] center]];
    [[self view] addSubview:_activityIndicator];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [[self passwordTextField] setDelegate:self];
    [[self passwordTextField] setText:@""];
    [self setTitle:[[[ETRSession sharedManager] room] title]];
    
    // Just in case there is a toolbar wanting to be displayed:
    [[self navigationController] setToolbarHidden:YES];
}

- (void)threadStartAnimating:(id)data {
    [_activityIndicator startAnimating];
}

#pragma mark - IBAction

- (IBAction)joinButtonPressed:(id)sender {
    // Only perform a join action, if the user did not join yet.
    if (![[ETRSession sharedManager] didBeginSession]) {
        // Show the password prompt, if the device location is inside the region.
        if ([ETRLocationHelper isInSessionRegion]) {
           [self checkEnteredPassword];
        } else {
          [ETRAlertViewFactory showDistanceLeftAlertView];
        }
    }
}

#pragma mark - UITextFieldDelegate

// Press the OK button of the password prompt, when the return key is hit.
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    [self checkEnteredPassword];
    return YES;
}

//TODO: Localization
- (void)checkEnteredPassword {
    
    // Start the activity indicator.
    [NSThread detachNewThreadSelector:@selector(threadStartAnimating:)
                             toTarget:self
                           withObject:nil];
        
    // Hide the keyboard.
    [[self passwordTextField] resignFirstResponder];
    
    // Get the password values.
    NSString *typedPassword = [[self passwordTextField] text];
    NSString *password = [[[ETRSession sharedManager] room] password];
    
#ifdef DEBUG_NO_PW_CHECK
//    typedPassword = password;
#endif
    
    if([typedPassword isEqualToString:password]) {
        // The right password was given.
        // If the user is already registered, attempt to join the room.
        // Otherwise let the user create a profile first.
        if ([[ETRLocalUserManager sharedManager] userID] > 10) {
            
            [[ETRSession sharedManager] beginSession];
            
            if ([[ETRSession sharedManager] didBeginSession]) {
                [self performSegueWithIdentifier:kSegueToChat sender:self];
            } else {
                //TODO: Error handling
            }
        } else {
            // There is no local user created yet.
            [self performSegueWithIdentifier:kSegueToCreateProfile sender:self];
        }
    } else {
        [ETRAlertViewFactory showWrongPasswordAlertView];
    }
    
    [_activityIndicator stopAnimating];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Tell the Create Profile controller to go to the chat when done.
    if ([[segue identifier] isEqualToString:kSegueToChat]) {
        ETRChatViewController *destination = [segue destinationViewController];
        [destination setConversationID:kPublicReceiverID];
    } else if ([[segue identifier] isEqualToString:kSegueToCreateProfile]) {
        ETRLoginViewController *destination = [segue destinationViewController];
        [destination startSessionOnLogin];
    }
}

@end
