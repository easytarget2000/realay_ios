//
//  ETRCircleView.m
//  Realay
//
//  Created by Michel on 26/02/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRCircleView.h"

#import "ETRColorMacros.h"

@implementation ETRCircleView

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, rect);
    CGContextAddEllipseInRect(context, rect);
    CGContextSetFillColor(context, CGColorGetComponents([[UIColor kAccentColor] CGColor]));
    CGContextFillPath(context);
}

@end
