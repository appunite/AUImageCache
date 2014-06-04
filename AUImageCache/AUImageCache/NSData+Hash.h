//
//  NSData+Hash.h
//
//  Copyright 2011 AppUnite. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Hash)

/** Calculate the md5 hash of this data using CC_MD5.
 @return md5 hash of this data
 */
@property (nonatomic, readonly) NSString *md5Hash;

/** Calculate the SHA1 hash of this data using CC_SHA1.
 @return SHA1 hash of this data
 */
@property (nonatomic, readonly) NSString *sha1Hash;

@end
