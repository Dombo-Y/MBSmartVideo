//
//  UIColor+UIImage.m
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "UIColor+UIImage.h"




@implementation UIColor (UIImage)

// 通过颜色返回一个1*1大小的纯色图片
- (UIImage *)image {
    
    CGRect imageRect = CGRectMake(0, 0, 1, 1);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nil,
                                                 1,
                                                 1,
                                                 8,
                                                 4,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast);
    CGContextSetFillColorWithColor(context, [self CGColor]);
    CGContextFillRect(context, imageRect);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CFRelease(imageRef);
    
    return newImage;
}

@end
