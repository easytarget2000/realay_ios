//
//  WelcomeViewController.h
//  Realay
//
//  Created by Michel on 16.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRBaseViewController.h"

@interface ETRLoginViewController : ETRBaseViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

- (IBAction)saveButtonPressed:(id)sender;

- (void)startSessionOnLogin;

- (void)showProfileOnLogin;

@end
