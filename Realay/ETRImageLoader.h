//
//  ETRIconDownloader.h
//  Realay
//
//  Created by Michel S on 11.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

@class ETRChatObject;
@class ETRImageView;


extern NSString *const ETRKeyIntendedObject;

extern NSString *const ETRKeyDidLoadHiRes;


@interface ETRImageLoader : NSObject

//@property (strong, nonatomic, readonly) void (^completionHandler)(void);

@property (weak, nonatomic, readonly) ETRChatObject *chatObject;

@property (weak, nonatomic, readonly) ETRImageView *targetImageView;

@property (nonatomic, readonly) NSInteger tag;

+ (void)loadImageForObject:(ETRChatObject *)chatObject doLoadHiRes:(BOOL)doLoadHiRes;

+ (void)loadImageForObject:(ETRChatObject *)chatObject
                  intoView:(ETRImageView *)targetImageView
          placeHolderImage:(UIImage *)placeHolderImage
               doLoadHiRes:(BOOL)doShowHiRes;

@end
