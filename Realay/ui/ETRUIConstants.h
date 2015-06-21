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

extern NSString *const ETRCellIdentifierUser;

extern NSString *const ETRViewControllerIDBlockedUsers;

extern NSString *const ETRViewControllerIDConversation;

extern NSString *const ETRViewControllerIDDetails;

extern NSString *const ETRViewControllerIDJoin;

extern NSString *const ETRViewControllerIDMap;

extern NSString *const ETRImageNameArrowRight;

extern NSString *const ETRImageNameAttachFile;

extern NSString *const ETRImageNameImagePlaceholder;

extern NSString *const ETRImageNameProfilePlaceholder;

extern NSString *const ETRImageNameRoomPlaceholder;

extern NSString *const ETRImageNameUserIcon;

extern CGFloat const ETRFontSizeSmall;

extern CGFloat const ETRRowHeightUser;


+ (UIColor *)primaryColor;

+ (UIColor *)primaryTransparentColor;

+ (UIColor *)darkPrimaryColor;

+ (UIColor *)accentColor;

+ (UIColor *)secondaryBackgroundColor;

@end
