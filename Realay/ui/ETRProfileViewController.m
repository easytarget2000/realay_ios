//
//  ETRProfileViewControllerTableViewController.m
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRProfileViewController.h"

#import "ETRLocalUserManager.h"
#import "ETRProfileButtonCell.h"
#import "ETRProfileHeaderCell.h"
#import "ETRProfileSocialCell.h"
#import "ETRProfileValueCell.h"
#import "ETRUser.h"

#define kHeaderCellIdentifier       @"profileHeaderCell"
#define kValueCellIdentifier        @"profileValueCell"
#define kSocialMediaCellIdentifier  @"socialMediaCell"
#define kButtonCellIdentifier       @"profileButtonCell"

@interface ETRProfileViewController ()

@property (nonatomic) NSInteger phoneRow;

@property (nonatomic) NSInteger mailRow;

@property (nonatomic) NSInteger websiteRow;

@property (nonatomic) NSInteger socialMediaRow;

@end

@implementation ETRProfileViewController

@synthesize user = _user;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self tableView] setRowHeight:UITableViewAutomaticDimension];
    [[self tableView] setEstimatedRowHeight:64.0f];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self tableView] reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section != 0 || !_user) {
        return 0;
    }
    
    // Two rows for the header and status plus value rows and an optional block row:
    NSInteger numberOfRows = 2;
    if ([_user phone] && [[_user phone] length]) {
        numberOfRows++;
        _phoneRow = numberOfRows - 1;
    } else {
        _phoneRow = -1;
    }
    
    if ([_user mail] && [[_user mail] length]) {
        numberOfRows++;
        _mailRow = numberOfRows - 1;
    } else {
        _mailRow = -1;
    }
    
    if ([_user website] && [[_user website] length]) {
        numberOfRows++;
        _websiteRow = numberOfRows - 1;
    } else {
        _websiteRow = -1;
    }
    
    if ([self doShowSocialMediaRow]) {
        numberOfRows++;
        _socialMediaRow = numberOfRows - 1;
    } else {
        _socialMediaRow = -1;
    }
    
    if (![[ETRLocalUserManager sharedManager] isLocalUser:_user]) {
        // If this is not the local User, add a row for the block button.
        numberOfRows ++;
    }
    
    return numberOfRows;
}

- (BOOL)doShowSocialMediaRow {
    if ([_user facebook] && [[_user facebook] length]) {
        return YES;
    }
    
    if ([_user instagram] && [[_user instagram] length]) {
        return YES;
    }
    
    if ([_user twitter] && [[_user twitter] length]) {
        return YES;
    }
    
    return NO;
}

// TODO: Translate.

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    
    if (row == 0) {     // Configure the header cell.
        ETRProfileHeaderCell *headerCell;
        headerCell = [tableView dequeueReusableCellWithIdentifier:kHeaderCellIdentifier
                                                     forIndexPath:indexPath];
        [[headerCell nameLabel] setText:[_user name]];
        return headerCell;
    }
    
    if (![[ETRLocalUserManager sharedManager] isLocalUser:_user]) {
        // The last row contains the block button, if this is not the local User.
        if (row == ([tableView numberOfRowsInSection:0] - 1)) {
            ETRProfileButtonCell *blockButtonCell;
            blockButtonCell = [tableView dequeueReusableCellWithIdentifier:kButtonCellIdentifier
                                                              forIndexPath:indexPath];
            
            NSString *blockUser = @"Block user";
            [[blockButtonCell buttonLabel] setText:blockUser];
            
            return blockButtonCell;
        }
    }
    
    if (row == _socialMediaRow) {
        // The cell for this row displays the social network buttons.
        ETRProfileSocialCell *socialMediaCell;
        socialMediaCell = [tableView dequeueReusableCellWithIdentifier:kSocialMediaCellIdentifier
                                                          forIndexPath:indexPath];
        return socialMediaCell;
    }
    
    // The cell for this row displays one specific attribute.
    
    ETRProfileValueCell *valueCell;
    valueCell = [tableView dequeueReusableCellWithIdentifier:kValueCellIdentifier
                                                 forIndexPath:indexPath];
    
    if (row == 1) {     // Configure the status cell.
        NSString *statusKey = @"status";
        [[valueCell keyLabel] setText:statusKey];
        [[valueCell valueLabel] setText:[_user status]];
        return valueCell;
    }
    
    if (row == _phoneRow && [_user phone] && [[_user phone] length]) {
        NSString *phoneKey = @"phone number";
        [[valueCell keyLabel] setText:phoneKey];
        [[valueCell valueLabel] setText:[_user phone]];
        return valueCell;
    }
    
    if (row == _mailRow && [_user mail] && [[_user mail] length]) {
        NSString *emailKey = @"email";
        [[valueCell keyLabel] setText:emailKey];
        [[valueCell valueLabel] setText:[_user mail]];
        return valueCell;
    }
    
    if (row == _mailRow && [_user website] && [[_user website] length]) {
        NSString *websiteKey = @"website";
        [[valueCell keyLabel] setText:websiteKey];
        [[valueCell valueLabel] setText:[_user website]];
        return valueCell;
    }
    
    // Empty fallback cell:
    return [tableView dequeueReusableCellWithIdentifier:kValueCellIdentifier
                                           forIndexPath:indexPath];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
