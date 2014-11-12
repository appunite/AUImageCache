//
//  NSData+ImageContentType.h
//  AUKit
//
//  Created by Natalia Osiecka on 10.3.2014.
//  Copyright (c) 2014 AppUnite.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//Frameworks
#import "decode.h"

typedef NS_ENUM(NSUInteger, AUImageContentType) {
    AUImageContentTypeOther = 0,
    AUImageContentTypeJPEG,
    AUImageContentTypePNG,
    AUImageContentTypeGIF,
    AUImageContentTypeTIFF,
    AUImageContentTypeWEBP
};

@interface NSData (ImageContentType)

// draws image from data
- (UIImage *)imageAtScale:(CGFloat)scale webpConfig:(WebPDecoderConfig *)config;

// draws inflated image from data (faster than imageAtScale:webpConfig:), should use this method if possible
- (UIImage *)inflatedImageAtScale:(CGFloat)scale webpConfig:(WebPDecoderConfig *)config;

// use to get image data type from NSData
- (AUImageContentType)contentType;

// use to get mnemonical html type of image from AUImageContentTypes
+ (NSString *)htmlContentTypeFromAUImageContentType:(AUImageContentType)imageContentType;

@end
