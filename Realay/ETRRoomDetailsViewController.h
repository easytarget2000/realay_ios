//
//  ETRRoomDetailsViewController.h
//  Realay
//
//  Created by Michel S on 01.03.14.
//  Copyright (c) 2014 Michel Sievers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ETRSession.h"

@interface ETRRoomDetailsViewController : UITableViewController <ETRRelayedLocationDelegate>

@property (strong, nonatomic) IBOutlet UITableView      *tableView;

@property (weak, nonatomic) IBOutlet UIButton           *imageButton;
@property (weak, nonatomic) IBOutlet UILabel            *titleLabel;

@property (weak, nonatomic) IBOutlet UITableViewCell    *distanceCell;
@property (weak, nonatomic) IBOutlet UILabel            *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel            *distanceValueLabel;
@property (weak, nonatomic) IBOutlet UILabel            *accuracyLabel;
@property (weak, nonatomic) IBOutlet UILabel            *radiusLabel;

@property (weak, nonatomic) IBOutlet UILabel            *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel            *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel            *userCountLabel;
@property (weak, nonatomic) IBOutlet UILabel            *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem    *joinButton;

- (IBAction)imageButtonPressed:(id)sender;
- (IBAction)joinButtonPressed:(id)sender;

@end