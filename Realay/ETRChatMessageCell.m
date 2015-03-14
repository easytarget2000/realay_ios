//
//  ETRChatMessageCell.m
//  Realay
//
//  Created by Michel S on 03.04.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRChatMessageCell.h"

#import "ETRSession.h"

#import "ETRSharedMacros.h"
//#define DEBUG_LABEL_BOUNDS 1
#define kHeightSenderLabel 18

@implementation ETRChatMessageCell {
    UIImageView *_bubbleView;
    UILabel *_nameLabel;
    UILabel *_textLabel;
}

- (id)initWithStyle:(UITableViewCellStyle)style
    reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        // Create a background image view.
        _bubbleView = [[UIImageView alloc] init];
        [_bubbleView setClearsContextBeforeDrawing:NO];
        [_bubbleView setBackgroundColor:[UIColor whiteColor]];
        [[self contentView] addSubview:_bubbleView];
        
        // Create a name label.
        _nameLabel = [[UILabel alloc] init];
        [_nameLabel setClearsContextBeforeDrawing:NO];
        [_nameLabel setBackgroundColor:[UIColor clearColor]];
        [_nameLabel setNumberOfLines:1];
        [_nameLabel setLineBreakMode:NSLineBreakByTruncatingMiddle];
        UIFont *nameFont = [[ETRSession sharedManager] msgSenderFont];
        [_nameLabel setFont:nameFont];
        [[self contentView] addSubview:_nameLabel];
        
        // Create a text label.
        _textLabel = [[UILabel alloc] init];
        [_textLabel setClearsContextBeforeDrawing:NO];
        [_textLabel setBackgroundColor:[UIColor clearColor]];
        [_textLabel setNumberOfLines:0];
        [_textLabel setLineBreakMode:NSLineBreakByWordWrapping];
        UIFont *textFont = [[ETRSession sharedManager] msgTextFont];
        [_textLabel setFont:textFont];
        [[self contentView] addSubview:_textLabel];
    }
    
    return self;
}

- (void)applyMessage:(ETRAction *)message fitsWidth:(CGFloat)width {
    
    if (![message messageContent]) return;
    
    // Calculate the size of the combined labels.
    BOOL isMyMessage = [message isSentMessage];
    BOOL doShowSender = !isMyMessage && [message isPublicMessage];
    CGSize innerSize;
//    innerSize = [message frameSizeForWidth:width hasNameLabel:doShowSender];
    
    // Add the margins to the labels to get the size of the bubble frame.
    CGSize bubbleSize = CGSizeMake(kMarginInner + innerSize.width + kMarginInner,
                                   kMarginInner + innerSize.height + kMarginInnerBottom);
    
    // The image and the x-coordinate of the bubble differ depending on the type of cell.
    CGFloat bubbleX;
    UIImage *bubbleImage;
    
    // Messages sent by the local user are displayed right-bound cells.
    if (isMyMessage) {
        
        // Load the bubble.
        bubbleImage = [UIImage imageNamed:@"RightBubble.png"];
        
        // Calculate the upper left x-coordinate.
        bubbleX = width - bubbleSize.width - kMarginOuter;
        
        // Configure all elements as left-flexible (right-bound) with black font.
        [_bubbleView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
#ifdef DEBUG_LABEL_BOUNDS
        [_bubbleView setBackgroundColor:[UIColor grayColor]];
#endif
        
        [_nameLabel setTextColor:[UIColor blackColor]];
        [_nameLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        
        [_textLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        [_textLabel setTextColor:[UIColor blackColor]];
        
    } else {
        // Load the bubble.
        bubbleImage = [UIImage imageNamed:@"LeftBubble.png"];
        
        // Calculate the upper left x-coordinate.
        bubbleX = kMarginOuter;
        
        // Left bubble frame:
        
        // Configure all elements as right-flexible (right-bound) with black font.
        [_bubbleView setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
#ifdef DEBUG_LABEL_BOUNDS
        [_bubbleView setBackgroundColor:[UIColor redColor]];
#endif
        
        [_nameLabel setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
        [_nameLabel setTextColor:[UIColor whiteColor]];
        
        [_textLabel setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
        [_textLabel setTextColor:[UIColor whiteColor]];

    }
    
    // Calculate the size of the bubble image and apply it.
    CGRect frame;
    frame = CGRectMake(bubbleX,
                       kMarginOuter,
                       bubbleSize.width,
                       bubbleSize.height);
    [_bubbleView setFrame:frame];
    bubbleImage = [bubbleImage stretchableImageWithLeftCapWidth:12 topCapHeight:12];
    [_bubbleView setImage:bubbleImage];
    
    // Apply a frame to the sender label or hide it.
    CGFloat senderLabelHeight = 0;
    if (doShowSender) {
        senderLabelHeight = kHeightSenderLabel;
        [_nameLabel setHidden:NO];
    } else {
        [_nameLabel setHidden:YES];
    }
    frame = CGRectMake(bubbleX + kMarginInner,
                       kMarginOuter + kMarginInner,
                       innerSize.width,
                       senderLabelHeight);
    [_nameLabel setFrame:frame];
#ifdef DEBUG_LABEL_BOUNDS
    [_nameLabel setBackgroundColor:[UIColor yellowColor]];
#endif
    
    // Give the remaining space to the text label.
    frame = CGRectMake(bubbleX + kMarginInner,
                       kMarginOuter + kMarginInner + senderLabelHeight,
                       innerSize.width,
                       innerSize.height - senderLabelHeight);
    [_textLabel setFrame:frame];
#ifdef DEBUG_LABEL_BOUNDS
    [_textLabel setBackgroundColor:[UIColor greenColor]];
#endif

    // Apply the values to the views.
    if (doShowSender) {
        // Get user name from UserCache.
    }
    [_textLabel setText:[message messageContent]];
}

- (CGSize)frameSizeForWidth:(CGFloat)width hasNameLabel:(BOOL)hasNameLabel {
    
    // Calculate the frame of the name label, if wanted.
    CGSize nameSize = CGSizeMake(0, 0);
    if (hasNameLabel) {
        NSString *senderName;
        // TODO: Get User data from Cache.
        if (senderName) {
            UIFont *nameFont = [[ETRSession sharedManager] msgSenderFont];
            nameSize = [senderName sizeWithAttributes:@{NSFontAttributeName:nameFont}];
        }
    }
    
    // Calculate the frame of the message label.
//    CGSize maxMsgSize = CGSizeMake(width - 76, MAXFLOAT);
//    UIFont *textFont = [[ETRSession sharedManager] msgTextFont];
    CGRect messageRect;
//    messageRect = [self boundingRectWithSize:maxMsgSize
//                                               options:NSStringDrawingUsesLineFragmentOrigin
//                                            attributes:@{NSFontAttributeName:textFont}
//                                               context:nil];
    
    CGSize frameSize;
    if (nameSize.width > messageRect.size.width) frameSize.width = nameSize.width + 4;
    else frameSize.width = messageRect.size.width + 4;
    
    //    if (name)
    //    else frameSize.height = messageRect.size.height;
    frameSize.height = nameSize.height + messageRect.size.height;
    
    //    if (frameSize.width < 64) frameSize.width = 64;
    
    return frameSize;
}

- (CGFloat)rowHeightForWidth:(CGFloat)width hasNameLabel:(BOOL)hasNameLabel {
    CGSize frameSize = [self frameSizeForWidth:width hasNameLabel:hasNameLabel];
    return kMarginOuter + kMarginInner + frameSize.height + kMarginInner + 20;
}


@end
