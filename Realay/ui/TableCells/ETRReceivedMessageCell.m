//
//  ETRReceivedMessageCell.m
//  Realay
//
//  Created by Michel on 17/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRReceivedMessageCell.h"

#import "ETRImageView.h"

@implementation ETRReceivedMessageCell

- (void)prepareForReuse {
    [[self userIconView] setImageName:nil];
    [[self nameLabel] setText:@""];
    [[self messageLabel] setText:@""];
    [[self timeLabel] setText:@""];
}

@end
