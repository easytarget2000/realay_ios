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

@interface ETRProfileHeaderEditorCell () <UITextFieldDelegate>

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
    [[self nameField] setDelegate:self];
    [[self nameField] setTag:tag];
    [[self nameField] setText:[user name]];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    
    if ([[touch view] isEqual:[self iconImageView]] && _viewController) {
        [_viewController imagePickerButtonPressed:nil];
    }
}

- (BOOL)textField:(nonnull UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(nonnull NSString *)string {
    
    NSString * newText;
    newText = [[textField text] stringByReplacingCharactersInRange:range
                                                        withString:string];
    if([newText length] <= 24) {
        return YES;
    } else {
        [textField setText:[newText substringToIndex:24]];
        return NO;
    }
}

@end
