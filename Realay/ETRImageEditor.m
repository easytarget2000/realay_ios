//
//  ETRImageEditor.m
//  Realay
//
//  Created by Michel on 03/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRImageEditor.h"

#import "ETRChatObject.h"
#import "ETRImageLoader.h"

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
    
    if (!image || !targetImageView) {
        return;
    }
    
    // Adjust the size if needed.
    UIImage * croppedImage = [ETRImageEditor cropImage:image toSize:targetImageView.frame.size];
    if (targetImageView && [targetImageView tag] == tag) {
        // Verifying reference for quick scrolling of Image Views inside of reusable cells.
        [targetImageView setImage:croppedImage];
    } else {
        NSLog(@"DEBUG: Image View reference changed midway.");
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
    
//    if (image.size.width != size.width || image.size.height != size.width) {
//        UIGraphicsBeginImageContext(size);
//        CGRect imageRect = CGRectMake(0.0f, 0.0f, size.width, size.width);
//        [image drawInRect:imageRect];
//        UIImage * croppedImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//        return croppedImage;
//    } else {
//        // The image already has the requested dimensions.
//        return image;
//    }
    
    //If scale factor is not touched, no scaling will occur.
    CGFloat scaleFactor = 1.0f;
    
    //Decide which factor to use to scale the image (factor = targetSize / imageSize)
    if (image.size.width > size.width || image.size.height > size.height) {
        if (!((scaleFactor = (size.width / image.size.width)) > (size.height / image.size.height))) {
            scaleFactor = size.height / image.size.height;
        }
    }

    
    UIGraphicsBeginImageContext(size);
    
    // Create the Rect in which the image will be drawn.
    CGFloat x = (size.width - image.size.width * scaleFactor) * 0.5f;
    CGFloat y = (size.height -  image.size.height * scaleFactor) * 0.5f;
    CGFloat width = image.size.width * scaleFactor;
    CGFloat height = image.size.height * scaleFactor;
    CGRect rect = CGRectMake(x, y, width, height);
    
    //Draw the image into the Rect.
    [image drawInRect:rect];
    
    //Save the image, ending the image context.
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

@end
