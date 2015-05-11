//
//  RoomListViewController.m
//  Realay
//
//  Created by Michel on 18.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRRoomListViewController.h"

#import "ETRAnimator.h"
#import "ETRCoreDataHelper.h"
#import "ETRDefaultsHelper.h"
#import "ETRDetailsViewController.h"
#import "ETRImageLoader.h"
#import "ETRInformationCell.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRLoginViewController.h"
#import "ETRReadabilityHelper.h"
#import "ETRRoom.h"
#import "ETRRoomListCell.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"


static CGFloat const ETRRoomCellHeight = 380.0f;

static NSString *const ETRInfoCellIdentifier = @"infoCell";

static NSString *const ETRRoomCellIdentifier = @"roomCell";

static NSString *const ETRRoomListToMapSegue = @"roomListToMapSegue";

static NSString *const ETRRoomListToLoginSegue = @"roomListToLoginSegue";

static NSString *const ETRRoomListToProfileSegue = @"roomListToProfileSegue";

@interface ETRRoomListViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) UIRefreshControl * refreshControl;

@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;

@end


@implementation ETRRoomListViewController

@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark - 
#pragma mark UIViewController Overrides

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize Fetched Results Controller
    _fetchedResultsController = [ETRCoreDataHelper roomListResultsController];
    
    // Do not go back.
    [[self navigationItem] setHidesBackButton:YES];
    
    // Do not display empty cells at the end.
    [[self tableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [[self tableView] setRowHeight:ETRRoomCellHeight];
    
    UIRefreshControl * refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self
                       action:@selector(updateRoomsTable)
             forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[ETRUIConstants accentColor]];
    [[self tableView] addSubview:refreshControl];
    [self setRefreshControl:refreshControl];
        

    if (![ETRDefaultsHelper didRunOnce]) {
        [[self infoView] setHidden:NO];
        [[self infoLabel] setHidden:NO];
        [self setTitle:@""];
    } else {
        [self setTitle:NSLocalizedString(@"Near_You", @"Rooms Nearby")];
    }
    
}

// TODO: Make sure the Status Bar Color is always white, especially after returning from media selection.

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // (Re-)enable the Fetched Results Controller.
    [_fetchedResultsController setDelegate:self];
    // Perform Fetch
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"ERROR: performFetch: %@", error);
    }
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self tableView] reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([[self refreshControl] isRefreshing]) {
        [[self refreshControl] endRefreshing];
    }
    // Disable the Fetched Results Controller.
    [_fetchedResultsController setDelegate:nil];
}

#pragma mark -
#pragma mark Fetched Results Controller Delegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self refreshControl] endRefreshing];
    if ([self tableView]) {
        [[self tableView] endUpdates];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            UITableViewCell *cell = [[self tableView] cellForRowAtIndexPath:indexPath];
            if (cell && [cell isKindOfClass:[ETRRoomListCell class]]) {
                [self configureRoomCell:(ETRRoomListCell *)cell atIndexPath:indexPath];
            }
            break;
        }
        case NSFetchedResultsChangeMove: {
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

#pragma mark -
#pragma mark Table View Data Source Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (!_fetchedResultsController) {
        return 0;
    } else {
        return [[_fetchedResultsController sections] count];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows;
    
    if (!_fetchedResultsController) {
        numberOfRows = 0;
    } else {
        numberOfRows = [[_fetchedResultsController fetchedObjects] count];
    }
    
    if (numberOfRows < 1) {
        [self setTitle:@""];
        [ETRAnimator fadeView:[self infoView] doAppear:YES];
    } else {
        [self setTitle:NSLocalizedString(@"Near_You", @"Rooms Nearby")];
        [ETRAnimator fadeView:[self infoView] doAppear:NO];
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![[_fetchedResultsController fetchedObjects] count]) {
        return [self infoCellAtIndexPath:indexPath];
    } else {
        return [self roomCellAtIndexPath:indexPath];
    }
}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//    if (![[_fetchedResultsController fetchedObjects] count]) {
//        return tableView.bounds.size.height;
//    } else {
//       return kRoomCellHeight;
//    }
//}

- (ETRRoomListCell *)roomCellAtIndexPath:(NSIndexPath *)indexPath {
    ETRRoomListCell *cell;
    cell = [[self tableView] dequeueReusableCellWithIdentifier:ETRRoomCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[ETRRoomListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ETRRoomCellIdentifier];
    }
    
    [self configureRoomCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureRoomCell:(ETRRoomListCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Get the Room Record from the ResultsController
    // and apply its attributes to the cell views.
    ETRRoom *record = [_fetchedResultsController objectAtIndexPath:indexPath];
    [[cell titleLabel] setText:[record title]];
    NSString *size = [ETRReadabilityHelper formattedLength:[record radius]];
    [[cell sizeLabel] setText:size];
    NSString *timeSpan = [ETRReadabilityHelper timeSpanForStartDate:[record startTime]
                                                            endDate:[record endDate]];
    [[cell timeLabel] setText:timeSpan];
    [[cell descriptionLabel] setText:[record summary]];
    
    // Display the distance to the closest region point.
    NSInteger distance = [[ETRLocationManager sharedManager] distanceToRoom:record];
    if (distance < 20) {
        [[cell distanceLabel] setHidden:YES];
        [[cell placeIcon] setHidden:NO];
    } else {
        [[cell placeIcon] setHidden:YES];
        [[cell distanceLabel] setHidden:NO];
        NSString * formattedDistance;
        formattedDistance = [ETRReadabilityHelper formattedIntegerLength:distance];
        [[cell distanceLabel] setText:formattedDistance];
    }
    
    [ETRImageLoader loadImageForObject:record
                              intoView:[cell headerImageView]
                      placeHolderImage:[UIImage imageNamed:ETRImageNameRoomPlaceholder]
                           doLoadHiRes:YES];
}

- (ETRInformationCell *)infoCellAtIndexPath:(NSIndexPath *)indexPath {
    
    ETRInformationCell * cell;
    cell = [[self tableView] dequeueReusableCellWithIdentifier:ETRInfoCellIdentifier
                                                  forIndexPath:indexPath];
    if (!cell) {
        cell = [[self tableView] dequeueReusableCellWithIdentifier:ETRInfoCellIdentifier];
    }
    ETRInformationCell * infoCell = (ETRInformationCell *) cell;
    
    // TODO: Button to location menu
    // TODO: Localization
    //        if (_locationIsUnknown) {
    //            NSString *statusNoLocation = @"Please allow Realay to find places near your location.\n\nPull down to refresh.";
    //            [[loadingCell infoLabel] setText:statusNoLocation];
    //        } else if (_noRoomFoundCounter > 5) {
    //            NSString *radius = [ETRChatObject lengthFromMetres:(kDefaultRangeInKm * 1000)];
    //            NSString *statusNoRooms = [NSString stringWithFormat:
    //                                       @"No Realays found in a %@ radius.\n\nPull down to refresh.", radius];
    //            [[loadingCell textLabel] setText:statusNoRooms];
    //            [_activityIndicator stopAnimating];
    //        } else {
    NSString * searching = @"Searching for Realays...";
    [[infoCell infoLabel] setText:searching];
    //        }
    
    cell = infoCell;
    return cell;
}

#pragma mark -
#pragma mark Table View Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // If the list only shows information cells and no Rooms, do not listen to selections.
    if (![[_fetchedResultsController fetchedObjects] count]) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }
    
    // Hide the selection, prepare the Session and go to the Room Map.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ETRRoom *record = [_fetchedResultsController objectAtIndexPath:indexPath];
    [[ETRSessionManager sharedManager] prepareSessionInRoom:record navigationController:[self navigationController]];
    
    NSLog(@"Did select Room: %ld", [[record remoteID] longValue]);
    
    [self performSegueWithIdentifier:ETRRoomListToMapSegue sender:record];
}

#pragma mark - UITableViewDataSource

- (void)updateRoomsTable {
    [ETRServerAPIHelper updateRoomListWithCompletionHandler:^(BOOL didReceive) {
        // If no Rooms were received, end refreshing immediately.
        // Otherwise the Table update will end the refresh.
        if (!didReceive) {
            [[self refreshControl] endRefreshing];
        }
        
        // TODO: End refreshing after a while.
    }];
}


#pragma mark - UIScrollViewDelegate

// In case of SCROLLING into a set of cells which do not have their icons yet,
// load the images at the end of the scroll.
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForOnScreenRows];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate {
    
    if (!decelerate) [self loadImagesForOnScreenRows];
}

- (void)loadImagesForOnScreenRows {
    
}

#pragma mark - Navigation

// Create or view my profile.
- (IBAction)profileButtonPressed:(id)sender {
    if ([ETRLocalUserManager userID] > 10) {
        [self performSegueWithIdentifier:ETRRoomListToProfileSegue sender:self];
    } else {
        [self performSegueWithIdentifier:ETRRoomListToLoginSegue sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:ETRRoomListToLoginSegue]) {
        // Create my profile before showing it.
        
        // Tell the Create Profile controller where to go next.
        ETRLoginViewController * destination = [segue destinationViewController];
        [destination showProfileOnLogin];
        
    } else if([[segue identifier] isEqualToString:ETRRoomListToProfileSegue]) {
        // Just show my own user profile.
        
        ETRDetailsViewController *destination = [segue destinationViewController];
        [destination setUser:[[ETRLocalUserManager sharedManager] user]];
        //TODO: Tell the View Profile controller to come back to the Room List on Back.
    }
    
}

@end
