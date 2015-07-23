//
//  JoinRoomViewController.m
//  Realay
//
//  Created by Michel on 23.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRMapViewController.h"

#import "ETRAnimator.h"
#import "ETRDetailsViewController.h"
#import "ETRLocationManager.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"


static NSString *const ETRSegueMapToDetails = @"MapToDetails";

static NSString *const ETRSegueMapToPassword = @"MapToPassword";

static NSString *const ETRSegueMapToShare = @"MapToShare";


@interface ETRMapViewController () <MKMapViewDelegate>

@property (nonatomic) BOOL didSetUpMap;

@end


@implementation ETRMapViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[[self navigationController] navigationBar] setTranslucent:NO];
    [[self navigationController] setToolbarHidden:NO animated:NO];
    
    // Basic GUI setup:
    [self setTitle:[[ETRSessionManager sessionRoom] title]];
    
    // Hide the join button if the user is already in this room.
    if ([[ETRSessionManager sharedManager] didStartSession]) {
        UIBarButtonItem * barButton;
        barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Share", @"Share location")
                                                     style:UIBarButtonItemStylePlain
                                                    target:self
                                                    action:@selector(shareButtonPressed:)];
        [[self navigationItem] setRightBarButtonItem:barButton];
        [self setDirectionsButton:nil];
    } else {
        [[self navigationItem] setRightBarButtonItem:[self joinButton]];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setUpMap];
}

- (void)viewWillDisappear:(BOOL)animated {
    _didSetUpMap = NO;
    
    NSArray * currentAnnotations = [[self mapView] annotations];
    if (currentAnnotations) {
        [[self mapView] removeAnnotations:currentAnnotations];
    }
    
    NSArray * currentOverlays = [[self mapView] overlays];
    if (currentOverlays) {
        [[self mapView] removeOverlays:currentOverlays];
    }
    
    
    [[self mapView] setUserTrackingMode:MKUserTrackingModeNone];
    [[self mapView] setShowsUserLocation:NO];
    [[self mapView] setDelegate:nil];
    
    [super viewWillDisappear:animated];
}

- (void)setUpMap {
    // Create the room marker.
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    if (!sessionRoom) {
        NSLog(@"ERROR: %@: Cannot start without a prepared Session Room.", [self class]);
        [[self navigationController] popToRootViewControllerAnimated:YES];
        return;
    }
    
    CLLocationDistance regionDistance;
    CLLocation * location = [ETRLocationManager location];
    CLLocationDistance radius = [[sessionRoom radius] doubleValue];
    
    if (!location) {
        regionDistance = 500.0;
    } else {
        regionDistance = [location distanceFromLocation:[sessionRoom location]];
        if (regionDistance < radius) {
            regionDistance = radius * 4.0;
        } else {
            regionDistance *= 4.0;
        }
    }
    
    CLLocationCoordinate2D roomCoordinate = sessionRoom.location.coordinate;
    
    MKCoordinateRegion roomRegion;
    roomRegion = MKCoordinateRegionMakeWithDistance(roomCoordinate, regionDistance, regionDistance);
    
    //    MKCoordinateRegion visibleRegion = [[self mapView] regionThatFits:roomRegion];
    [[self mapView] setRegion:roomRegion animated:NO];
    [[self mapView] setUserTrackingMode:MKUserTrackingModeNone];
    [[self mapView] setShowsUserLocation:YES];
    [[self mapView] setShowsPointsOfInterest:YES];
    [[self mapView] setDelegate:self];
    
    MKPointAnnotation * roomAnnotation = [[MKPointAnnotation alloc] init];
    [roomAnnotation setTitle:[sessionRoom title]];
    [roomAnnotation setCoordinate:roomCoordinate];
    [[self mapView] addAnnotation:roomAnnotation];
    
    MKCircle * circle = [MKCircle circleWithCenterCoordinate:roomCoordinate radius:radius];
    [[self mapView] addOverlay:circle];
}

#pragma mark -
#pragma mark MKMapView

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    MKCircleView * circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    [circleView setFillColor:[ETRUIConstants primaryColor]];
    [circleView setStrokeColor:[ETRUIConstants primaryTransparentColor]];
    [circleView setAlpha:0.5f];
    return circleView;
}

- (IBAction)mapTypeSegmentChanged:(id)sender {
    if ([[self mapTypeSegmentedControl] selectedSegmentIndex] == 0) {
        [_mapView setMapType:MKMapTypeStandard];
    } else {
        [_mapView setMapType:MKMapTypeHybrid];
    }
}

#pragma mark -
#pragma mark Navigation

- (IBAction)navigateButtonPressed:(id)sender {
    
    ETRRoom * sessionRoom = [[ETRSessionManager sharedManager] room];
    NSString * address;
    if ([[sessionRoom address] length] > 4) {
        address = [sessionRoom address];
    } else {
        address = [NSString stringWithFormat:@"%@,%@", [sessionRoom longitude], [sessionRoom latitude]];
    }
    
    NSString * URLString;
    NSURL * gmapsURL = [NSURL URLWithString:@"comgooglemaps://"];
    
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
    [self performSegueWithIdentifier:ETRSegueMapToDetails sender:self];
}

- (IBAction)cancelShareButtonPressed:(id)sender {
    [ETRAnimator toggleBounceInView:[self sharePanel] animateFromTop:YES completion:nil];
}

- (IBAction)joinButtonPressed:(id)sender {
    [super joinButtonPressed:sender joinSegue:ETRSegueMapToPassword];
}

- (IBAction)shareButtonPressed:(id)sender {
    [self performSegueWithIdentifier:ETRSegueMapToShare sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:ETRSegueMapToDetails]) {
        ETRDetailsViewController * destination;
        destination = [segue destinationViewController];
        [destination setRoom:[[ETRSessionManager sharedManager] room]];
    }
}

@end
