//
//  ETRReceivedMessageCell.h
//  Realay
//
//  Created by Michel on 17/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ETRImageView;


@interface ETRReceivedMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet ETRImageView *userIconView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
