//
//  AUImageCache.m
//  AUKit
//
//  Created by Emil Wojtaszek on 06.12.2012.
//  Copyright (c) 2012 AppUnite.com. All rights reserved.
//

#import "AUImageCache.h"

//Others
#import "UIImage+ImageIO.h"
#import "NSData+ImageContentType.h"

//Frameworks
#import <MobileCoreServices/MobileCoreServices.h>
#import <uiimage-from-animated-gif/UIImage+animatedGIF.h>
#import "decode.h"

@implementation AUImageCache

+ (instancetype)sharedImageCache {
    static dispatch_once_t pred;
    static id  __sharedCache;
    dispatch_once(&pred, ^{
        __sharedCache = [[self alloc] init];
    });
    
    return __sharedCache;
}

- (id)init {
    self = [super init];
    if (self) {
        if ([[[UIDevice currentDevice] model] hasPrefix:@"iPod"]) {
            _automaticallyInflatesResponseImage = NO;
        } else {
            _automaticallyInflatesResponseImage = YES;
        }
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *__unused notification) {
            [self removeMemoryCache];
        }];
    }
    
    return self;
}

#pragma mark - Utils

- (BOOL)dataExistsForKey:(NSString *)key cachePolicy:(AUCachePolicy)policy {
    if (policy & AUCachePolicyMemory) {
        // check if cache exist
        UIImage *image = [self.memoryCache objectForKey:key];
        
        // if found, return data
        if (image) {
            return YES;
        }
    }
    
    // check policy
    if (policy & AUCachePolicyDisk) {
        
        // check if file exist
        if ([_storedKeys containsObject:key]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Setters

- (void)setImage:(UIImage *)image forKey:(NSString *)key cachePolicy:(AUCachePolicy)policy {
    if (!key || !image) {
        return;
    }
    
    // save in memory
    if (policy & AUCachePolicyMemory) {
        // store decomprssed image
        [self.memoryCache setObject:image forKey:key];
    }
}

- (void)setData:(NSData *)data forKey:(NSString *)key cachePolicy:(AUCachePolicy)policy {
    
    if (!key || !data) {
        return;
    }
    
    // save on disk
    if (policy & AUCachePolicyDisk) {
        // get save path
        [self writeImageDataToFile:data forKey:key];
    }
}

#pragma mark - Getters

- (NSData *)dataForKey:(NSString *)key cachePolicy:(AUCachePolicy)policy cacheInMemory:(BOOL)memory {
    // check policy
    if (policy & AUCachePolicyDisk) {
        
        // check if file exist
        if ([_storedKeys containsObject:key]) {
            
            // storage path
            NSString *path = [self.defaultCachePath stringByAppendingPathComponent:key];
            
            // get NSData object
            NSData *data = [NSData dataWithContentsOfFile:path];
            
            // return the object
            return data;
        }
    }
    
    // nothing found
    return nil;
}

- (UIImage *)imageForKey:(NSString *)key cachePolicy:(AUCachePolicy)policy cacheInMemory:(BOOL)memory {
    
    if (!key) {
        return nil;
    }
    
    // if image from memory
    if (policy & AUCachePolicyMemory) {
        // check if cache exist
        UIImage *image = [self.memoryCache objectForKey:key];
        
        // if found, return image
        if (image) {
            return image;
        }
    }
    
    // if image from disc
    NSData *data = [self dataForKey:key cachePolicy:policy cacheInMemory:memory];
    if (data) {
        UIImage *image = [self imageFromData:data];
        
        // save to memory cache for later use
        if (image) {
            // store decomprssed image
            [self setImage:image forKey:key cachePolicy:AUCachePolicyMemory];
        }
        
        return image;
    }
    
    return nil;
}

- (UIImage *)imageFromData:(NSData *)data {
    if (data && [data length] > 0) {
        UIImage *outputImage = nil;
        
        if ([data contentType] == AUImageContentTypeGIF) {
            outputImage = [UIImage animatedImageWithAnimatedGIFData:data];
            
        } else {
            WebPDecoderConfig config;
            if (!WebPInitDecoderConfig(&config)) {
                return nil;
            }
            
            config.output.colorspace = MODE_rgbA;
            config.options.use_threads = 1;
            config.options.no_fancy_upsampling = 1;
            config.options.bypass_filtering = 1;
            
            // get the screen scale
            CGFloat scale = [[UIScreen mainScreen] scale];
            
            // draw image
            if (_automaticallyInflatesResponseImage) {
                outputImage = [data inflatedImageAtScale:scale webpConfig:&config];
            } else {
                outputImage = [data imageAtScale:scale webpConfig:&config];
            }
        }
        
        return outputImage;
    }
    
    return nil;
}

#pragma mark - Helpers

- (void)writeImageDataToFile:(NSData *)data forKey:(NSString *)key {
    // get save path
    NSString *path = [self.defaultCachePath stringByAppendingPathComponent:key];
    
    // save file
    [data writeToFile:path atomically:NO];
    
    // save in cached files keys
    @synchronized(self) {
        [_storedKeys addObject:key];
    }
}

@end
