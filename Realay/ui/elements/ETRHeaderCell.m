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

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUpWithRoom:(ETRRoom *)room {
    if (!room) {
        return;
    }
    
    [[self nameLabel] setText:[room title]];
    [ETRImageLoader loadImageForObject:room
                              intoView:[self headerImageView]
                           doLoadHiRes:YES];
}

- (void)setUpWithUser:(ETRUser *)user {
    if (!user) {
        return;
    }
    
    [[self nameLabel] setText:[user name]];
    [[self headerImageView] setImage:[UIImage imageNamed:ETRProfilePlaceholderImageName]];
    [ETRImageLoader loadImageForObject:user
                              intoView:[self headerImageView]
                           doLoadHiRes:YES];
}

@end
