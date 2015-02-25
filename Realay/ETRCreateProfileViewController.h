//
//  WelcomeViewController.h
//  Realay
//
//  Created by Michel on 16.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETRCreateProfileViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;

@property (nonatomic) NSInteger goToOnFinish;

- (IBAction)saveButtonPressed:(id)sender;

@end
