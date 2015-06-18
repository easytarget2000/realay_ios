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
#import "ETRRoomCell.h"
#import "ETRServerAPIHelper.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"


static CGFloat const ETRRoomCellHeight = 424.0f;

static NSString *const ETRRoomCellIdentifier = @"RoomCell";

static NSString *const ETRSegueRoomsToMap = @"RoomsToMap";

static NSString *const ETRSegueRoomsToLogin = @"RoomsToLogin";

static NSString *const ETRSegueRoomsToSettings = @"RoomsToSettings";

@interface ETRRoomListViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) UIRefreshControl * refreshControl;

@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;

@property (nonatomic) BOOL doHideInformationView;

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
                       action:@selector(refreshRoomList)
             forControlEvents:UIControlEventValueChanged];
    [refreshControl setTintColor:[ETRUIConstants accentColor]];
    [[self tableView] addSubview:refreshControl];
    [self setRefreshControl:refreshControl];
    
    [[self infoContainer] setHidden:![ETRDefaultsHelper didRunOnce]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // (Re-)enable the Fetched Results Controller.
    [_fetchedResultsController setDelegate:self];
    // Perform Fetch
    NSError * error = nil;
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
    
    ETRSessionManager * sessionMan = [ETRSessionManager sharedManager];
    if ([sessionMan didBeginSession] && [sessionMan room]) {
        [super pushToPublicConversationViewController];
    } else if ([sessionMan restoreSession]) {
        [super pushToJoinViewController];
    } else {
        [[self tableView] reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[self refreshIndicator] stopAnimating];
    [[self refreshIndicator] setHidden:YES];
    [[self refreshButton] setHidden:_doHideInformationView];
    
    if ([[self refreshControl] isRefreshing]) {
        [[self refreshControl] endRefreshing];
    }
    // Disable the Fetched Results Controller.
    [_fetchedResultsController setDelegate:nil];
}

#pragma mark -
#pragma mark Information View

- (void)setInformationViewHidden:(BOOL)isHidden {
//    BOOL wasHidden = _doHideInformationView;
    _doHideInformationView = isHidden;
//    
//    if (wasHidden == _doHideInformationView) {
//        return;
//    }
    
    [[self infoLabel] setHidden:_doHideInformationView];
    [[self refreshButton] setHidden:_doHideInformationView];
    [[self refreshIndicator] setHidden:YES];
    
    if (_doHideInformationView) {
        [self setTitle:NSLocalizedString(@"Near_You", @"Rooms Nearby")];
    } else {
        [self setTitle:@""];
    }
    
    [ETRAnimator fadeView:[self infoContainer] doAppear:!_doHideInformationView completion:nil];
//    [ETRAnimator toggleBounceInView:[self infoContainer] animateFromTop:YES completion:nil];
}

/*
 Hide the button, show the indicator and get the entire Room List from the Server.
 */
- (IBAction)refreshButtonPressed:(id)sender {
    [[self refreshButton] setHidden:YES];
    [[self refreshIndicator] startAnimating];
    [ETRAnimator fadeView:[self refreshIndicator]
                 doAppear:YES
               completion:^{
                   [self refreshRoomList];
               }];
}

#pragma mark -
#pragma mark Fetched Results Controller Delegate Methods

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self refreshControl] endRefreshing];
    [[self tableView] endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert: {
            [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete: {
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate: {
            UITableViewCell * cell = [[self tableView] cellForRowAtIndexPath:indexPath];
            if (cell && [cell isKindOfClass:[ETRRoomCell class]]) {
                [self configureRoomCell:(ETRRoomCell *)cell atIndexPath:indexPath];
            }
            break;
        }
        case NSFetchedResultsChangeMove: {
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
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
    
    [self setInformationViewHidden:(numberOfRows > 0)];
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self roomCellAtIndexPath:indexPath];
}

- (ETRRoomCell *)roomCellAtIndexPath:(NSIndexPath *)indexPath {
    ETRRoomCell *cell;
    cell = [[self tableView] dequeueReusableCellWithIdentifier:ETRRoomCellIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[ETRRoomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ETRRoomCellIdentifier];
    }
    
    [self configureRoomCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureRoomCell:(ETRRoomCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Get the Room Record from the ResultsController
    // and apply its attributes to the cell views.
    ETRRoom * record = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    [[cell titleLabel] setText:[record title]];
    
    if ([[record address] length]) {
//        [[cell keyLabel] setText:NSLocalizedString(@"Address", @"Physical address")];
        [[cell addressLabel] setText:[record address]];
    } else {
//        [[cell keyLabel] setText:NSLocalizedString(@"Coordinates", @"GPS Coordinates")];
        NSString * coordinates;
        coordinates = [NSString stringWithFormat:@"%@, %@", [record longitude], [record latitude]];
        [[cell addressLabel] setText:coordinates];
    }
    
    NSString *size = [ETRReadabilityHelper formattedLength:[record radius]];
    [[cell sizeLabel] setText:size];
    [[cell hoursLabel] setText:[record hours]];
    
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

#pragma mark -
#pragma mark Table View Delegate Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self setInformationViewHidden:!_doHideInformationView];

    // Hide the selection, prepare the Session and go to the Room Map.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ETRRoom *record = [_fetchedResultsController objectAtIndexPath:indexPath];
    [[ETRSessionManager sharedManager] prepareSessionInRoom:record navigationController:[self navigationController]];
    
    NSLog(@"Did select Room: %ld", [[record remoteID] longValue]);
    
    [self performSegueWithIdentifier:ETRSegueRoomsToMap sender:record];
}

#pragma mark - UITableViewDataSource

- (void)refreshRoomList {
    [ETRServerAPIHelper updateRoomListWithCompletionHandler:^(BOOL didReceive) {
        // If no Rooms were received, end refreshing immediately.
        // Otherwise the Table update will end the refresh.
        [[self refreshIndicator] stopAnimating];
        [[self refreshIndicator] setHidden:YES];
        if (!_doHideInformationView) {
            [ETRAnimator fadeView:[self refreshButton] doAppear:YES completion:nil];
        }
        
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


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:ETRSegueRoomsToLogin]) {
        // Create my profile before showing it.
        
        // Tell the Create Profile controller where to go next.
        ETRLoginViewController * destination = [segue destinationViewController];
        [destination showProfileOnLogin];
        
    }
}

@end
