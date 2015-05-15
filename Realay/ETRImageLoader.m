//
//  ETRIconDownloader.m
//  Realay
//
//  Created by Michel S on 11.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRImageLoader.h"

#import "ETRChatObject.h"
#import "ETRImageEditor.h"
#import "ETRImageView.h"
#import "ETRServerAPIHelper.h"

NSString *const ETRKeyIntendedObject = @"intended_object";

NSString *const ETRKeyDidLoadHiRes = @"hi_res";

@implementation ETRImageLoader {
    BOOL _doShowHiRes;
}

- initWithObject:(ETRChatObject *)chatObject
 targetImageView:(ETRImageView *)targetImageView
placeHolderImage:(UIImage *)placeHolderImage
     doLoadHiRes:(BOOL)doLoadHiRes {
    
    self = [super init];
    _chatObject = chatObject;
    _doShowHiRes = doLoadHiRes;
    
    if (targetImageView) {
        _targetImageView = targetImageView;
        if (placeHolderImage) {
            [_targetImageView setImage:placeHolderImage];
        }
    }
    
    return self;
}

+ (void)loadImageForObject:(ETRChatObject *)chatObject doLoadHiRes:(BOOL)doLoadHiRes {
    ETRImageLoader * instance = [[ETRImageLoader alloc] initWithObject:chatObject
                                                      targetImageView:nil
                                                     placeHolderImage:nil
                                                          doLoadHiRes:doLoadHiRes];
    [NSThread detachNewThreadSelector:@selector(startLoadingImage:)
                             toTarget:instance
                           withObject:nil];
}

+ (void)loadImageForObject:(ETRChatObject *)chatObject
                  intoView:(ETRImageView *)targetImageView
          placeHolderImage:(UIImage *)placeHolderImage
               doLoadHiRes:(BOOL)doShowHiRes {
    
    NSString * imageName = [chatObject imageFileName:doShowHiRes];
    if ([targetImageView hasImage:imageName]) {
        return;
    }
    
    ETRImageLoader * instance = [[ETRImageLoader alloc] initWithObject:chatObject
                                                      targetImageView:targetImageView
                                                      placeHolderImage:placeHolderImage
                                                          doLoadHiRes:(BOOL)doShowHiRes];
    [NSThread detachNewThreadSelector:@selector(startLoadingImage:)
                             toTarget:instance
                           withObject:nil];
}

- (void)startLoadingImage:(id)sender {
    if (!_chatObject) {
      return;
    }
    
    long imageID = [[_chatObject imageID] longValue];
    if (imageID < 100 && imageID > -100) {
//        NSLog(@"ERROR: Not loading image with ID %@.", [_chatObject imageID]);
        return;
    }
    
    NSString * loResImageName = [_chatObject imageFileName:NO];
    
    if ([_chatObject lowResImage]) {
        [ETRImageEditor cropImage:[_chatObject lowResImage]
                        imageName:loResImageName
                      applyToView:_targetImageView];
        
        if (!_doShowHiRes) {
            // Only the low-resolution image was requested.
            return;
        }
    }
    
    // First, look for the low-res image in the file cache.
    UIImage * cachedLoResImage;
    cachedLoResImage = [UIImage imageWithContentsOfFile:[_chatObject imageFilePath:NO]];
    if (cachedLoResImage) {
        [_chatObject setLowResImage:cachedLoResImage];
        [ETRImageEditor cropImage:cachedLoResImage
                        imageName:loResImageName
                      applyToView:_targetImageView];
    } else {
        // If the low-res image has not been stored as a file, download it.
        // This will also place it into the Object and View.
        [ETRServerAPIHelper getImageForLoader:self doLoadHiRes:NO];
    }
    
    // If the high-resolution image is not supposed to be shown, return.
    if (!_doShowHiRes) {
        return;
    }
    
    
    UIImage * cachedHiResImage;
    cachedHiResImage = [UIImage imageWithContentsOfFile:[_chatObject imageFilePath:YES]];
    if (cachedHiResImage) {
        [ETRImageEditor cropImage:cachedHiResImage
                        imageName:[_chatObject imageFileName:YES]
                      applyToView:_targetImageView];
    } else {
        [ETRServerAPIHelper getImageForLoader:self doLoadHiRes:YES];
    }
}



@end
