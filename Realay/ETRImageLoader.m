//
//  ETRIconDownloader.m
//  Realay
//
//  Created by Michel S on 11.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRImageLoader.h"

#import "ETRImageEditor.h"
#import "ETRServerAPIHelper.h"

@implementation ETRImageLoader {
    BOOL _doShowHiRes;
}

- initWithObject:(ETRChatObject *)chatObject targetImageView:(UIImageView *)targetImageView doLoadHiRes:(BOOL)doLoadHiRes{
    self = [super init];
    _chatObject = chatObject;
    _targetImageView = targetImageView;
    _doShowHiRes = doLoadHiRes;
    _tag = (int) [chatObject imageID];
    return self;
}

+ (void)loadImageForObject:(ETRChatObject *)chatObject doLoadHiRes:(BOOL)doLoadHiRes {
    ETRImageLoader *instance = [[ETRImageLoader alloc] initWithObject:chatObject
                                                      targetImageView:nil
                                                          doLoadHiRes:doLoadHiRes];
    [NSThread detachNewThreadSelector:@selector(startLoadingImage:)
                             toTarget:instance
                           withObject:nil];
}

+ (void)loadImageForObject:(ETRChatObject *)chatObject intoView:(UIImageView *)targetImageView doLoadHiRes:(BOOL)doShowHiRes {
    ETRImageLoader *instance = [[ETRImageLoader alloc] initWithObject:chatObject
                                                      targetImageView:targetImageView
                                                          doLoadHiRes:(BOOL)doShowHiRes];
    [NSThread detachNewThreadSelector:@selector(startLoadingImage:)
                             toTarget:instance
                           withObject:nil];
}

- (void)startLoadingImage:(id)sender {
    if (!_chatObject) {
      return;
    }
    
    if (_targetImageView) {
        NSInteger tag = [_targetImageView tag];
        if (tag > 100) {
            NSLog(@"DEBUG: ImageView already has tag %i.", (int) tag);
        } else {
            [_targetImageView setTag:tag];
        }
    }
    
    long imageID = [[_chatObject imageID] longValue];
    if (imageID < 100 && imageID > -100) {
//        NSLog(@"WARNING: Not loading image with ID %@.", [_chatObject imageID]);
        return;
    }
    
    if ([_chatObject lowResImage]) {
        [ETRImageEditor cropImage:[_chatObject lowResImage]
                      applyToView:_targetImageView
                          withTag:_tag];
        if (!_doShowHiRes) {
            // Only the low-resolution image was requested.
            return;
        }
    }
    
    // First, look for the low-res image in the file cache.
    UIImage *cachedLoResImage = [UIImage imageWithContentsOfFile:[_chatObject imageFilePath:NO]];
    if (cachedLoResImage) {
        [_chatObject setLowResImage:cachedLoResImage];
        [ETRImageEditor cropImage:cachedLoResImage
                      applyToView:_targetImageView
                          withTag:_tag];
    } else {
        // If the low-res image has not been stored as a file, download it.
        // This will also place it into the Object and View.
        [ETRServerAPIHelper getImageForLoader:self doLoadHiRes:NO];
    }
    
    // If the high-resolution image is not supposed to be shown, return.
    if (!_doShowHiRes) {
        return;
    }
    
    UIImage *cachedHiResImage = [UIImage imageWithContentsOfFile:[_chatObject imageFilePath:YES]];
    if (cachedHiResImage) {
        [ETRImageEditor cropImage:cachedHiResImage applyToView:_targetImageView withTag:_tag];
    } else {
        [ETRServerAPIHelper getImageForLoader:self doLoadHiRes:YES];
    }
}

@end
