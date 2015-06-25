//
//  ETRProfileHeaderEditorCell.m
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRProfileHeaderEditorCell.h"

#import "ETRImageLoader.h"
#import "ETRImageView.h"
#import "ETRProfileEditorViewController.h"
#import "ETRUIConstants.h"
#import "ETRUser.h"

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
    
    [ETRImageLoader loadImageForObject:user
                              intoView:[self iconImageView]
                      placeHolderImage:[UIImage imageNamed:ETRImageNameUserIcon]
                           doLoadHiRes:NO];
    
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
