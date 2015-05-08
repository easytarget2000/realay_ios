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

static NSString *const ETRProfilePlaceholderImageName = @"PlaceholderProfileW";

static NSString *const ETRRoomPlaceholderImageName = @"PlaceholderRoomW";

@implementation ETRHeaderCell

- (void)setUpWithRoom:(ETRRoom *)room {
    if (room) {
        [[self nameLabel] setText:[room title]];
        [ETRImageLoader loadImageForObject:room
                                  intoView:[self headerImageView]
                               doLoadHiRes:YES];
    }
}

- (void)setUpWithUser:(ETRUser *)user {
    if (user) {
        [[self nameLabel] setText:[user name]];
        [[self headerImageView] setImage:[UIImage imageNamed:ETRProfilePlaceholderImageName]];
        [ETRImageLoader loadImageForObject:user
                                  intoView:[self headerImageView]
                               doLoadHiRes:YES];
    }
}

@end
