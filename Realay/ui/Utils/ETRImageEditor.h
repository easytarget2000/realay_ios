//
//  ETRImageEditor.h
//  Realay
//
//  Created by Michel on 03/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ETRChatObject;
@class ETRImageView;


@interface ETRImageEditor : NSObject

#pragma mark -
#pragma mark ETRImageView & Cropping

+ (void)cropImage:(UIImage *)image
        imageName:(NSString *)imageName
      applyToView:(ETRImageView *)targetImageView;

#pragma mark -
#pragma mark Image Picker

+ (UIImage *)imageFromPickerInfo:(NSDictionary *)info;

#pragma mark -
#pragma mark Scaling

+ (NSData *)scalePreviewImage:(UIImage *)image writeToFile:(NSString *)filePath;

+ (NSData *)scaleProfileImage:(UIImage *)image writeToFile:(NSString *)filePath;

+ (NSData *)scaleLimitMessageImage:(UIImage *)image writeToFile:(NSString *)filePath;

@end
