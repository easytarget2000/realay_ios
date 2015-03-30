//
//  ETRProfileViewControllerTableViewController.h
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRRoom;
@class ETRUser;

@interface ETRDetailsViewController : UITableViewController

@property (strong, nonatomic) ETRRoom * room;

@property (strong, nonatomic) ETRUser * user;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButton;

- (IBAction)barButtonPressed:(id)sender;

@end
