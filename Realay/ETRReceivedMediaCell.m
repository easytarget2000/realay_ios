//
//  ETRReceivedMediaCell.m
//  Realay
//
//  Created by Michel on 31/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRReceivedMediaCell.h"

@implementation ETRReceivedMediaCell

- (void)prepareForReuse {
    [[self userIconView] setTag:0];
    [[self iconView] setTag:0];
}

@end
