//
//  AUImageFetchController.h
//  AUKit
//
//  Created by Emil Wojtaszek on 17.04.2013.
//  Copyright (c) 2013 AppUnite.com. All rights reserved.
//

//Frameworks
#import <Foundation/Foundation.h>

// AFNetworking
#import <AFNetworking/AFNetworking.h>

//Cahce
#import "AUImageCache.h"

extern NSString *const AUImageErrorDomain;

typedef void (^AUImageFetchSuccessHandler)(UIImage *image, NSString *url);
typedef void (^AUImageFetchFailureHandler)(NSError *error);
typedef UIImage *(^AUImageFetchProcessingHandler)(UIImage *image);

@interface AUImageFetchController : NSObject {
    // key identifier, value operation
    NSMutableDictionary *_operations;
    
    // disk operation serial GCD queue
    NSOperationQueue *_storageQueue;
    
    // NSURLConnection concurrent download queue
    NSOperationQueue *_downloadQueue;
}

// shared instance
+ (instancetype)sharedDownloader;

// generate unique image identifier base on image URL
- (NSString *)imageIdentifierForURL:(NSString *)url;

// will cancel all not started operations
- (void)cancelOperationWithIdentifier:(NSString *)identifier;
- (void)cancelAllOperations;

// cache memory cache for identifier
- (UIImage *)imageFromMemoryCacheWithURL:(NSString *)url;
- (UIImage *)imageFromMemoryCacheWithIdentifier:(NSString *)identifier;

// fetch image from URL
- (NSOperation *)fetchImageWithURL:(NSString *)url
                           success:(AUImageFetchSuccessHandler)success
                           failure:(AUImageFetchFailureHandler)failure;

- (NSOperation *)fetchImageWithURL:(NSString *)url
              imageProcessingBlock:(AUImageFetchProcessingHandler)imageProcessingBlock
                           success:(AUImageFetchSuccessHandler)success
                           failure:(AUImageFetchFailureHandler)failure;

// return download request for URL
- (NSURLRequest *)imageDownloadRequestForURL:(NSString *)url;

@end

@interface AUImageFetchController ()

/** Keep cache object, which take care of caching downloaded imaged, default [AUImageCache sharedCache] */
@property (nonatomic, strong) AUImageCache *imageCache;

@end

