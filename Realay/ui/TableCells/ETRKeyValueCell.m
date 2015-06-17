//
//  ETRProfileValueCell.m
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRKeyValueCell.h"

@implementation ETRKeyValueCell

- (void)prepareForReuse {
    [[self keyLabel] setHidden:NO];
}

@end
