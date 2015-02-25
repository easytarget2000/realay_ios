//
//  EditFieldViewController.m
//  Realay
//
//  Created by Michel S on 28.01.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETREditFieldViewController.h"

#import "ETRLocalUser.h"
#import "ETRAlertViewBuilder.h"

#import "SharedMacros.h"

@implementation ETREditFieldViewController

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    
    NSString *attribute, *value;
    
    if ([[self attributeKey] isEqualToString:kUserDefsUserName]) {
        //TODO: Localization
        attribute = @"Name:";
        value = [[ETRLocalUser sharedLocalUser] name];
        
    } else if ([[self attributeKey] isEqualToString:kUserDefsUserStatus]) {
        attribute = @"Status:";
        value = [[ETRLocalUser sharedLocalUser] status];
    }
    
    [[self editAttributeLabel] setText:attribute];
    [[self editTextField] setText:value];

}

#pragma mark - IBAction

- (IBAction)saveButtonPressed:(id)sender {
    UIActivityIndicatorView *queryListIndicator = [[UIActivityIndicatorView alloc]
                                                   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [queryListIndicator setCenter:[[self view] center]];
    [[self view] addSubview:queryListIndicator];

    [queryListIndicator startAnimating];
    
    NSString *typedValue = [[[self editTextField] text]
                             stringByTrimmingCharactersInSet:
                             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([[self attributeKey] isEqualToString:kUserDefsUserName]) {
        // User wants to edit the name.
        // Check the length first.
        if ([typedValue length] > 2) {
            [[ETRLocalUser sharedLocalUser] setName:typedValue];
        }
        else {
            [queryListIndicator stopAnimating];
            [ETRAlertViewBuilder showTypedNameTooShortAlert];
            return;
        }
    } else if ([[self attributeKey] isEqualToString:kUserDefsUserStatus]) {
        [[ETRLocalUser sharedLocalUser] setStatus:typedValue];
    }
    

    [[ETRLocalUser sharedLocalUser] wasAbleToUpdateUser];
    [queryListIndicator stopAnimating];
    [[self navigationController] popViewControllerAnimated:YES];
}

@end
