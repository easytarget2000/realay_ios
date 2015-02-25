//
//  ETRChatMessageCell.h
//  Realay
//
//  Created by Michel S on 03.04.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ETRChatMessage.h"

@interface ETRChatMessageCell : UITableViewCell

- (void)applyMessage:(ETRChatMessage *)message
           fitsWidth:(CGFloat)width
            sentByMe:(BOOL)sentByMe
         showsSender:(BOOL)showsSender;

@end
