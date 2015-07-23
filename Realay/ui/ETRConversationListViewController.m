//
//  ETRConversationListViewController.m
//  Realay
//
//  Created by Michel on 27/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRConversationListViewController.h"

#import "ETRActionManager.h"
#import "ETRAlertViewFactory.h"
#import "ETRConversation.h"


@implementation ETRConversationListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [super setInfoView:[self conversationsInfoView]];
    [super setUpForConversationList:YES];
    
    /*
     Reference to Alert View builder and click handler
     */
    UILongPressGestureRecognizer * recognizer;
    recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [recognizer setMinimumPressDuration:0.8];
    [[self tableView] addGestureRecognizer:recognizer];
}

#pragma mark -
#pragma mark Message Long Press

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
        CGPoint point = [gestureRecognizer locationInView:[self tableView]];
        NSIndexPath * indexPath = [[self tableView] indexPathForRowAtPoint:point];
        
        ETRConversation * record = [[self resultsController] objectAtIndexPath:indexPath];
        [[self alertHelper] showMenuForConversation:record calledByViewController:self];
    }
}

@end
