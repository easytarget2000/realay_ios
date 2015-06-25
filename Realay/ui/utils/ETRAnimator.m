//
//  ETRAnimator.m
//  Realay
//
//  Created by Michel on 30/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRAnimator.h"


static NSTimeInterval const ETRIntervalAnimationDefault = 0.4;


@implementation ETRAnimator

+ (void)toggleBounceInView:(UIView *)view
            animateFromTop:(BOOL)doAnimateFromTop
                completion:(void(^)(void))completion {
    
    [ETRAnimator toggleBounceInView:view
                     animateFromTop:doAnimateFromTop
                           duration:ETRIntervalAnimationDefault
                         completion:completion];
}

+ (void)toggleBounceInView:(UIView *)view
            animateFromTop:(BOOL)doAnimateFromTop
                  duration:(NSTimeInterval)duration
                completion:(void(^)(void))completion {
    
    CGSize size = view.frame.size;
    CGPoint origin = view.frame.origin;
    
    CGPoint originalCenter = [view center];
    
    CGPoint hideCenter;
    
    if (doAnimateFromTop) {
        hideCenter = CGPointMake(
                                 originalCenter.x,
                                 origin.y
                                 );
    } else {
        hideCenter = CGPointMake(
                                 originalCenter.x,
                                 origin.y + (size.height)
                                 );
    }
    
    CGFloat blowupScale = 1.2f;
    BOOL doAppear = [view isHidden];
    
    NSTimeInterval blowupDuration, settleDuration;
    NSTimeInterval shortDuration = 0.1;
    CGFloat settleScale;
    if (doAppear) {
        blowupDuration = duration;
        settleDuration = shortDuration;
        settleScale = 1.0f;
        
        [view setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, 0.0f)];
        [view setHidden:NO];
        [view setCenter:hideCenter];
    } else {
        blowupDuration = shortDuration;
        settleDuration = duration;
        settleScale = 0.1f;
    }
    
    UIViewAnimationOptions options;
    options = (UIViewAnimationOptionCurveEaseInOut);
    
    // Perform the blowup animation.
    [UIView animateWithDuration:blowupDuration
                          delay:0.1
                        options:options
                     animations:^{
                         [view setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, blowupScale)];
//                         [view setCenter:hideCenter];
                     }
                     completion:nil];
    
    [UIView animateWithDuration:settleDuration
                          delay:blowupDuration + 0.1
                        options:options
                     animations:^{
                         [view setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, settleScale)];
                         if (!doAppear) {
                             [view setCenter:hideCenter];
                         } else {
                             [view setCenter:originalCenter];
                         }
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             if(!doAppear) {
                                 [view setHidden:YES];
                             }
                             
                             [view setCenter:originalCenter];
                             
                             if (completion) {
                                 completion();
                             }
                         }
                     }];
}

+ (void)fadeView:(UIView *)view
        doAppear:(BOOL)doAppear
      completion:(void(^)(void))completion {

    if (doAppear) {
        if (![view isHidden] && [view alpha] > 0.9f) {
            if (completion) {
                completion();
            }
            return;
        }
        
        [view setHidden:NO];
        
        [UIView animateWithDuration:ETRIntervalAnimationDefault
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [view setAlpha:1.0f];
                         }
                         completion:^(BOOL finished){
                             if (completion) {
                                 completion();
                             }
                         }];
    } else {
        if ([view isHidden]) {
            return;
        }
        
        [UIView animateWithDuration:ETRIntervalAnimationDefault
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [view setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [view setHidden:YES];
                             if (completion) {
                                 completion();
                             }
                         }];
    }
}

+ (void)moveView:(UIView *)view
  toDisappearAtY:(CGFloat)targetY
      completion:(void(^)(void))completion {
    
    CGRect targetFrame = [view frame];
    targetFrame.origin.y = targetY;
    
    [UIView animateWithDuration:ETRIntervalAnimationDefault
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [view setFrame:targetFrame];
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             completion();
                         }
                     }];

}

@end
