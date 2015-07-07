//
//  ETRReceivedMediaCell.m
//  Realay
//
//  Created by Michel on 31/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRReceivedMediaCell.h"

#import "ETRAnimator.h"
#import "ETRImageView.h"


@implementation ETRReceivedMediaCell

- (void)prepareForReuse {
    [[self userIconView] setImageName:nil];
    [[self iconView] setImageName:nil];
    [[self nameLabel] setText:@""];
    [[self timeLabel] setText:@""];
}

@end
