//
//  UIColor+Category.h
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Category)
// 通过颜色返回一个1*1大小的纯色图片
- (UIImage *)image;

+ (UIColor *)transformWithHexString:(NSString *)hexString;
@end
