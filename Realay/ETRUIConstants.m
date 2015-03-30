//
//  ETRUIConstants.m
//  Realay
//
//  Created by Michel on 19/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRUIConstants.h"

static UIColor * PrimaryColor;

static UIColor * PrimaryTransparentColor;

static UIColor * DarkPrimaryColor;

static UIColor * AccentColor;

@implementation ETRUIConstants

/*
 Corner radius that is used for Icon ImageViews to give them a circle shape;
 Has to be half the side length of the View
 */
CGFloat const ETRIconViewCornerRadius = 20.0f;

+ (UIColor *)primaryColor {
    if (!PrimaryColor) {
        PrimaryColor = [UIColor colorWithRed:(0x7A/255.0f)
                                       green:(0xBA/255.0f)
                                        blue:(0x3A/255.0f)
                                       alpha:1.0f];
    }
    return PrimaryColor;
}

+ (UIColor *)primaryTransparentColor {
    if (!PrimaryTransparentColor) {
        PrimaryTransparentColor = [UIColor colorWithRed:(0x7A/255.0f)
                                                   green:(0xBA/255.0f)
                                                    blue:(0x3A/255.0f)
                                                   alpha:0.4f];
    }
    return PrimaryTransparentColor;
}

+ (UIColor *)darkPrimaryColor {
    return [UIColor redColor];
}

+ (UIColor *)accentColor {
    if (!AccentColor) {
        AccentColor = [UIColor colorWithRed:(0xFF/255.0f)
                                      green:(0x98/255.0f)
                                       blue:(0x00/255.0f)
                                      alpha:1.0f];
    }
    return AccentColor;
}

@end