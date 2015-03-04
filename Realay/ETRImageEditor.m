//
//  ETRImageEditor.m
//  Realay
//
//  Created by Michel on 03/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRImageEditor.h"

@implementation ETRImageEditor


+ (void)cropImage:(UIImage *)image applyToView:(UIImageView *)targetImageView withTag:(NSInteger)tag {
    if ([targetImageView tag] == tag) {
        [ETRImageEditor cropImage:image applyToView:targetImageView];
    } else {
        NSLog(@"DEBUG: Not applying image because tags are unequal: %ld != %ld", [targetImageView tag], tag);
    }
}

+ (void)cropImage:(UIImage *)image applyToView:(UIImageView *)targetImageView {
    if (!image || !targetImageView) return;
    // TODO: Check that image currently in this View is smaller before replacing it.
    
    // Adjust the size if needed.
    CGSize viewSize = targetImageView.frame.size;
    if (image.size.width != viewSize.width || image.size.height != viewSize.height) {
        UIGraphicsBeginImageContext(viewSize);
        CGRect imageRect = CGRectMake(0.0f, 0.0f, viewSize.width, viewSize.height);
        [image drawInRect:imageRect];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    [targetImageView setImage:image];
}

@end
