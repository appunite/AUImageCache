//
//  NSData+Hash.m
//
//  Copyright 2011 AppUnite. All rights reserved.
//

#import "NSData+Hash.h"

//Frameworks
#import <CommonCrypto/CommonDigest.h>

@implementation NSData (Hash)

- (NSString *)md5Hash {
    // This is the destination
    uint8_t digest[CC_MD5_DIGEST_LENGTH];
    // This one function does an unkeyed MD5 hash of your hash data
    CC_MD5([self bytes], [self length], digest);
    
    // return string
    return [self stringFromHexArray:digest];
}

- (NSString *)sha1Hash {
    // This is the destination
    uint8_t digest[CC_SHA1_DIGEST_LENGTH] = {0};
    // This one function does an unkeyed SHA1 hash of your hash data
    CC_MD5([self bytes], [self length], digest);
    
    // return string
    return [self stringFromHexArray:digest];
}

- (NSString *)stringFromHexArray:(unsigned char *)digest {
    // credits - Jackek Marchwicki
    //##OBJCLEAN_SKIP##
    char data[CC_MD5_DIGEST_LENGTH * 2 + 1];
    int dest_data = 0;
    //##OBJCLEAN_ENDSKIP##
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; ++i) {
        char byte = digest[i];
        char char1 = ((byte >> 4) & 0x0f) + '0';
        if (char1 > '9') {
            char1 = char1 - '9' + 'a' - 1;
        }
        char char2 = (byte & 0x0f) + '0';
        if (char2 > '9') {
            char2 = char2 - '9' + 'a' - 1;
        }
        data[dest_data++] = char1;
        data[dest_data++] = char2;
    }
    data[dest_data] = '\0';
    
    return [NSString stringWithCString:data encoding:NSASCIIStringEncoding];
}

@end
