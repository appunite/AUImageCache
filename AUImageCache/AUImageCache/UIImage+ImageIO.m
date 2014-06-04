//
//  UIImage+ImageIO.m
//  AUKit
//
//  Created by Emil Wojtaszek on 11.08.2013.
//  Copyright (c) 2013 AppUnite.com. All rights reserved.
//

//Categories
#import "UIImage+ImageIO.h"

//Frameworks
#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>

@implementation UIImage (ImageIO)

+ (UIImage *)imageWithData:(NSData *)data options:(NSDictionary *)options scale:(CGFloat)scale orientation:(UIImageOrientation)orientation {
    CGImageRef        image = NULL;
    CGImageSourceRef  imageSource;
    
    if (!data) {
        return nil;
    }
    
    // create an image source from the URL
    imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)options);
    
    // make sure the image source exists before continuing
    if (imageSource == NULL) {
        NSLog(@"Image source is NULL"); return nil;
    }
    
    // create an image source from the URL
    image = CGImageSourceCreateImageAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
    
    // release memory
    CFRelease(imageSource);
    
    // make sure the image exists before continuing
    if (image == NULL) {
        NSLog(@"Image not created from image source"); return nil;
    }
    
    // get UIImage ref
    UIImage *outImage = [UIImage imageWithCGImage:image scale:scale orientation:orientation];
    
    // release memory
    CFRelease(image);
    
    // return final image
    return outImage;
}

+ (UIImage *)imageThumbnailWithData:(NSData *)data options:(NSDictionary *)options scale:(CGFloat)scale orientation:(UIImageOrientation)orientation {
    CGImageRef        image = NULL;
    CGImageSourceRef  imageSource;
    
    if (!data) {
        return nil;
    }
    
    // create an image source from the URL
    imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)data, (__bridge CFDictionaryRef)options);
    
    // make sure the image source exists before continuing
    if (imageSource == NULL) {
        NSLog(@"Image source is NULL"); return nil;
    }
    
    // create an image source from the URL
    image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
    
    // release memory
    CFRelease(imageSource);
    
    // make sure the image exists before continuing
    if (image == NULL) {
        NSLog(@"Image not created from image source"); return nil;
    }
    
    // get UIImage ref
    UIImage *outImage = [UIImage imageWithCGImage:image scale:scale orientation:orientation];
    
    // release memory
    CFRelease(image);
    
    // return final image
    return outImage;
}

+ (UIImage *)imageWithContentOfFile:(NSURL *)url options:(NSDictionary *)options scale:(CGFloat)scale orientation:(UIImageOrientation)orientation {
    
    CGImageRef        image = NULL;
    CGImageSourceRef  imageSource;
    
    if (!url) {
        return nil;
    }
    
    // create an image source from the URL
    imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, (__bridge CFDictionaryRef)options);
    
    // make sure the image source exists before continuing
    if (imageSource == NULL) {
        NSLog(@"Image source is NULL"); return nil;
    }
    
    // create an image from the first item in the image source.
    image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    
    // release memory
    CFRelease(imageSource);
    
    // make sure the image exists before continuing
    if (image == NULL) {
        NSLog(@"Image not created from image source"); return nil;
    }
    
    // get UIImage ref
    UIImage *outImage = [UIImage imageWithCGImage:image scale:scale orientation:orientation];
    
    // release memory
    CFRelease(image);
    
    // return final image
    return outImage;
}

+ (UIImage *)imageThumbnailWithContentOfFile:(NSURL *)url options:(NSDictionary *)options scale:(CGFloat)scale orientation:(UIImageOrientation)orientation {
    CGImageRef        image = NULL;
    CGImageSourceRef  imageSource;
    
    if (!url) {
        return nil;
    }
    
    // create an image source from the URL
    imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)url, (__bridge CFDictionaryRef)options);
    
    // make sure the image source exists before continuing
    if (imageSource == NULL) {
        NSLog(@"Image source is NULL"); return nil;
    }
    
    // create an image from the first item in the image source.
    image = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, NULL);
    
    // release memory
    CFRelease(imageSource);
    
    // make sure the image exists before continuing
    if (image == NULL) {
        NSLog(@"Image not created from image source"); return nil;
    }
    
    // get UIImage ref
    UIImage *outImage = [UIImage imageWithCGImage:image scale:scale orientation:orientation];
    
    // release memory
    CFRelease(image);
    
    // return final image
    return outImage;
}

- (void)writeImageToURL:(NSURL *)url withType:(NSString *)imageType options:(NSDictionary *)options {
    
    // get image
    CGImageRef image = [self CGImage];
    
    if (image) {
        // set default dict if not exist
        if (!options) {
            options = @{ (NSString *)kCGImageSourceShouldCache : (id)kCFBooleanFalse,
                         (NSString *)kCGImageSourceShouldAllowFloat : (id)kCFBooleanFalse };
        }
        
        // create image destination
        CGImageDestinationRef imageDest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, (__bridge CFStringRef)imageType, 1, (__bridge CFDictionaryRef)options);
        
        if (imageDest != NULL) {
            CGImageDestinationAddImage(imageDest, image, (__bridge CFDictionaryRef)options);
            CGImageDestinationFinalize(imageDest);
            CFRelease(imageDest);
        }
    }
}

@end
