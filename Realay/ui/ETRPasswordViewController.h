//
//  ETRPasswordViewController.h
//  Realay
//
//  Created by Michel S on 17.03.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRBaseViewController.h"

@interface ETRPasswordViewController : ETRBaseViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)joinButtonPressed:(id)sender;

@end
