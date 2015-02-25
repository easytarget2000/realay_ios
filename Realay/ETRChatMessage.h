//
//  RLChatMessage.h
//  Realay
//
//  Created by Michel S on 10.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ETRUser.h"

@interface ETRChatMessage : NSObject

@property (nonatomic)                   NSInteger   messageID;
@property (nonatomic)                   NSInteger   chatID;
@property (strong, nonatomic)           ETRUser     *sender;
@property (strong, nonatomic, readonly) NSDate      *sentDate;
@property (strong, nonatomic)           NSString    *messageString;

+ (ETRChatMessage *)messageFromJSONDictionary:(NSDictionary *)JSONDict;
+ (ETRChatMessage *)outgoingMessage:(NSString *)messageString
                             inChat:(NSInteger)chatID;

- (CGSize)frameSizeForWidth:(CGFloat)width hasNameLabel:(BOOL)hasNameLabel;
- (void)insertMessageIntoDB;
- (CGFloat)rowHeightForWidth:(CGFloat)width hasNameLabel:(BOOL)hasNameLabel;
- (NSString *)sentDateHoursAndMinutes;
- (NSString *)sentDateDayDate;
- (void)setSentDateFromSqlString:(NSString *)dateString;

@end
