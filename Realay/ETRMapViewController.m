//
//  JoinRoomViewController.m
//  Realay
//
//  Created by Michel on 23.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRMapViewController.h"

#import <GoogleMaps/GoogleMaps.h>

#import "ETRAlertViewFactory.h"
#import "ETRDetailsViewController.h"
#import "ETRLocationManager.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"


static CGFloat const ETRMapCloseZoom = 15.0f;

static CGFloat const ETRMapWideZoom = 11.0f;

static NSString *const ETRMapToPasswordSegue = @"mapToPasswordSegue";

static NSString *const ETRMapToDetailsSegue = @"mapToDetailsSegue";


@implementation ETRMapViewController {
    GMSMapView *_mapView;   // Google Maps SDK Object
}

#pragma mark -
#pragma mark UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[[self navigationController] navigationBar] setTranslucent:NO];
    
    // Basic GUI setup:
    [self setTitle:[[ETRSessionManager sessionRoom] title]];
    [[self navigationController] setToolbarHidden:NO animated:YES];
    
    // Hide the join button if the user is already in this room.
    if ([[ETRSessionManager sharedManager] didBeginSession]) {
        [[self navigationItem] setRightBarButtonItem:nil];
        [self setDirectionsButton:nil];
    } else {
        [[self navigationItem] setRightBarButtonItem:[self joinButton]];
    }
    
    // Send a notification when the device is rotated.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    NSInteger myControllerIndex;
    myControllerIndex = [[[self navigationController] viewControllers] count] - 1;
    [[ETRSessionManager sharedManager] setMapControllerIndex:myControllerIndex];
    
    // Make sure the room manager meets the requirements for this view controller.
    if (![[ETRSessionManager sharedManager] room]) {
        [[self navigationController] popViewControllerAnimated:NO];
        NSLog(@"ERROR: No room set in manager.");
        return;
    }
    
    
    _mapView = [[GMSMapView alloc] init];
    [_mapView setFrame:[[self mapSubView] bounds]];
    [_mapView setCamera:[self adjustedCamera]];
    
    // Other map settings:
    [_mapView setMyLocationEnabled:YES];
    [[_mapView settings] setMyLocationButton:YES];
    [[_mapView settings] setIndoorPicker:YES];
    [[self mapSubView] addSubview:_mapView];
    
    // Create the room marker.
    ETRRoom * room = [[ETRSessionManager sharedManager] room];
    if (!room) {
        NSLog(@"ERROR: Cannot start ETRMapViewController without a prepared Session Room.");
        return;
    }
    GMSMarker *roomMarker = [[GMSMarker alloc] init];
    
    [roomMarker setTitle:[room title]];
    [roomMarker setAppearAnimation:kGMSMarkerAnimationPop];
    [roomMarker setPosition:[[room location] coordinate]];
    [roomMarker setMap:_mapView];
    [_mapView setSelectedMarker:roomMarker];
    
    // Add a radius circle to the marker.
    GMSCircle *circle = [[GMSCircle alloc] init];
    [circle setRadius:[[room radius] doubleValue]];
    [circle setFillColor:[ETRUIConstants primaryTransparentColor]];
    [circle setStrokeColor:[ETRUIConstants primaryColor]];
    [circle setPosition:[roomMarker position]];
    [circle setMap:_mapView];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    // Remove the orientation obsever.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
    
    // Remove the map.
    _mapView = nil;
    
    // Check if the back button was pressed.
    NSInteger myNavIndex = [[[self navigationController] viewControllers] indexOfObject:self];
    if (myNavIndex == NSNotFound) {
        
        // If we didn't join this room, discard it.
        if (![[ETRSessionManager sharedManager] didBeginSession]) {
            [[ETRSessionManager sharedManager] endSession];
#ifdef DEBUG
            NSLog(@"INFO: Manager Room object reset.");
#endif
        }
    }
}

/*
 Readjusts the frame of the map when the device is rotated
 */
- (void)orientationChanged:(NSNotification *)notification {
    [_mapView setFrame:[[self mapSubView] bounds]];
}


#pragma mark - Google Maps

- (GMSCameraPosition *)adjustedCamera {
    
    // Get data from the session manager.
    CLLocation *currentLocation = [ETRLocationManager location];
    ETRRoom *room = [[ETRSessionManager sharedManager] room];
    
    // Decide which camera to show.
    if (currentLocation) {
        
        if ([ETRLocationManager isInSessionRegion]) {
            // Zoom in on the region, not the user, if the user is inside.
            
            // TODO: Determine a useful zoom level for different region radii.
            CGFloat zoom = ETRMapCloseZoom;
//            if ([room radius] < 250) zoom = 16;
            
            return [GMSCameraPosition cameraWithTarget:[[room location] coordinate]
                                                  zoom:zoom];
        } else {
            // The map should include the device position, as well as the room's location.
            GMSCoordinateBounds *bounds;
            
            bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:[currentLocation coordinate]
                                                          coordinate:[[room location] coordinate]];
            return [_mapView cameraForBounds:bounds insets:UIEdgeInsetsMake(70.0f, 70.0f, 70.0f, 70.0f)];
        }
    } else {
        // Just show where approximately the region is if the device location is unknown.
        // TODO: Use different zoom levels depending on the size of the radius.
        return [GMSCameraPosition cameraWithTarget:[[room location] coordinate]
                                              zoom:ETRMapWideZoom];
    }
}

#pragma mark - Toolbar Buttons

- (IBAction)mapTypeSegmentChanged:(id)sender {
    if ([[self mapTypeSegmentedControl] selectedSegmentIndex] == 0) {
        [_mapView setMapType:kGMSTypeNormal];
    } else {
        [_mapView setMapType:kGMSTypeSatellite];
    }
}

#pragma mark - Navigation

- (IBAction)navigateButtonPressed:(id)sender {
    NSString *URLString;
    
    NSURL *gmapsURL = [NSURL URLWithString:@"comgooglemaps://"];
    NSString *address = [[[ETRSessionManager sharedManager] room] address];
    if ([[UIApplication sharedApplication] canOpenURL:gmapsURL]) {
        URLString = [NSString stringWithFormat:@"comgooglemaps://?daddr=%@", address];
    } else {
        // No app was found that opens Google Maps URLs.
#ifdef DEBUG
        NSLog(@"INFO: Can not use comgooglemaps://.");
#endif
        URLString = [NSString stringWithFormat:@"http://maps.apple.com/?daddr=%@", address];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
}

- (IBAction)detailsButtonPressed:(id)sender {
    [self performSegueWithIdentifier:ETRMapToDetailsSegue sender:self];
}

- (IBAction)joinButtonPressed:(id)sender {
    // Only perform a join action, if the user did not join yet.
    if ([[ETRSessionManager sharedManager] didBeginSession]) {
        return;
    }
    
#ifdef DEBUG_JOIN
    [self performSegueWithIdentifier:ETRMapToPasswordSegue sender:nil];
#else
    if (![ETRLocationManager didAuthorize]) {
        // The location access has not been authorized.
        [ETRAlertViewFactory showAuthorizationAlert];
    } else if ([ETRLocationManager isInSessionRegion]) {
        // Show the password prompt, if the device location is inside the region.
        [self performSegueWithIdentifier:ETRMapToPasswordSegue sender:self];
    } else {
        // The user is outside of the radius.
        [ETRAlertViewFactory showRoomDistanceAlert];
    }
#endif
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:ETRMapToDetailsSegue]) {
        ETRDetailsViewController *destination;
        destination = [segue destinationViewController];
        [destination setRoom:[[ETRSessionManager sharedManager] room]];
    }
}

@end
