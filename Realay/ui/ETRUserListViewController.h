//
//  ETRUserListViewController.h
//  Realay
//
//  Created by Michel on 06/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRUserListBaseViewController.h"


@class ETRImageView;


@interface ETRUserListViewController : ETRUserListBaseViewController

@property (weak, nonatomic) IBOutlet UITableView * tableView;

@property (weak, nonatomic) IBOutlet ETRImageView * infoView;

@property (weak, nonatomic) IBOutlet UILabel * unreadCounterLabel;

@end
