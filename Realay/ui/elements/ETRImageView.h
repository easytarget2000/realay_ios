//
//  ETRImageView.h
//  Realay
//
//  Created by Michel on 09/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETRImageView : UIImageView

- (BOOL)hasImage:(NSString *)imageName;

- (void)setImageName:(NSString *)imageName;

@end
