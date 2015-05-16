//
//  ETRUserListViewController.m
//  Realay
//
//  Created by Michel on 06/05/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRUserListViewController.h"

#import "ETRAction.h"
#import "ETRActionManager.h"
#import "ETRAnimator.h"
#import "ETRConversation.h"
#import "ETRConversationViewController.h"
#import "ETRCoreDataHelper.h"
#import "ETRDetailsViewController.h"
#import "ETRImageLoader.h"
#import "ETRLocalUserManager.h"
#import "ETRRoom.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"
#import "ETRUser.h"
#import "ETRUserCell.h"


static NSString *const ETRUsersToConversationSegue = @"usersToConversationSegue";

static NSString *const ETRUsersToMapSegue = @"usersToMapSegue";

static NSString *const ETRUsersToProfileSegue = @"usersToProfileSegue";

static NSString *const ETRUserCellIdentifier = @"userCell";

static NSString *const ETRInfoCellIdentifier = @"infoCell";

static CGFloat const ETRUserRowHeight = 64.0f;


@interface ETRUserListViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) UIRefreshControl * refreshControl;

@property (strong, nonatomic) NSFetchedResultsController * conversationsResultsController;

@property (strong, nonatomic) NSFetchedResultsController * usersResultsController;

@property (nonatomic) BOOL doShowInfoView;

@end


@implementation ETRUserListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _doShowInfoView = NO;
    
    // Enable the Fetched Results Controllers.
    _conversationsResultsController = [ETRCoreDataHelper conversationResulsControllerWithDelegate:self];
    _usersResultsController = [ETRCoreDataHelper userListResultsControllerWithDelegate:self];
    
    NSError * error = nil;
    [_conversationsResultsController performFetch:&error];
    if (error) {
        NSLog(@"ERROR: performFetch: %@", error);
    }
    [_usersResultsController performFetch:&error];
    if (error) {
        NSLog(@"ERROR: performFetch: %@", error);
    }
    
    // Do not display empty cells at the end.
    [[self usersTableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    // The title is the current Room
    // and the back-button TO this View Controller is supposed to be empty.
    [self setTitle:[[ETRSessionManager sessionRoom] title]];
    [[[self navigationItem] backBarButtonItem] setTitle:@""];
    
    // The User list has a fixed row height.
    [[self usersTableView] setRowHeight:ETRUserRowHeight];
        
    // Configure manual refresher.
    UIRefreshControl * refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(updateUserList)
             forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[ETRUIConstants accentColor]];
    [[self usersTableView] addSubview:refreshControl];
    [self setRefreshControl:refreshControl];
    
    // Create the Map and Profile BarButtons and place them in the NavigationBar.
    UIImage * mapButtonIcon = [UIImage imageNamed:@"Map"];
    UIBarButtonItem * mapButton = [[UIBarButtonItem alloc] initWithImage:mapButtonIcon
                                                     landscapeImagePhone:mapButtonIcon
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(mapButtonPressed:)];
    UIImage * profileButtonIcon = [UIImage imageNamed:@"Profile"];
    UIBarButtonItem * profileButton = [[UIBarButtonItem alloc] initWithImage:profileButtonIcon
                                                         landscapeImagePhone:profileButtonIcon
                                                                       style:UIBarButtonItemStylePlain target:self
                                                                      action:@selector(profileButtonPressed:)];
    
    NSArray * rightBarButtons = [[NSArray alloc] initWithObjects:profileButton, mapButton, nil];
    [[self navigationItem] setRightBarButtonItems:rightBarButtons];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self usersTableView] reloadData];
    [[ETRActionManager sharedManager] setForegroundPartnerID:@(-51L)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[self refreshControl] endRefreshing];
}

#pragma mark -
#pragma mark Table

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self usersTableView] beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self refreshControl] endRefreshing];
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
            UITableViewCell *cell = [[self usersTableView] cellForRowAtIndexPath:indexPath];
            if (cell && [cell isKindOfClass:[ETRUserCell class]]) {
                [self configureUserCell:(ETRUserCell *)cell atIndexPath:indexPath];
            }
            break;
        }
        case NSFetchedResultsChangeMove: {
            [[self usersTableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
            [[self usersTableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_conversationsResultsController && [[_conversationsResultsController fetchedObjects] count]) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfSections = [tableView numberOfSections];
    
    NSInteger numberOfRows;
    if (section == 0 && numberOfSections > 1) {
        if (!_conversationsResultsController) {
            numberOfRows = 0;
        } else {
            numberOfRows = [[_conversationsResultsController fetchedObjects] count];
        }
    } else {
        if (!_usersResultsController) {
            numberOfRows = 0;
        } else {
            numberOfRows = [[_usersResultsController fetchedObjects] count];
        }
    }
    
    _doShowInfoView = numberOfRows < 1;
    
    if (_doShowInfoView) {
        // Wait for possible results before actually deciding to show the Info View.
        dispatch_after(
                       400,
                       dispatch_get_main_queue(),
                       ^{
                           [ETRAnimator fadeView:[self infoView] doAppear:_doShowInfoView];
                       });
    } else {
        // Hiding the Info View happens immediately.
        [ETRAnimator fadeView:[self infoView] doAppear:NO];
    }

    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
//    if (!_conversationsResultsController || ![[_conversationsResultsController fetchedObjects] count]) {
//        return nil;
//    } else if (!_usersResultsController || ![[_usersResultsController fetchedObjects] count]) {
//        return nil;
//    }
    ETRUserCell * userCell = [tableView dequeueReusableCellWithIdentifier:ETRUserCellIdentifier
                                                             forIndexPath:indexPath];
    [self configureUserCell:userCell atIndexPath:indexPath];
    return userCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return ETRUserRowHeight;
}

- (void)configureUserCell:(ETRUserCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Give the Image Views a circular shape.
    //    [[[cell iconView] layer] setCornerRadius:ETRIconViewCornerRadius];
    //    [[cell iconView] setClipsToBounds:YES];
    
    NSInteger numberOfSections = [[self usersTableView] numberOfSections];
    
    // Get the User object from the appropriate Fetched Results Controller
    // and apply the data to the Cell elements.
    ETRUser * user;
    if ([indexPath section] == 0 && numberOfSections > 1) {
        ETRConversation * convo = [_conversationsResultsController objectAtIndexPath:indexPath];
        user = [convo partner];
        
        NSString * message;
        if ([[convo lastMessage] isPhotoMessage]) {
            message = NSLocalizedString(@"Picture", @"Picture");
        } else {
            message = [[convo lastMessage] messageContent];
        }
        
        [[cell infoLabel] setText:message];
    } else {
        // The Index Path gives Section 1 but the Fetched Results Controller assumes its values are in Section 0.
        NSIndexPath * alignedPath = [NSIndexPath indexPathForRow:[indexPath row] inSection:0];
        user = [_usersResultsController objectAtIndexPath:alignedPath];
        [[cell infoLabel] setText:[user status]];
    }
    
    [[cell nameLabel] setText:[user name]];
    [ETRImageLoader loadImageForObject:user
                              intoView:[cell iconView]
                      placeHolderImage:[UIImage imageNamed:ETRImageNameUserIcon]
                           doLoadHiRes:NO];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0 && [[_conversationsResultsController fetchedObjects] count]) {
        return NSLocalizedString(@"Private_Conversations", @"Private Chats");
    } else {
        return NSLocalizedString(@"Users_Around_You", @"All Session Users");
    }
}

- (void)updateUserList {
    [ETRServerAPIHelper updateRoomListWithCompletionHandler:^(BOOL didReceive) {
        [[self refreshControl] endRefreshing];
    }];
}

#pragma mark - Navigation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Hides the selection and if a valid selection was made,
    // opens a Conversation View Controller with the selected partner User.
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([indexPath section] == 0 && [[_conversationsResultsController fetchedObjects] count]) {
        ETRConversation * record = [_conversationsResultsController objectAtIndexPath:indexPath];
        [self performSegueWithIdentifier:ETRUsersToConversationSegue sender:[record partner]];
    } else {
        // The Index Path gives Section 1 but the Fetched Results Controller assumes its values are in Section 0.
        NSIndexPath * alignedPath = [NSIndexPath indexPathForRow:[indexPath row] inSection:0];
        ETRUser * record = [_usersResultsController objectAtIndexPath:alignedPath];
        [self performSegueWithIdentifier:ETRUsersToConversationSegue sender:record];
    }
}

- (IBAction)mapButtonPressed:(id)sender {
    [self performSegueWithIdentifier:ETRUsersToMapSegue sender:self];
}

- (IBAction)profileButtonPressed:(id)sender {
    [self performSegueWithIdentifier:ETRUsersToProfileSegue
                              sender:[[ETRLocalUserManager sharedManager] user]];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    id destination = [segue destinationViewController];
    
    if ([destination isKindOfClass:[ETRConversationViewController class]]) {
        if ([sender isKindOfClass:[ETRUser class]]) {
            ETRConversationViewController *viewController;
            viewController = (ETRConversationViewController *)destination;
            [viewController setPartner:sender];
        }
        return;
    }
    
    //    if ([destination isKindOfClass:[ETRMapViewController class]]) {
    //        return;
    //    }
    
    if ([destination isKindOfClass:[ETRDetailsViewController class]]) {
        if (sender && [sender isKindOfClass:[ETRUser class]]) {
            ETRDetailsViewController * profileViewController;
            profileViewController = (ETRDetailsViewController *)destination;
            [profileViewController setUser:(ETRUser *)sender];
        }
    }
}

@end
