//
//  MBSmartVideoWriter.h
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MBSmartVideoWriter;
@protocol MBSmartVideoWriterDelegate <NSObject>
- (void)smartVideoWriterDidFinishRecording:(MBSmartVideoWriter *)recorder status:(BOOL)isCancle;
@end

@interface MBSmartVideoWriter : NSObject

- (instancetype)initWithURL:(NSURL *)URL cropSize:(CGSize)cropSize;

@property (nonatomic, weak) id<MBSmartVideoWriterDelegate> delegate;
@property (nonatomic, strong, readonly) NSURL *recordingURL;

- (void)finishRecording;//正常结束
- (void)cancleRecording;//取消录制

- (void)appendAudioBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)appendVideoBuffer:(CMSampleBufferRef)sampleBuffer;
@end
