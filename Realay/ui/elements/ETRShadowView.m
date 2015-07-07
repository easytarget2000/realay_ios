//
//  ETRHeaderImageView.m
//  Realay
//
//  Created by Michel on 19/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRShadowView.h"

static UIColor * ShadowStartColor;

static UIColor * ShadowEndColor;


@interface ETRShadowView ()

@property (nonatomic) CGFloat didDrawForWidth;

@end


@implementation ETRShadowView

- (void)drawRect:(CGRect)rect {
    if (self.frame.size.width == _didDrawForWidth) {
        // Do not draw the gradient over and over.
        return;
    }
    
    CAGradientLayer * gradient = [CAGradientLayer layer];
    [gradient setFrame:[self bounds]];
    
    if (!ShadowStartColor) {
        ShadowStartColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    }
    
    if (!ShadowEndColor) {
        ShadowEndColor = [UIColor colorWithWhite:0.0f alpha:0.0f];
    }
    
    
    UIColor * bottomColor;
    UIColor * topColor;
    if (_doDrawShadowDown) {
        bottomColor = ShadowEndColor;
        topColor = ShadowStartColor;
    } else {
        bottomColor = ShadowStartColor;
        topColor = ShadowEndColor;
    }
    NSArray * colors = [NSArray arrayWithObjects:(id)[topColor CGColor], (id)[bottomColor CGColor], nil];
    [gradient setColors:colors];
    
    [[self layer] insertSublayer:gradient atIndex:0];
    
    _didDrawForWidth = self.frame.size.width;
}

@end
