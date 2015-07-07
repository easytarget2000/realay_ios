//
//  ETRUserListViewController.m
//  Realay
//
//  Created by Michel on 06/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRUserListViewController.h"

#import "ETRActionManager.h"
#import "ETRAnimator.h"
#import "ETRServerAPIHelper.h"
#import "ETRUIConstants.h"


@interface ETRUserListViewController () <ETRInternalNotificationHandler>

@property (weak, nonatomic) UIRefreshControl * refreshControl;

@end


@implementation ETRUserListViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [super setInfoView:(UIView *)[self usersInfoView]];
    [super setUpForConversationList:NO];
        
    // Configure manual refresher.
    UIRefreshControl * refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(updateUserList)
             forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[ETRUIConstants accentColor]];
    [[self tableView] addSubview:refreshControl];
    [self setRefreshControl:refreshControl];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[ETRActionManager sharedManager] setInternalNotificationHandler:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self refreshControl] endRefreshing];
    [ETRAnimator fadeView:[self unreadCounterLabel] doAppear:NO completion:nil];
}

- (void)setPrivateMessagesBadgeNumber:(NSInteger)number {
    [super setPrivateMessagesBadgeNumber:number
                                 inLabel:[self unreadCounterLabel]
                          animateFromTop:NO];
}

#pragma mark -
#pragma mark UIRefreshControl

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [super controllerDidChangeContent:controller];
    [[self refreshControl] endRefreshing];
}

- (void)updateUserList {
    [ETRServerAPIHelper updateRoomListWithCompletionHandler:^(BOOL didReceive) {
        [[self refreshControl] endRefreshing];
    }];
}

@end
