//
//  ETRIconDownloader.h
//  Realay
//
//  Created by Michel S on 11.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ETRChatObject;
@class ETRImageView;
@class ETRMediaViewController;

typedef void(^CompletionBlock)(void);

extern NSString *const ETRKeyIntendedObject;

extern NSString *const ETRKeyDidLoadHiRes;


@interface ETRImageLoader : NSObject

@property (weak, nonatomic, readonly) ETRChatObject * chatObject;

@property (weak, nonatomic, readonly) ETRImageView * targetImageView;

@property (strong, nonatomic) UINavigationController * navigationController;


@property (weak, nonatomic) UIActivityIndicatorView * activityIndicator;

@property (nonatomic, readonly) NSInteger tag;

+ (void)loadImageForObject:(ETRChatObject *)chatObject
               doLoadHiRes:(BOOL)doLoadHiRes
activityIndicatorContainer:(UIView *)activityIndicatorContainer
      navigationController:(UINavigationController *)navigationController;

+ (void)loadImageForObject:(ETRChatObject *)chatObject
                  intoView:(ETRImageView *)targetImageView
          placeHolderImage:(UIImage *)placeHolderImage
               doLoadHiRes:(BOOL)doShowHiRes;

+ (void)loadImageForObject:(ETRChatObject *)chatObject
                  intoView:(ETRImageView *)targetImageView
          placeHolderImage:(UIImage *)placeHolderImage
               doLoadHiRes:(BOOL)doShowHiRes
                    doCrop:(BOOL)doCrop;

- (void)startLoadingImage:(id)sender;

@end
