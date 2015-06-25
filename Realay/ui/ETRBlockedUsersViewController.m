//
//  ETRBlockedUsersViewController.m
//  Realay
//
//  Created by Michel on 05/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRBlockedUsersViewController.h"

#import "ETRAlertViewFactory.h"
#import "ETRAnimator.h"
#import "ETRCoreDataHelper.h"
#import "ETRImageLoader.h"
#import "ETRImageView.h"
#import "ETRUIConstants.h"
#import "ETRUser.h"
#import "ETRUserCell.h"


@interface ETRBlockedUsersViewController ()
<UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController * resultsController;

@property (nonatomic) BOOL doShowInfoView;

@end


@implementation ETRBlockedUsersViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _doShowInfoView = NO;
    
    // Enable the Fetched Results Controllers.
    _resultsController = [ETRCoreDataHelper blockedUserListControllerWithDelegate:self];
    NSError * error = nil;
    [_resultsController performFetch:&error];
    if (error) {
        NSLog(@"ERROR: performFetch: %@", error);
    }
    
    // Do not display empty cells at the end.
    [[self usersTableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    // The User list has a fixed row height.
    [[self usersTableView] setRowHeight:ETRRowHeightUser];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self usersTableView] reloadData];
    [self updateInformationView];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[[self navigationController] navigationBar] setTranslucent:NO];
    [[self navigationController] setToolbarHidden:YES animated:YES];
}

- (void)updateInformationView {
    NSInteger numberOfBlockedUsers = [[self usersTableView] numberOfRowsInSection:0];
    if (numberOfBlockedUsers < 1) {
        [ETRAnimator fadeView:[self infoLabel] doAppear:YES completion:nil];
    } else {
        [ETRAnimator fadeView:[self infoLabel] doAppear:NO completion:nil];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[_resultsController fetchedObjects] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ETRUserCell * userCell = [tableView dequeueReusableCellWithIdentifier:ETRCellIdentifierUser
                                                             forIndexPath:indexPath];

    ETRUser * user = [_resultsController objectAtIndexPath:indexPath];
    
    [ETRImageLoader loadImageForObject:user
                              intoView:[userCell iconView]
                      placeHolderImage:[UIImage imageNamed:ETRImageNameUserIcon]
                           doLoadHiRes:NO];
    
    [[userCell nameLabel] setText:[user name]];
    [[userCell infoLabel] setText:[user status]];
    
    return userCell;
}

#pragma mark -
#pragma mark Table View Input

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ETRUser * record = [_resultsController objectAtIndexPath:indexPath];
    [[self alertHelper] showUnblockViewForUser:record];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self usersTableView] beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self usersTableView] endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [[self usersTableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                         withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [[self usersTableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                         withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {

        }
        case NSFetchedResultsChangeMove: {
            [[self usersTableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                         withRowAnimation:UITableViewRowAnimationFade];
            [[self usersTableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                         withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    
    [self updateInformationView];
}

@end
