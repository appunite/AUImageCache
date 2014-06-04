//
//  UIImage+ImageIO.h
//  AUKit
//
//  Created by Emil Wojtaszek on 11.08.2013.
//  Copyright (c) 2013 AppUnite.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ImageIO)

/** Load image from NSData using ImageIO framework */
+ (UIImage *)imageWithData:(NSData *)data options:(NSDictionary *)options scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;
+ (UIImage *)imageThumbnailWithData:(NSData *)data options:(NSDictionary *)options scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;

/** Load image at given URL using ImageIO framework */
+ (UIImage *)imageWithContentOfFile:(NSURL *)url options:(NSDictionary *)options scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;
+ (UIImage *)imageThumbnailWithContentOfFile:(NSURL *)url options:(NSDictionary *)options scale:(CGFloat)scale orientation:(UIImageOrientation)orientation;

/** Save image at given URL using ImageIO framework */
- (void)writeImageToURL:(NSURL *)url withType:(NSString *)imageType options:(NSDictionary *)options;

@end
