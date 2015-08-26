//
//  ETRProfileValueEditorCell.m
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRKeyValueEditorCell.h"

#import "ETRUser.h"



@interface ETRKeyValueEditorCell () <UITextFieldDelegate>

@property (nonatomic) short characterLimit;

@end


@implementation ETRKeyValueEditorCell

- (void)prepareForReuse {
    [[self valueField] setText:@""];
}

- (void)setUpStatusEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeDefault];
    [[self valueField] setSpellCheckingType:UITextSpellCheckingTypeYes];
    [[self valueField] setAutocorrectionType:UITextAutocorrectionTypeYes];
    [[self valueField] setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
    [[self keyLabel] setText:NSLocalizedString(@"Status", @"Status Message")];
    
    NSString * statusMessage = [user status];
    if (statusMessage) {
        [[self valueField] setText:statusMessage];
    } else {
        [[self valueField] setText:@"..."];
    }
    _characterLimit = 140;
}

- (void)setUpPhoneNumberEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user{
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypePhonePad];
    [[self keyLabel] setText:NSLocalizedString(@"Phone_Number", @"Phone Number")];
    
    NSString *phoneNumber = [user phone];
    if (phoneNumber) {
        [[self valueField] setText:phoneNumber];
    } else {
        [[self valueField] setText:@""];
    }
    _characterLimit = 18;
}


- (void)setUpEmailEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeEmailAddress];
    [[self keyLabel] setText:NSLocalizedString(@"Email_Address", @"Email Address")];
    
    NSString *emailAddress = [user mail];
    if (emailAddress) {
        [[self valueField] setText:emailAddress];
    } else {
        [[self valueField] setText:@""];
    }
    _characterLimit = 50;
}

- (void)setUpWebsiteURLEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeURL];
    [[self keyLabel] setText:NSLocalizedString(@"Website", @"Website URL")];
    
    NSString *websiteURL = [user website];
    if (websiteURL) {
        [[self valueField] setText:websiteURL];
    } else {
        [[self valueField] setText:@""];
    }
    _characterLimit = 240;
}

- (void)setUpInstagramNameEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user; {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeNamePhonePad];
    [[self keyLabel] setText:NSLocalizedString(@"Instagram_Name", @"Instagram username")];
    
    NSString *instagramName = [user instagram];
    if (instagramName) {
        [[self valueField] setText:instagramName];
    } else {
        [[self valueField] setText:@""];
    }
    _characterLimit = 60;
}

- (void)setUpTwitterNameEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user; {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeNamePhonePad];
    [[self keyLabel] setText:NSLocalizedString(@"Twitter_Name", @"Twitter username")];
    
    NSString *twitterName = [user twitter];
    if (twitterName) {
        [[self valueField] setText:twitterName];
    } else {
        [[self valueField] setText:@""];
    }
    _characterLimit = 60;
}

- (NSString *)validatedFieldValue {
    NSString * enteredText = [[self valueField] text];
    return [enteredText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textField:(nonnull UITextField *)textField
shouldChangeCharactersInRange:(NSRange)range
replacementString:(nonnull NSString *)string {
    
    if (_characterLimit < 2) {
        return YES;
    }
    
    NSString * newText = [[textField text] stringByReplacingCharactersInRange:range withString:string];
    
    if([newText length] <= _characterLimit){
        return YES;
    } else {
        [textField setText:[newText substringToIndex:_characterLimit]];
        return NO;
    }
}

@end
