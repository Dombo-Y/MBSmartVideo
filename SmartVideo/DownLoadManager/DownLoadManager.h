//
//  DownLoadManager.h
//  SmartVideo
//
//  Created by yindongbo on 2017/4/24.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownLoadManager : NSObject

 
typedef void (^resultBlock)(NSString *url, NSString *m, NSInteger code);
typedef void (^processBlock)(CGFloat processNum);

+ (void)qnFileUploadWithPath:(NSString *)path result:(resultBlock)block;

+ (void)downLoadFileWithURL:(NSString *)url process:(processBlock)processBlock result:(resultBlock)resultBlock;
@end
