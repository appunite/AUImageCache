//
//  AUImageFetchController.m
//  AUKit
//
//  Created by Emil Wojtaszek on 17.04.2013.
//  Copyright (c) 2013 AppUnite.com. All rights reserved.
//

#import "AUImageFetchController.h"

//Categories
#import "NSString+Hash.h"

NSString *const AUImageErrorDomain = @"com.appunite.AppUnite.ImageErrorDomain";

@implementation AUImageFetchController

+ (instancetype)sharedDownloader {
    static dispatch_once_t pred;
    static id  __sharedManager;
    dispatch_once(&pred, ^{
        __sharedManager = [[self alloc] init];
    });
    
    return __sharedManager;
}

- (id)init {
    self = [super init];
    if (self) {
        
        // set default image cache
        _imageCache = [AUImageCache sharedImageCache];
        
        // create storage queue
        _storageQueue = [[NSOperationQueue alloc] init];
        _storageQueue.name = @"com.aukit.AUImageFetchController.storageQueue";
        _storageQueue.maxConcurrentOperationCount = 2;
        
        // create download operation queue
        _downloadQueue = [[NSOperationQueue alloc] init];
        _downloadQueue.name = @"com.aukit.AUImageFetchController.downloadQueue";
        _downloadQueue.maxConcurrentOperationCount = 4;
        
        // create dictionaries
        _operations = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (NSString *)imageIdentifierForURL:(NSString *)url {
    return [url sha1Hash];
}

- (NSURLRequest *)imageDownloadRequestForURL:(NSString *)path {
    NSURL *url = [NSURL URLWithString:path];
    
    return [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0f];
}

#pragma mark - Fetching images

- (UIImage *)imageFromMemoryCacheWithURL:(NSString *)url {
    // get identifier
    NSString *identifier = [self imageIdentifierForURL:url];
    // check cache
    return [self imageFromMemoryCacheWithIdentifier:identifier];
}

- (UIImage *)imageFromMemoryCacheWithIdentifier:(NSString *)identifier {
    // check cache
    return [_imageCache imageForKey:identifier cachePolicy:AUCachePolicyMemory cacheInMemory:NO];
}

- (NSOperation *)fetchImageWithURL:(NSString *)url
              imageProcessingBlock:(AUImageFetchProcessingHandler)imageProcessingBlock
                           success:(AUImageFetchSuccessHandler)success
                           failure:(AUImageFetchFailureHandler)failure {
    
    // handle nil url
    if (!url) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: NSLocalizedString(@"Couldn't download image", nil),
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"Url doesn't exist", nil),
                                   NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please contact with developer", nil)};
        
        failure([NSError errorWithDomain:AUImageErrorDomain code:90 userInfo:userInfo]);
    }
    
    // make sure to get string not url
    if ([url isKindOfClass:[NSURL class]]) {
        url = [(NSURL *)url absoluteString];
    }
    
    NSOperation *operation = nil;
    
    // get unique identifer
    NSString *identifier = [self imageIdentifierForURL:url];
    
    // memory cache
    UIImage *image = [self imageFromMemoryCacheWithIdentifier:identifier];
    if (image) {
        // fire success block
        if (success) {
            success(image, url);
        }
        
        return nil;
        
    // disk cache
    } else if ([_imageCache isCacheForKey:identifier policy:AUCachePolicyDisk]) {
        // fetch image from disk cache
        operation = [self fetchDiskImageForUrl:url withIdentifier:identifier
                                       success:success failure:failure];
        
        // add operation to queue
        [_storageQueue addOperation:operation];
        
    // remote source
    } else {
        // fetch image from remote source
        operation = [self fetchRemoteImageWithURL:url
                                       identifier:identifier
                             imageProcessingBlock:imageProcessingBlock
                                          success:success failure:failure];
        // add operation to queue
        [_downloadQueue addOperation:operation];
    }
    
    // make sure there is no operation with such key
    if (operation && identifier.length > 0 && ![_operations objectForKey:identifier]) {
        // save operation object
        [_operations setObject:operation forKey:identifier];
        
        // add observer for isFinished property
        [operation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:(__bridge void *)(identifier)];
    } else {
        [operation cancel];
    }
    
    return operation;
}

- (NSOperation *)fetchImageWithURL:(NSString *)url
                           success:(AUImageFetchSuccessHandler)success
                           failure:(AUImageFetchFailureHandler)failure {
    
    return [self fetchImageWithURL:url imageProcessingBlock:nil success:success failure:failure];
}

#pragma mark - Private

- (NSOperation *)operationWithIdentifier:(NSString *)identifier {
    return [_operations objectForKey:identifier];
}

- (NSOperation *)fetchDiskImageForUrl:(NSString *)url withIdentifier:(NSString *)identifier
                              success:(AUImageFetchSuccessHandler)success
                              failure:(AUImageFetchFailureHandler)failure {
    
    NSBlockOperation *operation = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation *weakOperation = operation;
    
    [operation addExecutionBlock:^{
        if (![weakOperation isCancelled]) {
            
            // get image from disk cache
            UIImage *cachedImage = [_imageCache imageForKey:identifier cachePolicy:AUCachePolicyDisk cacheInMemory:NO];
            
            if (cachedImage) {
                // move to main queue
                dispatch_async(dispatch_get_main_queue(), ^ {
                    // fire success block
                    if (success) {
                        success(cachedImage, url);
                    }
                });
            } else {
                // move to main queue
                dispatch_async(dispatch_get_main_queue(), ^ {
                    // create error
                    NSError *error = [NSError errorWithDomain:AUImageErrorDomain code:100 userInfo:nil];
                    // fire failure block
                    if (failure) {
                        failure(error);
                    }
                });
            }
        }
    }];
    
    // return operation
    return operation;
}

- (NSOperation *)fetchRemoteImageWithURL:(NSString *)url
                              identifier:(NSString *)identifier
                    imageProcessingBlock:(AUImageFetchProcessingHandler)imageProcessingBlock
                                 success:(AUImageFetchSuccessHandler)success
                                 failure:(AUImageFetchFailureHandler)failure {
    
    
    // create & get download request
    NSURLRequest *request = [self imageDownloadRequestForURL:url];
    
    // create operation
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        // save data to disc cache
        [_storageQueue addOperationWithBlock:^{
            [_imageCache setData:responseObject forKey:identifier cachePolicy:AUCachePolicyAll];
        }];
        
        // fire success block
        if (success) {
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                // save image to memory cache
                UIImage *resultImage = [_imageCache imageFromData:responseObject];
                [_imageCache setImage:resultImage forKey:identifier cachePolicy:AUCachePolicyAll];
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    success(resultImage, url);
                });
            });
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // fire failure block
        if (failure) {
            failure(error);
        }
    }];
    
    // return operation for later use (eg with queue)
    return operation;
}

#pragma mark - Canceling

- (void)cancelOperationWithIdentifier:(NSString *)identifier {
    // make sure there is identifier
    if (!identifier || identifier.length == 0) {
        return;
    }
    
    NSOperation *operation = [self operationWithIdentifier:identifier];
    
    // cancel operation if not executing
    if (![operation isExecuting]) {
        [operation cancel];
    }
    
    // remove operation from dict
    [_operations removeObjectForKey:identifier];
}

- (void)cancelAllOperations {
    [_downloadQueue cancelAllOperations];
    [_storageQueue cancelAllOperations];
    
    [_operations removeAllObjects];
}

- (void)convertDownloadedImage:(NSData *)data conversionBlock:(AUImageFetchProcessingHandler)convBlock cacheWithIdentifier:(NSString *)identifier completitionBlock:(AUImageFetchSuccessHandler)compBlock {
//    dispatch_async(
//        _renderQueue, ^ {
//
//        // get image representation of data
//        UIImage* image = !convBlock ? _conversionBlock(data) : convBlock(data);
//
//        // move to main queue
//        dispatch_async(dispatch_get_main_queue(), ^ {
//            if (compBlock) {
//                compBlock(identifier, image, nil, AUCachePolicyNone);
//            }
//        });
//
//        dispatch_async(_storageQueue, ^ {
//            // save image in memory cache
//            [_imageCache setImage:image forKey:identifier cachePolicy:AUCachePolicyAll imageType:type];
//        });
//    });
}

#pragma mark - Key-Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isFinished"] && [change[@"new"] isEqualToNumber:@(YES)]) {
        // get identifier from context
        id identifer = (__bridge id)context;
        
        // remove operation from array base on operation identifier
        if (identifer && [identifer isKindOfClass:[NSString class]] && [(NSString *)identifer length] > 0) {
            [_operations removeObjectForKey:identifer];
        }
        
        // remove object observer
        [object removeObserver:self forKeyPath:@"isFinished"];
    }
}

@end
