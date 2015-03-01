//
//  User.h
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * remoteID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * mail;
@property (nonatomic, retain) NSString * phone;
@property (nonatomic, retain) NSString * website;
@property (nonatomic, retain) NSString * instagram;
@property (nonatomic, retain) NSString * facebook;
@property (nonatomic, retain) NSString * twitter;
@property (nonatomic, retain) NSNumber * imageID;
@property (nonatomic, retain) NSManagedObject *lastKnownRoom;
@property (nonatomic, retain) NSManagedObject *sentActions;
@property (nonatomic, retain) NSManagedObject *receivedActions;
@property (nonatomic, retain) NSManagedObject *inConversation;

+ (User *)userFromJSONDictionary:(NSDictionary *)JSONDict;

@end
