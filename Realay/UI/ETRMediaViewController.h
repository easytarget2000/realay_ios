//
//  ETRMediaViewController.h
//  Realay
//
//  Created by Michel on 29/06/15.
//  Copyright © 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRAction;
@class ETRImageView;

@interface ETRMediaViewController : UIViewController

@property (strong, nonatomic) ETRAction * message;

@property (weak, nonatomic) IBOutlet UILabel *senderLabel;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet ETRImageView *imageView;

- (IBAction)saveButtonPressed:(id)sender;

@end
