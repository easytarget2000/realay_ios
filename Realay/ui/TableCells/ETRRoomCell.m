//
//  RoomListCell.m
//  Realay
//
//  Created by Michel on 20.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRRoomCell.h"

#import "ETRImageView.h"


@implementation ETRRoomCell

- (void)prepareForReuse {
    [[self titleLabel] setText:@"-"];
    [[self addressLabel] setText:@"-"];
    [[self sizeLabel] setText:@"-"];
    [[self hoursLabel] setText:@"-"];
}

@end
