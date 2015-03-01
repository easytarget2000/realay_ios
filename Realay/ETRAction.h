//
//  Action.h
//  Realay
//
//  Created by Michel on 01/03/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ETRRoom, User;

@interface ETRAction : NSManagedObject

@property (nonatomic, retain) NSNumber * remoteID;
@property (nonatomic, retain) NSDate * sentTime;
@property (nonatomic, retain) NSNumber * code;
@property (nonatomic, retain) NSNumber * imageID;
@property (nonatomic, retain) NSString * messageContent;
@property (nonatomic, retain) NSNumber * isInQueue;
@property (nonatomic, retain) User *sender;
@property (nonatomic, retain) User *recipient;
@property (nonatomic, retain) ETRRoom *room;

+ (ETRAction *)actionFromJSONDictionary:(NSDictionary *)JSONDict;
+ (ETRAction *)outgoingMessage:(NSString *)messageContent toRecipient:(User *)recipient;

- (CGSize)frameSizeForWidth:(CGFloat)width hasNameLabel:(BOOL)hasNameLabel;
- (CGFloat)rowHeightForWidth:(CGFloat)width hasNameLabel:(BOOL)hasNameLabel;
- (NSString *)sentDateHoursAndMinutes;
- (NSString *)sentDateDayDate;

- (BOOL)isPublicMessage;

- (BOOL)isPhotoMessage;

- (BOOL)isSentMessage;

@end
