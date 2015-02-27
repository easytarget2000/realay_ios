//
//  RLChatMessage.m
//  Realay
//
//  Created by Michel S on 10.12.13.
//  Copyright (c) 2013 Michel Sievers. All rights reserved.
//

#import "ETRChatMessage.h"

#import "ETRHTTPHandler.h"
#import "ETRSession.h"

#import "SharedMacros.h"
#define kInfoMsgSenderId -10

@implementation ETRChatMessage

#pragma mark - Factory Methods

+ (ETRChatMessage *)messageFromJSONDictionary:(NSDictionary *)JSONDict {
    ETRChatMessage *message = [[ETRChatMessage alloc] init];
    
    // Get the message data from the JSON key array.
    NSString *senderKey = [JSONDict objectForKey:@"user_id"];
    
    ETRUser *sender = [[[ETRSession sharedSession] users] objectForKey:senderKey];
    if (!sender) {
        NSLog(@"INFO: User %@ not found in user list.", senderKey);
        sender = [ETRUser userWithIDKey:senderKey];
        [[[ETRSession sharedSession] users] setObject:sender forKey:senderKey];
    }
    
    [message setSender:sender];
    
    [message setMessageID:[[JSONDict objectForKey:@"id"] integerValue]];
    [message setChatID:[[JSONDict objectForKey:@"chat_id"] intValue]];
    [message setSentDateFromSqlString:[JSONDict objectForKey:@"time"]];
    [message setMessageString:[JSONDict objectForKey:@"message"]];
    
    // Save the highest message ID.
    [message setMessageID:[[JSONDict objectForKey:@"id"] intValue]];
    
    return message;
}

+ (ETRChatMessage *)outgoingMessage:(NSString *)messageString
                             inChat:(NSInteger)chatID {
    
    ETRChatMessage *message = [[ETRChatMessage alloc] init];
    
    [message setMessageID:-1];
    [message setMessageString:messageString];
    [message setChatID:chatID];
    
    return message;
}

#pragma mark - Factory Helper

- (CGSize)frameSizeForWidth:(CGFloat)width hasNameLabel:(BOOL)hasNameLabel {
    
    // Calculate the frame of the name label, if wanted.
    CGSize nameSize;
    if (hasNameLabel) {
        NSString *senderName = [[self sender] name];
        if (senderName) {
            UIFont *nameFont = [[ETRSession sharedSession] msgSenderFont];
            nameSize = [senderName sizeWithAttributes:@{NSFontAttributeName:nameFont}];
        }
    }
    
    // Calculate the frame of the message label.
    CGSize maxMsgSize = CGSizeMake(width - 76, MAXFLOAT);
    UIFont *textFont = [[ETRSession sharedSession] msgTextFont];
    CGRect messageRect;
    messageRect = [[self messageString] boundingRectWithSize:maxMsgSize
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:textFont}
                                                     context:nil];
    
    CGSize frameSize;
    if (nameSize.width > messageRect.size.width) frameSize.width = nameSize.width + 4;
    else frameSize.width = messageRect.size.width + 4;
    
//    if (name)
//    else frameSize.height = messageRect.size.height;
    frameSize.height = nameSize.height + messageRect.size.height;
    
//    if (frameSize.width < 64) frameSize.width = 64;
    
    return frameSize;
}

- (CGFloat)rowHeightForWidth:(CGFloat)width hasNameLabel:(BOOL)hasNameLabel {
    CGSize frameSize = [self frameSizeForWidth:width hasNameLabel:hasNameLabel];
    return kMarginOuter + kMarginInner + frameSize.height + kMarginInner + 20;
}

#pragma mark - Database

-(void)insertMessageIntoDB {
    
    // Put the message into HTTP body data.
    NSString *bodyString;
    bodyString = [NSString stringWithFormat:@"room_id=%ld&user_id=%ld&chat_id=%ld&code=MSG&message=%@",
                  [[[ETRSession sharedSession] room] roomID],
                  [[ETRLocalUser sharedLocalUser] userID],
                  [self chatID],
                  [self messageString]];
    
    // Get the JSON data and parse it.
    NSDictionary *JSONDict = [ETRHTTPHandler JSONDictionaryFromPHPScript:kPHPInsertAction
                                                    bodyString:bodyString];
    NSString *statusCode = [JSONDict objectForKey:@"status"];
    if (![statusCode isEqualToString:@"INSERT_ACTION_MSG_OK"]) {
        NSLog(@"ERROR: %@", statusCode);
    }
    
}

- (NSString *)sentDateHoursAndMinutes {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    
    return [timeFormat stringFromDate:_sentDate];
}

- (NSString *)sentDateDayDate {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"dd MMM"];
    
    return [timeFormat stringFromDate:_sentDate];
}

- (void)setSentDateFromSqlString:(NSString *)dateString {
    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    _sentDate = [timeFormat dateFromString:dateString];
}

@end
