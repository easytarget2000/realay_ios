//
//  ETRConversationListViewController.h
//  Realay
//
//  Created by Michel on 27/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRUserListBaseViewController.h"


@class ETRImageView;


@interface ETRConversationListViewController : ETRUserListBaseViewController

@property (weak, nonatomic) IBOutlet UITableView * tableView;

@property (weak, nonatomic) IBOutlet UIView * conversationsInfoView;

@end
