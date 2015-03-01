//
//  ETRIconDownloader.m
//  Realay
//
//  Created by Michel S on 11.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRImageLoader.h"

#import "ETRServerAPIHelper.h"

@implementation ETRImageLoader {
    BOOL _doShowHiRes;
}

- initWithObject:(ETRChatObject *)chatObject targetImageView:(UIImageView *)targetImageView doLoadHiRes:(BOOL)doLoadHiRes{
    self = [super init];
    _chatObject = chatObject;
    _targetImageView = targetImageView;
    _doShowHiRes = doLoadHiRes;
    return self;
}

+ (void)loadImageForObject:(ETRChatObject *)chatObject doLoadHiRes:(BOOL)doLoadHiRes {
    ETRImageLoader *instance = [[ETRImageLoader alloc] initWithObject:chatObject targetImageView:nil doLoadHiRes:doLoadHiRes];
    [NSThread detachNewThreadSelector:@selector(startLoading)
                             toTarget:instance
                           withObject:nil];
}

+ (void)loadImageForObject:(ETRChatObject *)chatObject intoView:(UIImageView *)targetImageView doLoadHiRes:(BOOL)doShowHiRes {
    ETRImageLoader *instance = [[ETRImageLoader alloc] initWithObject:chatObject targetImageView:targetImageView doLoadHiRes:(BOOL)doShowHiRes];
//    [instance startLoading];
    [NSThread detachNewThreadSelector:@selector(startLoading)
                             toTarget:instance
                           withObject:nil];
}

- (void)startLoading {
    if (!_chatObject) return;
    if ([[_chatObject imageID] longValue] < 100) return;
    
    if ([_chatObject lowResImage]) {
        [ETRImageLoader cropImage:[_chatObject lowResImage] applyToView:_targetImageView];
        if (!_doShowHiRes) return;
    }
    
    // First, look for the low-res image in the file cache.
    UIImage *cachedLoResImage = [UIImage imageWithContentsOfFile:[self imagefilePath:NO]];
    if (cachedLoResImage) {
        [_chatObject setLowResImage:cachedLoResImage];
        [ETRImageLoader cropImage:cachedLoResImage applyToView:_targetImageView];
    } else {
        // If the low-res image has not been stored as a file, download it.
        // This will also place it into the Object and View.
        [ETRServerAPIHelper getImageLoader:self doLoadHiRes:NO];
    }
    
    // If the high-resolution image is not supposed to be shown, return.
    if (!_doShowHiRes) return;
    
    UIImage *cachedHiResImage = [UIImage imageWithContentsOfFile:[self imagefilePath:YES]];
    if (cachedHiResImage) {
        [ETRImageLoader cropImage:cachedHiResImage applyToView:_targetImageView];
    } else {
        [ETRServerAPIHelper getImageLoader:self doLoadHiRes:YES];
    }
}

- (NSString *)imagefilePath:(BOOL)doLoadHiRes {
    if (!_chatObject) return nil;
    
    // Save image.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [_chatObject imageIDWithHiResFlag:doLoadHiRes]];
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
}

+ (void)cropImage:(UIImage *)image applyToView:(UIImageView *)targetImageView {
    if (!image || !targetImageView) return;
    
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
