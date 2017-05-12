//
//  MBSmartVideoRecorder.m
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "MBSmartVideoRecorder.h"
#import "MBSmartVideoWriter.h"
#import "MBSmartVideoConverter.h"

typedef NS_ENUM(NSInteger, CaptureAVSetupResult) {
    CaptureAVSetupResultDefault,
    CaptureAVSetupResultSucess,
    CaptureAVSetupResultCameraNotAuthorized,
    CaptureAVSetupResultSessionConfigurationFailed
};

@interface MBSmartVideoRecorder()<
AVCaptureAudioDataOutputSampleBufferDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate,
MBSmartVideoWriterDelegate
>
{
    CMTime _timeOffset;
    CMTime _lastVideo;
    CMTime _lastAudio;
    
    MBSmartVideoWriter* _writer;
    
    NSTimer *_durationTimer;
    
    NSString *_smartVideoPath;
}

@property (nonatomic, assign)BOOL isCapturing; //!< 开始录制

@property (nonatomic, assign) CaptureAVSetupResult result;

@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) dispatch_queue_t audioDataOutputQueue;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDevice *audioCaptureDevice;

@property (nonatomic, strong) NSMutableArray *frames;//存储录制帧

@property (nonatomic, strong) AVCaptureConnection *videoConnection; //!< 视频控制
@property (nonatomic, strong) AVCaptureConnection *audioConnection; //!< 音频控制

@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput; //!< 视频捕捉
@property (nonatomic, strong) AVCaptureDeviceInput *audioDeviceInput; //!< 音频捕捉

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;//!< 视频输出
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;//!< 音频输出

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview; //!< 视频预览层

@property (nonatomic, assign) RecorderFinishedReason finishReason;
@end

@implementation MBSmartVideoRecorder

+ (MBSmartVideoRecorder *)sharedRecorder {
    static MBSmartVideoRecorder *recorder;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        recorder = [[MBSmartVideoRecorder alloc] init];
    });
    return recorder;
}

- (instancetype)init {
    if (self = [super init])
    {
        _duration = 0.f;
        self.result = CaptureAVSetupResultDefault;
        self.frames = [NSMutableArray arrayWithCapacity:0];
        
        self.sessionQueue = dispatch_queue_create("ydb.smartVideoRecorder.queue", DISPATCH_QUEUE_SERIAL);
        self.videoDataOutputQueue = dispatch_queue_create("ydb.smartVideoRecorder.queue", DISPATCH_QUEUE_SERIAL);
        self.audioDataOutputQueue = dispatch_queue_create("ydb.smartViedeoRecorder.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.videoDataOutputQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        dispatch_set_target_queue(self.audioDataOutputQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    }
    return self;
}

- (AVCaptureVideoPreviewLayer *)getPreviewLayer {
    return self.preview;
}

#pragma mark - ConfigurationSession
- (void)setup {
    if (!self.session)
    {
        NSLog(@"setup session");
        self.isCapturing = NO;
        
        self.session = [[AVCaptureSession alloc] init];
        
        [self capturePermissionCheck];
        [self configurationSession];
        [self configurationPreviewLayer];
    }
}

- (void)startSession {
    if (![self.session isRunning])
    {
        [self.session startRunning];
    }
}

- (void)stopSession {
    if ([self.session isRunning])
    {
        [self.session stopRunning];
        [self.preview removeFromSuperlayer];
        self.session = nil;
        self.preview = nil;
    }
}

- (void)startCapture {
    @synchronized (self)
    {
        dispatch_async(self.sessionQueue, ^{
            if (!self.isCapturing)
            {
                if (![self.session isRunning])
                {
                    [self.session startRunning];
                }
                [self.frames removeAllObjects];
                self.isCapturing = YES;

                dispatch_async(dispatch_get_main_queue(), ^{
                    _durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(computeDuration:) userInfo:nil repeats:YES];
                });
            }
        });
    }
}

- (void)stopCapture {
    [self finishCaptureWithReason:RecorderFinishedReasonNormal];
}

- (void)cancelCapture {
    [self finishCaptureWithReason:RecorderFinishedReasonCancle];
}

- (void)capturePermissionCheck {
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo])
    {
        case AVAuthorizationStatusNotDetermined:
            self.result = CaptureAVSetupResultDefault;
        {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted)
                {
                    self.result = CaptureAVSetupResultSucess;
                }
            }];
        }
            break;
        case AVAuthorizationStatusAuthorized:
            self.result = CaptureAVSetupResultSucess;
            break;
        case AVAuthorizationStatusDenied:
            self.result = CaptureAVSetupResultCameraNotAuthorized;
            break;
        case AVAuthorizationStatusRestricted:
            self.result = CaptureAVSetupResultSessionConfigurationFailed;
            break;
        default:
            break;
    }
    
    if (self.result != CaptureAVSetupResultSucess)
    {
        NSLog(@"没有摄像权限，提示用户");
    }
}

- (void)configurationSession {
    dispatch_async(self.sessionQueue, ^{
        self.captureDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        
        if (self.videoDeviceInput) {
            [self.session removeInput:self.videoDeviceInput];
        }
        
        NSError *error = nil;
        self.videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:&error];
        if (!self.videoDeviceInput)
        {
            NSLog(@"未找到设备");
        }
        
        [self.session beginConfiguration];
        int frameRate;
        if ([NSProcessInfo processInfo].processorCount == 1)
        {
            if ([self.session canSetSessionPreset:AVCaptureSessionPresetLow])
            {
                [self.session setSessionPreset:AVCaptureSessionPresetLow];
            }
            frameRate = 10;
        }
        else
        {
            if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480])
            {
                [self.session setSessionPreset:AVCaptureSessionPreset640x480];
            }
            frameRate = 30;
        }
        
        CMTime frameDuration = CMTimeMake(1, frameRate);
        if ([self.captureDevice lockForConfiguration:&error])
        {
            self.captureDevice.activeVideoMaxFrameDuration = frameDuration;
            self.captureDevice.activeVideoMinFrameDuration = frameDuration;
            [self.captureDevice unlockForConfiguration];
        }
        else
        {
            NSLog(@"captureDevice error %@",error);
        }
        
        
        if ([self.session canAddInput:self.videoDeviceInput])
        {
            [self.session addInput:self.videoDeviceInput];
            if (self.videoDataOutput)
            {
                [self.session removeOutput:self.videoDataOutput];
            }
           
            //MARK :视频输出
            self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            self.videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
            [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
            
            if ([self.session canAddOutput:self.videoDataOutput])
            {
                [self.session addOutput:self.videoDataOutput];
                [self.captureDevice addObserver:self
                                     forKeyPath:@"adjustingFocus"
                                        options:NSKeyValueObservingOptionNew
                                        context:nil];
               
                self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
                if (self.videoConnection.isVideoStabilizationSupported)
                {
                    self.videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                }
                
                UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                if (statusBarOrientation != UIInterfaceOrientationUnknown)
                {
                    initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                }
                self.videoConnection.videoOrientation = initialVideoOrientation;
            }
            else
            {
                NSLog(@"无法添加视频输入到会话");
            }
            
            if (self.imageDataOutput) {
                [self.session removeOutput:self.imageDataOutput];
            }
            // MARK：图片输出
            self.imageDataOutput = [[AVCaptureStillImageOutput alloc] init];
            if ([self.session canAddOutput:self.imageDataOutput]) {
                [self.session addOutput:self.imageDataOutput];
            }
            
            // MARK :音频输出
            self.audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            self.audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.audioCaptureDevice error:&error];
            if (!self.audioDeviceInput)
            {
                NSLog(@"不能创建音频 %@", error);
            }
            
            if ([self.session canAddInput:self.audioDeviceInput])
            {
                [self.session addInput:self.audioDeviceInput];
            }else{
                NSLog(@"无法添加音频输入");
            }
            
            self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
            [self.audioDataOutput setSampleBufferDelegate:self queue:self.audioDataOutputQueue];
            
            if ([self.session canAddOutput:self.audioDataOutput])
            {
                [self.session addOutput:self.audioDataOutput];
            }
            self.audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
            [self.session commitConfiguration];
        }
    });
}

- (void)configFrameDuration {
    int frameRate;
    NSError *error;
    if ([NSProcessInfo processInfo].processorCount == 1)
    {
        if ([self.session canSetSessionPreset:AVCaptureSessionPresetLow])
        {
            [self.session setSessionPreset:AVCaptureSessionPresetLow];
        }
        frameRate = 10;
    }
    else
    {
        if ([self.session canSetSessionPreset:AVCaptureSessionPreset640x480])
        {
            [self.session setSessionPreset:AVCaptureSessionPreset640x480];
        }
        frameRate = 30;
    }
    
    CMTime frameDuration = CMTimeMake(1, frameRate);
    if ([self.captureDevice lockForConfiguration:&error])
    {
        self.captureDevice.activeVideoMaxFrameDuration = frameDuration;
        self.captureDevice.activeVideoMinFrameDuration = frameDuration;
        [self.captureDevice unlockForConfiguration];
    }
    else
    {
        NSLog(@"captureDevice error %@",error);
    }
}

- (void)configurationSessionFront {
    dispatch_async(self.sessionQueue, ^{
        self.captureDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionFront];
        
        if (self.videoDeviceInput) {
            [self.session removeInput:self.videoDeviceInput];
        }
        
        [self configFrameDuration];
        
        NSError *error = nil;
        self.videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.captureDevice error:&error];
        if (!self.videoDeviceInput)  {  NSLog(@"未找到设备");  }
        
        // === beginConfiguration ===
        [self.session beginConfiguration];
        if ([self.session canAddInput:self.videoDeviceInput])
        {
            [self.session addInput:self.videoDeviceInput];
            if (self.videoDataOutput)
            {
                [self.session removeOutput:self.videoDataOutput];
            }
            
            //MARK :视频输出
            self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            self.videoDataOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
            [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
            
            if ([self.session canAddOutput:self.videoDataOutput])
            {
                [self.session addOutput:self.videoDataOutput];
                [self.captureDevice addObserver:self
                                     forKeyPath:@"adjustingFocus"
                                        options:NSKeyValueObservingOptionNew
                                        context:nil];
                
                self.videoConnection = [self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
                if (self.videoConnection.isVideoStabilizationSupported)
                {
                    self.videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                }
                
                UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
                AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                if (statusBarOrientation != UIInterfaceOrientationUnknown)
                {
                    initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
                }
                self.videoConnection.videoOrientation = initialVideoOrientation;
            }
            else
            {
                NSLog(@"无法添加视频输入到会话");
            }
            
            if (self.imageDataOutput) {
                [self.session removeOutput:self.imageDataOutput];
            }
            // MARK：图片输出
            self.imageDataOutput = [[AVCaptureStillImageOutput alloc] init];
            if ([self.session canAddOutput:self.imageDataOutput]) {
                [self.session addOutput:self.imageDataOutput];
            }else {
                NSLog(@"图片输出 加入失败");
            }
            
            // MARK :音频输出
            self.audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            self.audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.audioCaptureDevice error:&error];
            if (!self.audioDeviceInput)
            {
                NSLog(@"不能创建音频 %@", error);
            }
            
            if ([self.session canAddInput:self.audioDeviceInput])
            {
                [self.session addInput:self.audioDeviceInput];
            }
            else
            {
                NSLog(@"无法添加音频输入");
            }
            
            self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
            [self.audioDataOutput setSampleBufferDelegate:self queue:self.audioDataOutputQueue];
            
            if ([self.session canAddOutput:self.audioDataOutput])
            {
                [self.session addOutput:self.audioDataOutput];
            }
            self.audioConnection = [self.audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
            [self.session commitConfiguration];
        }
    });
}

- (void)configurationPreviewLayer {
    self.preview = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
}


- (void)swapFrontAndBackCameras {
    NSArray *inputs =self.session.inputs;
    for (AVCaptureDeviceInput *input in inputs ) {
        AVCaptureDevice *device = input.device;
        if ( [device hasMediaType:AVMediaTypeVideo] ) {
            AVCaptureDevicePosition position = device.position;
//            AVCaptureDevice *newCamera =nil;
//            AVCaptureDeviceInput *newInput =nil;
            if (position ==AVCaptureDevicePositionFront)
//                self.captureDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
                [self configurationSession];
            else
//                self.captureDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
                [self configurationSessionFront];
            
//            self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
// 
//            [self.session beginConfiguration];
//            [self.session removeInput:input];
//            [self.session addInput:self.videoDeviceInput];
//            [self.session commitConfiguration];
            break;
        }
    }
}

//- (void)swapFrontAndBackCameras {
//    NSArray *inputs =self.session.inputs;
//    for (AVCaptureDeviceInput *input in inputs ) {
//        AVCaptureDevice *device = input.device;
//        if ( [device hasMediaType:AVMediaTypeVideo] ) {
//            AVCaptureDevicePosition position = device.position;
//            if (position ==AVCaptureDevicePositionFront)
//                self.captureDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
//            else
//                self.captureDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
//            
//                        self.videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:nil];
//            
//                        [self.session beginConfiguration];
//                        [self.session removeInput:input];
//                        [self.session addInput:self.videoDeviceInput];
//                        [self.session commitConfiguration];
//            break;
//        }
//    }
//}


- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices )
        if ( device.position == position )
            return device;
    return nil;
}

#pragma mark - AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    BOOL bVideo = YES;
    @synchronized (self)
    {
        if (!self.isCapturing)
        {
            return;
        }
        
        if (connection != self.videoConnection)
        {
            bVideo = NO;
        }
 
        
        if ((_writer == nil) && !bVideo)
        {
            NSString *name = [NSString stringWithFormat:@"/%@.mov",[self getVideoSaveFilePathString]];
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask, YES);
            _smartVideoPath = [paths objectAtIndex:0];
            _smartVideoPath = [_smartVideoPath stringByAppendingString:name];
            _recordURL = [NSURL fileURLWithPath:_smartVideoPath];
            _writer  = [[MBSmartVideoWriter alloc] initWithURL:_recordURL cropSize:_cropSize];
            _writer.delegate = self;
            NSLog(@"_smartVideoPath == %@",_smartVideoPath);
        }
        
         CFRetain(sampleBuffer);
        
        if (bVideo)
        {
            @autoreleasepool
            {
                UIImage *frame = [MBSmartVideoConverter convertSampleBufferRefToUIImage:sampleBuffer];
                [self.frames addObject:frame];
            }
            [_writer appendVideoBuffer:sampleBuffer];
        }
        else
        {
            if (connection == self.audioConnection)
            {
                [_writer appendAudioBuffer:sampleBuffer];
            }
        }
    }
     CFRelease(sampleBuffer);
}

- (void)smartVideoWriterDidFinishRecording:(MBSmartVideoWriter *)recorder status:(BOOL)isCancle {
    if (_duration < 1.0f)
    {
        NSLog(@"录制时间太短");
    }
    
    if (!isCancle && _duration >= 1.0f)
    {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeVideoAtPathToSavedPhotosAlbum:recorder.recordingURL completionBlock:^(NSURL *assetURL, NSError *error)
         {
             NSLog(@"save completed");
             if (self.finishBlock)
             {
                 long long size = [self getCacheFileSize:_smartVideoPath];
                 long long videoSize = size / 1024;
                 NSLog(@"_smartVideoPath == %@",_smartVideoPath);
                 NSDictionary *info = @{@"videoURL":[_recordURL description],
                                        @"videoDuration":[NSString stringWithFormat:@"%.0f",_duration],
                                        @"videoSize":[NSString stringWithFormat:@"%lldkb",videoSize],
                                        @"videoFirstFrame":[self.frames firstObject]
                                        };
                 self.finishBlock(info,self.finishReason);
             }
         }];
    
    }
    else
    {
        NSLog(@"用户手动取消录制操作");
    }
    
    self.isCapturing = NO;
    _writer = nil;
    _duration = 0.f;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"%s", __FUNCTION__);
    if([keyPath isEqualToString:@"adjustingFocus"])
    {
        BOOL adjustingFocus =[[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
//        NSLog(@"Is adjusting focus? %@", adjustingFocus ?@"YES":@"NO");
//        NSLog(@"Change dictionary: %@", change);
        if (adjustingFocus) {
            NSLog(@"对焦成功");
        }else {
            NSLog(@"对焦失败");
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - CustoMethod 
- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset {
    CMItemCount count;
    CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
    CMSampleTimingInfo* pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
    CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
    for (CMItemCount i = 0; i < count; i++)
    {
        pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
        pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
    }
    CMSampleBufferRef sout;
    CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
    free(pInfo);
    return sout;
}


- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices )
    {
        if ( device.position == position )
        {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

// NSTimers 调用事件
- (void)computeDuration:(NSTimer *)timer {
    if (self.isCapturing)
    {
        [self willChangeValueForKey:@"duration"];
        _duration += 0.1;
        [self didChangeValueForKey:@"duration"];
        NSLog(@"%f", _duration);
       
        if (_duration >= _maxDuration)
        {
            [self finishCaptureWithReason:RecorderFinishedReasonBeyondMaxDuration];
            [timer invalidate];
            NSLog(@"录制超时,结束录制");
        }
    }
}

// 录制结束
- (void)finishCaptureWithReason:(RecorderFinishedReason)reason {
    @synchronized (self)
    {
        if (self.isCapturing)
        {
            self.isCapturing = NO;
            [_durationTimer invalidate];
            dispatch_async(self.sessionQueue, ^{
                switch (reason)
                {
                    case RecorderFinishedReasonNormal:
                    {
                        [_writer finishRecording];
                        NSLog(@"finishRecording");
                        break;
                    }
                    case RecorderFinishedReasonCancle:
                    {
                        [_writer cancleRecording];
                        NSLog(@"cancleRecording");
                        break;
                    }
                    case RecorderFinishedReasonBeyondMaxDuration:
                    {
                        [_writer finishRecording];
                        NSLog(@"finishRecording");
                        break;
                    }
                }
                self.finishReason = reason;
            });
        }
    }
}

- (BOOL)setScaleFactor:(CGFloat)factor {
    [_captureDevice lockForConfiguration:nil];
    BOOL success = NO;
    if(_captureDevice.activeFormat.videoMaxZoomFactor > factor)
    {
        [_captureDevice rampToVideoZoomFactor:factor withRate:30.f];//平滑过渡
//        NSLog(@"Current format: %@, max zoom factor: %f", _captureDevice.activeFormat, _captureDevice.activeFormat.videoMaxZoomFactor);
        success = YES;
    }
    [_captureDevice unlockForConfiguration];
    
    return success;
}

#pragma mark - ToolsMethod
- (NSString*)getVideoSaveFilePathString {
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMddHHmmss";
    NSString* nowTimeStr = [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:0]];
    return nowTimeStr;
}

- (long long)getCacheFileSize:(NSString *)path {
    NSFileManager  *fileMananger = [NSFileManager defaultManager];
    if ([fileMananger fileExistsAtPath:path])
    {
        NSDictionary *dic = [fileMananger attributesOfItemAtPath:path error:nil];
        return [dic[@"NSFileSize"] longLongValue];
    }
    return 0;
}

// MARK: 焦距改变
- (void)setFocusPoint:(CGPoint)point {
    if (self.captureDevice.isFocusPointOfInterestSupported) {
        NSError *error = nil;
        [self.captureDevice lockForConfiguration:&error];
        /*****必须先设定聚焦位置，在设定聚焦方式******/
        //聚焦点的位置
        if ([self.captureDevice isFocusPointOfInterestSupported]) {
            [self.captureDevice setFocusPointOfInterest:point];
        }
        
        // 聚焦模式
        if ([self.captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [self.captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }else{
            NSLog(@"聚焦模式修改失败");
        }
        
        //曝光点的位置
        if ([self.captureDevice isExposurePointOfInterestSupported]) {
            [self.captureDevice setExposurePointOfInterest:point];
        }
        
        //曝光模式
        if ([self.captureDevice isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            [self.captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }else{
            NSLog(@"曝光模式修改失败");
        }
        [self.captureDevice unlockForConfiguration];
    }
}
#pragma mark -
- (void)dealloc {
    
}
@end
