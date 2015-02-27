//
//  ETRCircleView.m
//  Realay
//
//  Created by Michel on 26/02/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRCircleView.h"

// #FF9800
#define kAccentColor colorWithRed:(0xFF/255.0f) green:(0x98/255.0f) blue:(0x00/255.0f) alpha:1.0f

@implementation ETRCircleView

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextAddEllipseInRect(context, rect);
    CGContextSetFillColor(context, CGColorGetComponents([[UIColor kAccentColor] CGColor]));
    CGContextFillPath(context);
}

@end
