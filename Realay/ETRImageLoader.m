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
    [NSThread detachNewThreadSelector:@selector(startLoading)
                             toTarget:instance
                           withObject:nil];
}

- (void)startLoading {
    if (!_chatObject) {
      return;
    }
    
    if (_targetImageView) {
        NSInteger tag = [_targetImageView tag];
        if (tag > 100) {
            NSLog(@"DEBUG: ImageView already has tag %i.", (int) tag);
        } else {
            [_targetImageView setTag:(int) [_chatObject imageID]];
        }
    }
    
    if ([[_chatObject imageID] longValue] < 100) {
        NSLog(@"ERROR: Image ID %@ is not valid.", [_chatObject imageID]);
        return;
    }
    
    if ([_chatObject lowResImage]) {
        [ETRImageEditor cropImage:[_chatObject lowResImage] applyToView:_targetImageView];
        if (!_doShowHiRes) return;
    }
    
    // First, look for the low-res image in the file cache.
    UIImage *cachedLoResImage = [UIImage imageWithContentsOfFile:[self imagefilePath:NO]];
    if (cachedLoResImage) {
        [_chatObject setLowResImage:cachedLoResImage];
        [ETRImageEditor cropImage:cachedLoResImage applyToView:_targetImageView];
    } else {
        // If the low-res image has not been stored as a file, download it.
        // This will also place it into the Object and View.
        [ETRServerAPIHelper getImageForLoader:self doLoadHiRes:NO];
    }
    
    // If the high-resolution image is not supposed to be shown, return.
    if (!_doShowHiRes) {
        return;
    }
    
    UIImage *cachedHiResImage = [UIImage imageWithContentsOfFile:[self imagefilePath:YES]];
    if (cachedHiResImage) {
        [ETRImageEditor cropImage:cachedHiResImage applyToView:_targetImageView];
    } else {
        [ETRServerAPIHelper getImageForLoader:self doLoadHiRes:YES];
    }
}

- (NSString *)imagefilePath:(BOOL)doLoadHiRes {
    if (!_chatObject) return nil;
    
    // Save image.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *fileName = [NSString stringWithFormat:@"%@.jpg", [_chatObject imageIDWithHiResFlag:doLoadHiRes]];
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
}

@end
