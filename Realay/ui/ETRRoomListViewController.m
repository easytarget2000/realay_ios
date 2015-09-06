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
#import "ETRImageEditor.h"
#import "ETRImageView.h"
#import "ETRInformationCell.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationManager.h"
#import "ETRLoginViewController.h"
#import "ETRFormatter.h"
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

@property (strong, nonatomic) NSMutableDictionary * imageDownloadsInProgress;

@property (nonatomic) BOOL didAppear;

@property (nonatomic) BOOL doHideInformationView;

@property (nonatomic) BOOL doShowDistances;

@end


@implementation ETRRoomListViewController

@synthesize fetchedResultsController = _fetchedResultsController;


#pragma mark - 
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _didAppear = NO;
    
    // Initialize Fetched Results Controller
    _fetchedResultsController = [ETRCoreDataHelper roomListResultsController];
    [_fetchedResultsController setDelegate:self];
    NSError * error = nil;
    [_fetchedResultsController performFetch:&error];
    if (error) {
        NSLog(@"ERROR: %@ viewDidLoad: %@", [[self class] description], error);
    }
    
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
    
    [self setImageDownloadsInProgress:[NSMutableDictionary dictionary]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateDistanceVisiblity];
    
    // Reenable the Fetched Results Controller.
    [_fetchedResultsController setDelegate:self];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:NO];
    
    // Send a notification when the device is rotated.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    ETRSessionManager * sessionMan = [ETRSessionManager sharedManager];
    if ([sessionMan restoreSession]) {
        if ([ETRLocationManager isInSessionRegionWithIntervalCheck:NO]) {
            // isInSessionRegion implies that a Session Room has been set.
            // Check if the Session has already been started.
            if ([sessionMan didStartSession] && [sessionMan room]) {
                [super pushToPublicConversationViewController];
                return;
            } else {
                // Usually a reconnect is neccessary,
                // because the app has been restarted at this point.
                [super pushToJoinViewController];
                return;
            }
        }
#ifdef DEBUG
        else {
            NSLog(@"Stored Session will not be restored due to distance.");
        }
#endif
    }
    
    [[self tableView] reloadData];
    [[self refreshIndicator] startAnimating];
    


    if ([[_fetchedResultsController fetchedObjects] count] > 0) {
        //            if ([ETRDefaultsHelper didRunOnce] && ![[self infoContainer] isHidden]) {
        // The app has been started once before and we are not going directly into a Session.
        [ETRAnimator fadeView:[self infoContainer] doAppear:NO completion:nil];
        //             }
    } else {
        [self setInformationViewHidden:NO];
        [self refreshButtonPressed:nil];
    }
    
    
    // Load any remaining images after a while, if the table is calm.
    dispatch_after(
                   dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
                   dispatch_get_main_queue(),
                   ^{
                       if (![[self tableView] isDragging] && ![[self tableView] isDecelerating]) {
                           [self loadImagesForOnScreenRows];
                       }
                   }
                   );
    _didAppear = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[self refreshIndicator] stopAnimating];
    [[self refreshIndicator] setHidden:YES];
    [[self refreshButton] setHidden:YES];
    
    if ([[self refreshControl] isRefreshing]) {
        [[self refreshControl] endRefreshing];
    }
    // Disable the Fetched Results Controller.
    [_fetchedResultsController setDelegate:nil];
    
    [[self refreshIndicator] stopAnimating];
    
    // Remove the orientation obsever.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

- (void)orientationChanged:(NSNotification *)notification {
    [[self tableView] reloadData];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self updateDistanceVisiblity];
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
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate: {
            UITableViewCell * cell = [[self tableView] cellForRowAtIndexPath:indexPath];
            if (cell && [cell isKindOfClass:[ETRRoomCell class]]) {
                [self configureRoomCell:(ETRRoomCell *)cell atIndexPath:indexPath];
            }
            break;
        }
        case NSFetchedResultsChangeMove:
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
            [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                    withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = [[_fetchedResultsController fetchedObjects] count];
    [self setInformationViewHidden:(numberOfRows > 0)];
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self roomCellAtIndexPath:indexPath];
}

- (ETRRoomCell *)roomCellAtIndexPath:(NSIndexPath *)indexPath {
    ETRRoomCell *cell;
    cell = [[self tableView] dequeueReusableCellWithIdentifier:ETRRoomCellIdentifier
                                                  forIndexPath:indexPath];
    if (!cell) {
        cell = [[ETRRoomCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:ETRRoomCellIdentifier];
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
        [[cell addressLabel] setText:[record address]];
    } else {
        NSString * coordinates;
        coordinates = [NSString stringWithFormat:@"%@, %@", [record longitude], [record latitude]];
        [[cell addressLabel] setText:coordinates];
    }
    
    int diameter = (int) [[record radius] integerValue] * 2;
    NSString * size = [ETRFormatter formattedIntLength:diameter];
    [[cell sizeLabel] setText:size];
    NSString * timeSpan = [ETRFormatter timeSpanForStartDate:[record startDate]
                                                     endDate:[record endDate]];
    [[cell hoursLabel] setText:timeSpan];
    
    // Display the distance to the closest region point.
    if (_doShowDistances) {
        [[cell distanceBadge] setHidden:NO];
        
        int distance = (int) [[record distance] integerValue];
        if (distance < 20) {
            [[cell distanceLabel] setHidden:YES];
            [[cell placeIcon] setHidden:NO];
        } else {
            [[cell placeIcon] setHidden:YES];
            [[cell distanceLabel] setHidden:NO];
            NSString * formattedDistance;
            formattedDistance = [ETRFormatter formattedIntLength:distance];
            [[cell distanceLabel] setText:formattedDistance];
        }
    } else {
        [[cell distanceBadge] setHidden:YES];
    }
    
    if (![[self tableView] isDragging] && ![[self tableView] isDecelerating]) {
        [ETRImageLoader loadImageForObject:record
                                  intoView:[cell headerImageView]
                          placeHolderImage:[UIImage imageNamed:ETRImageNameRoomPlaceholder]
                               doLoadHiRes:YES];
    } else {
        if ([record lowResImage]) {
            [ETRImageEditor cropImage:[record lowResImage]
                            imageName:[record imageFileName:NO]
                          applyToView:[cell headerImageView]];
        } else {
            [[cell headerImageView] setImage:[UIImage imageNamed:ETRImageNameRoomPlaceholder]];
        }
    }
}

- (void)updateDistanceVisiblity {
    if ([ETRLocationManager location]) {
        _doShowDistances = [ETRLocationManager didAuthorizeWhenInUse];
    } else {
        _doShowDistances = NO;
    }
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Hide the selection, prepare the Session and go to the Room Map.
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ETRRoom *record = [_fetchedResultsController objectAtIndexPath:indexPath];
    [[ETRSessionManager sharedManager] prepareSessionInRoom:record navigationController:[self navigationController]];
        
    [self performSegueWithIdentifier:ETRSegueRoomsToMap sender:record];
}

#pragma mark -
#pragma mark Manual Refresh

- (void)refreshRoomList {
    [[ETRLocationManager sharedManager] launch:nil];
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
        
        [self setInformationViewHidden:didReceive];
    }];
}


#pragma mark -
#pragma mark Information View

- (void)setInformationViewHidden:(BOOL)isHidden {
    NSString * nearYouTitle = NSLocalizedString(@"Near_You", @"Rooms Nearby");
    
    if (!_didAppear) {
        if (isHidden) {
            [self setTitle:nearYouTitle];
        }
        return;
    }
    
    _doHideInformationView = isHidden;
    
    [[self infoLabel] setHidden:_doHideInformationView];
    [[self refreshButton] setHidden:_doHideInformationView];
    [[self refreshIndicator] setHidden:YES];
    
    if (_doHideInformationView) {
        [self setTitle:nearYouTitle];
    } else {
        NSString * infoText;
        if ([ETRLocationManager didAuthorizeWhenInUse]) {
            infoText = NSLocalizedString(@"No_Realays_found", @"No Rooms nearby");
        } else {
            infoText = NSLocalizedString(@"Enable_location", @"Authorize to see list");
        }
        [[self infoLabel] setText:infoText];
        [self setTitle:@""];
    }
    
    [ETRAnimator fadeView:[self infoContainer]
                 doAppear:!_doHideInformationView
               completion:nil];
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
#pragma mark UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForOnScreenRows];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                 willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadImagesForOnScreenRows];
    }
}

- (void)loadImagesForOnScreenRows {
    if ([[self tableView] numberOfRowsInSection:0] > 0) {

        
        NSArray * visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath * indexPath in visiblePaths) {
            ETRRoomCell * cell;
            cell = (ETRRoomCell *)[[self tableView] cellForRowAtIndexPath:indexPath];
            
            
            [ETRImageLoader loadImageForObject:[_fetchedResultsController objectAtIndexPath:indexPath]
                                      intoView:[cell headerImageView]
                              placeHolderImage:nil
                                   doLoadHiRes:YES];
        }
    }
}

#pragma mark -
#pragma mark Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:ETRSegueRoomsToLogin]) {
        // Create my profile before showing it.
        
        // Tell the Create Profile controller where to go next.
        ETRLoginViewController * destination = [segue destinationViewController];
        [destination showProfileOnLogin];
        
    }
}

@end
