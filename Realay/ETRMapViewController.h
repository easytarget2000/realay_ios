//
//  JoinRoomViewController.h
//  Realay
//
//  Created by Michel on 23.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "ETRSession.h"

@interface ETRMapViewController : UIViewController

//@property (nonatomic) CLLocationCoordinate2D initialDeviceCoordinate;
@property (weak, nonatomic) IBOutlet UIView             *mapSubView;    // View for GMap
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapTypeSegmentedControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem    *joinButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem    *directionsButton;

- (IBAction)joinButtonPressed:(id)sender;
- (IBAction)mapTypeSegmentChanged:(id)sender;
- (IBAction)navigateButtonPressed:(id)sender;
- (IBAction)detailsButtonPressed:(id)sender;

@end
