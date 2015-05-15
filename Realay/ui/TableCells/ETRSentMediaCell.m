//
//  ETRSentMediaCell.m
//  Realay
//
//  Created by Michel on 31/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRSentMediaCell.h"

#import "ETRImageView.h"


@implementation ETRSentMediaCell

- (void)prepareForReuse {
//    [[self iconView] setImageName:nil];
    [[self timeLabel] setText:@""];
}

@end
