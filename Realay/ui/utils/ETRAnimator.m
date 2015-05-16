//
//  ETRAnimator.m
//  Realay
//
//  Created by Michel on 30/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRAnimator.h"

static NSTimeInterval const ETRAnimationDurationScale = 0.4;

static NSTimeInterval const ETRAnimationDurationFade = 1.2;

@implementation ETRAnimator

+ (void)toggleBounceInView:(UIView *)view completion:(void(^)(void))completion {
//    CGPoint newCenter = CGPointMake(100.0,100.0);
    
    CGSize size = view.frame.size;
    CGPoint origin = view.frame.origin;
    
    CGPoint originalCenter = [view center];
    
    CGPoint hideCenter = CGPointMake(
                                 originalCenter.x,
                                 origin.y + (size.height)
                                 );
    
    CGFloat blowupScale = 1.2f;
    BOOL doAppear = [view isHidden];
    
    NSTimeInterval blowupDuration, settleDuration;
    NSTimeInterval shortDuration = 0.1;
    CGFloat settleScale;
    if (doAppear) {
        blowupDuration = ETRAnimationDurationScale;
        settleDuration = shortDuration;
        settleScale = 1.0f;
        
        
        [view setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, 0.0f)];
        [view setHidden:NO];
        [view setCenter:hideCenter];
    } else {
        blowupDuration = shortDuration;
        settleDuration = ETRAnimationDurationScale;
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

#pragma mark -
#pragma mark Fading

+ (void)fadeView:(UIView *)view doAppear:(BOOL)doAppear {

    if (doAppear) {
        if (![view isHidden] && [view alpha] > 0.9f) {
            return;
        }
        
//        [view setAlpha:0.0f];
        [view setHidden:NO];
        
        [UIView animateWithDuration:ETRAnimationDurationFade
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [view setAlpha:1.0f];
                         }
                         completion:nil];
    } else {
        if ([view isHidden]) {
            return;
        }
        
        [UIView animateWithDuration:ETRAnimationDurationFade
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [view setAlpha:0.0f];
                         }
                         completion:^(BOOL finished) {
                             [view setHidden:YES];
                         }];
    }
}

@end
