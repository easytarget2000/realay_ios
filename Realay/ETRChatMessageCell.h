//
//  ETRChatMessageCell.h
//  Realay
//
//  Created by Michel S on 03.04.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ETRAction.h"

@interface ETRChatMessageCell : UITableViewCell

@property (strong, nonatomic, readonly) ETRAction *message;

- (void)applyMessage:(ETRAction *)message fitsWidth:(CGFloat)width;

@end
