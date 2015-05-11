//
//  ETRUIConstants.h
//  Realay
//
//  Created by Michel on 19/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETRUIConstants : NSObject

extern CGFloat const ETRIconViewCornerRadius;

extern NSString *const ETRViewControllerIDConversation;

extern NSString *const ETRViewControllerIDDetails;

extern NSString *const ETRViewControllerIDJoin;

extern NSString *const ETRImageNameImagePlaceholder;

extern NSString *const ETRImageNameProfilePlaceholder;

extern NSString *const ETRImageNameRoomPlaceholder;

extern NSString *const ETRImageNameUserIcon;

+ (UIColor *)primaryColor;

+ (UIColor *)primaryTransparentColor;

+ (UIColor *)darkPrimaryColor;

+ (UIColor *)accentColor;

@end
