//
//  EditFieldViewController.h
//  Realay
//
//  Created by Michel S on 28.01.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETREditFieldViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel        *editAttributeLabel;
@property (weak, nonatomic) IBOutlet UITextField    *editTextField;

@property (nonatomic) NSString *attributeKey;

- (IBAction)saveButtonPressed:(id)sender;

@end
