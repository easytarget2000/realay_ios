//
//  ETRImageEditor.h
//  Realay
//
//  Created by Michel on 03/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETRImageEditor : NSObject

+ (void)cropImage:(UIImage *)image applyToView:(UIImageView *)targetImageView withTag:(NSInteger)tag;

+ (void)cropImage:(UIImage *)image applyToView:(UIImageView *)targetImageView;

@end
