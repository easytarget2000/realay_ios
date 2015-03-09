//
//  ETRProfileHeaderEditorCell.h
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRUser;

@interface ETRProfileHeaderEditorCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

- (void)setUpWithTag:(NSInteger)tag forUser:(ETRUser *)user;

@end
