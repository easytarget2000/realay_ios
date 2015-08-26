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
    [[self nameLabel] setText:nil];
//    [[self messageView] setDataDetectorTypes:UIDataDetectorTypeNone];
    
    [[self messageView] setAttributedText:nil];
//    [[self messageView] setEditable:NO];
//    [[self messageView] setEditable:YES];
    [[self timeLabel] setText:nil];
}

@end
