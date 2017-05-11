//
//  VideoPlayerView.m
//  SmartVideo
//
//  Created by yindongbo on 2017/5/10.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "VideoPlayerView.h"

@implementation VideoPlayerView{
    AVPlayer *_player;
    AVPlayerItem *_playItem;
    AVPlayerLayer *_playerLayer;
    
    NSString *_videoDurationTime;
    NSString *_totalSecond;
    id _playbackTimeObserver;
}

- (instancetype)initWithFrame:(CGRect)frame videoUrl:(NSString *)url {
    if (self = [super initWithFrame:frame]) {
        _playItem = [AVPlayerItem playerItemWithURL:[self urlValidation:url]];
        _player = [[AVPlayer alloc] initWithPlayerItem:_playItem];
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; // 不写这句是不会全屏的！
        _playerLayer.frame = self.bounds;
        [self.layer addSublayer:_playerLayer];
        
        if (kSYSTEM_VERSION_iOS10Later) _player.automaticallyWaitsToMinimizeStalling = NO;
        [self noticeAndKVO];
    }
    return self;
}

#pragma mark - URL 检查
- (NSURL *)urlValidation:(NSString *)URLString {
    NSURL *url;
    if ([URLString hasPrefix:@"http"]) {
        url = [NSURL URLWithString:URLString]; // 网络播放
    }else {
        if ([URLString hasPrefix:@"file://"]) {     // 本地播放
            NSMutableString *mutableString = [URLString mutableCopy];
            [mutableString replaceCharactersInRange:NSMakeRange(0, 7) withString:@""];
            URLString = [mutableString copy];
        }
        url = [NSURL fileURLWithPath:URLString];
    }
    return url;
}

#pragma mark - noticeAndKVO
- (void)noticeAndKVO {
    [_playItem addObserver:self
                forKeyPath:@"status"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
    
    [_playItem addObserver:self
                forKeyPath:@"loadedTimeRanges"
                   options:NSKeyValueObservingOptionNew
                   context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerDidFinished:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:nil];
}
 
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"])
    {
        if (_player.currentItem.status == AVPlayerItemStatusReadyToPlay)
        {
            [_player play];
            CGFloat totalSecond = _playItem.duration.value / _playItem.duration.timescale;
            _totalSecond = [NSString stringWithFormat:@"%.0f",totalSecond];// 转换成秒
            _videoDurationTime = [self convertTime:totalSecond];
            [self monitoringPlayback:_playItem];
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerView:playerStatus:)]) {
                [self.delegate videoPlayerView:self playerStatus:VideoPlayerStatusReadyToPlay];
            }
        }
        else if (_player.currentItem.status == AVPlayerItemStatusFailed)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerView:playerStatus:)]) {
                [self.delegate videoPlayerView:self playerStatus:VideoPlayerStatusFailed];
            }
        }
        else if (_player.currentItem.status == AVPlayerItemStatusUnknown)
        {
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerView:playerStatus:)]) {
                [self.delegate videoPlayerView:self playerStatus:VideoPlayerStatusUnknown];
            }
        }
    }
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSLog(@"播放进度");
//        CMTime duration = _playItem.currentTime;
//        double totalDuration = CMTimeGetSeconds(duration);
//        NSLog(@"totalDuration == %f", totalDuration);
//        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
//        NSLog(@"Time Interval:%f",timeInterval);
//        CMTime duration = _playItem.duration;
//        CGFloat totalDuration = CMTimeGetSeconds(duration);
//        NSLog(@"totalDuration == %f", totalDuration);
    }
}

- (void)playerDidFinished:(NSNotification*)noti {
    [_player pause];
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerView:playerStatus:)]) {
        [self.delegate videoPlayerView:self playerStatus:VideoPlayerStatusFinished];
    }
}

- (AVPlayer *)avplayer {
    return _player;
}

- (NSString *)videoDurationTime:(VideoPlayerTimeEnum)timeEnum {
    switch (timeEnum) {
        case VideoPlayerTimeString:{
            return _videoDurationTime;
        }
            break;
        case VideoPlayerTimeNum:{
            return _totalSecond;
        }
            break;
    }
    return @"";
}


#pragma mark - Shortcut Command
- (void)play {
    [_player play];
}

- (void)pause {
    [_player pause];
}

- (void)seekToTime:(CMTime)time {
    [_player seekToTime:time];
}

- (void)cyclePlayVideo {
    [_player seekToTime:kCMTimeZero];
    [_player play];
}

#pragma mark - ToolMethod
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    if (second/3600 >= 1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    } else {
        [formatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [formatter stringFromDate:d];
    return showtimeNew;
}


- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    __weak id weakSelf = self;
    _playbackTimeObserver = [_player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
        NSString *timeString = [weakSelf convertTime:currentSecond];
        [weakSelf timeUpdata:currentSecond timeString:timeString];
    }];
}

- (void)timeUpdata:(CGFloat)currentSecond timeString:(NSString *)timeString {
    if (self.delegate && [self.delegate respondsToSelector:@selector(videoPlayerView:currentSecond:timeString:)]) {
        [self.delegate videoPlayerView:self currentSecond:currentSecond timeString:timeString];
    }
}

#pragma mark - dealloc
-(void)dealloc {
    [_playItem removeObserver:self forKeyPath:@"status" context:nil];
    [_playItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}
@end
