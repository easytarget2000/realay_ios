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
        // TODO: Check if this ImageView already contains the desired Image.
        if (placeHolderImage) {
            [_targetImageView setImage:placeHolderImage];
        }
    }
    return self;
}

+ (void)loadImageForObject:(ETRChatObject *)chatObject doLoadHiRes:(BOOL)doLoadHiRes {
    ETRImageLoader *instance = [[ETRImageLoader alloc] initWithObject:chatObject
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
    
//    NSLog(@"DEBUG: Started loading image for Object: %@", [_chatObject remoteID]);
    
    if (_targetImageView) {
        [_targetImageView setTag:[[_chatObject remoteID] intValue]];
    }
    
    long imageID = [[_chatObject imageID] longValue];
    if (imageID < 100 && imageID > -100) {
        NSLog(@"ERROR: Not loading image with ID %@.", [_chatObject imageID]);
        return;
    }
    
    if ([_chatObject lowResImage]) {
        [ETRImageEditor cropImage:[_chatObject lowResImage]
                      applyToView:_targetImageView
                          isHiRes:NO];
        
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
                          isHiRes:NO];
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
        [ETRImageEditor cropImage:cachedHiResImage
                      applyToView:_targetImageView
                          isHiRes:YES];
    } else {
        [ETRServerAPIHelper getImageForLoader:self doLoadHiRes:YES];
    }
}



@end
