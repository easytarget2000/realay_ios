//
//  ETRProfileHeaderEditorCell.m
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRProfileHeaderEditorCell.h"

#import "ETRImageLoader.h"
#import "ETRProfileEditorViewController.h"
#import "ETRUser.h"

/*
 Corner radius that is used for this Icon ImageView to give them a circle shape;
 Has to be half the side length of the View
 */
static CGFloat const ETRIconButtonCornerRadius = 32.0f;

@interface ETRProfileHeaderEditorCell ()

@property (weak, nonatomic) ETRProfileEditorViewController * viewController;

@end


@implementation ETRProfileHeaderEditorCell

- (void)setUpWithTag:(NSInteger)tag
             forUser:(ETRUser *)user
    inViewController:(ETRProfileEditorViewController *)viewController {
    if (!user) {
        return;
    }
    
    _viewController = viewController;
    
    [[[self iconImageView] layer] setCornerRadius:ETRIconButtonCornerRadius];
    [[self iconImageView] setClipsToBounds:YES];
    [ETRImageLoader loadImageForObject:user intoView:[self iconImageView] doLoadHiRes:NO];
    
    [[self nameField] setTag:tag];
    [[self nameField] setText:[user name]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if ([[touch view] isEqual:[self iconImageView]] && _viewController) {
        [_viewController imagePickerButtonPressed:nil];
    }
}

@end
