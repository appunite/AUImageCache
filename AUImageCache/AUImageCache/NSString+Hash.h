//
//  NSString+Hash.h
//
//  Copyright 2011 AppUnite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Hash)

/**
 * Calculate the md5 hash of this string using CC_MD5.
 *
 * @return md5 hash of this string
 */
@property (nonatomic, readonly) NSString *md5Hash;

/**
 * Calculate the SHA1 hash of this string using CommonCrypto CC_SHA1.
 *
 * @return NSString with SHA1 hash of this string
 */
@property (nonatomic, readonly) NSString *sha1Hash;

@end

