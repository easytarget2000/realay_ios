//
//  ETRUserListViewController.m
//  Realay
//
//  Created by Michel on 06/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRUserListViewController.h"

#import "ETRServerAPIHelper.h"
#import "ETRUIConstants.h"


@interface ETRUserListViewController ()

@property (weak, nonatomic) UIRefreshControl * refreshControl;

@end


@implementation ETRUserListViewController

- (void)viewDidLoad {
    [super viewDidLoadForConversationList:NO];
        
    // Configure manual refresher.
    UIRefreshControl * refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(updateUserList)
             forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[ETRUIConstants accentColor]];
    [[self tableView] addSubview:refreshControl];
    [self setRefreshControl:refreshControl];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self refreshControl] endRefreshing];
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
