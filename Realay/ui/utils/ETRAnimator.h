//
//  ETRAnimator.h
//  Realay
//
//  Created by Michel on 30/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ETRAnimator : NSObject

+ (void)toggleBounceInView:(UIView *)view completion:(void(^)(void))completion;

@end
