//
//  ETRIconDownloader.h
//  Realay
//
//  Created by Michel S on 11.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETRChatObject.h"

@interface ETRImageLoader : NSObject

@property (strong, nonatomic, readonly) void (^completionHandler)(void);
@property (strong, nonatomic, readonly) ETRChatObject *chatObject;
@property (weak, nonatomic, readonly) UIImageView *targetImageView;

+ (void)loadImageForObject:(ETRChatObject *)chatObject doLoadHiRes:(BOOL)doLoadHiRes;

+ (void)loadImageForObject:(ETRChatObject *)chatObject intoView:(UIImageView *)targetImageView doLoadHiRes:(BOOL)doShowHiRes;

- (NSString *)imagefilePath:(BOOL)doLoadHiRes;

- (void)startLoading;

@end
