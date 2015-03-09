//
//  ETRProfileValueEditorCell.m
//  Realay
//
//  Created by Michel on 07/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRKeyValueEditorCell.h"

#import "ETRUser.h"

@implementation ETRKeyValueEditorCell

// TODO: Translate.

- (void)setUpStatusEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeDefault];
    [[self keyLabel] setText:@"status"];
    
    NSString *statusMessage = [user status];
    if (statusMessage) {
        [[self valueField] setText:statusMessage];
    } else {
        [[self valueField] setText:@"..."];
    }
}

- (void)setUpPhoneNumberEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user{
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypePhonePad];
    [[self keyLabel] setText:@"phone"];
    
    NSString *phoneNumber = [user phone];
    if (phoneNumber) {
        [[self valueField] setText:phoneNumber];
    } else {
        [[self valueField] setText:@""];
    }
}


- (void)setUpEmailEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeEmailAddress];
    [[self keyLabel] setText:@"email"];
    
    NSString *emailAddress = [user mail];
    if (emailAddress) {
        [[self valueField] setText:emailAddress];
    } else {
        [[self valueField] setText:@""];
    }
}

- (void)setUpWebsiteURLEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeURL];
    [[self keyLabel] setText:@"website"];
    
    NSString *websiteURL = [user website];
    if (websiteURL) {
        [[self valueField] setText:websiteURL];
    } else {
        [[self valueField] setText:@""];
    }
    
}

- (void)setUpFacebookNameEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeNamePhonePad];
    [[self keyLabel] setText:@"facebook id"];
    
    NSString *facebookName = [user facebook];
    if (facebookName) {
        [[self valueField] setText:facebookName];
    } else {
        [[self valueField] setText:@""];
    }
}

- (void)setUpInstagramNameEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user; {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeNamePhonePad];
    [[self keyLabel] setText:@"instagram username"];
    
    NSString *instagramName = [user instagram];
    if (instagramName) {
        [[self valueField] setText:instagramName];
    } else {
        [[self valueField] setText:@""];
    }
}

- (void)setUpTwitterNameEditorCellWithTag:(NSInteger)tag forUser:(ETRUser *)user; {
    if (!user) {
        return;
    }
    
    [[self valueField] setTag:tag];
    [[self valueField] setKeyboardType:UIKeyboardTypeNamePhonePad];
    [[self keyLabel] setText:@"twitter username"];
    
    NSString *twitterName = [user twitter];
    if (twitterName) {
        [[self valueField] setText:twitterName];
    } else {
        [[self valueField] setText:@""];
    }
}

- (NSString *)validatedFieldValue {
    NSString *enteredText = [[self valueField] text];
    return [enteredText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end
