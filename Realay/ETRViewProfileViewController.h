//
//  RLViewProfileViewController.h
//  Realay
//
//  Created by Michel S on 12.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ETRUser.h"

@interface ETRViewProfileViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *headerImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

@property (nonatomic) ETRUser *user;
@property (nonatomic) UIViewController  *previousController;

@end
