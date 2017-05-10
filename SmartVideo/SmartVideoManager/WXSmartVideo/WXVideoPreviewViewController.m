//
//  WXVideoPreviewViewController.m
//  SmartVideo
//
//  Created by yindongbo on 2017/5/9.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "WXVideoPreviewViewController.h"
#import "VideoPlayerView.h"
@interface WXVideoPreviewViewController ()<
VideoPlayerViewDelegate
>

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) AVPlayerItem *item;

@property (nonatomic, strong) VideoPlayerView *playerView;
@end

@implementation WXVideoPreviewViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor brownColor];
    
    self.playerView = [[VideoPlayerView alloc] initWithFrame:CGRectMake(0, 50, self.view.width, self.view.height - 50) videoUrl:self.url];
    self.playerView.delegate = self;
    [self.view addSubview:self.playerView];
//    NSURL *url;
//    if ([self.url hasPrefix:@"http"]) {
//        // 网络播放
//        url = [NSURL URLWithString:self.url];
//    }else {
//        // 本地播放
//        url = [NSURL fileURLWithPath:self.url];
//    }
//    self.item = [AVPlayerItem playerItemWithURL:url]; //#
//    self.player = [[AVPlayer alloc] initWithPlayerItem:self.item];
//    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer: self.player];
//    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    self.playerLayer.frame = CGRectMake(0, 50, self.view.width, self.view.height - 50); //#
//    self.playerLayer.backgroundColor = [UIColor purpleColor].CGColor;
//    [self.view.layer addSublayer:self.playerLayer];
//    [self.playerLayer setNeedsDisplay];
//    
//    [self.item addObserver:self
//                forKeyPath:@"status"
//                   options:NSKeyValueObservingOptionNew
//                   context:nil];
//    
//    [self.item addObserver:self
//                forKeyPath:@"loadedTimeRanges"
//                   options:NSKeyValueObservingOptionNew
//                   context:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(playerDidFinished:)
//                                                 name:AVPlayerItemDidPlayToEndTimeNotification
//                                               object:nil];
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(0, 0, 50, 50);
    btn.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)back {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)videoPlayerView:(VideoPlayerView *)playerView playerStatus:(VideoPlayerStatusEnum)status {
    switch (status) {
        case VideoPlayerStatusReadyToPlay:{
            NSLog(@"准备播放");
            NSLog(@"总时长：%@", [self.playerView videoDurationTime:1]);
            
        }
            break;
        case VideoPlayerStatusFinished: {
            NSLog(@"播放完成");
            [self.playerView cyclePlayVideo];
        }
            break;
        case VideoPlayerStatusFailed: {
            NSLog(@"播放失败");
        }
            break;
        case VideoPlayerStatusUnknown: {
            NSLog(@"未知失败");
        }
        default:
            break;
    }
}

- (void)videoPlayerView:(VideoPlayerView *)playerView currentSecond:(CGFloat)second timeString:(NSString *)timeString {
    NSLog(@"timeString == %@", timeString);
    NSLog(@"currentSecond == %f", second);
}

- (void)dealloc {
    NSLog(@"销毁");
}
@end
