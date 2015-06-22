//
//  ETRProfileValueEditorCell.h
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ETRUser;

@interface ETRKeyValueEditorCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *keyLabel;

@property (weak, nonatomic) IBOutlet UITextField *valueField;

- (void)setUpStatusEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user;

- (void)setUpPhoneNumberEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user;

- (void)setUpEmailEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user;

- (void)setUpWebsiteURLEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user;

- (void)setUpFacebookNameEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user;

- (void)setUpInstagramNameEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user;

- (void)setUpTwitterNameEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user;

//- (NSString *)validatedFieldValueWithTag:(NSInteger)tag forUser:(ETRUser *)user;

@end
