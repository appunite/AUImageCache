//
//  NSData+ImageContentType.m
//  AUKit
//
//  Created by Natalia Osiecka on 10.3.2014.
//  Copyright (c) 2014 AppUnite.com. All rights reserved.
//

#import "NSData+ImageContentType.h"

@implementation NSData (ImageContentType)

- (AUImageContentType)contentType {
    uint8_t c;
    [self getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return AUImageContentTypeJPEG;
        case 0x89:
            return AUImageContentTypePNG;
        case 0x47:
            return AUImageContentTypeGIF;
        case 0x49:
        case 0x4D:
            return AUImageContentTypeTIFF;
        case 0x52:
            // R as RIFF for WEBP
            if ([self length] < 12) {
                return AUImageContentTypeOther;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[self subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return AUImageContentTypeWEBP;
            }
            
            return AUImageContentTypeOther;
    }
    
    return AUImageContentTypeOther;
}

+ (NSString *)htmlContentTypeFromAUImageContentType:(AUImageContentType)imageContentType {
    switch (imageContentType) {
        case AUImageContentTypeJPEG:
            return @"image/jpeg";
        case AUImageContentTypeGIF:
            return @"image/gif";
        case AUImageContentTypeTIFF:
            return @"image/tiff";
        case AUImageContentTypePNG:
            return @"image/png";
        case AUImageContentTypeWEBP:
            return @"image/webp";
        default: // AUImageContentTypeOther
            return @"";
    }
}

// Callback for CGDataProviderRelease //
static void FreeImageData(void *info, const void *data, size_t size) {
    free((void *)data);
}

- (UIImage *)imageAtScale:(CGFloat)scale webpConfig:(WebPDecoderConfig *)config {
    uint8_t c;
    [self getBytes:&c length:1];
    NSString *testString = [[NSString alloc] initWithData:[self subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
    if (!(c == 0x52 && [testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"])) {
        return [UIImage imageWithData:self];
    }
    
    // Decode the WebP image data into a RGBA value array.
    if (WebPDecode([self bytes], [self length], config) != VP8_STATUS_OK) {
        return nil;
    }
    
    int width = config->input.width;
    int height = config->input.height;
    if (config->options.use_scaling) {
        width = config->options.scaled_width;
        height = config->options.scaled_height;
    }
    
    // Construct a UIImage from the decoded RGBA value array.
    CGDataProviderRef provider =
    CGDataProviderCreateWithData(NULL, config->output.u.RGBA.rgba, config->output.u.RGBA.size, FreeImageData);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef =
    CGImageCreate(width, height, 8, 32, 4 * width, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    
    // orientation isn't supported by library for now
    UIImage *newImage = [[UIImage alloc] initWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    
    return newImage;
    
}

- (UIImage *)inflatedImageAtScale:(CGFloat)scale webpConfig:(WebPDecoderConfig *)config {
    if (!self || [self length] == 0) {
        return nil;
    }
    
    UIImage *image = [self imageAtScale:scale webpConfig:config];
    if (image.images) {
        return image;
    }
    
    CGImageRef imageRef = nil;
    CGDataProviderRef dataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)self);
    
    if ([self contentType] == AUImageContentTypePNG) {
        imageRef = CGImageCreateWithPNGDataProvider(dataProvider,  NULL, true, kCGRenderingIntentDefault);
    } else if ([self contentType] == AUImageContentTypeJPEG) {
        imageRef = CGImageCreateWithJPEGDataProvider(dataProvider, NULL, true, kCGRenderingIntentDefault);
    }
    
    if (!imageRef) {
        imageRef = CGImageCreateCopy([image CGImage]);
        
        if (!imageRef) {
            CGDataProviderRelease(dataProvider);
            
            return image;
        }
    }
    
    CGDataProviderRelease(dataProvider);
    
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    size_t bytesPerRow = 0; // CGImageGetBytesPerRow() calculates incorrectly in iOS 5.0, so defer to CGBitmapContextCreate()
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    
    if (CGColorSpaceGetNumberOfComponents(colorSpace) == 3) {
        int alpha = (bitmapInfo & kCGBitmapAlphaInfoMask);
        if (alpha == kCGImageAlphaNone) {
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaNoneSkipFirst;
        } else if (!(alpha == kCGImageAlphaNoneSkipFirst || alpha == kCGImageAlphaNoneSkipLast)) {
            bitmapInfo &= ~kCGBitmapAlphaInfoMask;
            bitmapInfo |= kCGImageAlphaPremultipliedFirst;
        }
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
    
    CGColorSpaceRelease(colorSpace);
    
    if (!context) {
        CGImageRelease(imageRef);
        
        return image;
    }
    
    CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
    CGContextDrawImage(context, rect, imageRef);
    CGImageRef inflatedImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    UIImage *inflatedImage = [[UIImage alloc] initWithCGImage:inflatedImageRef scale:scale orientation:image.imageOrientation];
    CGImageRelease(inflatedImageRef);
    CGImageRelease(imageRef);
    
    return inflatedImage;
}

@end
