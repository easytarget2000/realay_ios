//
//  ETRProfileEditorViewController.m
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRProfileEditorViewController.h"

#import "ETRAlertViewFactory.h"
#import "ETRCoreDataHelper.h"
#import "ETRImageEditor.h"
#import "ETRLocalUserManager.h"
#import "ETRProfileHeaderEditorCell.h"
#import "ETRKeyValueEditorCell.h"
#import "ETRServerAPIHelper.h"
#import "ETRUser.h"

static CGFloat const ETRHeaderCellHeight = 80.0f;

static CGFloat const ETRValueCellHeight = 64.0f;

static short const ETRCellTagOffset = 40;

static NSString *const ETRHeaderEditorCellIdentifier = @"headerEditorCell";

static NSString *const ETRValueEditorCellIdentifier = @"valueEditorCell";


@interface ETRProfileEditorViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate>

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

#pragma mark - Table view data source

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if ([indexPath row] > 0) {
        ETRKeyValueEditorCell * valueCell;
        valueCell = (ETRKeyValueEditorCell *) [tableView cellForRowAtIndexPath:indexPath];
        
        if (valueCell) {
            [[valueCell valueField] becomeFirstResponder];
        }
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    if (row == 0) {
        ETRProfileHeaderEditorCell *headerCell;
        headerCell = [tableView dequeueReusableCellWithIdentifier:ETRHeaderEditorCellIdentifier
                                                     forIndexPath:indexPath];
        [headerCell setUpWithTag:ETRCellTagOffset + 0
                         forUser:_localUserCopy
                inViewController:self];
        return headerCell;
    }
    
    ETRKeyValueEditorCell *valueCell;
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
        
        case 5:
            [valueCell setUpFacebookNameEditorCellWithTag:ETRCellTagOffset + 5
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
    
    return valueCell;
}

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
        
//        // If you are scrolling to the top of the cell (in my case it means that if the user taps "enter" in the last row, therefore the next one will be the first one)
//        // then setup a delay of 0.6 seconds
//        double delayInSeconds = 0;
//        if (nextIndexPath.section == 0 && nextIndexPath.row == 0) {
//            delayInSeconds = 0.6;
//        }
//        
//        // Retrieve the cell after the afore-defined delay
//        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//            UITableViewCell *nextCell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
//            YourCustomCell *advancedCell = (YourCustomCell *) nextCell;
//            [advancedCell.editField becomeFirstResponder];
//        });
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
    if (_lastTouchedTextFieldTag == [textField tag]) {
        _lastTouchedTextFieldTag = -1;
    }
    
    [self readChangesFromTextField:textField];
}

- (void)readChangesFromTextField:(UITextField *)textField {
    if (!textField) {
        return;
    }

    // Read in the new field value and apply it to the User duplicate.
    NSCharacterSet *trimSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *enteredText;
    enteredText = [[textField text] stringByTrimmingCharactersInSet:trimSet];
    
    switch ([textField tag] - ETRCellTagOffset) {
        case 0: {
            if (![enteredText length]) {
                [ETRAlertViewFactory showTypedNameTooShortAlert];
            } else {
                [_localUserCopy setName:enteredText];
            }
            break;
        }
        case 1: {
            if (![enteredText length]) {
                [_localUserCopy setStatus:@"..."];
            } else {
                [_localUserCopy setStatus:enteredText];
            }
            break;
        }
            
        case 2: {
            if ([enteredText length] && [self isValidPhoneNumber:enteredText]) {
                [_localUserCopy setPhone:enteredText];
            } else {
                // TODO: Show alert.
                [_localUserCopy setPhone:nil];
            }
            break;
        }
            
        case 3: {
            if ([enteredText length] && [self isValidEmailAddress:enteredText]) {
                [_localUserCopy setMail:enteredText];
            } else {
                // TODO: Show alert.
                [_localUserCopy setMail:nil];
            }
            break;
        }
            
        case 4: {
            [_localUserCopy setWebsite:enteredText];
            break;
        }
            
        case 5: {
            [_localUserCopy setFacebook:enteredText];
            break;
        }
            
        case 6: {
            [_localUserCopy setInstagram:enteredText];
            break;
        }
            
        case 7: {
            [_localUserCopy setTwitter:enteredText];
        }
    }
    
}

#pragma mark -
#pragma mark Buttons

- (void)imagePickerButtonPressed:(id)sender {
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    [picker setDelegate:self];
    [picker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    [picker setAllowsEditing:YES];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)cameraButtonPressed:(id)sender {
    UIImagePickerController * picker = [[UIImagePickerController alloc] init];
    [picker setDelegate:self];
    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self dismissViewControllerAnimated:picker completion:nil];
    
    // Load the given image and display the progress in the header Cell's icon ImageView.
    NSIndexPath * headerIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    ETRProfileHeaderEditorCell * headerCell;
    headerCell = (ETRProfileHeaderEditorCell *)[[self tableView] cellForRowAtIndexPath:headerIndexPath];
    
    [[ETRLocalUserManager sharedManager] setImage:[ETRImageEditor imageFromPickerInfo:info]
                                    withImageView:[headerCell iconImageView]];
}

- (void)saveButtonPressed:(id)sender {
    NSInteger lastTouchedRow = _lastTouchedTextFieldTag - ETRCellTagOffset;
    if (lastTouchedRow < 0) {
        [[self navigationController] popViewControllerAnimated:YES];
        return;
    }
    
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
    
    if (![[_localUserCopy imageID] isEqualToNumber:[localUser imageID]]) {
        // Do not send an update API call for image changes.
        // The image upload already does this.
        [localUser setImageID:[_localUserCopy imageID]];
        [localUser setLowResImage:[_localUserCopy lowResImage]];
    }
    
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
    
    if (![[_localUserCopy facebook] isEqualToString:[localUser facebook]]) {
        doSendUpdate = YES;
        [localUser setFacebook:[_localUserCopy facebook]];
    }
    
    if (![[_localUserCopy instagram] isEqualToString:[localUser instagram]]) {
        doSendUpdate = YES;
        [localUser setInstagram:[_localUserCopy instagram]];
    }
    
    if (![[_localUserCopy twitter] isEqualToString:[localUser twitter]]) {
        doSendUpdate = YES;
        [localUser setTwitter:[_localUserCopy twitter]];
    }
    
    if (doSendUpdate && [ETRCoreDataHelper saveContext]) {
        // TODO: Add Action to query with Action Code "User update".
        // This will fetch the local User object and upload it to the server.
        [ETRServerAPIHelper sendLocalUserUpdate];
    }
    
    
    [[self navigationController] popViewControllerAnimated:YES];
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
