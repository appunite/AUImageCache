//
//  AUImageCache.h
//  AUKit
//
//  Created by Emil Wojtaszek on 06.12.2012.
//  Copyright (c) 2012 AppUnite.com. All rights reserved.
//

//Frameworks
#import <Foundation/Foundation.h>

//Others
#import "AUCache.h"

@interface AUImageCache : AUCache

/** Shared singleton */
+ (instancetype)sharedImageCache;

// Whether to automatically inflate response image data for compressed formats (such as PNG or JPEG). Enabling this can significantly improve drawing performance on iOS when used with `setCompletionBlockWithSuccess:failure:`, as it allows a bitmap representation to be constructed in the background rather than on the main thread. `YES` by default.
@property (nonatomic, assign) BOOL automaticallyInflatesResponseImage;

// return if image exists in either memory or disc cache
- (BOOL)dataExistsForKey:(NSString *)key cachePolicy:(AUCachePolicy)policy;

// save image to memory cache
- (void)setImage:(UIImage *)image forKey:(NSString *)key cachePolicy:(AUCachePolicy)policy;

// save data to disc cache
- (void)setData:(NSData *)data forKey:(NSString *)key cachePolicy:(AUCachePolicy)policy;

// returns image from either memory or disc cache, also caches to memory if only disc cache available for given key
- (UIImage *)imageForKey:(NSString *)key cachePolicy:(AUCachePolicy)policy cacheInMemory:(BOOL)memory;

// utility to convert NSData image to UIImage
- (UIImage *)imageFromData:(NSData *)data;

@end
