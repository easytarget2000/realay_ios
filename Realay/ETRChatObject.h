//
//  ETRChatObject.h
//  Realay
//
//  Created by Michel on 26/02/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface ETRChatObject : NSManagedObject

@property (nonatomic, retain) NSNumber *remoteID;
@property (nonatomic, retain) NSNumber *imageID;
@property (strong, nonatomic) UIImage *lowResImage;

- (NSString *)imageFileName:(BOOL)doLoadHiRes;

- (NSString *)imageFilePath:(BOOL)isHiRes;

- (void)deleteImageFiles;

@end
