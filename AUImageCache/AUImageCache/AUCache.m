//
//  AUCache.m
//
//  Created by Emil Wojtaszek on 22.01.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AUCache.h"

//Additions
#import "NSString+Hash.h"

static const NSTimeInterval kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week

@interface AUCache ()

- (void)createStorageDirectoryIfNeeded;

@end

@implementation AUCache

+ (instancetype)sharedCache {
    static dispatch_once_t pred;
    static id  __sharedCache;
    dispatch_once(&pred, ^{
        __sharedCache = [[self alloc] init];
    });
    
    return __sharedCache;
}

- (id)init {
    return [self initWithNamespace:@"default"];
}

- (id)initWithNamespace:(NSString *)aNamespace {
    self = [super init];
    if (self) {
        // save default max cache age
        _maxCacheAge = kDefaultCacheMaxCacheAge;
        
        // create memory cache
        _memoryCache = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                             valueOptions:NSMapTableStrongMemory];
        
        // create path component
        NSString *pathComponent = [NSString stringWithFormat:@"com.appunite.%@", aNamespace];
        
        // use setter to create path if needed
        self.defaultCachePath = [[self cacheDirectory] stringByAppendingPathComponent:pathComponent];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(removeOutdatedDiskCache)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    // remove all observers
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // remove outdated cache
#ifndef DEBUG
    [self removeOutdatedDiskCache];
#else
    [self removeDiskCache];
#endif
}

#pragma mark - Class methods

+ (NSString *)uniqueKeyForString:(NSString *)string {
    return [string sha1Hash];
}

- (BOOL)isCacheForKey:(NSString *)key policy:(AUCachePolicy)cachePolicy {
    BOOL result = NO;
    
    // check policy
    if (cachePolicy & AUCachePolicyMemory) {
        // check if cache exist
        result = ([_memoryCache objectForKey:key] != nil);
    }
    
    // check policy
    if (!result && cachePolicy & AUCachePolicyDisk) {
        @synchronized(self) {
            // check if file exist
            result = ([_storedKeys containsObject:key]);
        }
    }
    
    return result;
}

- (void)removeDiskCache {
    // get file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // get path
    NSString *path = self.defaultCachePath;
    
    // remove directory
    [fileManager removeItemAtPath:path error:nil];
    
    // recreate storage directory
    [self createStorageDirectoryIfNeeded];
}

- (void)removeOutdatedDiskCache {
    // get file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // calculate expiration date
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:(-1 * _maxCacheAge)];
    
    // get path
    NSString *path = self.defaultCachePath;
    
    // get file enumerator
    NSDirectoryEnumerator *fileEnumerator = [fileManager enumeratorAtPath:path];
    
    // iterate all items
    for (NSString *fileName in fileEnumerator) {
        // get full item path
        NSString *filePath = [path stringByAppendingPathComponent:fileName];
        // get file attributes
        NSDictionary *attrs = [fileManager attributesOfItemAtPath:filePath error:nil];
        
        // compare date and remove item if needed
        if ([[attrs fileModificationDate] compare:expirationDate] == NSOrderedAscending) {
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }
    
    // create dict (if needed), reload cached keys
    [self createStorageDirectoryIfNeeded];
}

- (void)removeMemoryCache {
    [_memoryCache removeAllObjects];
}

#pragma mark - Setters

- (void)setDefaultCachePath:(NSString *)defaultCachePath {
    
    if (defaultCachePath != _defaultCachePath) {
        _defaultCachePath = defaultCachePath;
        
        // create storage directory if needed
        if (defaultCachePath != nil) {
            [self createStorageDirectoryIfNeeded];
        }
    }
}

- (void)createStorageDirectoryIfNeeded {
    // create cache directory on disk
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.defaultCachePath isDirectory:nil]) {
        [fileManager createDirectoryAtPath:self.defaultCachePath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
    }
    
    @synchronized(self) {
        // load cached files key
        _storedKeys = [NSMutableSet setWithArray:[fileManager contentsOfDirectoryAtPath:self.defaultCachePath error:NULL]];
        
        // create new empty directory if needed
        if (!_storedKeys) {
            _storedKeys = [NSMutableSet new];
        }
    }
}

#pragma mark - Private

- (NSString *)cacheDirectory {
    return [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Caches/AUCache"];
}

@end
