//
//  ETRProfileSocialCell.h
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRUser;

@interface ETRProfileSocialCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView * facebookButton;

@property (weak, nonatomic) IBOutlet UIImageView * instagramButton;

@property (weak, nonatomic) IBOutlet UIImageView * twitterButton;

- (void)setUpForUser:(ETRUser *)user;

@end
