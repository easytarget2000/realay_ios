//
//  ETRProfileSocialCell.h
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM(short, ETRSocialNetwork) {
    ETRSocialNetworkFacebook = 1,
    ETRSocialNetworkInstagram = 2,
    ETRSocialNetworkTwitter = 3
};

@class ETRUser;

@interface ETRProfileSocialCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

- (void)setUpForUser:(ETRUser *)user network:(ETRSocialNetwork)network;

- (void)openProfile;

@end
