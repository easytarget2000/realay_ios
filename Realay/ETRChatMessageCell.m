//
//  ETRChatMessageCell.m
//  Realay
//
//  Created by Michel S on 03.04.14.
//  Copyright (c) 2014 Easy Target. All rights reserved.
//

#import "ETRChatMessageCell.h"

#import "ETRSession.h"

#import "SharedMacros.h"
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
        UIFont *nameFont = [[ETRSession sharedSession] msgSenderFont];
        [_nameLabel setFont:nameFont];
        [[self contentView] addSubview:_nameLabel];
        
        // Create a text label.
        _textLabel = [[UILabel alloc] init];
        [_textLabel setClearsContextBeforeDrawing:NO];
        [_textLabel setBackgroundColor:[UIColor clearColor]];
        [_textLabel setNumberOfLines:0];
        [_textLabel setLineBreakMode:NSLineBreakByWordWrapping];
        UIFont *textFont = [[ETRSession sharedSession] msgTextFont];
        [_textLabel setFont:textFont];
        [[self contentView] addSubview:_textLabel];
    }
    
    return self;
}

- (void)applyMessage:(ETRChatMessage *)message
           fitsWidth:(CGFloat)width
            sentByMe:(BOOL)sentByMe
         showsSender:(BOOL)showsSender {
    
    if (![message messageString]) return;
    
    // Calculate the size of the combined labels.
    CGSize innerSize = [message frameSizeForWidth:width hasNameLabel:showsSender];
    
    // Add the margins to the labels to get the size of the bubble frame.
    CGSize bubbleSize = CGSizeMake(kMarginInner + innerSize.width + kMarginInner,
                                   kMarginInner + innerSize.height + kMarginInnerBottom);
    
    // The image and the x-coordinate of the bubble differ depending on the type of cell.
    CGFloat bubbleX;
    UIImage *bubbleImage;
    
    // Messages sent by the local user are displayed right-bound cells.
    if (sentByMe) {
        
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
    if (showsSender) {
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
    if (showsSender) {
        [_nameLabel setText:[[message sender] name]];
    }
    [_textLabel setText:[message messageString]];
}

@end
