//
//  WXSmartVideoView.m
//  SmartVideo
//
//  Created by yindongbo on 2017/5/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "WXSmartVideoView.h"
#import "WXSmartVideoBottomView.h"
#import "MBSmartVideoRecorder.h"

#import "GPUImage.h"
#import "GPUImageSketchFilter.h"

#import <AssetsLibrary/ALAssetsLibrary.h>
@interface WXSmartVideoView()<
WXSmartVideoDelegate
>

@property (nonatomic, strong) UIButton *invertBtn;
@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) WXSmartVideoBottomView *bottomView; // 包含箭头和文字 and controlView

@property (nonatomic, strong) MBSmartVideoRecorder *recorder;

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
//@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) GPUImageMovieWriter *writer;

@property (nonatomic, strong) GPUImageSobelEdgeDetectionFilter *filter;
@end

#define kMAXDURATION 6


#define kFaceSmartVideo 1
@implementation WXSmartVideoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        
        if (kFaceSmartVideo) {
            NSLog(@"美颜");
            self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
            self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
            self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
//            self.videoCamera.horizontallyMirrorRearFacingCamera = YES;
            
            GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:frame];
            filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
            [self.videoCamera addTarget:filterView];
            [self addSubview:filterView];
            
//            GPUImageSepiaFilter *filter = [[GPUImageSepiaFilter alloc] init];
//            GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
//            _filter = filter;
//            [self.videoCamera addTarget:_filter];
            
//            NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
//            NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
//            _writer = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
//            _writer.encodingLiveVideo = YES;
            
//            [_filter addTarget:filterView];
//            [_filter addTarget:_writer];
 
            [self.videoCamera startCameraCapture];
        }
        else {
            NSLog(@"普通");
            [self addSubview:self.preview];
            [self configRecorder];
            [self.recorder setup];
            [self configCaptureUI];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.recorder startSession];
            });
        }
        
        [self addSubview:self.invertBtn];
        [self addSubview:self.bottomView];
    }
    return self;
}

#pragma mark - LazyInit
- (UIButton *)invertBtn {
    if (!_invertBtn) {
        _invertBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_invertBtn setTitle:@"前置" forState:UIControlStateNormal];
        [_invertBtn setTitle:@"后置" forState:UIControlStateSelected];
        [_invertBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        [_invertBtn addTarget:self action:@selector(InvertShot:) forControlEvents:UIControlEventTouchUpInside];
        _invertBtn.frame = CGRectMake(SCREEN_WIDTH - 60, 10, 50, 50);
    }
    return _invertBtn;
}

- (WXSmartVideoBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[WXSmartVideoBottomView alloc] initWithFrame:CGRectMake(0,SCREEN_HEIGHT - 180, SCREEN_WIDTH, 300)];
        _bottomView.backgroundColor = [UIColor clearColor];
        _bottomView.delegate = self;
        __weak id weakSelf = self;
        [_bottomView setBackBlock:^{
            [weakSelf removeFromSuperview];
        }];
    }
    return _bottomView;
}

- (UIView *)preview {
    if (!_preview) {
        _preview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        _preview.backgroundColor = [UIColor purpleColor];
    }
    return _preview;
}

#pragma mark - ActionMethod
- (void)InvertShot:(UIButton *)btn {
    btn.selected = !btn.selected;
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

#pragma  mark - WXSmartVideoDelegate
- (void)wxSmartVideo:(WXSmartVideoBottomView *)smartVideoView zoomLens:(CGFloat)scaleNum {
//    [self.recorder setScaleFactor:scaleNum];
    NSLog(@"scaleNum == %f" , scaleNum);
}

- (void)wxSmartVideo:(WXSmartVideoBottomView *)smartVideoView isRecording:(BOOL)recording {
    if (recording) {
        NSLog(@"开始录制");
        self.videoCamera.audioEncodingTarget = _writer;
        [_writer startRecording];
    }else {
        self.videoCamera.audioEncodingTarget = nil;
        [_writer finishRecording];
        NSLog(@"结束录制");
    }
}
- (void)writerMove {
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
     NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    _writer = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
    _writer.encodingLiveVideo = YES;
    
    
}
@end
