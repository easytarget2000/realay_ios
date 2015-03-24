//
//  ETRImageConnectionHandler.m
//  Realay
//
//  Created by Michel on 26/02/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRImageConnectionHandler.h"

#import "ETRImageEditor.h"

#define kDebugTag @"ETRImageConnectionHandler"

@interface ETRImageConnectionHandler()

@property (retain, nonatomic) NSMutableData * activeDlData;

@property (retain, nonatomic) NSURLConnection * imageConnection;

@property (retain, nonatomic) ETRImageLoader * imageLoader;

@property (nonatomic) BOOL doLoadHiRes;

@end


@implementation ETRImageConnectionHandler

@synthesize activeDlData = _activeDlData;
@synthesize imageConnection = _imageConnection;
@synthesize imageLoader = _imageLoader;
@synthesize doLoadHiRes = _doLoadHiRes;

- (id)initWithImageLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL)doLoadHiRes {
    self = [super init];
    
    _imageLoader = imageLoader;
    _doLoadHiRes = doLoadHiRes;
    
    // Initialise empty data.
    _activeDlData = [NSMutableData data];
    return self;
}

+ (void)performRequest:(NSURLRequest *)request
                                    forLoader:(ETRImageLoader *)imageLoader
                                  doLoadHiRes:(BOOL)doLoadHiRes {    
    ETRImageConnectionHandler *instance = [[ETRImageConnectionHandler alloc] initWithImageLoader:imageLoader doLoadHiRes:doLoadHiRes];
    [instance imageConnection:[[NSURLConnection alloc] initWithRequest:request delegate:instance]];
}

- (void)imageConnection:(NSURLConnection *)imageConnection {
    _imageConnection = imageConnection;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"Response: %@", response);
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_activeDlData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // Release the data and clear the connection.
    _activeDlData = nil;
    _imageConnection = nil;
    NSLog(@"ERROR: %@: %@", kDebugTag, error);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if (!_imageLoader) return;
    // Try to build an image from the received data.
    UIImage *image = [[UIImage alloc] initWithData:_activeDlData];
    // Release the data and clear the connection.
    _activeDlData = nil;
    _imageConnection = nil;
    
    if (!image) {
        NSLog(@"ERROR: %@: No image in data: %@", kDebugTag, _activeDlData);
        return;
    }
    
    // Display the image and store the image file and the low-res image inside of the Object.
    UIImageView *loaderImageView = [_imageLoader targetImageView];
    [ETRImageEditor cropImage:image applyToView:loaderImageView withTag:[_imageLoader tag]];
    
    
    // Store the image as a file and the low-res image in the Object.
    ETRChatObject *loaderObject = [_imageLoader chatObject];
    if (!_doLoadHiRes && loaderObject) {
        [loaderObject setLowResImage:image];
    }
    
    [UIImageJPEGRepresentation(image, 1.0f) writeToFile:[[_imageLoader chatObject] imageFilePath:_doLoadHiRes]
                                             atomically:YES];
}

@end
