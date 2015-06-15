//
//  RoomListViewController.h
//  Realay
//
//  Created by Michel on 18.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRBaseViewController.h"


@interface ETRRoomListViewController : ETRBaseViewController

@property (weak, nonatomic) IBOutlet UITableView * tableView;

@property (weak, nonatomic) IBOutlet UIView * infoView;

@property (weak, nonatomic) IBOutlet UILabel * infoLabel;

@property (weak, nonatomic) IBOutlet UIImageView *refreshButton;

@end
