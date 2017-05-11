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
  
    [self removeAllSubView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *imgView ;
    if (self.url.length >0) {
        imgView = [[UIImageView alloc] initWithImage:[self getVideoPreViewImage]];
        [self.view addSubview:imgView];
        imgView.frame = self.view.bounds;
        
        self.playerView = [[VideoPlayerView alloc] initWithFrame:self.view.bounds videoUrl:self.url];
        self.playerView.delegate = self;
        [self.view addSubview:self.playerView];
    }else {
        imgView = [[UIImageView alloc] initWithImage:self.img];
        [self.view addSubview:imgView];
        imgView.contentMode = UIViewContentModeScaleAspectFill;
        imgView.frame = self.view.bounds;
    }
    

    
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [confirmBtn setImage:[UIImage imageNamed:@"video_right"] forState:UIControlStateNormal];
    confirmBtn.frame = CGRectMake(0, 0, 80, 80);
    confirmBtn.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT - 80);
    confirmBtn.layer.cornerRadius = confirmBtn.width / 2;
    [confirmBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    confirmBtn.tag = 2;
    [self.view addSubview:confirmBtn];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setImage:[UIImage imageNamed:@"video_back"] forState:UIControlStateNormal];
    backBtn.frame = confirmBtn.frame;
    backBtn.layer.cornerRadius = backBtn.width / 2;
    backBtn.tag = 1;
    [backBtn addTarget:self action:@selector(clickAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    [UIView animateWithDuration:0.1 animations:^{
        backBtn.left = SCREEN_WIDTH *0.093;
        confirmBtn.right = SCREEN_WIDTH - SCREEN_WIDTH *0.093;
    }];

}
- (void)removeAllSubView {
    while (self.view.subviews.count) {
        [self.view.subviews.lastObject removeFromSuperview];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage*) getVideoPreViewImage {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:self.url] options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return img;
}

#pragma mark - ActionMethod
- (void)clickAction:(UIButton *)btn {
    [self.view removeFromSuperview];
    [self.playerView pause];
    [self.playerView removeFromSuperview];
    self.playerView = nil;
    if (btn.tag == 1) {
        NSLog(@"后退");
    }
    else if (btn.tag == 2){
        NSLog(@"提交");
        if (self.operateBlock) {
            self.operateBlock();
        }
    }
}

#pragma mark - VideoPlayerViewDelegate
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

#pragma mark - dealloc
- (void)dealloc {
    NSLog(@"销毁");
}
@end
