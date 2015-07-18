//
//  ETRProfileViewControllerTableViewController.m
//  Realay
//
//  Created by Michel on 06/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRDetailsViewController.h"

#import <AddressBook/AddressBook.h>

#import "ETRAlertViewFactory.h"
#import "ETRBlockedUsersViewController.h"
#import "ETRCoreDataHelper.h"
#import "ETRHeaderCell.h"
#import "ETRKeyValueCell.h"
#import "ETRLocalUserManager.h"
#import "ETRLocationCell.h"
#import "ETRLoginViewController.h"
#import "ETRProfileSocialCell.h"
#import "ETRFormatter.h"
#import "ETRRoom.h"
#import "ETRSessionManager.h"
#import "ETRUIConstants.h"
#import "ETRUser.h"

static NSString *const ETRCellLocation = @"Location";

static NSString *const ETRHeaderCellIdentifier = @"profileHeaderCell";

static NSString *const ETRValueCellIdentifier = @"profileValueCell";

static NSString *const ETRSocialMediaCellIdentifier = @"profileSocialCell";

static NSString *const ETRButtonCellIDentifier = @"profileButtonCell";

static NSString *const ETRCellBlockButton = @"BlockButton";

static NSString *const ETRSegueProfileToEditor = @"ProfileToEditor";

static NSString *const ETRSegueDetailsToPassword = @"DetailsToPassword";


@interface ETRDetailsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSInteger phoneRow;

@property (nonatomic) NSInteger mailRow;

@property (nonatomic) NSInteger websiteRow;

@property (nonatomic) NSInteger socialMediaRow;

@property (nonatomic) NSInteger blockButtonRow;

/**
 To be used with viewDidAppear:, in order to store if this View Controller appeared once.
 */
@property (nonatomic) BOOL doReloadTableOnAppear;

@end


@implementation ETRDetailsViewController

@synthesize room = _room;
@synthesize user = _user;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _doReloadTableOnAppear = NO;
    
    if ([[ETRLocalUserManager sharedManager] isLocalUser:_user]) {
        NSArray * controllerStack = [[self navigationController] viewControllers];
        
        for (UIViewController * viewController in controllerStack) {
            if([viewController isKindOfClass:[ETRLoginViewController class]]) {
                [viewController removeFromParentViewController];
            }
        }
    }

    [[self tableView] setRowHeight:UITableViewAutomaticDimension];
    [[self tableView] setEstimatedRowHeight:128.0f];
    [[self tableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UINavigationBar * navigationBar = [[self navigationController] navigationBar];
    [navigationBar setTranslucent:YES];
    [navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [navigationBar setShadowImage:[UIImage new]];
    
    if (_room) {        
        UIBarButtonItem * barButton;
        
        if ([[ETRSessionManager sharedManager] didStartSession]) {
//            barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Share", @"Share location")
//                                                         style:UIBarButtonItemStylePlain
//                                                        target:self
//                                                        action:@selector(shareButtonPressed:)];
        } else {
            barButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Join", @"Join")
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(joinButtonPressed:)];
        }
        
        [[self navigationItem] setRightBarButtonItem:barButton];
        
    } else if (_user) {
        if ([[ETRLocalUserManager sharedManager] isLocalUser:_user]) {
            
            UIBarButtonItem * editButton;
            
            // Edit Button:
            editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                      target:self
                                                                      action:@selector(editProfileButtonPressed:)];
            [[self navigationItem] setRightBarButtonItem:editButton];
        } else {
            // Add Contact Button:
            UIBarButtonItem * addButton;
            addButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add_Contact", @"Save To Contacts")
                                                         style:UIBarButtonItemStylePlain
                                                        target:self
                                                        action:@selector(addUserButtonPressed:)];
            [[self navigationItem] setRightBarButtonItem:addButton];
        }
    }
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:YES];
    
    // Send a notification when the device is rotated.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Refresh the content if returning to this View Controller.
    if (_doReloadTableOnAppear) {
        [[self tableView] reloadData];
    }
    _doReloadTableOnAppear = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    // Remove the orientation obsever.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect rect = self.navigationController.navigationBar.frame;
    
    [[self tableView] setContentInset:UIEdgeInsetsMake(-rect.origin.y, 0.0f, 0.0f, 0.0f)];
}

- (void)orientationChanged:(NSNotification *)notification {
    [[self topShadow] setNeedsLayout];
    [[self tableView] reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section != 0) {
        return 0;
    }
    
    if (_room) {
        // This instance displays Room Details.
        // Rows: header, location status, address, size, hours, number of people, description:
        return 7;
        
    } else if (_user) {
        // This instance displays User Details.
        // Rows: header, status,
        // (phone number, email address, website URL, Facebook ID, Instagram name, Twitter name)
        
        NSInteger numberOfRows = 2;
        if ([_user phone] && [[_user phone] length]) {
            _phoneRow = numberOfRows++;
        } else {
            _phoneRow = -1;
        }
        
        if ([_user mail] && [[_user mail] length]) {
            _mailRow = numberOfRows++;
        } else {
            _mailRow = -1;
        }
        
        if ([_user website] && [[_user website] length]) {
            _websiteRow = numberOfRows++;
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
            _blockButtonRow = numberOfRows++;
        } else {
            _blockButtonRow = -1;
        }
        
        return numberOfRows;
    }
    
    return 0;
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

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([indexPath row] == 0) {     // Configure the header cell.
        ETRHeaderCell *headerCell;
        headerCell = [tableView dequeueReusableCellWithIdentifier:ETRHeaderCellIdentifier];
        
        if (_room) {
            [headerCell setUpWithRoom:_room];
        } else if (_user) {
            [headerCell setUpWithUser:_user];
        }
        return headerCell;
    }
    
    if (_room) {
        if ([indexPath row] == 1) {
//            ETRLocationCell * locationCell;
            return [tableView dequeueReusableCellWithIdentifier:ETRCellLocation];
        } else {
            return [self roomCellInTableView:tableView forIndexPath:indexPath];
        }
    } else if (_user) {
        return [self userCellInTableView:tableView forIndexPath:indexPath];
    }
    
    // Empty fallback cell:
    return [tableView dequeueReusableCellWithIdentifier:ETRValueCellIdentifier
                                           forIndexPath:indexPath];
}

- (ETRKeyValueCell *)roomCellInTableView:(UITableView *)tableView
                                forIndexPath:indexPath {

    ETRKeyValueCell *cell;
    cell = [tableView dequeueReusableCellWithIdentifier:ETRValueCellIdentifier
                                           forIndexPath:indexPath];
    
    switch ([indexPath row]) {
        case 2: {
            if ([[_room address] length]) {
                [[cell keyLabel] setText:NSLocalizedString(@"Address", @"Physical address")];
                [[cell valueLabel] setText:[_room address]];
            } else {
                [[cell keyLabel] setText:NSLocalizedString(@"Coordinates", @"GPS Coordinates")];
                
                NSString * coordinates;
                coordinates = [NSString stringWithFormat:@"%@, %@", [_room longitude], [_room latitude]];
                [[cell valueLabel] setText:coordinates];
            }

            break;
        }
            
        case 3: {
            [[cell keyLabel] setText:NSLocalizedString(@"Size", @"Room Size")];
            int diameter = (int) [[_room radius] integerValue] * 2;
            NSString * size = [ETRFormatter formattedIntLength:diameter];
            [[cell valueLabel] setText:size];
        }
            break;
            
        case 4: {
            [[cell keyLabel] setText:NSLocalizedString(@"Hours", @"Opening hours")];
            NSString * timeSpan = [ETRFormatter timeSpanForStartDate:[_room startDate]
                                                                    endDate:[_room endDate]];
            [[cell valueLabel] setText:timeSpan];
        }
            break;
            
        case 5: {
            NSString *labelText;
            labelText = NSLocalizedString(@"Users_online", @"Number of Users");
            [[cell keyLabel] setText:labelText];
            
            NSString * numberOfUsers;
            if ([[ETRSessionManager sharedManager] didStartSession]) {
                numberOfUsers = [NSString stringWithFormat:@"%d", [ETRCoreDataHelper numberOfUsersInSessionRoom]];
            } else {
                numberOfUsers = [[_room queryUserCount] stringValue];
            }
            [[cell valueLabel] setText:numberOfUsers];

        }
            break;
            
        case 6: {
            [[cell keyLabel] setHidden:YES];
            [[cell valueLabel] setText:[_room summary]];
        }
            break;
        
    }
    
    return cell;
}

- (UITableViewCell *)userCellInTableView:(UITableView *)tableView
                                forIndexPath:indexPath {
    
    NSInteger row = [indexPath row];

    if (row == _socialMediaRow) {
        // The cell for this row displays the social network buttons.
        ETRProfileSocialCell * socialMediaCell;
        socialMediaCell = [tableView dequeueReusableCellWithIdentifier:ETRSocialMediaCellIdentifier];
        [socialMediaCell setUpForUser:_user];
        return socialMediaCell;
    } else if (row == _blockButtonRow) {
        return [tableView dequeueReusableCellWithIdentifier:ETRCellBlockButton];
    }
    
    // The cell for this row displays one specific attribute.
    
    ETRKeyValueCell *valueCell;
    valueCell = [tableView dequeueReusableCellWithIdentifier:ETRValueCellIdentifier
                                                forIndexPath:indexPath];
    
    if (row == 1) {     // Configure the status cell.
        NSString *statusKey;
        statusKey = NSLocalizedString(@"Status", @"Status message");
        [[valueCell keyLabel] setText:statusKey];
        [[valueCell valueLabel] setText:[_user status]];
        return valueCell;
    }
    
    if (row == _phoneRow && [_user phone] && [[_user phone] length]) {
        NSString *phoneKey = NSLocalizedString(@"Phone_Number", @"Phone number");
        [[valueCell keyLabel] setText:phoneKey];
        [[valueCell valueLabel] setText:[_user phone]];
        return valueCell;
    }
    
    if (row == _mailRow && [_user mail] && [[_user mail] length]) {
        NSString *emailKey = NSLocalizedString(@"Email_Address", @"Email address");
        [[valueCell keyLabel] setText:emailKey];
        [[valueCell valueLabel] setText:[_user mail]];
        return valueCell;
    }
    
    if (row == _websiteRow && [_user website] && [[_user website] length]) {
        NSString *websiteKey = NSLocalizedString(@"Website", "Website URL");
        [[valueCell keyLabel] setText:websiteKey];
        [[valueCell valueLabel] setText:[_user website]];
        return valueCell;
    }
    
    return valueCell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if ([indexPath row] == _blockButtonRow) {
        [[self alertHelper] showBlockConfirmViewForUser:_user viewController:self];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Navigation

// TODO: Rewrite for iOS9.

- (IBAction)addUserButtonPressed:(id)sender {
    if (!_user) {
        return;
    }
    
    CFErrorRef error;
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(nil, &error);
    
    if (error) {
        addressBookRef = nil;
        NSLog(@"ERROR: addUserButtonPressed: %@", error);
        [ETRAlertViewFactory showGeneralErrorAlert];
        return;
    }
    
    void (^createABEntry)(void) = ^{
        CFErrorRef error;
        
        ABRecordRef newPerson = ABPersonCreate();
        ABRecordSetValue(newPerson, kABPersonNicknameProperty, (__bridge CFTypeRef)([_user name]), &error);
        if ([[_user mail] length]) {
            ABRecordSetValue(newPerson, kABPersonEmailProperty, (__bridge CFTypeRef)([_user mail]), &error);
        }
        if ([[_user phone] length]) {
            ABRecordSetValue(newPerson, kABPersonPhoneProperty, (__bridge CFTypeRef)([_user phone]), &error);
        }
        if ([[_user website] length]) {
            ABRecordSetValue(newPerson, kABPersonURLProperty, (__bridge CFTypeRef)([_user website]), &error);
        }
        
        ABAddressBookAddRecord(addressBookRef, newPerson, &error);
        
        ABAddressBookSave(addressBookRef, &error);
        CFRelease(newPerson);
        CFRelease(addressBookRef);
        if (error) {
            CFStringRef errorDesc = CFErrorCopyDescription(error);
            NSLog(@"Contact not saved: %@", errorDesc);
            CFRelease(errorDesc);
            [ETRAlertViewFactory showGeneralErrorAlert];
        } else {
            NSString * titleFormat = NSLocalizedString(@"Added_User", @"Added %@");
            NSString * title = [NSString stringWithFormat:titleFormat, [_user name]];
            NSString * message = NSLocalizedString(@"In_contacts", @"Now in phonebook");
            [[[UIAlertView alloc] initWithTitle:title
                                       message:message
                                      delegate:nil
                             cancelButtonTitle:NSLocalizedString(@"OK", @"Affirmative")
                             otherButtonTitles:nil] show];
        }
    };
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact.
                createABEntry();
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added.
            }
        });
    } else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact.
        createABEntry();
    } else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app.
        return;
    }
}

- (IBAction)blockedUsersButtonPressed:(id)sender {
    UIStoryboard * storyboard = [self storyboard];
    ETRBlockedUsersViewController * viewController;
    viewController = [storyboard instantiateViewControllerWithIdentifier:ETRViewControllerIDBlockedUsers];
    
    [[self navigationController] pushViewController:viewController animated:YES];
}

- (IBAction)editProfileButtonPressed:(id)sender {
    [self performSegueWithIdentifier:ETRSegueProfileToEditor sender:nil];
}

- (IBAction)joinButtonPressed:(id)sender {
    [super joinButtonPressed:sender joinSegue:ETRSegueDetailsToPassword];
}

- (IBAction)shareButtonPressed:(id)sender {
   // TODO: Implement sharing.
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
