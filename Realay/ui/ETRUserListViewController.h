//
//  ETRUserListViewController.h
//  Realay
//
//  Created by Michel on 06/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRBaseViewController.h"


@interface ETRUserListViewController : ETRBaseViewController

@property (strong, nonatomic) IBOutlet UITableView * usersTableView;

@property (weak, nonatomic) IBOutlet UIView *
infoView;

@end
