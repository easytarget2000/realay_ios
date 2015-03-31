//
//  ETRReceivedMessageCell.m
//  Realay
//
//  Created by Michel on 17/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRReceivedMessageCell.h"

@implementation ETRReceivedMessageCell

- (void)prepareForReuse {
    [[self userIconView] setTag:0];
}

@end
