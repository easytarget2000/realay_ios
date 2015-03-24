//
//  ETRProfileHeaderCell.h
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRRoom;
@class ETRUser;

@interface ETRHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *headerImageView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UIView *distanceContainer;

@property (weak, nonatomic) IBOutlet UILabel *distanceView;

@property (weak, nonatomic) IBOutlet UIImageView *placeIcon;

- (void)setUpWithRoom:(ETRRoom *)room;

- (void)setUpWithUser:(ETRUser *)user;

@end
