//
//  AUCache.h
//
//  Created by Emil Wojtaszek on 22.01.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

/**
 * Cache policy for determining how to use AUCache
 */
typedef NS_ENUM(NSUInteger, AUCachePolicy) {
    // Never use the cache
    AUCachePolicyNone       = 0,
    // Use only memory caching
    AUCachePolicyMemory     = 1 << 0,
    // Use only disk caching
    AUCachePolicyDisk       = 1 << 1,
    // Use memory and disk caching
    AUCachePolicyAll        = AUCachePolicyMemory | AUCachePolicyDisk
};

/** This class is abstract. Do not use it! */
@interface AUCache : NSObject {
    // array of stored fiels keys
    NSMutableSet *_storedKeys;
}

/** Define location of files storege if cache policy is AUDiskCachePolicy
 ** If you set your own path, it will create for you if not exist */
@property (nonatomic, strong) NSString *defaultCachePath;

/** The maximum length of time to keep an image in the disk cache, in seconds */
@property (assign, nonatomic) NSTimeInterval maxCacheAge;

/** Storage all memory cache */
@property (nonatomic, strong, readonly) NSMapTable *memoryCache;

/** Init a new cache store with a specific namespace */
- (id)initWithNamespace:(NSString *)aNamespace;

/** Return SHA1 hash from string */
+ (NSString *)uniqueKeyForString:(NSString *)string;

/** Check if cache exists in give resource type */
- (BOOL)isCacheForKey:(NSString *)key policy:(AUCachePolicy)cachePolicy;

/** Remove all objects from memory cache */
- (void)removeMemoryCache;

/** Remove all/outdated objects from disk cache */
- (void)removeDiskCache;
- (void)removeOutdatedDiskCache;

@end
