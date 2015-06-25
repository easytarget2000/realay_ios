//
//  ETRAnimator.h
//  Realay
//
//  Created by Michel on 30/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETRAnimator : NSObject

+ (void)toggleBounceInView:(UIView *)view
            animateFromTop:(BOOL)doAnimateFromTop
                completion:(void(^)(void))completion;

+ (void)fadeView:(UIView *)view
        doAppear:(BOOL)doAppear
      completion:(void(^)(void))completion;

+ (void)moveView:(UIView *)view
  toDisappearAtY:(CGFloat)targetY
      completion:(void(^)(void))completion;

+ (void)toggleBounceInView:(UIView *)view
            animateFromTop:(BOOL)doAnimateFromTop
                  duration:(NSTimeInterval)duration
                completion:(void(^)(void))completion;

@end
