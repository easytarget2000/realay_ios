//
//  ETRProfileViewControllerTableViewController.h
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRBaseViewController.h"

@class ETRRoom;
@class ETRUser;


@interface ETRDetailsViewController : ETRBaseViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) ETRRoom * room;

@property (strong, nonatomic) ETRUser * user;

- (IBAction)blockedUsersButtonPressed:(id)sender;

@end
