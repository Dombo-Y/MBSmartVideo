//
//  WXSmartVideoView.m
//  SmartVideo
//
//  Created by yindongbo on 2017/5/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "WXSmartVideoView.h"
#import "WXSmartVideoControlView.h"
#import "MBSmartVideoRecorder.h"
@interface WXSmartVideoView()

@property (nonatomic, strong) UIButton *invertBtn;
@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) WXSmartVideoControlView *controlView; // 包含箭头和文字 and controlView

@property (nonatomic, strong) MBSmartVideoRecorder *recorder;
@end

#define kMAXDURATION 6
@implementation WXSmartVideoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        
        self.backgroundColor = [UIColor blackColor];
//        self.alpha = 0.7;
        
        [self addSubview:self.preview];
        [self addSubview:self.invertBtn];
        [self addSubview:self.controlView];
        
        [self configRecorder];
        [self.recorder setup];
        [self configCaptureUI];
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.recorder startSession];
        });
    }
    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self removeFromSuperview];
}

#pragma mark - LazyInit
- (UIButton *)invertBtn {
    if (!_invertBtn) {
        _invertBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _invertBtn.backgroundColor = [UIColor brownColor];
        [_invertBtn addTarget:self action:@selector(InvertShot) forControlEvents:UIControlEventTouchUpInside];
        _invertBtn.frame = CGRectMake(SCREEN_WIDTH - 60, 10, 50, 50);
    }
    return _invertBtn;
}

- (WXSmartVideoControlView *)controlView {
    if (!_controlView) {
        _controlView = [[WXSmartVideoControlView alloc] initWithFrame:CGRectMake(0,SCREEN_HEIGHT - 180, SCREEN_WIDTH, 300)];
        _controlView.backgroundColor = [UIColor clearColor];
    }
    return _controlView;
}

- (UIView *)preview {
    if (!_preview) {
        _preview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _preview.backgroundColor = [UIColor purpleColor];
    }
    return _preview;
}

#pragma mark - ActionMethod
- (void)InvertShot {
    NSLog(@"翻转镜头");
    [self.recorder swapFrontAndBackCameras];
}

#pragma mark - configRecorder
- (void)configRecorder {
    self.recorder = [MBSmartVideoRecorder sharedRecorder];
    self.recorder.maxDuration = kMAXDURATION;
    self.recorder.cropSize = self.preview.frame.size;
    
    __weak __typeof(&*self)weakSelf = self;
    [self.recorder setFinishBlock:^(NSDictionary *info, RecorderFinishedReason reason) {
         switch (reason)
         {
             case RecorderFinishedReasonNormal:
             case RecorderFinishedReasonBeyondMaxDuration:
             {
                 NSLog(@"%@", info);
//                 if (weakSelf.finishedRecordBlock)
//                 {
//                     weakSelf.finishedRecordBlock(info);
//                 }
                 [weakSelf removeSelf];
             }
                 break;
             case RecorderFinishedReasonCancle:
             {
                 NSLog(@"重置");
             }
                 break;
         }
     }];
}

- (void)removeSelf {
    [self.recorder stopSession];
    [self removeFromSuperview];
}

- (void)configCaptureUI {
    CALayer *tempLayer = [self.recorder getPreviewLayer];
    tempLayer.frame = self.preview.bounds;
    [self.preview.layer  addSublayer:tempLayer];
}
@end
