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
#import "ETRLocalUserManager.h"
#import "ETRProfileHeaderEditorCell.h"
#import "ETRKeyValueEditorCell.h"
#import "ETRUser.h"

#define kHeaderEditorCellIdentifier @"headerEditorCell"
#define kValueEditorCellIdentifier  @"valueEditorCell"

#define kHeaderCellHeight           80.0f
#define kValueCellHeight            64.0f

#define kCellTagOffset              40

@interface ETRProfileEditorViewController ()

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1 + 4 + 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath row] == 0) {
        return kHeaderCellHeight;
    } else {
        return kValueCellHeight;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    if (row == 0) {
        ETRProfileHeaderEditorCell *headerCell;
        headerCell = [tableView dequeueReusableCellWithIdentifier:kHeaderEditorCellIdentifier
                                                     forIndexPath:indexPath];
        [headerCell setUpWithTag:kCellTagOffset + 0 forUser:_localUserCopy];
        return headerCell;
    }
    
    ETRKeyValueEditorCell *valueCell;
    valueCell = [tableView dequeueReusableCellWithIdentifier:kValueEditorCellIdentifier
                                                forIndexPath:indexPath];
    switch (row) {
        case 1:
            [valueCell setUpStatusEditorCellWithTag:kCellTagOffset + 1
                                            forUser:_localUserCopy];
            break;
            
        case 2:
            [valueCell setUpPhoneNumberEditorCellWithTag:kCellTagOffset + 2
                                                 forUser:_localUserCopy];
            break;
            
        case 3:
            [valueCell setUpEmailEditorCellWithTag:kCellTagOffset + 3
                                           forUser:_localUserCopy];
            break;
            
        case 4:
            [valueCell setUpWebsiteURLEditorCellWithTag:kCellTagOffset + 4
                                                forUser:_localUserCopy];
            break;
        
        case 5:
            [valueCell setUpFacebookNameEditorCellWithTag:kCellTagOffset + 5
                                                  forUser:_localUserCopy];
            break;
        
        case 6:
            [valueCell setUpInstagramNameEditorCellWithTag:kCellTagOffset + 6
                                                   forUser:_localUserCopy];
            break;
            
        case 7:
            [valueCell setUpTwitterNameEditorCellWithTag:kCellTagOffset + 7
                                                 forUser:_localUserCopy];
            break;
    }
    
    return valueCell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    UITableViewCell *currentCell = (UITableViewCell *) [[textField superview] superview];
    
    NSIndexPath *currentIndexPath = [[self tableView] indexPathForCell:currentCell];
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
    
    switch ([textField tag] - kCellTagOffset) {
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
#pragma mark Keyboard Scrolling

- (void)keyboardWillShow:(NSNotification *)sender
{
    CGSize kbSize = [[[sender userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSTimeInterval duration = [[[sender userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 0, kbSize.height, 0);
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

- (void)saveButtonPressed:(id)sender {
    NSInteger lastTouchedRow = _lastTouchedTextFieldTag - kCellTagOffset;
    if (lastTouchedRow < 0) {
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
    ETRUser *localUser = [[ETRLocalUserManager sharedManager] user];
    
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
    }
    
    
    [[self navigationController] popViewControllerAnimated:YES];
}

@end
