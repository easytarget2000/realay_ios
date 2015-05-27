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

// TODO: Morph into ETRBaseViewController child.

@interface ETRDetailsViewController : UITableViewController

@property (strong, nonatomic) ETRRoom * room;

@property (strong, nonatomic) ETRUser * user;

- (IBAction)blockedUsersButtonPressed:(id)sender;

@end
