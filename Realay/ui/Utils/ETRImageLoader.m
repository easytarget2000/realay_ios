//
//  ETRIconDownloader.m
//  Realay
//
//  Created by Michel S on 11.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRImageLoader.h"

#import "ETRAction.h"
#import "ETRChatObject.h"
#import "ETRImageEditor.h"
#import "ETRImageView.h"
#import "ETRMediaViewController.h"
#import "ETRServerAPIHelper.h"
#import "ETRUIConstants.h"


NSString *const ETRKeyIntendedObject = @"intended_object";

NSString *const ETRKeyDidLoadHiRes = @"hi_res";


@interface ETRImageLoader ()

@property (nonatomic) BOOL doShowHiRes;

@property (nonatomic) BOOL doAdjust;

@end


@implementation ETRImageLoader

@synthesize activityIndicator = _activityIndicator;


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

+ (void)loadImageForObject:(ETRChatObject *)chatObject
               doLoadHiRes:(BOOL)doLoadHiRes
activityIndicatorContainer:(UIView *)activityIndicatorContainer
      navigationController:(UINavigationController *)navigationController {
    
    ETRImageLoader * instance = [[ETRImageLoader alloc] initWithObject:chatObject
                                                      targetImageView:nil
                                                     placeHolderImage:nil
                                                          doLoadHiRes:doLoadHiRes];
    
    // Prepare an Activity Indicator that fits into a given View.
    UIActivityIndicatorView * activityIndicator;
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [instance setActivityIndicator:activityIndicator];
    
    CGSize containerSize = activityIndicatorContainer.frame.size;
    [[instance activityIndicator] setCenter:CGPointMake(containerSize.width / 2.0f, containerSize.height / 2.0f)];
    [activityIndicatorContainer addSubview:[instance activityIndicator]];
    
    // Store the Navigation Controller for an automatic View Controller push later.
    [instance setNavigationController:navigationController];

    [NSThread detachNewThreadSelector:@selector(startLoadingImage:)
                             toTarget:instance
                           withObject:nil];
}

+ (void)loadImageForObject:(ETRChatObject *)chatObject
                  intoView:(ETRImageView *)targetImageView
          placeHolderImage:(UIImage *)placeHolderImage
               doLoadHiRes:(BOOL)doShowHiRes
                    doCrop:(BOOL)doCrop {
    
    NSString * imageName = [chatObject imageFileName:doShowHiRes];
    if ([targetImageView hasImage:imageName]) {
        return;
    }
    
    ETRImageLoader * instance = [[ETRImageLoader alloc] initWithObject:chatObject
                                                       targetImageView:targetImageView
                                                      placeHolderImage:placeHolderImage
                                                           doLoadHiRes:doShowHiRes];
    
    [instance setDoAdjust:doCrop];
    
    [NSThread detachNewThreadSelector:@selector(startLoadingImage:)
                             toTarget:instance
                           withObject:nil];
}

+ (void)loadImageForObject:(ETRChatObject *)chatObject
                  intoView:(ETRImageView *)targetImageView
          placeHolderImage:(UIImage *)placeHolderImage
               doLoadHiRes:(BOOL)doShowHiRes {
    
    [ETRImageLoader loadImageForObject:chatObject
                              intoView:targetImageView
                      placeHolderImage:placeHolderImage
                           doLoadHiRes:doShowHiRes
                                doCrop:YES];
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
    
    if ([_chatObject lowResImage] && _targetImageView) {
        if (_doAdjust) {
            [ETRImageEditor cropImage:[_chatObject lowResImage]
                            imageName:loResImageName
                          applyToView:_targetImageView];
        } else {
            [_targetImageView setImage:[_chatObject lowResImage]];
        }
        
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
        if (_doAdjust) {
            [ETRImageEditor cropImage:cachedLoResImage
                            imageName:loResImageName
                          applyToView:_targetImageView];
        } else {
            [_targetImageView setImage:cachedLoResImage];
        }

    } else {
        // If the low-res image has not been stored as a file, download it.
        // This will also place it into the Object and View.
        [ETRServerAPIHelper getImageForLoader:self doLoadHiRes:NO doAdjust:_doAdjust];
    }
    
    // If the high-resolution image is not supposed to be shown, return.
    if (!_doShowHiRes) {
        return;
    }    
    
    UIImage * cachedHiResImage;
    cachedHiResImage = [UIImage imageWithContentsOfFile:[_chatObject imageFilePath:YES]];
    if (cachedHiResImage) {

        _activityIndicator = nil;

        if (_navigationController && [_chatObject isKindOfClass:[ETRAction class]]) {
            UIStoryboard * storyboard = [_navigationController storyboard];
            ETRMediaViewController * mediaViewController;
            mediaViewController = [storyboard instantiateViewControllerWithIdentifier:ETRViewControllerMedia];
            
            [mediaViewController setMessage:(ETRAction *)_chatObject];
            
            [_navigationController pushViewController:mediaViewController animated:YES];
        }
        
        if (_doAdjust) {
            [ETRImageEditor cropImage:cachedHiResImage
                            imageName:[_chatObject imageFileName:YES]
                          applyToView:_targetImageView];
        } else {
            [_targetImageView setImage:cachedHiResImage];
        }
    } else {
        [ETRServerAPIHelper getImageForLoader:self doLoadHiRes:YES doAdjust:_doAdjust];
        if (_activityIndicator) {
            [_activityIndicator startAnimating];
        }
    }
}



@end
