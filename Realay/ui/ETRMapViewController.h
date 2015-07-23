//
//  JoinRoomViewController.h
//  Realay
//
//  Created by Michel on 23.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRPrepareSessionViewController.h"

#import <MapKit/MapKit.h>

@interface ETRMapViewController : ETRPrepareSessionViewController

@property (weak, nonatomic) IBOutlet MKMapView * mapView;

@property (weak, nonatomic) IBOutlet UISegmentedControl * mapTypeSegmentedControl;

@property (weak, nonatomic) IBOutlet UIBarButtonItem * joinButton;

@property (weak, nonatomic) IBOutlet UIBarButtonItem * directionsButton;

@property (weak, nonatomic) IBOutlet UIView *sharePanel;

- (IBAction)joinButtonPressed:(id)sender;

- (IBAction)mapTypeSegmentChanged:(id)sender;

- (IBAction)navigateButtonPressed:(id)sender;

- (IBAction)detailsButtonPressed:(id)sender;

- (IBAction)cancelShareButtonPressed:(id)sender;

@end
