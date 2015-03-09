//
//  WelcomeViewController.m
//  Realay
//
//  Created by Michel on 16.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRLoginViewController.h"

#import "ETRAlertViewFactory.h"
#import "ETRLocalUserManager.h"
#import "ETRDetailsViewController.h"
#import "ETRServerAPIHelper.h"
#import "ETRSession.h"
#import "ETRUser.h"

#import "ETRSharedMacros.h"

#define kSegueToChat        @"createProfileToChatSegue"
#define kSegueToViewProfile @"loginToProfileSegue"

@interface ETRLoginViewController()

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (nonatomic) BOOL doShowProfileOnFinish;
@property (nonatomic) BOOL doStartSessionOnFinish;

@end

@implementation ETRLoginViewController

@synthesize activityIndicator = _activityIndicator;

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
    if ([[ETRLocalUserManager sharedManager] user]) {
#ifdef DEBUG
        NSLog(@"WARNING: Skipping Create Profile. Local user is %@.",
              [[[ETRLocalUserManager sharedManager] user] name]);
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

- (void)showProfileOnLogin {
    _doShowProfileOnFinish = YES;
    _doStartSessionOnFinish = NO;
}

- (void)startSessionOnLogin {
    _doStartSessionOnFinish = YES;
    _doShowProfileOnFinish = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:kSegueToViewProfile] && [sender isKindOfClass:[ETRUser class]]) {
        ETRDetailsViewController *destination = [segue destinationViewController];
        [destination setUser:(ETRUser *) sender];
    }
}

- (IBAction)saveButtonPressed:(id)sender {
    NSString *typedName;
    typedName = [[_nameTextField text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([typedName length] < 1) {
        [ETRAlertViewFactory showTypedNameTooShortAlert];
    } else {
        // The typed name is long enough.
        
        // Show an activity indicator during the DB actions.
        [NSThread detachNewThreadSelector:@selector(threadStartAnimating:)
                                 toTarget:self
                               withObject:nil];
        
        // Hide the keyboard.
        [[self nameTextField] resignFirstResponder];
        
        [ETRServerAPIHelper loginUserWithName:typedName onSuccessBlock:^(ETRUser *localUser) {
            if (localUser) {
                [self performSegueWithIdentifier:kSegueToViewProfile sender:localUser];
            } else {
                [ETRAlertViewFactory showGeneralErrorAlert];
            }
        }];
    }
    
}

@end
