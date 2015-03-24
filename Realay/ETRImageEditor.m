//
//  ETRImageEditor.m
//  Realay
//
//  Created by Michel on 03/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRImageEditor.h"

static CGSize const ETRHiResImageSize = {
    .width = 1080.0f,
    .height = 1080.0f
};

static CGSize const ETRLoResImageSize = {
    .width = 128.0f,
    .height = 128.0f
};

static CGFloat const ETRHiResImageQuality = 0.9f;

static CGFloat const ETRLoResImageQuality = 0.6f;


@implementation ETRImageEditor

+ (void)cropImage:(UIImage *)image applyToView:(UIImageView *)targetImageView withTag:(NSInteger)tag {
    if (!image || !targetImageView) return;
    
    NSInteger targetImageViewTag = [targetImageView tag];
    if (tag < 100 || targetImageViewTag == tag || targetImageViewTag < 100) {
        if (tag > 100 && targetImageViewTag < 100) {
           [targetImageView setTag:tag];
        }
        // TODO: Check that image currently in this View is smaller before replacing it.
        
        // Adjust the size if needed.
        UIImage * croppedImage = [ETRImageEditor cropImage:image toSize:targetImageView.frame.size];
        [targetImageView setImage:croppedImage];
        
    } else {
        NSLog(@"DEBUG: Not applying image because tags are unequal: %ld != %ld", [targetImageView tag], tag);
    }
}

+ (UIImage *)imageFromPickerInfo:(NSDictionary *)info {
    if (!info) {
        NSLog(@"ERROR: Received nil Picker Info.");
        return nil;
    }
    
    UIImage *pickedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!pickedImage) {
        NSLog(@"WARNING: No Edit Image Object found in Picker Info. Using original image.");
        pickedImage = [info objectForKeyedSubscript:UIImagePickerControllerOriginalImage];
        if (!pickedImage) {
            NSLog(@"ERROR: No image found in Picker Info.");
        }
    }
    
    return pickedImage;
}

+ (NSData *)cropHiResImage:(UIImage *)image writeToFile:(NSString *)filePath {
    UIImage * hiResImage = [ETRImageEditor cropImage:image toSize:ETRHiResImageSize];
    NSData * hiResData = UIImageJPEGRepresentation(hiResImage, ETRHiResImageQuality);
    [hiResData writeToFile:filePath atomically:YES];
    return hiResData;
}

+ (NSData *)cropLoResImage:(UIImage *)image writeToFile:(NSString *)filePath {
    UIImage * loResImage = [ETRImageEditor cropImage:image toSize:ETRLoResImageSize];
    NSData * loResData = UIImageJPEGRepresentation(loResImage, ETRLoResImageQuality);
    [loResData writeToFile:filePath atomically:YES];
    return loResData;
}

+ (UIImage *)cropImage:(UIImage *)image toSize:(CGSize)size {
    if (!image) {
        NSLog(@"ERROR: Nil image given to be cropped.");
        return nil;
    }
    
    if (image.size.width != size.width || image.size.height != size.height) {
        UIGraphicsBeginImageContext(size);
        CGRect imageRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
        [image drawInRect:imageRect];
        UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return croppedImage;
    } else {
        // The image already has the requested dimensions.
        return image;
    }
}

@end
