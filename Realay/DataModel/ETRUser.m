//
//  User.m
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRUser.h"

#import <AddressBook/AddressBook.h>


short const ETRUserNameMaxLength = 40;

short const ETRUserSocialMaxLength = 60;


@implementation ETRUser

@dynamic remoteID;
@dynamic imageID;
@dynamic name;
@dynamic status;
@dynamic mail;
@dynamic phone;
@dynamic website;
@dynamic instagram;
@dynamic facebook;
@dynamic twitter;
@dynamic isBlocked;
@dynamic inRoom;
@dynamic sentActions;
@dynamic receivedActions;
@dynamic inConversation;

- (NSComparisonResult)compare:(ETRUser *)otherUser {
    return [[self name] compare:[otherUser name]];
}

- (void)addToAddressBook {

    // ...
    // Set other properties
    // ...
    
    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(nil, nil);
    
    void (^createABEntry)(void) = ^{
        CFErrorRef error;
        
        ABRecordRef newPerson = ABPersonCreate();
        ABRecordSetValue(newPerson, kABPersonNicknameProperty, (__bridge CFTypeRef)([self name]), &error);
        if ([self mail]) {
            ABRecordSetValue(newPerson, kABPersonEmailProperty, (__bridge CFTypeRef)([self mail]), &error);
        }
        if ([self phone]) {
            ABRecordSetValue(newPerson, kABPersonPhoneProperty, (__bridge CFTypeRef)([self phone]), &error);
        }
        if ([self website]) {
            ABRecordSetValue(newPerson, kABPersonURLProperty, (__bridge CFTypeRef)([self website]), &error);
        }
        
        ABAddressBookAddRecord(addressBookRef, newPerson, &error);
        
        ABAddressBookSave(addressBookRef, &error);
        CFRelease(newPerson);
        CFRelease(addressBookRef);
//        if (error) {
//            CFStringRef errorDesc = CFErrorCopyDescription(error);
//            NSLog(@"Contact not saved: %@", errorDesc);
//            CFRelease(errorDesc);
//        }
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



@end
