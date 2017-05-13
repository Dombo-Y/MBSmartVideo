//
//  WXSmartVideoView.h
//  SmartVideo
//
//  Created by yindongbo on 2017/5/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WXSmartVideoView : UIView


@property (nonatomic, copy) void (^finishedRecordBlock)(NSDictionary *dic);

@property (nonatomic, copy) void (^finishedCaptureBlock)(UIImage *img);



- (instancetype)initWithFrame:(CGRect)frame GPUImage:(BOOL)open;
@end
