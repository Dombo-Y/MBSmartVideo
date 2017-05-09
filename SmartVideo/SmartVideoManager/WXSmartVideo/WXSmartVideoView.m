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
#import "GPUImageBeautifyFilter.h"

#import <AssetsLibrary/ALAssetsLibrary.h>
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

@property (nonatomic, strong) NSURL *videoUrl;

@property (nonatomic, assign) BOOL savingImg;
@end


#define kMAXDURATION 6
#define kFaceSmartVideo 0
@implementation WXSmartVideoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        
        if (kFaceSmartVideo) {
            [self faceSmartVideo]; NSLog(@"美颜");
        }
        else {
            [self normalSmartVideo]; NSLog(@"普通");
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
        
        CALayer *layer = [[CALayer alloc] init];
        layer.frame = _invertBtn.bounds;
        layer.backgroundColor = [UIColor blackColor].CGColor;
        layer.opacity = 0.7;
        layer.cornerRadius = layer.frame.size.width/2;
        [_invertBtn.layer addSublayer:layer];
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

- (NSURL *)videoUrl {
    if (!_videoUrl) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES);
        NSString *pathToMovie = [paths objectAtIndex:0];
        _videoUrl = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/aaa.mp4",pathToMovie]];
        unlink([pathToMovie UTF8String]);
    }
    return _videoUrl;
}

- (GPUImageMovieWriter *)writer {
    if (!_writer) {
        _writer = [[GPUImageMovieWriter alloc] initWithMovieURL:self.videoUrl size:self.size];
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

#pragma mark - ActionMethod 前后摄像头切换
- (void)InvertShot:(UIButton *)btn {
    btn.selected = !btn.selected;
    if (kFaceSmartVideo) {
        [self.camera rotateCamera];
    }else {
        [self.recorder swapFrontAndBackCameras];
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

#pragma mark - VideoConfig
- (void)faceSmartVideo {
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:self.bounds];
    [self addSubview:filterView];
    [self.camera addTarget:filterView];
    [self.camera startCameraCapture];
    filterView.fillMode = 2;
    
#warning 这是一个坑
    [self.camera removeAllTargets]; // 这句很重要！！ 否则添加滤镜会闪屏
// MARK: 添加 美颜滤镜
    _beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [self.camera addTarget:_beautifyFilter];
    [_beautifyFilter addTarget:filterView];
}

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
//    [self.recorder setScaleFactor:scaleNum];
    NSLog(@"scaleNum == %f" , scaleNum);
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
        if (kFaceSmartVideo) {
            [self writerCurrentFrameToLibrary];
        }else {
            [self smartVideoCurrentFrame];
        }
    }
}


- (void)smartVideoCurrentFrame {
    _savingImg = YES;
    AVCaptureConnection *conntion = [self.recorder.imageDataOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!conntion) {
        NSLog(@"拍照失败");
        return;
    }
    [self.recorder.imageDataOutput captureStillImageAsynchronouslyFromConnection:conntion
                                                      completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                          if (imageDataSampleBuffer == nil) {
                                                              return ;
                                                          }
                                                          NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                          UIImage *img = [UIImage imageWithData:imageData];
                                                        UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
                                                      }];
}


- (void)startRecording {
    if (kFaceSmartVideo) {
        self.camera.audioEncodingTarget = _writer;
        [_writer startRecording];
    }else {
        
    }
}

- (void)finishRecording {
    if (kFaceSmartVideo) {
        [_beautifyFilter removeTarget:_writer];
        self.camera.audioEncodingTarget = nil;
        [_writer finishRecording];
        [self writerVideoToLibrary];
    }else {
        
    }
}

#pragma mark - Save 
- (void)writerVideoToLibrary {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
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
    [self.camera capturePhotoAsJPEGProcessedUpToFilter:_beautifyFilter withCompletionHandler:^(NSData *processedJPEG, NSError *error){
#warning 这是第二个坑，用这种方式保存照片到相册正常，官方demo种的相片保存会90度旋转
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:self.camera.currentCaptureMetadata completionBlock:^(NSURL *assetURL, NSError *error2) {
             UIImage *img = [UIImage imageWithData:processedJPEG];
             if (img) {
                 UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
             }
         }];
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    _savingImg = NO;
    if (!error) {
        [self showAlterViewTitle:@"成功" message:@"照片保存成功"];
    }else {
        [self showAlterViewTitle:@"失败" message:@"照片保存失败"];
    }
}

#pragma mark - CustomMethod
- (void)showAlterViewTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
