//
//  UIImage+Category.h
//  SmartVideo
//
//  Created by yindongbo on 2017/5/12.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Category)

+ (UIImage *)fixOrientation:(UIImage *)aImage;

+ (UIImage *)rotateImage:(UIImage *)aImage;
@end
