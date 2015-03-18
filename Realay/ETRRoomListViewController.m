//
//  RoomListViewController.m
//  Realay
//
//  Created by Michel on 18.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRRoomListViewController.h"

#import "ETRAlertViewFactory.h"
#import "ETRCoreDataHelper.h"
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

//#import "ETRSharedMacros.h"

#define kDefaultRangeInKm       15
#define kInfoCellIdentifier     @"infoCell"
#define kRoomCellHeight         380
#define kRoomCellIdentifier     @"roomCell"
#define kMapSegueIdentifier     @"roomListToMapSegue"
#define kSegueToCreateProfile   @"roomListToLoginSegue"
#define kSegueToViewProfile     @"roomListToProfileSegue"

@interface ETRRoomListViewController () <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@end

@implementation ETRRoomListViewController

@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark - UIViewController Overrides

#pragma mark -
#pragma mark View Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do not go back.
    [[self navigationItem] setHidesBackButton:YES];
    
    // Do not display empty cells at the end.
    [[self tableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    [[self tableView] setRowHeight:UITableViewAutomaticDimension];
    [[self tableView] setEstimatedRowHeight:kRoomCellHeight];
        
    // Initialize Fetched Results Controller
    _fetchedResultsController = [ETRCoreDataHelper roomListResultsControllerWithDelegate:self];
    
    // Perform Fetch
    NSError *error = nil;
    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"ERROR: performFetch: %@", error);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Refreshing:
    [[self refreshControl] addTarget:self
                              action:@selector(updateRoomsTable)
                    forControlEvents:UIControlEventValueChanged];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //    NSInteger myControllerIndex;
    //    myControllerIndex = [[[self navigationController] viewControllers] count] - 1;
    //    [[ETRSession sharedManager] setRoomListControllerIndex:myControllerIndex];
    
    //    // Refreshing:
    //    [[self refreshControl] addTarget:self
    //                              action:@selector(updateRoomsTable)
    //                    forControlEvents:UIControlEventValueChanged];
    [[self tableView] reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([[self refreshControl] isRefreshing]) {
        [[self refreshControl] endRefreshing];
    }
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
    if (!_fetchedResultsController || ![[_fetchedResultsController fetchedObjects] count]) {
        return 0;
    }
    
    id<NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
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
    cell = [[self tableView] dequeueReusableCellWithIdentifier:kRoomCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[ETRRoomListCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kRoomCellIdentifier];
    }
    
    [self configureRoomCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureRoomCell:(ETRRoomListCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    //[[[roomCell contentView] layer] setShadowOffset:CGSizeMake(1, -1)];
    //[[[roomCell contentView] layer] setShadowOpacity:0.5f];
    
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
        NSString *formattedDistance;
        formattedDistance = [ETRReadabilityHelper formattedIntegerLength:distance];
        [[cell distanceLabel] setText:formattedDistance];
    }
    
    //    [self startIconDownload:currentRoom forIndexPath:indexPath];
    [ETRImageLoader loadImageForObject:record intoView:[cell headerImageView] doLoadHiRes:YES];
    [[cell headerImageView] setTag:[indexPath row]];
}

- (ETRInformationCell *)infoCellAtIndexPath:(NSIndexPath *)indexPath {
    
    ETRInformationCell *cell;
    cell = [[self tableView] dequeueReusableCellWithIdentifier:kInfoCellIdentifier
                                                  forIndexPath:indexPath];
    if (!cell) {
        cell = [[self tableView] dequeueReusableCellWithIdentifier:kInfoCellIdentifier];
    }
    ETRInformationCell *infoCell = (ETRInformationCell *) cell;
    
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
    NSString *searching = @"Searching for Realays...";
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
    
    [self performSegueWithIdentifier:kMapSegueIdentifier sender:record];
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
        [self performSegueWithIdentifier:kSegueToViewProfile sender:self];
    } else {
        [self performSegueWithIdentifier:kSegueToCreateProfile sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:kSegueToCreateProfile]) {
        // Create my profile before showing it.
        
        // Tell the Create Profile controller where to go next.
        ETRLoginViewController *destination = [segue destinationViewController];
        [destination showProfileOnLogin];
        
    } else if([[segue identifier] isEqualToString:kSegueToViewProfile]) {
        // Just show my own user profile.
        
        ETRDetailsViewController *destination = [segue destinationViewController];
        [destination setUser:[[ETRLocalUserManager sharedManager] user]];
        //TODO: Tell the View Profile controller to come back to the Room List on Back.
    }
    
}

@end
