//
//  ETRReceivedMediaCell.h
//  Realay
//
//  Created by Michel on 31/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRImageView;


@interface ETRReceivedMediaCell : UITableViewCell

@property (weak, nonatomic) IBOutlet ETRImageView *userIconView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (weak, nonatomic) IBOutlet ETRImageView *iconView;

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@end
