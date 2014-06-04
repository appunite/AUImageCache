//
//  NSString+Hash.m
//
//  Copyright 2011 AppUnite. All rights reserved.
//

#import "NSString+Hash.h"
#import "NSData+Hash.h"

//Frameworks
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Hash)

- (NSString *)md5Hash {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] md5Hash];
}

- (NSString *)sha1Hash {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] sha1Hash];
}

@end
