//
//  WXSmartVideoBottomView.h
//  SmartVideo
//
//  Created by yindongbo on 2017/5/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WXSmartVideoBottomView;
@protocol WXSmartVideoDelegate <NSObject>

- (void)wxSmartVideo:(WXSmartVideoBottomView *)smartVideoView zoomLens:(CGFloat)scaleNum;

- (void)wxSmartVideo:(WXSmartVideoBottomView *)smartVideoView isRecording:(BOOL)recording;

- (void)wxSmartVideo:(WXSmartVideoBottomView *)smartVideoView captureCurrentFrame:(BOOL)capture;

@end

@interface WXSmartVideoBottomView : UIView

@property (nonatomic, copy)void (^backBlock)();

@property (nonatomic, weak)id <WXSmartVideoDelegate>delegate;

@property (nonatomic, assign)NSInteger duration;
@end

