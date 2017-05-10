//
//  VideoPlayerView.h
//  SmartVideo
//
//  Created by yindongbo on 2017/5/10.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VideoPlayerView;

typedef enum : NSUInteger {
    VideoPlayerStatusUnknown,
    VideoPlayerStatusReadyToPlay,
    VideoPlayerStatusFailed,
    VideoPlayerStatusFinished
} VideoPlayerStatusEnum;

typedef enum : NSUInteger {
    VideoPlayerTimeString, // string 类型 00:004
    VideoPlayerTimeNum  // num 类型 4
} VideoPlayerTimeEnum;



@protocol VideoPlayerViewDelegate <NSObject>

/*
 监控播放状态
 **/
- (void)videoPlayerView:(VideoPlayerView *)playerView
           playerStatus:(VideoPlayerStatusEnum)status;

/* 获取当前播放时间
 second : 1.00
 timeString : 00:02
 **/
- (void)videoPlayerView:(VideoPlayerView *)playerView
          currentSecond:(CGFloat)second
             timeString:(NSString *)timeString;
@end



@interface VideoPlayerView : UIView

- (instancetype)initWithFrame:(CGRect)frame videoUrl:(NSString *)url;
@property (nonatomic, weak)id <VideoPlayerViewDelegate>delegate;

// ============ element
- (AVPlayer *)avplayer;
- (NSString *)videoDurationTime:(VideoPlayerTimeEnum)timeEnum ;//!< 获取总时长

// ============ quick command
- (void)play;//!< 播放
- (void)pause;//!< 暂停
- (void)seekToTime:(CMTime)time; //!< 跳转
- (void)cyclePlayVideo; //!< 循环播放

@end
