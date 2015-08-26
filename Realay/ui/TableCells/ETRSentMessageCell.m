//
//  ETRSentMessageCell.m
//  Realay
//
//  Created by Michel on 14/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRSentMessageCell.h"

@implementation ETRSentMessageCell

- (void)prepareForReuse {
    
    [[self messageView] setText:nil];
    [[self timeLabel] setText:nil];
}

@end
