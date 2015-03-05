//
//  EditFieldViewController.m
//  Realay
//
//  Created by Michel S on 28.01.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import "ETREditFieldViewController.h"

#import "ETRLocalUserManager.h"
#import "ETRAlertViewBuilder.h"

#import "ETRSharedMacros.h"

@implementation ETREditFieldViewController

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - IBAction

- (IBAction)saveButtonPressed:(id)sender {
    UIActivityIndicatorView *queryListIndicator = [[UIActivityIndicatorView alloc]
                                                   initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [queryListIndicator setCenter:[[self view] center]];
    [[self view] addSubview:queryListIndicator];

    [queryListIndicator startAnimating];
    
//    NSString *typedValue = [[[self editTextField] text]
//                             stringByTrimmingCharactersInSet:
//                             [NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    

    

    [[ETRLocalUserManager sharedManager] storeUserDefaults];
    [queryListIndicator stopAnimating];
    [[self navigationController] popViewControllerAnimated:YES];
}

@end
