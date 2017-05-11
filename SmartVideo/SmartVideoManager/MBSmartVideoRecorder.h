//
//  MBSmartVideoRecorder.h
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSInteger, RecorderFinishedReason){
    RecorderFinishedReasonNormal,//主动结束
    RecorderFinishedReasonCancle,//取消
    RecorderFinishedReasonBeyondMaxDuration//超时结束
};

typedef void (^FinishRecordingBlock)(NSDictionary *info, RecorderFinishedReason finishReason);

@interface MBSmartVideoRecorder : NSObject

+ (MBSmartVideoRecorder *)sharedRecorder;
- (AVCaptureVideoPreviewLayer *)getPreviewLayer;

@property (nonatomic, copy)FinishRecordingBlock finishBlock;//录制结束


// === 照相捕捉
@property (nonatomic, strong) AVCaptureStillImageOutput *imageDataOutput;

//=== 参数设置
@property (nonatomic, assign) CGSize cropSize;//!< 视频捕捉画面宽高
@property (nonatomic, assign) NSTimeInterval maxDuration;//视频最长时间

//=== Results
@property (nonatomic, assign) NSTimeInterval duration; //!< 视频持续时间
@property (nonatomic, strong) NSURL *recordURL;//!< 本地视频地址

//=== setup
/***/
- (void)setup;

- (void)startSession; /*开启摄像头**/
- (void)stopSession; /* 关闭摄像头**/

- (void)startCapture; /*开始视频捕捉**/
- (void)stopCapture; /*结束视频捕捉**/
- (void)cancelCapture; /*取消视频捕捉**/

- (void)swapFrontAndBackCameras; /*摄像头翻转**/

- (BOOL)setScaleFactor:(CGFloat)factor;/***/// 设置缩放比例
- (void)setFocusPoint:(CGPoint)point; /*焦距改变**/ 
@end
