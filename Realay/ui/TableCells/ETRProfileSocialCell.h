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

@property (weak, nonatomic) IBOutlet UIButton * facebookButton;

@property (weak, nonatomic) IBOutlet UIButton * instagramButton;

@property (weak, nonatomic) IBOutlet UIButton *twitterButton;

- (void)setUpForUser:(ETRUser *)user;

- (IBAction)facebookButtonPressed:(id)sender;

- (IBAction)instagramButtonPressed:(id)sender;

- (IBAction)twitterButtonPressed:(id)sender;


@end
