//
//  ETRBlockedUsersViewController.h
//  Realay
//
//  Created by Michel on 05/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRBaseViewController.h"


@class ETRImageView;


@interface ETRBlockedUsersViewController : ETRBaseViewController

@property (weak, nonatomic) IBOutlet UITableView *usersTableView;

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

@end
