//
//  ETRImageEditor.h
//  Realay
//
//  Created by Michel on 03/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ETRChatObject;
@class ETRImageView;

@interface ETRImageEditor : NSObject

+ (void)cropImage:(UIImage *)image
      applyToView:(ETRImageView *)targetImageView
          isHiRes:(BOOL)isHiRes;

+ (UIImage *)imageFromPickerInfo:(NSDictionary *)info;

+ (NSData *)cropHiResImage:(UIImage *)image writeToFile:(NSString *)filePath;

+ (NSData *)cropLoResImage:(UIImage *)image writeToFile:(NSString *)filePath;

@end
