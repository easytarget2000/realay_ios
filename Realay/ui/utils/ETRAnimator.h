//
//  ETRAnimator.h
//  Realay
//
//  Created by Michel on 30/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETRAnimator : NSObject

+ (void)toggleBounceInView:(UIView *)view
            animateFromTop:(BOOL)doAnimateFromTop
                completion:(void(^)(void))completion;

#pragma mark -
#pragma mark Fading

+ (void)fadeView:(UIView *)view doAppear:(BOOL)doAppear;

@end
