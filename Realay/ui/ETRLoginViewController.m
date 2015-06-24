//
//  WelcomeViewController.m
//  Realay
//
//  Created by Michel on 16.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRLoginViewController.h"

#import "ETRAlertViewFactory.h"
#import "ETRAnimator.h"
#import "ETRLocalUserManager.h"
#import "ETRDetailsViewController.h"
#import "ETRServerAPIHelper.h"
#import "ETRUser.h"

static NSString *const ETRSegueLoginToJoin = @"LoginToJoin";

static NSString *const ETRSegueLoginToProfile = @"LoginToProfile";


@interface ETRLoginViewController()

@property (nonatomic) BOOL doShowProfileOnFinish;

@property (nonatomic) BOOL doStartSessionOnFinish;

@end


@implementation ETRLoginViewController

@synthesize activityIndicator = _activityIndicator;

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [[self nameTextField] setText:@""];
    [super viewWillAppear:animated];
    
    // Directly pop the controller if there is already a valid local user stored.
    if ([[ETRLocalUserManager sharedManager] user]) {
        NSLog(@"WARNING: Skipping Create Profile. Local user has been set up.");
        [[self navigationController] popToRootViewControllerAnimated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self nameTextField] becomeFirstResponder];
}

- (void)threadStartAnimating:(id)data {
    [_activityIndicator startAnimating];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(nonnull UITextField *)textField {
    [self saveButtonPressed:nil];
    return YES;
}

//- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
//    if(theTextField == [self nameTextField]) {
//        [theTextField resignFirstResponder];
//    }
//    return YES;
//}

#pragma mark - Navigation

- (void)showProfileOnLogin {
    _doShowProfileOnFinish = YES;
    _doStartSessionOnFinish = NO;
}

- (void)startSessionOnLogin {
    _doStartSessionOnFinish = YES;
    _doShowProfileOnFinish = NO;
}



- (IBAction)saveButtonPressed:(id)sender {
    NSString * typedName;
    typedName = [[_nameTextField text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([typedName length] < 1) {
        [ETRAnimator fadeView:[self nameTextField]
                     doAppear:NO
                   completion:^{
                       [ETRAnimator fadeView:[self nameTextField]
                                    doAppear:YES
                                  completion:^{
                                      [[self nameTextField] becomeFirstResponder];
                                  }];
        }];
    } else if ([typedName length] > ETRUserNameMaxLength) {
        [_nameTextField setText:[typedName substringToIndex:ETRUserNameMaxLength]];
        [ETRAnimator fadeView:[self nameTextField]
                     doAppear:NO
                   completion:^{
                       [ETRAnimator fadeView:[self nameTextField]
                                    doAppear:YES
                                  completion:^{
                                      [[self nameTextField] becomeFirstResponder];
                                  }];
                   }];
    } else {
        // The typed name is long enough.
        
        // Start the ProgressView.
        [NSThread detachNewThreadSelector:@selector(threadStartAnimating:)
                                 toTarget:self
                               withObject:nil];
        
        // Hide the keyboard.
        [[self nameTextField] resignFirstResponder];
        
        [ETRServerAPIHelper loginUserWithName:typedName
                            completionHandler:^(BOOL didSucceed) {
                                [NSThread detachNewThreadSelector:@selector(handleLoginCompletion:)
                                                         toTarget:self
                                                       withObject:@(didSucceed)];
                            }];
    }
}

- (void)handleLoginCompletion:(NSNumber *)didSucceed {
    if ([didSucceed boolValue]) {
        if (_doStartSessionOnFinish) {
            [super pushToJoinViewController];
        } else {
            [self performSegueWithIdentifier:ETRSegueLoginToProfile sender:nil];
        }
    } else {
        [ETRAlertViewFactory showGeneralErrorAlert];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:ETRSegueLoginToProfile]) {
        ETRDetailsViewController * destination = [segue destinationViewController];
        [destination setUser:[[ETRLocalUserManager sharedManager] user]];
    }
}

@end
