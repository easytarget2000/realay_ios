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


static CGFloat const ETRSideLengthImageMax = 1440.0f;

static CGFloat const ETRSideLengthImagePreview = 128.0f;

static CGFloat const ETRSideLengthImageProfile = 1080.0f;

static CGFloat const ETRHiResImageQuality = 0.9f;

static CGFloat const ETRLoResImageQuality = 0.6f;


@implementation ETRImageEditor

#pragma mark -
#pragma mark ETRImageView

+ (void)cropImage:(UIImage *)image
        imageName:(NSString *)imageName
      applyToView:(ETRImageView *)targetImageView {
    
    // Adjust the size if needed.
    UIImage * croppedImage;
    croppedImage = [ETRImageEditor scaleCropImage:image toSize:targetImageView.frame.size];
    
    dispatch_async(
                   dispatch_get_main_queue(),
                   ^{
                       if (!image || !targetImageView) {
                           return;
                       }
                       
                       if ([targetImageView hasImage:imageName]) {
                           return;
                       }

//                       [targetImageView setImage:croppedImage];
//                       [targetImageView setImageName:imageName];

                       [UIView transitionWithView:targetImageView
                                         duration:0.2
                                          options:UIViewAnimationOptionTransitionCrossDissolve
                                       animations:^{
                                           [targetImageView setImage:croppedImage];
                                       }
                                       completion:^(BOOL finished) {
                                           if (finished) {
                                               [targetImageView setImageName:imageName];
                                           }
                                       }];

                       
                       //    [targetImageView setImage:image];
                   });
}

+ (UIImage *)scaleCropImage:(UIImage *)image
                     toSize:(CGSize)targetSize {
    
    if (targetSize.width < 0.1f || targetSize.height < 0.1f) {
        return image;
    }
    
    CGSize imageSize = [image size];
    if (imageSize.width == targetSize.width && imageSize.height == targetSize.width) {
        return image;
    }
    
//    UIImageOrientation orientation;
//    if ([image imageOrientation] == UIImageOrientationDownMirrored) {
//        orientation = UIImageOrientationUp;
//    } else {
//        orientation = UIImageOrientationDownMirrored;
//    }
    
    CGFloat shortestImageSide;
    if (imageSize.width > imageSize.height) {
        shortestImageSide = imageSize.height;
    } else {
        shortestImageSide = imageSize.width;
    }
    
    CGFloat longerSideLength;
    if (targetSize.width > targetSize.height) {
        longerSideLength = targetSize.width;
    } else {
        longerSideLength = targetSize.height;
    }
    CGFloat resizeFactor = longerSideLength / shortestImageSide;
    
    CGSize scaleSize = imageSize;
    scaleSize.width *= resizeFactor;
    scaleSize.height *= resizeFactor;
    
    CGFloat cropX = 0.0f;
    CGFloat cropY = 0.0f;
    if (targetSize.width > targetSize.height) {
        cropY = (scaleSize.height * 0.5f) - (targetSize.height * 0.5f);
    } else {
        cropX = (scaleSize.width * 0.5f) - (targetSize.width * 0.5f);
    }
    
    CGRect cropRect = CGRectMake(cropX, cropY, targetSize.width, targetSize.height);
    
    UIImage * scaledImage = [ETRImageEditor scaleImage:image toMaxSideLength:longerSideLength];
    //    UIImage * scaledImage = [UIImage imageWithCGImage:[image CGImage]
    //                                                scale:1.0f/resizeFactor
    //                                          orientation:[image imageOrientation]];
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([scaledImage CGImage], cropRect);
    
    UIImage * outputImage = [UIImage imageWithCGImage:imageRef
                                                scale:[image scale]
                                          orientation:[image imageOrientation]];
    CGImageRelease(imageRef);
    
    //    NSLog(@"Image orientation 3: %d", [outputImage imageOrientation]);
    
    return outputImage;
}

#pragma mark -
#pragma mark Image Picker

+ (UIImage *)imageFromPickerInfo:(NSDictionary *)info {
    if (!info) {
        NSLog(@"ERROR: Received nil Picker Info.");
        return nil;
    }
    
    UIImage * pickedImage = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!pickedImage) {
        NSLog(@"WARNING: No Edit Image Object found in Picker Info. Using original image.");
        pickedImage = [info objectForKeyedSubscript:UIImagePickerControllerOriginalImage];
        if (!pickedImage) {
            NSLog(@"ERROR: No image found in Picker Info.");
            return nil;
        }
    }
    
    return pickedImage;
}

#pragma mark -
#pragma mark Scaling

+ (NSData *)scalePreviewImage:(UIImage *)image writeToFile:(NSString *)filePath {
    UIImage * loResImage = [ETRImageEditor scaleImage:image toMaxSideLength:ETRSideLengthImagePreview];
    NSData * loResData = UIImageJPEGRepresentation(loResImage, ETRLoResImageQuality);
    [loResData writeToFile:filePath atomically:YES];
    return loResData;
}

+ (NSData *)scaleProfileImage:(UIImage *)image writeToFile:(NSString *)filePath {
    UIImage * hiResImage = [ETRImageEditor scaleImage:image toMaxSideLength:ETRSideLengthImageProfile];
    NSData * hiResData = UIImageJPEGRepresentation(hiResImage, ETRHiResImageQuality);
    [hiResData writeToFile:filePath atomically:YES];
    return hiResData;
}

+ (UIImage *)scaleImage:(UIImage *)image toMaxSideLength:(CGFloat)maxSideLength {
    if (maxSideLength < 4.0f ) {
        maxSideLength = 4.0f;
    }
    
    CGSize size;
    if (image.size.width > image.size.height) {
        size.width = maxSideLength;
        size.height = image.size.height / image.size.width * maxSideLength;
    } else {
        size.height = maxSideLength;
        size.width = image.size.width / image.size.height * maxSideLength;
    }
    
    UIGraphicsBeginImageContext(size);
    
    //    CGContextRef scaleContext = UIGraphicsGetCurrentContext();
    //    CGContextDrawImage(scaleContext, CGRectMake(0.0f, 0.0f, size.width, size.height), [image CGImage]);
    [image drawInRect:CGRectMake(0.0f, 0.0f, size.width, size.height)];
    UIImage * scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return [UIImage imageWithCGImage:[scaledImage CGImage]
                               scale:[scaledImage scale]
                         orientation:UIImageOrientationDownMirrored];
    
    //    return scaledImage;
}

+ (NSData *)scaleLimitMessageImage:(UIImage *)image writeToFile:(NSString *)filePath {
    UIImage * hiResImage;
    if (image.size.width > ETRSideLengthImageMax || image.size.height > ETRSideLengthImageMax) {
        hiResImage = [ETRImageEditor scaleImage:image toMaxSideLength:ETRSideLengthImageMax];
    } else {
        hiResImage = image;
    }
    
    NSData * hiResData = UIImageJPEGRepresentation(hiResImage, ETRHiResImageQuality);
    [hiResData writeToFile:filePath atomically:YES];
    return hiResData;
}

@end
