//
//  UIColor+Category.m
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "UIColor+Category.h"

@implementation UIColor (Category)
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

+ (UIColor *)transformWithHexString:(NSString *)hexString
{
    if (hexString) {
        NSMutableString * hexStringMutable = [NSMutableString stringWithString:hexString];
        [hexStringMutable replaceCharactersInRange:[hexStringMutable rangeOfString:@"#" ] withString:@"0x"];
        // 十六进制字符串转成整形。
        long colorLong = strtoul([hexStringMutable cStringUsingEncoding:NSUTF8StringEncoding], 0, 16);
        // 通过位与方法获取三色值
        int R = (colorLong & 0xFF0000 )>>16;
        int G = (colorLong & 0x00FF00 )>>8;
        int B =  colorLong & 0x0000FF;
        
        //string转color
        return [UIColor colorWithRed:R/255.0 green:G/255.0 blue:B/255.0 alpha:1.0];
    }
    return [[UIColor alloc] init];
    
}
@end
