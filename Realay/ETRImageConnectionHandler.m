//
//  ETRImageConnectionHandler.m
//  Realay
//
//  Created by Michel on 26/02/15.
//  Copyright (c) 2015 Easy Target. All rights reserved.
//

#import "ETRImageConnectionHandler.h"

#import "SharedMacros.h"

#define kDebugTag @"ETRImageConnectionHandler"

@implementation ETRImageConnectionHandler {
    NSMutableData *_activeDlData;
    NSURLConnection *_imageConnection;
    ETRImageLoader *_imageLoader;
    BOOL _doLoadHiRes;
}

- (id)initWithImageLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL)doLoadHiRes {
    self = [super init];
    
    _imageLoader = imageLoader;
    _doLoadHiRes = doLoadHiRes;
    
    // Initialise empty data.
    _activeDlData = [NSMutableData data];
    return self;
}

+ (void)loadForLoader:(ETRImageLoader *)imageLoader doLoadHiRes:(BOOL)doLoadHiRes {
    if (!imageLoader) return;
    
    // Prepare the URL to the download script.
    NSString *URLString = [NSString stringWithFormat:@"%@%@",
                           kURLPHPScripts, kPHPDownloadImage];
    NSURL *URL = [NSURL URLWithString:URLString];
    
    // Prepare the POST request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    NSString *bodyString;
    
    ETRChatObject *chatObject = [imageLoader chatObject];
    if (!chatObject) return;
    if ([chatObject imageID] < 100) return;
    bodyString = [NSString stringWithFormat:@"image_id=%@", [chatObject imageIDWithHiResFlag:doLoadHiRes]];
    NSData *bodyData = [bodyString dataUsingEncoding:NSASCIIStringEncoding];
    [request setHTTPBody:[NSMutableData dataWithData:bodyData]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:kHTTPTimeout];
    
    ETRImageConnectionHandler *instance = [[ETRImageConnectionHandler alloc] initWithImageLoader:imageLoader doLoadHiRes:doLoadHiRes];
    [instance imageConnection:[[NSURLConnection alloc] initWithRequest:request delegate:instance]];
}

- (void)imageConnection:(NSURLConnection *)imageConnection {
    _imageConnection = imageConnection;
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
    if (loaderImageView) {
       // TODO: Check that image currently in this View is smaller before replacing it.
       [loaderImageView setImage:image];
    }
    
    ETRChatObject *loaderObject = [_imageLoader chatObject];
    if (!_doLoadHiRes && loaderObject) [loaderObject setLowResImage:image];
    [UIImageJPEGRepresentation(image, 1.0f) writeToFile:[_imageLoader imagefilePath:_doLoadHiRes] atomically:YES];
    
//    if (_completionHandler) _completionHandler();
}

@end
