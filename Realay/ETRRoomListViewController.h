//
//  RoomListViewController.h
//  Realay
//
//  Created by Michel on 18.09.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ETRRoomListViewController : UITableViewController <CLLocationManagerDelegate>

- (IBAction)profileButtonPressed:(id)sender;

@end
