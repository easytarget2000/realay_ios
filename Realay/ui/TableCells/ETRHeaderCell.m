//
//  ETRProfileHeaderCell.m
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRHeaderCell.h"

#import "ETRImageLoader.h"
#import "ETRRoom.h"
#import "ETRUser.h"
#import "ETRUIConstants.h"

@implementation ETRHeaderCell

- (void)setUpWithRoom:(ETRRoom *)room {
    if (room) {
        [[self nameLabel] setText:[room title]];
        [ETRImageLoader loadImageForObject:room
                                  intoView:[self headerImageView]
                          placeHolderImage:[UIImage imageNamed:ETRImageNameRoomPlaceholder]
                               doLoadHiRes:YES];
    }
}

- (void)setUpWithUser:(ETRUser *)user {
    if (user) {
        [[self nameLabel] setText:[user name]];
        [ETRImageLoader loadImageForObject:user
                                  intoView:[self headerImageView]
                          placeHolderImage:[UIImage imageNamed:ETRImageNameProfilePlaceholder]
                               doLoadHiRes:YES];
    }
}

@end
