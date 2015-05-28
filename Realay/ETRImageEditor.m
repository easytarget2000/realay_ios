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
#import "ETRImageView.h"

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

+ (void)cropImage:(UIImage *)image
        imageName:(NSString *)imageName
      applyToView:(ETRImageView *)targetImageView {
    
    dispatch_async(
                   dispatch_get_main_queue(),
                   ^{
                       if (!image || !targetImageView) {
                           return;
                       }
                       
                       if ([targetImageView hasImage:imageName]) {
                           return;
                       }
                       
                       // Adjust the size if needed.
                       UIImage * croppedImage;
                       croppedImage = [ETRImageEditor scaleCropImage:image
                                                              toSize:targetImageView.frame.size];
                       [targetImageView setImage:croppedImage];
                       
                       [targetImageView setImageName:imageName];
                       //    [targetImageView setImage:image];
                   });
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
    UIImage * hiResImage = [ETRImageEditor scaleCropImage:image toSize:ETRHiResImageSize];
    NSData * hiResData = UIImageJPEGRepresentation(hiResImage, ETRHiResImageQuality);
    [hiResData writeToFile:filePath atomically:YES];
    return hiResData;
}

+ (NSData *)cropLoResImage:(UIImage *)image writeToFile:(NSString *)filePath {
    UIImage * loResImage = [ETRImageEditor scaleCropImage:image toSize:ETRLoResImageSize];
    NSData * loResData = UIImageJPEGRepresentation(loResImage, ETRLoResImageQuality);
    [loResData writeToFile:filePath atomically:YES];
    return loResData;
}

+ (UIImage *)scaleCropImage:(UIImage *)image toSize:(CGSize)targetSize {
    
    CGSize imageSize = [image size];
    if (imageSize.width == targetSize.width && imageSize.height == targetSize.width) {
        return image;
    }
    
    UIImage * fixedimage = [UIImage imageWithCGImage:[image CGImage]
                                                scale:1.0f
                                          orientation:UIImageOrientationUp];
    
    CGFloat shortestImageSide;
    if (imageSize.width > imageSize.height) {
        shortestImageSide = imageSize.height;
    } else {
        shortestImageSide = imageSize.width;
    }
    
    CGFloat resizeFactor;
    if (targetSize.width > targetSize.height) {
        resizeFactor = targetSize.width / shortestImageSide;
    } else {
        resizeFactor = targetSize.height / shortestImageSide;
    }
    
    CGSize scaleSize = imageSize;
    scaleSize.width *= resizeFactor;
    scaleSize.height *= resizeFactor;
    
//    NSLog(@"Scaling Image %g x %g to %g x %g to fit %g x %g.", imageSize.width, imageSize.height, scaleSize.width, scaleSize.height, targetSize.width, targetSize.width);
    
    UIGraphicsBeginImageContext(scaleSize);
    
    CGContextRef scaleContext = UIGraphicsGetCurrentContext();
    CGContextDrawImage(scaleContext, CGRectMake(0.0f, 0.0f, scaleSize.width, scaleSize.height), [fixedimage CGImage]);
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    CGFloat cropX = 0.0f;
    CGFloat cropY = 0.0f;
    if (targetSize.width > targetSize.height) {
        cropY = (scaleSize.height * 0.5f) - (targetSize.height * 0.5f);
    } else {
        cropX = (scaleSize.width * 0.5f) - (targetSize.width * 0.5f);
    }
    
    CGRect cropRect = CGRectMake(cropX, cropY, targetSize.width, targetSize.height);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([scaledImage CGImage], cropRect);
    UIImage * outputImage = [UIImage imageWithCGImage:imageRef
                                          scale:[scaledImage scale]
                                    orientation:UIImageOrientationDownMirrored];
    CGImageRelease(imageRef);
    
    return outputImage;
}


@end
