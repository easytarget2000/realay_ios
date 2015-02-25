//
//  WelcomeViewController.m
//  Realay
//
//  Created by Michel on 16.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRCreateProfileViewController.h"

#import "ETRViewProfileViewController.h"
#import "ETRLocalUser.h"
#import "ETRAlertViewBuilder.h"

#import "SharedMacros.h"

#define kSegueToChat        @"createProfileToChatSegue"
#define kSegueToViewProfile @"createProfileToViewProfileSegue"

@implementation ETRCreateProfileViewController {
    UIActivityIndicatorView *_activityIndicator;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self nameTextField] setDelegate:self];
    
    // Show an acitvity indicator while performing DB actions.
    _activityIndicator = [[UIActivityIndicatorView alloc]
                                                  initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [[self view] addSubview:_activityIndicator];
}

- (void)viewWillAppear:(BOOL)animated {
    [[self nameTextField] setText:@""];
    [super viewWillAppear:animated];
    
    // Directly pop the controller if there is already a valid local user stored.
    if ([[ETRLocalUser sharedLocalUser] userID]) {
#ifdef DEBUG
        NSLog(@"INFO: Skipping Create Profile. Local user is %@.",
              [[ETRLocalUser sharedLocalUser] name]);
#endif
        [[self navigationController] popViewControllerAnimated:NO];
    }
}

- (void)threadStartAnimating:(id)data {
    [_activityIndicator startAnimating];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if(theTextField == [self nameTextField]) {
        [theTextField resignFirstResponder];
    }
    return YES;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:kSegueToViewProfile]) {
        ETRViewProfileViewController *destination = [segue destinationViewController];
        [destination setShowMyProfile:YES];
    }
}

- (IBAction)saveButtonPressed:(id)sender {
    NSString *typedName = [[[self nameTextField] text]
                           stringByTrimmingCharactersInSet:
                           [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if([typedName length] < 2) {
        [ETRAlertViewBuilder showTypedNameTooShortAlert];
    } else {
        // The typed name is long enough.
        
        // Show an activity indicator during the DB actions.
        [NSThread detachNewThreadSelector:@selector(threadStartAnimating:)
                                 toTarget:self
                               withObject:nil];
        
        // Hide the keyboard.
        [[self nameTextField] resignFirstResponder];
        
        // Rewrite the local user singleton and insert its values into DBs and UserDefs.
        if ([[ETRLocalUser sharedLocalUser] insertNewLocalUserWithName:typedName]) {
            if ([self goToOnFinish] == kEnumGoToChat){

                // Attempt joining the room.
                [[ETRSession sharedSession] beginSession];
                
                // If we are about to join a room, we want to see the chat now.
                if ([[ETRSession sharedSession] didBeginSession]) {
                    [self performSegueWithIdentifier:kSegueToChat sender:self];
                }
            } else {
                // If we are coming from the room list, we want to see our profile now.
                [self performSegueWithIdentifier:kSegueToViewProfile sender:self];
            }
        }
    }
    
    [_activityIndicator stopAnimating];
}

@end
