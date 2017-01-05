//
//  MBSmartVideoConverter.h
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MBSmartVideoConverter : NSObject

//
+ (UIImage *)convertSampleBufferRefToUIImage:(CMSampleBufferRef)sampleBufferRef;

+ (void)convertVideoToGifImageWithURL:(NSURL *)url destinationUrl:(NSURL *)destinationUrl finishBlock:(void (^)(void))finishBlock;
@end
