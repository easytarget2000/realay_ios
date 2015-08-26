//
//  ETRProfileEditorViewController.m
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRProfileEditorViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import "ETRAnimator.h"
#import "ETRAlertViewFactory.h"
#import "ETRButtonCell.h"
#import "ETRCoreDataHelper.h"
#import "ETRImageEditor.h"
#import "ETRLocalUserManager.h"
#import "ETRProfileHeaderEditorCell.h"
#import "ETRKeyValueEditorCell.h"
#import "ETRServerAPIHelper.h"
#import "ETRUIConstants.h"
#import "ETRUser.h"

static CGFloat const ETRHeaderCellHeight = 80.0f;

static CGFloat const ETRValueCellHeight = 64.0f;

static short const ETRCellTagOffset = 40;

static NSString *const ETRHeaderEditorCellIdentifier = @"headerEditorCell";

static NSString *const ETRValueEditorCellIdentifier = @"valueEditorCell";

static NSInteger const ETREditRowFacebook = 5;


@interface ETRProfileEditorViewController () <UITextFieldDelegate>

@property (strong, nonatomic) ETRAlertViewFactory * alertViewFactory;

@property (strong, nonatomic) ETRUser *localUserCopy;

@property (nonatomic) BOOL didChangeAttribute;

@property (nonatomic) NSInteger lastTouchedTextFieldTag;

@end


@implementation ETRProfileEditorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do not display empty cells at the end.
    [[self tableView] setTableFooterView:[[UIView alloc] initWithFrame:CGRectZero]];
    
    // Listen to keyboard changes, so that the TableView can be scrolled automatically.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    ETRUser *localUser = [[ETRLocalUserManager sharedManager] user];
    _localUserCopy = [ETRCoreDataHelper copyUser:localUser];
    
    _didChangeAttribute = NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Reset Bar elements that might have been changed during navigation to other View Controllers.
    [[self navigationController] setToolbarHidden:YES];
    [[[self navigationController] navigationBar] setTranslucent:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[[FBSDKLoginManager alloc] init] logOut];
}

#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1 + 4 + 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == 0) {
        return ETRHeaderCellHeight;
    } else {
        return ETRValueCellHeight;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    if (row == 0) {
        ETRProfileHeaderEditorCell * headerCell;
        headerCell = [tableView dequeueReusableCellWithIdentifier:ETRHeaderEditorCellIdentifier
                                                     forIndexPath:indexPath];
        [headerCell setUpWithTag:ETRCellTagOffset + 0
                         forUser:_localUserCopy
                inViewController:self];
        return headerCell;
    } else if (row == ETREditRowFacebook) {
        ETRButtonCell * cell = [tableView dequeueReusableCellWithIdentifier:ETRCellButton];
        
        NSString * buttonText;
        UIColor * textColor;
        if ([[[[ETRLocalUserManager sharedManager] user] facebook] length]) {
            buttonText = NSLocalizedString(@"Unlink_Facebook", @"Remove Facebook Link");
            textColor = [ETRUIConstants accentColor];
        } else {
            buttonText = NSLocalizedString(@"Add_Link_Facebook", @"Connect to Facebook");
            textColor = [UIColor colorWithRed:(0x44/255.0f)
                                        green:(0x8A/255.0f)
                                         blue:(0xFF/255.0f)
                                        alpha:1.0f];
        }
        
        [[cell label] setText:buttonText];
        [[cell label] setTextColor:textColor];
        return cell;
    }
        
    
    ETRKeyValueEditorCell * valueCell;
    valueCell = [tableView dequeueReusableCellWithIdentifier:ETRValueEditorCellIdentifier
                                                forIndexPath:indexPath];
    switch (row) {
        case 1:
            [valueCell setUpStatusEditorCellWithTag:ETRCellTagOffset + 1
                                            forUser:_localUserCopy];
            break;
            
        case 2:
            [valueCell setUpPhoneNumberEditorCellWithTag:ETRCellTagOffset + 2
                                                 forUser:_localUserCopy];
            break;
            
        case 3:
            [valueCell setUpEmailEditorCellWithTag:ETRCellTagOffset + 3
                                           forUser:_localUserCopy];
            break;
            
        case 4:
            [valueCell setUpWebsiteURLEditorCellWithTag:ETRCellTagOffset + 4
                                                forUser:_localUserCopy];
            break;
        
        case 6:
            [valueCell setUpInstagramNameEditorCellWithTag:ETRCellTagOffset + 6
                                                   forUser:_localUserCopy];
            break;
            
        case 7:
            [valueCell setUpTwitterNameEditorCellWithTag:ETRCellTagOffset + 7
                                                 forUser:_localUserCopy];
            break;
    }
    
    [[valueCell valueField] setDelegate:self];
    
    return valueCell;
}

#pragma mark -
#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if ([indexPath row] == ETREditRowFacebook) {
        ETRUser * localUser = [[ETRLocalUserManager sharedManager] user];
        if ([[localUser facebook] length]) {
            // The User already has a Facebook ID set.
            // Clicking on this Cell removes the ID, stores and syncs the change.
            [localUser setFacebook:nil];
            [self saveSyncLocalUser];
            [[self tableView] reloadData];
        } else {
            // The User does not have an associated Facebook ID.
            // Log into Facebook to retrieve it, store it and sync with the Server.
            
            FBSDKLoginManager * loginMan = [[FBSDKLoginManager alloc] init];
            
            void (^loginHandler) (FBSDKLoginManagerLoginResult *, NSError *);
            loginHandler = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
                if (error) {
                    NSLog(@"Facebook Login error: %@", [error description]);
                    return;
                } else if ([result isCancelled]) {
#ifdef DEBUG
                    NSLog(@"Facebook Login cancelled");
#endif
                    return;
                }
                // TODO: Show progress circle here.
                
                FBSDKGraphRequest *request;
                request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:nil];
                [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                    if (!error && [result isKindOfClass:[NSDictionary class]]) {
#ifdef DEBUG
                        NSLog(@"fetched user:%@", result);
#endif
                        NSDictionary *values = (NSDictionary *)result;
                        [localUser setFacebook:[values objectForKey:@"id"]];
                        [self saveSyncLocalUser];
                        [loginMan logOut];
                        [[self tableView] reloadData];
                    }
                }];
            };
            
            [loginMan logInWithReadPermissions:@[@"public_profile"] handler:loginHandler];
        }
        
    } else if ([indexPath row] > 0) {
        ETRKeyValueEditorCell * valueCell;
        valueCell = (ETRKeyValueEditorCell *) [tableView cellForRowAtIndexPath:indexPath];
        
        if (valueCell) {
            [[valueCell valueField] becomeFirstResponder];
        }
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    UITableViewCell * currentCell = (UITableViewCell *) [[textField superview] superview];
    
    NSIndexPath * currentIndexPath = [[self tableView] indexPathForCell:currentCell];
    NSInteger currentRow = [currentIndexPath row];
    
    if (currentRow < 7) {
        NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:(currentRow + 1)
                                                        inSection:[currentIndexPath section]];
        ETRKeyValueEditorCell *nextCell;
        nextCell = (ETRKeyValueEditorCell *) [[self tableView] cellForRowAtIndexPath:nextIndexPath];
        if (!nextCell) {
            return YES;
        }
        
        [[self tableView] scrollToRowAtIndexPath:nextIndexPath
                                atScrollPosition:UITableViewScrollPositionMiddle
                                        animated:YES];
        
        [[nextCell valueField] becomeFirstResponder];
    }
    
    return YES;
}

- (BOOL)isValidPhoneNumber:(NSString *)phoneNumber {
    return YES;
}

- (BOOL)isValidEmailAddress:(NSString *)emailAddress {
    return YES;
}

#pragma mark -
#pragma mark TextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    _lastTouchedTextFieldTag = [textField tag];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self readChangesFromTextField:textField];
}

- (void)readChangesFromTextField:(UITextField *)textField {
    if (!textField) {
        return;
    }

    // Read in the new field value and apply it to the User duplicate.
    NSCharacterSet * trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString * enteredText;
    enteredText = [[textField text] stringByTrimmingCharactersInSet:trimSet];
    NSUInteger textLength = [enteredText length];
    
    switch ([textField tag] - ETRCellTagOffset) {
        case 0:
            if (textLength < 1) {
                [ETRAnimator fadeView:textField doAppear:NO completion:^{
                    [textField setText:[_localUserCopy name]];
                    [ETRAnimator fadeView:textField doAppear:YES completion:nil];
                }];
            } else if (textLength > ETRUserNameMaxLength) {
                [ETRAnimator fadeView:textField doAppear:NO completion:^{
                    [textField setText:[enteredText substringToIndex:ETRUserNameMaxLength]];
                    [ETRAnimator fadeView:textField doAppear:YES completion:nil];
                }];
            } else {
                [_localUserCopy setName:enteredText];
            }
            break;

        case 1:
            if (textLength > 0 && textLength < 140) {
                [_localUserCopy setStatus:enteredText];
            } else {
                [[self tableView] reloadData];
            }
            break;
            
        case 2:
            if (textLength == 0 || textLength > ETRUserSocialMaxLength) {
                [_localUserCopy setPhone:nil];
                [[self tableView] reloadData];
            } else if ([self isValidPhoneNumber:enteredText]) {
                [_localUserCopy setPhone:enteredText];
            } else {
                [[self tableView] reloadData];
            }
            break;
            
        case 3:
            if (textLength == 0 || textLength > ETRUserSocialMaxLength) {
                [_localUserCopy setMail:nil];
                [[self tableView] reloadData];
            } else if ([self isValidEmailAddress:enteredText]) {
                [_localUserCopy setMail:enteredText];
            } else {
                [[self tableView] reloadData];
            }
            break;
            
        case 4:
            if (textLength < ETRUserSocialMaxLength) {
                [_localUserCopy setWebsite:enteredText];
            } else {
                [[self tableView] reloadData];
            }
            break;
    
        case 5:
            if (textLength < ETRUserSocialMaxLength) {
                [_localUserCopy setFacebook:enteredText];
            } else {
                [[self tableView] reloadData];
            }
            break;
            
        case 6:
            if (textLength < ETRUserSocialMaxLength) {
                [_localUserCopy setInstagram:enteredText];
            } else {
                [[self tableView] reloadData];
            }
            break;
            
        case 7:
            if (textLength < ETRUserSocialMaxLength) {
                [_localUserCopy setTwitter:enteredText];
            } else {
                [[self tableView] reloadData];
            }
    }
}

#pragma mark -
#pragma mark Image Picker

- (void)imagePickerButtonPressed:(id)sender {
    NSIndexPath * headerIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ETRProfileHeaderEditorCell * headerCell;
    headerCell = (ETRProfileHeaderEditorCell *)[[self tableView] cellForRowAtIndexPath:headerIndexPath];
    
    [ETRAnimator flashFadeView:(UIView *)[headerCell iconImageView] completion:^{
        [[self alertHelper] showPictureSourcePickerForProfileEditor:self];
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Load the given image and display the progress in the header Cell's icon ImageView.
    NSIndexPath * headerIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ETRProfileHeaderEditorCell * headerCell;
    headerCell = (ETRProfileHeaderEditorCell *)[[self tableView] cellForRowAtIndexPath:headerIndexPath];
    
    [[ETRLocalUserManager sharedManager] setImage:[ETRImageEditor imageFromPickerInfo:info]
                                    withImageView:[headerCell iconImageView]];
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    [[navigationController navigationBar] setBarStyle:UIBarStyleBlack];
}

#pragma mark -
#pragma mark Save Button

- (void)saveButtonPressed:(id)sender {
    NSInteger lastTouchedRow = _lastTouchedTextFieldTag - ETRCellTagOffset;
//    if (lastTouchedRow < 0) {
//        [[self navigationController] popViewControllerAnimated:YES];
//        return;
//    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastTouchedRow inSection:0];
    id<NSObject> lastTouchedCell = [[self tableView] cellForRowAtIndexPath:indexPath];
    if ([lastTouchedCell isKindOfClass:[ETRKeyValueEditorCell class]]) {
        ETRKeyValueEditorCell *valueCell = (ETRKeyValueEditorCell *) lastTouchedCell;
        if (valueCell) {
            [self readChangesFromTextField:[valueCell valueField]];
        }
    } else if ([lastTouchedCell isKindOfClass:[ETRProfileHeaderEditorCell class]]) {
        ETRProfileHeaderEditorCell *headerCell = (ETRProfileHeaderEditorCell *) lastTouchedCell;
        if (headerCell) {
            [self readChangesFromTextField:[headerCell nameField]];
        }
    }
    
    // Check differences between the local User duplicate and the original
    // in order to determine, if the database entries need to be updated.
    BOOL doSendUpdate = NO;
    ETRUser * localUser = [[ETRLocalUserManager sharedManager] user];
    
    if ([_localUserCopy name]) {
        if (![[_localUserCopy name] isEqualToString:[localUser name]]) {
            doSendUpdate = YES;
            [localUser setName:[_localUserCopy name]];
        }
    }
    
    if ([_localUserCopy status]) {
        if (![[_localUserCopy status] isEqualToString:[localUser status]]) {
            doSendUpdate = YES;
            [localUser setStatus:[_localUserCopy status]];
        }
    }
    
    if (![[_localUserCopy mail] isEqualToString:[localUser mail]]) {
        doSendUpdate = YES;
        [localUser setMail:[_localUserCopy mail]];
    }
    
    if (![[_localUserCopy phone] isEqualToString:[localUser phone]]) {
        doSendUpdate = YES;
        [localUser setPhone:[_localUserCopy phone]];
    }
    
    if (![[_localUserCopy website] isEqualToString:[localUser website]]) {
        doSendUpdate = YES;
        [localUser setWebsite:[_localUserCopy website]];
    }
    
    if (![[_localUserCopy instagram] isEqualToString:[localUser instagram]]) {
        doSendUpdate = YES;
        [localUser setInstagram:[_localUserCopy instagram]];
    }
    
    if (![[_localUserCopy twitter] isEqualToString:[localUser twitter]]) {
        doSendUpdate = YES;
        [localUser setTwitter:[_localUserCopy twitter]];
    }
    
    if (doSendUpdate) {
        [self saveSyncLocalUser];
        [[self navigationController] popViewControllerAnimated:YES];
    }
}

- (void)saveSyncLocalUser {
    if ([ETRCoreDataHelper saveContext]) {
#ifdef DEBUG
        NSLog(@"Profile changed by user. Dispatching update to server.");
#endif
        // This will fetch the local User object, upload it to the server
        // and queue a retry if a connection problem occurred.
        [ETRServerAPIHelper dispatchUserUpdate];
    }
}

#pragma mark -
#pragma mark Keyboard Scrolling

- (void)keyboardWillShow:(NSNotification *)sender
{
    CGSize kbSize = [[[sender userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSTimeInterval duration;
    duration = [[[sender userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         UIEdgeInsets edgeInsets;
                         edgeInsets = UIEdgeInsetsMake(0.0f, 0.0f, kbSize.height, 0.0f);
                         [[self tableView] setContentInset:edgeInsets];
                         [[self tableView] setScrollIndicatorInsets:edgeInsets];
                     }];
}

- (void)keyboardWillHide:(NSNotification *)sender
{
    NSTimeInterval duration = [[[sender userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        UIEdgeInsets edgeInsets = UIEdgeInsetsZero;
        [[self tableView] setContentInset:edgeInsets];
        [[self tableView] setScrollIndicatorInsets:edgeInsets];
    }];
}

@end
