//
//  RLViewProfileViewController.h
//  Realay
//
//  Created by Michel S on 12.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ETRSession.h"

@interface ETRViewProfileViewController : UITableViewController
 <UIAlertViewDelegate, UITableViewDelegate, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton           *imageView;
@property (weak, nonatomic) IBOutlet UILabel            *nameLabel;
@property (weak, nonatomic) IBOutlet UITableViewCell    *statusCell;

@property (nonatomic) ETRUser           *user;
@property (nonatomic) UIViewController  *previousController;
@property (nonatomic) BOOL              showMyProfile;

- (IBAction)imageButtonPressed:(id)sender;

@end
