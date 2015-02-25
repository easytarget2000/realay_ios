//
//  ETRPasswordViewController.h
//  Realay
//
//  Created by Michel S on 17.03.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETRPasswordViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)joinButtonPressed:(id)sender;

@end
