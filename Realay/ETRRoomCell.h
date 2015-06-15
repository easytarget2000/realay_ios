//
//  RoomListCell.h
//  Realay
//
//  Created by Michel on 20.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRImageView;


@interface ETRRoomCell : UITableViewCell

@property (weak, nonatomic) IBOutlet ETRImageView *headerImageView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;

@property (weak, nonatomic) IBOutlet UILabel *addressHeaderLabel;

@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

@property (weak, nonatomic) IBOutlet UIImageView * placeIcon;

@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;

@property (weak, nonatomic) IBOutlet UILabel *hoursLabel;

@end
