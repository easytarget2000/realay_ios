//
//  ETRProfileValueCell.h
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETRKeyValueCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
//@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UITextView *valueLabel;

@end
