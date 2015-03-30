//
//  ETRAnimator.m
//  Realay
//
//  Created by Michel on 30/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRAnimator.h"

static NSTimeInterval const ETRScaleDuration = 0.5;

@implementation ETRAnimator

+ (void)toggleBounceInView:(UIView *)view completion:(void(^)(void))completion {
//    CGPoint newCenter = CGPointMake(100.0,100.0);
    
    CGFloat blowupScale = 1.2f;
    BOOL doAppear = [view isHidden];
    
    NSTimeInterval blowupDuration, settleDuration;
    NSTimeInterval shortDuration = 0.3;
    CGFloat settleScale;
    if (doAppear) {
        blowupDuration = ETRScaleDuration;
        settleDuration = shortDuration;
        settleScale = 1.0f;
        
        [view setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 0.0f, 0.0f)];
        [view setHidden:NO];
    } else {
        blowupDuration = shortDuration;
        settleDuration = ETRScaleDuration;
        settleScale = 0.1f;
    }
    
    // Perform the blowup animation.
    [UIView animateWithDuration:blowupDuration
                          delay:0.0
                        options:(UIViewAnimationOptionCurveLinear | UIViewAnimationOptionTransitionFlipFromBottom)
                     animations:^{
                         [view setTransform:CGAffineTransformScale(CGAffineTransformIdentity, blowupScale, blowupScale)];
                     }
                     completion:nil
     ];
    
    [UIView animateWithDuration:settleDuration
                          delay:blowupDuration
                        options:(UIViewAnimationOptionCurveLinear | UIViewAnimationOptionTransitionFlipFromBottom)
                     animations:^{
                         [view setTransform:CGAffineTransformScale(CGAffineTransformIdentity, settleScale, settleScale)];
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             if(!doAppear) {
                                 [view setHidden:YES];
                             }
                             
                             if (completion) {
                                 completion();
                             }
                         }
                     }];
}

@end
