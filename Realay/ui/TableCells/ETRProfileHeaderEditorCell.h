//
//  ETRProfileHeaderEditorCell.h
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRProfileEditorViewController;
@class ETRUser;
@class ETRImageView;


@interface ETRProfileHeaderEditorCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField * nameField;
@property (weak, nonatomic) IBOutlet ETRImageView * iconImageView;

- (void)setUpWithTag:(NSInteger)tag
             forUser:(ETRUser *)user
    inViewController:(ETRProfileEditorViewController *)viewController;

@end
