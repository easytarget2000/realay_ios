//
//  RoomListViewController.m
//  Realay
//
//  Created by Michel on 18.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRRoomListViewController.h"

#import "ETRCreateProfileViewController.h"
#import "ETRHTTPHandler.h"
#import "ETRImageLoader.h"
#import "ETRSession.h"
#import "ETRRoom.h"
#import "ETRInformationCell.h"
#import "ETRRoomListCell.h"
#import "ETRAlertViewBuilder.h"
#import "ETRViewProfileViewController.h"

#import "SharedMacros.h"

#define kDefaultRangeInKm       15
#define kInfoCellIdentifier     @"infoCell"
#define kRoomCellHeight         380
#define kRoomCellIdentifier     @"roomCell"
#define kSegueToNext            @"roomListToMapSegue"
#define kSegueToCreateProfile   @"roomListToCreateProfileSegue"
#define kSegueToViewProfile     @"roomListToViewProfileSegue"

@implementation ETRRoomListViewController {
    UIActivityIndicatorView *_activityIndicator;       // Spinning wheel
    //    CLLocationManager *_locationManager;                // Updates user location
    NSArray *_roomsArray;                               // Stores all rooms
    NSMutableDictionary *_imageDownloadsInProgress;     // Stores image downloads
    BOOL _locationIsUnknown;                            // For information cell
    NSInteger _noRoomFoundCounter;                      // For information cell
    NSInteger _nilArrayCounter;                         // For information cell
}

#pragma mark - UIViewController Overrides

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    NSInteger myControllerIndex;
    myControllerIndex = [[[self navigationController] viewControllers] count] - 1;
    [[ETRSession sharedSession] setRoomListControllerIndex:myControllerIndex];
    
    // Initialise failure variable.
    _noRoomFoundCounter = 0;
    _nilArrayCounter = 0;
    _locationIsUnknown = NO;
    
    // Refreshing:
    [[self refreshControl] addTarget:self
                              action:@selector(updateRoomsTable)
                    forControlEvents:UIControlEventValueChanged];
    
    // Adjust the location manager and act as its delegate for now.
    [[ETRSession sharedSession] resetLocationManager];
    [[[ETRSession sharedSession] locationManager] setDelegate:self];
    
    [_activityIndicator setColor:[UIColor whiteColor]];
    [_activityIndicator stopAnimating];
    
    NSLog(@"\n\nINFO: ETRoomListViewController viewWillAppear");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do not go back.
    [[self navigationItem] setHidesBackButton:YES];
    
    // Do not display empty cells at the end.
    [[self tableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    // Show an activity indicator (circle).
    _activityIndicator = [[UIActivityIndicatorView alloc]
                          initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [_activityIndicator setCenter:[[self view] center]];
    //[[self view] addSubview:_activityIndicator];
    
    [[self tableView] reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Just in case there is a toolbar wanting to be displayed:
    [[self navigationController] setToolbarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_activityIndicator stopAnimating];
    if ([[self refreshControl] isRefreshing]) [[self refreshControl] endRefreshing];
}

- (void)dealloc {
    NSLog(@"WARNING: ETRoomListViewController DEALLOC");
}

- (void)threadStartAnimating:(id)data {
    [_activityIndicator startAnimating];
}

#pragma mark - CLLocationManagerDelegate

// This method will be called when the location was updated successfully.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
#ifdef DEBUG
    NSLog(@"INFO: Device coordinates for room list query: %g %g",
          manager.location.coordinate.latitude,
          manager.location.coordinate.longitude);
#endif
    _locationIsUnknown = NO;
    [self updateRoomsTable];
}

// An error occured trying to get the device location.
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    //TODO: Handle error message.
    NSLog(@"ERROR: %@", error);
    _locationIsUnknown = YES;
    
    // Display info cell.
    [[self tableView] reloadData];
}

#pragma mark - UITableViewDataSource

- (void)updateRoomsTable {
    
    // Start the activity indicator spin.
    [NSThread detachNewThreadSelector:@selector(threadStartAnimating:)
                             toTarget:self
                           withObject:nil];
    
    // Stop refreshing the table.
    [[self refreshControl] endRefreshing];
    
    // The actual download of room data:
    _roomsArray = [ETRHTTPHandler queryRoomListInRadius:kDefaultRangeInKm];
    
    if ([_roomsArray count] > 0) {
        // A list of rooms was received.
        // Reset error counter.
        _noRoomFoundCounter = 0;
        _nilArrayCounter = 0;
        [_activityIndicator stopAnimating];
        
    } else if ([_roomsArray count] == 0) {
        // No room was found. The reason is unknown.
        _noRoomFoundCounter++;
        
        if (!_roomsArray) {
            //TODO: Handle DB Errors
            NSLog(@"ERROR: Database connection keeps failing.");
        }
    }
    
#ifdef DEBUG
    NSLog(@"INFO: Updated rooms table: %ld, %ld", [_roomsArray count], _noRoomFoundCounter);
#endif
    
    // Put the data into the table or at least display an info cell.
    [[self tableView] reloadData];
}

// This table only has one section.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

/**
 Get the number of rows for this table.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!_roomsArray) return 1;
    else if ([_roomsArray count] < 1) return 1;
    else return [_roomsArray count];
}

// Set up the table cells.
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //Add a placeholder cell while waiting for table data.
    if ([_roomsArray count] == 0 && [indexPath row] == 0) {
        ETRInformationCell *loadingCell = [tableView
                                        dequeueReusableCellWithIdentifier:kInfoCellIdentifier];
        
        if (!loadingCell) {
            loadingCell = [[ETRInformationCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                    reuseIdentifier:kInfoCellIdentifier];
        }
        
        // TODO: Button to location menu
        // TODO: Localization
        if (_locationIsUnknown) {
            NSString *statusNoLocation = @"Please allow Realay to find places near your location.\n\nPull down to refresh.";
            [[loadingCell infoLabel] setText:statusNoLocation];
        } else if (_noRoomFoundCounter > 5) {
            NSString *radius = [ETRChatObject lengthFromMetres:(kDefaultRangeInKm * 1000)];
            NSString *statusNoRooms = [NSString stringWithFormat:
                           @"No Realays found in a %@ radius.\n\nPull down to refresh.", radius];
            [[loadingCell textLabel] setText:statusNoRooms];
            [_activityIndicator stopAnimating];
        } else {
            NSString *searching = @"Searching for Realays...";
            [[loadingCell infoLabel] setText:searching];
        }
        
        // Configure the information text label.
        [[loadingCell textLabel] setTextColor:[UIColor grayColor]];
        [[loadingCell textLabel] setLineBreakMode:NSLineBreakByWordWrapping];
        [[loadingCell textLabel] setNumberOfLines:0];
        [[loadingCell textLabel] setTextAlignment:NSTextAlignmentCenter];
        [[loadingCell textLabel] setFont:[UIFont systemFontOfSize:14.0f]];
        
        return loadingCell;
    }
    
    /*
     We have found rooms. Give useful cells.
     */
    ETRRoomListCell *roomCell = [tableView
                                 dequeueReusableCellWithIdentifier:kRoomCellIdentifier];
    if (!roomCell) {
        roomCell = [[ETRRoomListCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:kRoomCellIdentifier];
    }

    //[[[roomCell contentView] layer] setShadowOffset:CGSizeMake(1, -1)];
    //[[[roomCell contentView] layer] setShadowOpacity:0.5f];
    
    // Get a Room from the RoomList and apply its attributes to the cell views.
    ETRRoom *currentRoom = [_roomsArray objectAtIndex:indexPath.row];
    [[roomCell titleLabel] setText:[currentRoom title]];
    [[roomCell sizeLabel] setText:[currentRoom size]];
    [[roomCell timeLabel] setText:[currentRoom timeSpan]];
    [[roomCell descriptionLabel] setText:[currentRoom info]];
    
    // Display the distance to the closest region point.
    ETRLocationManager *locMan = [[ETRSession sharedSession] locationManager];
    if ([locMan distanceToRoom:currentRoom] < 10) {
        [[roomCell distanceLabel] setHidden:YES];
        [[roomCell placeIcon] setHidden:NO];
    } else {
        [[roomCell placeIcon] setHidden:YES];
        [[roomCell distanceLabel] setHidden:NO];
        [[roomCell distanceLabel] setText:[locMan readableDistanceToRoom:currentRoom]];
    }
    
//    [self startIconDownload:currentRoom forIndexPath:indexPath];
    [ETRImageLoader loadImageForObject:currentRoom intoView:[roomCell headerImageView] doLoadHiRes:YES];
    [[roomCell headerImageView] setTag:[indexPath row]];
    return roomCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_roomsArray count] == 0) return tableView.bounds.size.height;
    else return kRoomCellHeight;
}

#pragma mark - Cell Icon Support

//- (void)startIconDownload:(ETRRoom *)room forIndexPath:(NSIndexPath *)indexPath {
//    // See if there is a download on the dict stack.
//    ETRImageLoader *iconDownloader = [_imageDownloadsInProgress objectForKey:indexPath];
//    
//    if (iconDownloader == nil) {
//        iconDownloader = [[ETRImageLoader alloc] initWithObject:room];
//        
//        [iconDownloader setCompletionHandler:^{
//            // After downloading, add the image to the appropriate cell.
//            ETRRoomListCell *roomCell;
//            roomCell = (ETRRoomListCell *)[[self tableView] cellForRowAtIndexPath:indexPath];
//            [self applyImage:[room lowResImage] toRoomCell:roomCell];
//            
//            // Remove the downloader from the in-progress list.
//            [_imageDownloadsInProgress removeObjectForKey:indexPath];
//        }];
//        
//        // Add the object to the progress stack after giving it a useful completion handler.
//        [_imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
//        [iconDownloader startLoading];
//    }
//}

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
//    if ([_roomsArray count] > 0) {
//        NSArray *visiblePaths = [[self tableView] indexPathsForVisibleRows];
//        
//        for (NSIndexPath *indexPath in visiblePaths) {
//            ETRRoom *currentRoom = [_roomsArray objectAtIndex:[indexPath row]];
//            
//            if (![currentRoom lowResImage]) {
//                [self startIconDownload:currentRoom forIndexPath:indexPath];
//            }
//            
//        }
//    }
    
}

#pragma mark - Navigation



// User touched a table row.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_roomsArray count] < 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        return;
    }
    
    // Start the activity indicator spin.
    [NSThread detachNewThreadSelector:@selector(threadStartAnimating:)
                             toTarget:self
                           withObject:nil];
    [[ETRSession sharedSession] prepareSessionInRoom:[_roomsArray objectAtIndex:[indexPath row]]
                                navigationController:[self navigationController]];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [_activityIndicator stopAnimating];
    [self performSegueWithIdentifier:kSegueToNext sender:nil];
}

// Create or view my profile.
- (IBAction)profileButtonPressed:(id)sender {
    if ([[ETRLocalUser sharedLocalUser] userID] > 10) {
        [self performSegueWithIdentifier:kSegueToViewProfile sender:self];
    } else {
        [self performSegueWithIdentifier:kSegueToCreateProfile sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:kSegueToCreateProfile]) {
        // Create my profile before showing it.
        
        // Tell the Create Profile controller where to go next.
        ETRCreateProfileViewController *destination = [segue destinationViewController];
        [destination setGoToOnFinish:kEnumGoToViewProfile];
        
    } else if([[segue identifier] isEqualToString:kSegueToViewProfile]) {
        // Just show my own user profile.
        
        ETRViewProfileViewController *destination = [segue destinationViewController];
        [destination setShowMyProfile:YES];
        //TODO: Tell the View Profile controller to come back to the Room List on Back.
    }
    
}

@end
