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
#import "WXVideoPreviewViewController.h"
#import "GPUImage.h"
#import "GPUImageSketchFilter.h"
#import "GPUImageBeautifyFilter.h"
#import <AssetsLibrary/ALAssetsLibrary.h>

#import "UIImage+Category.h"

typedef enum : NSUInteger {
    FaceCameraFilterNone,
    FaceCameraFilterBeautify,
    FaceCameraFilterSketch,
} FaceCameraFilterEnum;

@interface WXSmartVideoView()<
WXSmartVideoDelegate
>

@property (nonatomic, strong) UIButton *invertBtn;
@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) WXSmartVideoBottomView *bottomView; // 包含箭头和文字 and controlView

@property (nonatomic, strong) MBSmartVideoRecorder *recorder;

//@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
//GPUImageVideoCamera仅能录像， GPUImageStillCamera 可拍照可录像，继承于GPUImageVideoCamera
@property (nonatomic, strong) GPUImageStillCamera *camera;

@property (nonatomic, strong) GPUImageMovieWriter *writer;
@property (nonatomic, strong) GPUImageBeautifyFilter *beautifyFilter;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) id  tempFilter;


@property (nonatomic, strong) NSURL *videoUrl;

@property (nonatomic, assign) BOOL savingImg;

@property (nonatomic, strong) WXVideoPreviewViewController *vc;

@property (nonatomic, strong) UIView *focusView;

@property (nonatomic, strong) UIButton *selfieBtn;// 开启自拍按钮
@property (nonatomic, assign) BOOL isSelfie; // 是否自拍
@property (nonatomic, strong) UIButton *beautifyBtn; //滤镜button

@property (nonatomic, assign) BOOL OpenGPUImage;
@end


#define kMAXDURATION 10
//#define kWeakSelf
@implementation WXSmartVideoView

- (instancetype)initWithFrame:(CGRect)frame GPUImage:(BOOL)open{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        _OpenGPUImage = open;
        if (open) {
            [self faceSmartVideo]; NSLog(@"美颜");
            [self addSubview:self.beautifyBtn];
        }
        else {
            [self normalSmartVideo]; NSLog(@"普通");
        }
        
        [self addSubview:self.invertBtn];
        [self addSubview:self.bottomView];
//        [self addSubview:self.selfieBtn];
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
        
        CALayer *layer = [[CALayer alloc] init];
        layer.frame = _invertBtn.bounds;
        layer.backgroundColor = [UIColor blackColor].CGColor;
        layer.opacity = 0.7;
        layer.cornerRadius = layer.frame.size.width/2;
        [_invertBtn.layer addSublayer:layer];
    }
    return _invertBtn;
}

- (UIButton *)selfieBtn {
    if (!_selfieBtn) {
        _selfieBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selfieBtn setTitle:@"自拍模式" forState:UIControlStateNormal];
        [_selfieBtn setTitle:@"正常模式" forState:UIControlStateSelected];
        [_selfieBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_selfieBtn addTarget:self action:@selector(selfieAction:) forControlEvents:UIControlEventTouchUpInside];
        _selfieBtn.frame = CGRectMake(SCREEN_WIDTH - 90, 70, 80, 80);
        
        CALayer *layer = [[CALayer alloc] init];
        layer.frame = _selfieBtn.bounds;
        layer.backgroundColor = [UIColor blackColor].CGColor;
        layer.opacity = 0.7;
        layer.cornerRadius = layer.frame.size.width/2;
        [_selfieBtn.layer addSublayer:layer];
        
        _selfieBtn.hidden = YES;
    }
    return _selfieBtn;
}

- (UIButton *)beautifyBtn {
    if (!_beautifyBtn) {
        _beautifyBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_beautifyBtn setTitle:@"无" forState:UIControlStateNormal];
        [_beautifyBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_beautifyBtn addTarget:self action:@selector(filter:) forControlEvents:UIControlEventTouchUpInside];
        _beautifyBtn.frame = CGRectMake(SCREEN_WIDTH - 90, 70, 80, 80);
        _beautifyBtn.tag = 1;
        CALayer *layer = [[CALayer alloc] init];
        layer.frame = _beautifyBtn.bounds;
        layer.backgroundColor = [UIColor blackColor].CGColor;
        layer.opacity = 0.7;
        layer.cornerRadius = layer.frame.size.width/2;
        [_beautifyBtn.layer addSublayer:layer];
    }
    return _beautifyBtn;
}

- (WXSmartVideoBottomView *)bottomView {
    if (!_bottomView) {
        _bottomView = [[WXSmartVideoBottomView alloc] initWithFrame:CGRectMake(0,SCREEN_HEIGHT - 180, SCREEN_WIDTH, 300)];
        _bottomView.backgroundColor = [UIColor clearColor];
        _bottomView.delegate = self;
        _bottomView.duration = kMAXDURATION;
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
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapPreview:)];
        [_preview addGestureRecognizer:tap];
    }
    return _preview;
}

- (NSURL *)videoUrl {
    if (!_videoUrl) {
        NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
        _videoUrl = [NSURL fileURLWithPath:pathToMovie];
        unlink([pathToMovie UTF8String]);
    }
    return _videoUrl;
}

- (GPUImageMovieWriter *)writer {
    if (!_writer) {
        _writer = [[GPUImageMovieWriter alloc] initWithMovieURL:self.videoUrl size:self.filterView.size];
        _writer.encodingLiveVideo = YES;
        _writer.shouldPassthroughAudio = YES;
        _writer.hasAudioTrack=YES;
    }
    return _writer;
}

- (GPUImageStillCamera *)camera {
    if (!_camera) {
        self.camera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
        self.camera.outputImageOrientation = UIInterfaceOrientationPortrait;
        self.camera.horizontallyMirrorFrontFacingCamera = YES; // 前置摄像头需要 镜像反转
        self.camera.horizontallyMirrorRearFacingCamera = NO; // 后置摄像头不需要 镜像反转 （default：NO）
        [self.camera addAudioInputsAndOutputs]; //该句可防止允许声音通过的情况下，避免录制第一帧黑屏闪屏
    }
    return _camera;
}

- (UIView *)focusView {
    if (!_focusView) {
        _focusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _focusView.backgroundColor = [UIColor clearColor];
        _focusView.layer.borderWidth = 1;
        _focusView.layer.borderColor = [UIColor greenColor].CGColor;
        _focusView.hidden = YES;
        [self addSubview:_focusView];
    }
    return _focusView;
}

- (GPUImageView *)filterView {
    if (!_filterView) {
        _filterView = [[GPUImageView alloc] initWithFrame:self.bounds];
        _filterView.fillMode = 2;
    }
    return _filterView;
}

- (void)captureAndRecording {
//    _beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
//    _tempFilter = _beautifyFilter;
//    [self.camera addTarget:_beautifyFilter];
//    
//    [_beautifyFilter addTarget:self.writer];
//    [_beautifyFilter addTarget:self.filterView];
    
    [self addSubview:self.filterView];
    
    [self.camera addTarget:self.filterView];
    [self.camera startCameraCapture];
    self.camera.audioEncodingTarget = self.writer;
}
                           

#pragma mark - ActionMethod 前后摄像头切换
- (void)InvertShot:(UIButton *)btn {
    btn.selected = !btn.selected;
    if (btn.selected) {
        _isSelfie = YES;
        _selfieBtn.hidden = NO;
    }else {
        _isSelfie = NO;
        _selfieBtn.hidden = YES;
    }
    
    if (_OpenGPUImage) {
        [self.camera rotateCamera];
    }else {
        [self.recorder swapFrontAndBackCameras];
    }
}

- (void)selfieAction:(UIButton *)btn {
    btn.selected = !btn.selected;
    _isSelfie = btn.selected;
    if (_isSelfie) {
        NSLog(@"自拍模式 %d", _isSelfie);
    }else {
        NSLog(@"正常模式（镜像自拍）%d", _isSelfie);
    }
}

- (void)filter:(UIButton *)btn {
    FaceCameraFilterEnum filterEnum = btn.tag;
    [self.camera removeAllTargets];
    switch (filterEnum) {
        case FaceCameraFilterNone:{
            btn.tag = 1;
            [self.camera addTarget:_filterView];
            _tempFilter = nil;
            [_beautifyBtn setTitle:@"无" forState:UIControlStateNormal];
        }
            break;
        case FaceCameraFilterBeautify:{
            btn.tag = 2;
            // MARK: 添加 美颜滤镜
            _beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
            [self.camera addTarget:_beautifyFilter];
            [_beautifyFilter addTarget:_filterView];
            [_beautifyFilter addTarget:self.writer];
            _tempFilter = _beautifyFilter;
            [_beautifyBtn setTitle:@"美颜" forState:UIControlStateNormal];
        }
            break;
        case FaceCameraFilterSketch:{
            btn.tag = 0;
            GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
            [self.camera addTarget:filter];
            [filter addTarget:_filterView];
            [filter addTarget:self.writer];
            _tempFilter = filter;
            [_beautifyBtn setTitle:@"黑白" forState:UIControlStateNormal];
        }
            break;
        default:
            break;
    }
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
                 [weakSelf previewSandboxVideo:[info objectForKey:@"videoURL"] videoInfo:info];
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

#pragma mark - VideoConfig
// MARK : GPUImage 美颜相机
- (void)faceSmartVideo {
    //    _beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    //    _tempFilter = _beautifyFilter;
    //    [self.camera addTarget:_beautifyFilter];
    //
    //    [_beautifyFilter addTarget:self.writer];
    //    [_beautifyFilter addTarget:self.filterView];
    
    [self addSubview:self.filterView];
    
    [self.camera addTarget:self.filterView];
    [self.camera startCameraCapture];
    self.camera.audioEncodingTarget = self.writer;
}

// MARK : 普通相机
- (void)normalSmartVideo {
    [self addSubview:self.preview];
    [self configRecorder];
    [self.recorder setup];
    [self configCaptureUI];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.recorder startSession];
    });
}

#pragma  mark - WXSmartVideoDelegate
- (void)wxSmartVideo:(WXSmartVideoBottomView *)smartVideoView zoomLens:(CGFloat)scaleNum {
    [self.recorder setScaleFactor:scaleNum];
}

- (void)wxSmartVideo:(WXSmartVideoBottomView *)smartVideoView isRecording:(BOOL)recording {
    if (recording) {
        NSLog(@"开始录制");
        [self startRecording];
    }else {
        NSLog(@"结束录制");
        [self finishRecording];
    }

}

- (void)wxSmartVideo:(WXSmartVideoBottomView *)smartVideoView captureCurrentFrame:(BOOL)capture {
    if (capture && !_savingImg) {
        if (_OpenGPUImage) {
            [self writerCurrentFrameToLibrary];
        }else {
            [self smartVideoCurrentFrame];
        }
    }
}

- (void)smartVideoCurrentFrame {
    _savingImg = YES;
    AVCaptureConnection *conntion = [self.recorder.imageDataOutput connectionWithMediaType:AVMediaTypeVideo];
    UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
    [conntion setVideoOrientation:avcaptureOrientation];
    [conntion setVideoScaleAndCropFactor:1];
    if (!conntion) {
        NSLog(@"拍照失败");
        _savingImg = NO;
        return;
    }
    kWeakSelf(self)
    [self.recorder.imageDataOutput captureStillImageAsynchronouslyFromConnection:conntion
                                                      completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                          if (imageDataSampleBuffer == nil) {
                                                              return ;
                                                          }
                                                          NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                          UIImage *img = [UIImage imageWithData:imageData];
                                                          [weakSelf previewPhoto:img];
                                                      }];
}


- (void)startRecording {
    if (_OpenGPUImage) {
        if (!_tempFilter) {
            [self showAlterViewTitle:@"失败" message:@"没有滤镜不能录制"];
        }
        [self.writer startRecording];
    }else {
        [self.recorder startCapture];
    }
}

- (void)finishRecording {
    if (_OpenGPUImage) {
        [_beautifyFilter removeTarget:self.writer];
        self.camera.audioEncodingTarget = nil;
        [self.writer finishRecording];
        [self writerVideoToLibrary];
    }else {
        [self.recorder stopCapture];
    }
}

#pragma mark - Save 
- (void)writerVideoToLibrary {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    NSLog(@"视频录制完成 地址是这个 %@", self.videoUrl);
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:self.videoUrl]) {
        [library writeVideoAtPathToSavedPhotosAlbum:self.videoUrl completionBlock:^(NSURL *assetURL, NSError *error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (error) {
                     [self showAlterViewTitle:@"失败" message:@"视频保存失败"];
                 } else {
                     [self showAlterViewTitle:@"成功" message:@"视频保存成功"];
                 }
             });
         }];
    }
}

- (void)writerCurrentFrameToLibrary {
    _savingImg = YES;
    kWeakSelf(self)

    if (_tempFilter) {
        #warning 这是第二个坑，用这种方式保存照片到相册正常，官方demo种的相片保存会90度旋转
        //            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        //            [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:self.camera.currentCaptureMetadata completionBlock:^(NSURL *assetURL, NSError *error2) {
        //            }];
        [self.camera capturePhotoAsJPEGProcessedUpToFilter:_tempFilter withCompletionHandler:^(NSData *processedJPEG, NSError *error){
            UIImage *img = [UIImage imageWithData:processedJPEG];
            [weakSelf saveImageWriteToPhotosAlbum:img];
        }];
    }else {
         [self showAlterViewTitle:@"失败" message:@"没有滤镜不能进行拍照"];
    }
}

- (void)saveImageWriteToPhotosAlbum:(UIImage *)img {
    ALAuthorizationStatus author = [ALAssetsLibrary authorizationStatus];
    if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied){
        //无权限
        return ;
    }
    if (img) {
        UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }else {
         [self showAlterViewTitle:@"失败" message:@"照片保存失败"];
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (!error) {
        [self showAlterViewTitle:@"成功" message:@"照片保存成功"];
    }else {
        [self showAlterViewTitle:@"失败" message:@"照片保存失败"];
    }
}

#pragma mark - CustomMethod
- (void)showAlterViewTitle:(NSString *)title message:(NSString *)message {
    _savingImg = NO;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)previewSandboxVideo:(NSString *)sanboxURL videoInfo:(NSDictionary *)info{
    NSLog(@"%@", sanboxURL);
    kWeakSelf(self);
    self.vc = [WXVideoPreviewViewController new];
    self.vc.url = sanboxURL;
    [self.vc setOperateBlock:^{
         if (weakSelf.finishedRecordBlock)
         {
             weakSelf.finishedRecordBlock(info);
         }
         [weakSelf removeSelf];
    }];
    [self addSubview:self.vc.view];
}

- (void)previewPhoto:(UIImage *)img {
    kWeakSelf(self);
    _savingImg = NO;
    self.vc = [WXVideoPreviewViewController new];
    self.vc.img = img;
    [self.vc setOperateBlock:^{
        [weakSelf saveImageWriteToPhotosAlbum:img];
        [weakSelf finishedCapture:img];
    }];
    [self addSubview:self.vc.view];
}

- (void)finishedCapture:(UIImage *)img {
    if (self.finishedCaptureBlock) {
        self.finishedCaptureBlock(img);
    };
}

-(AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation {
    AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
    if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
        result = AVCaptureVideoOrientationLandscapeRight;
    else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
        result = AVCaptureVideoOrientationLandscapeLeft;
    return result;
}

- (void)tapPreview:(UITapGestureRecognizer *)tap {
    NSLog(@"%@", NSStringFromCGPoint([tap locationInView:self]));
    CGPoint point = [tap locationInView:self];
    [self showFouceView:point];
    CGPoint focusPoint = CGPointMake(point.x/self.width, point.y/self.height);
    [self.recorder setFocusPoint:focusPoint];
 }

- (void)showFouceView:(CGPoint)point {
    self.focusView.hidden = NO;
    self.focusView.center = point;
    [self hiddenFouceView];
}

- (void)hiddenFouceView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.focusView.hidden = YES;
    });
}
@end
