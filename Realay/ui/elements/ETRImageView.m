//
//  ETRImageView.m
//  Realay
//
//  Created by Michel on 09/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRImageView.h"

@interface ETRImageView ()

@property (strong, nonatomic) NSString * imageName;

@end


@implementation ETRImageView

- (BOOL)hasImage:(NSString *)imageName {
    if (imageName && _imageName) {
        return [imageName isEqualToString:_imageName];
    } else {
        return NO;
    }
}

- (void)setImageName:(NSString *)imageName {
    _imageName = imageName;
}

@end
