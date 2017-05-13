//
//  SmartViewController.m
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "SmartViewController.h"
#import "MBSmartVideoView.h"
#import "MBPlaySmartVideoViewController.h"
#import "DownLoadManager.h"
#import "HUBProcessView.h"
#import "WXSmartVideoView.h"
#import "WXVideoPreviewViewController.h"

//#import "UIImageView+Category.h"
#import "UIImage+Category.h"
@interface SmartViewController ()

@property (nonatomic, copy) NSString *videoUrll;
@property (nonatomic, assign) BOOL isUploadFile;

@property (nonatomic, strong) UIProgressView *progressView;

@property (strong, nonatomic) IBOutlet UIButton *RecordingBtn;
@property (strong, nonatomic) IBOutlet UIButton *playingBtn;
@property (strong, nonatomic) IBOutlet UIButton *downloadingBtn;
@property (strong, nonatomic) IBOutlet UIButton *wxSmartVideoBtn;

@property (nonatomic, strong) UIView *tempView;

@end

@implementation SmartViewController

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.navigationController.navigationBar.hidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.edgesForExtendedLayout = NO;
    _isUploadFile = YES;
    [self.view addSubview:self.progressView];
    
    
//    self.tempView = [[UIView alloc] initWithFrame:CGRectMake(0, 200, CGRectGetWidth(self.view.frame), 300)];
//    [self.view addSubview:self.tempView];
//    self.tempView.backgroundColor = [UIColor brownColor];
    
//    UIImage *img = [UIImage imageNamed:@"video_right"];
//    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
//    imgView.frame = CGRectMake(100, 300, 100, 100);
//    imgView.layer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
//    [self.view addSubview:imgView];
//    
//    UIImageView *imgViewB = [[UIImageView alloc] initWithImage:imgView.image];
//    imgViewB.frame = CGRectMake(100, 100, 100, 100);
//    [self.view addSubview:imgViewB];
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UIGraphicsBeginImageContext(imgView.size);
//            [imgView.layer renderInContext:UIGraphicsGetCurrentContext()];
//            UIImage *tempImg = UIGraphicsGetImageFromCurrentImageContext();
//            UIImageWriteToSavedPhotosAlbum([UIImage fixOrientation:tempImg], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//        }); 
//    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message
                                                   delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}


- (UIProgressView *)progressView {
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 400, CGRectGetWidth(self.view.frame), 5)];
    }
    return _progressView;
}

- (IBAction)uploadFile:(UISwitch *)sender {
    _isUploadFile = sender.on;
    if (sender.on) {
        NSLog(@"录制完后上传");
    }else {
        NSLog(@"录制完后不上传");
    }
}


- (IBAction)action:(UIButton *)sender {
    UIInterfaceOrientation currentOrient = [UIApplication  sharedApplication].statusBarOrientation;
    NSLog(@"currentOrient == %ld", (long)currentOrient);
    if (![self isSimulator]) {
        MBSmartVideoView *smart = [[MBSmartVideoView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
        NSLog(@".frame == %@", NSStringFromCGRect(smart.frame));
        [self.navigationController.view addSubview:smart];
        __weak __typeof(&*self)weakSelf = self;
        [smart setFinishedRecordBlock:^(NSDictionary *info) {
            weakSelf.videoUrll = [[info objectForKey:@"videoURL"] description];
            [weakSelf uploadFileWithURL:weakSelf.videoUrll];
        }];
    } else {
        NSLog(@"模拟器不支持小视频录制");
    }
}

- (IBAction)wxSmartVideo:(UIButton *)sender {
    if (![self isSimulator]) {
        NSLog(@"小视频全屏录制");
        WXSmartVideoView *wxsmartView = [[WXSmartVideoView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) GPUImage:NO];
//        wxsmartView.finishedRecordBlock = ^(NSDictionary *dic) {
//            NSLog(@"录制完成 %@", [dic objectForKey:@"videoURL"]);
//            self.videoUrll = [[dic objectForKey:@"videoURL"] description];
//        };
        [self.navigationController.view addSubview:wxsmartView];
    }else {
        NSLog(@"模拟器不支持小视频录制");
    }
}

- (IBAction)playVideo:(UIButton *)sender {
    if (self.videoUrll.length >0)
    {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:NO];
        MBPlaySmartVideoViewController *playVC =[[MBPlaySmartVideoViewController alloc] init];
        playVC.videoUrlString = self.videoUrll;
        [self.navigationController pushViewController:playVC animated:YES];
        
        NSLog(@"videoUrll == %@", self.videoUrll);
//        WXVideoPreviewViewController *vc = [[WXVideoPreviewViewController alloc] init];
//        vc.url = self.videoUrll;
//        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)downLoad:(UIButton *)sender {
    NSString *urlString = @"https://oimk77aue.qnssl.com/urvR-zC_bYguXcSEz0qrg9brhSA=/FoA9SzbYC3vSMa3ZhTatBdpPu8WW";
    __weak typeof(self) weakSekf=self;
    [[HUBProcessView shareHUBProcess] showHubProcess:0];
    [DownLoadManager downLoadFileWithURL:urlString
                                 process:^(CGFloat processNum) {
                                     NSLog(@"%f", processNum);
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         weakSekf.progressView.progress = processNum;
                                         [[HUBProcessView shareHUBProcess] showHubProcess:processNum];
                                     });
                                 }
                                  result:^(NSString *url, NSString *m, NSInteger code) {
                                      [[HUBProcessView shareHUBProcess] hidenHubProcess];
                                      if (code == 0) {
                                          NSLog(@"%@ -- %@",m,url);
                                          weakSekf.videoUrll = url;
                                      }else {
                                          NSLog(@"%@",m);
                                      }
                                  }];
}

- (IBAction)GPUImageCapture:(UIButton *)sender {
    if (![self isSimulator]) {
        NSLog(@"小视频全屏录制");
        WXSmartVideoView *wxsmartView = [[WXSmartVideoView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT) GPUImage:YES];
        [self.navigationController.view addSubview:wxsmartView];
    }else {
        NSLog(@"模拟器不支持小视频录制");
    }
}

- (void)uploadFileWithURL:(NSString *)url{
//    if (_isUploadFile) {
        [DownLoadManager   qnFileUploadWithPath:url result:^(NSString *url, NSString *m, NSInteger code) {
            
        }];
//    }else {
//        NSLog(@"不需要文件上传");
//    }
}


// 调用此方法时superview.bounds已经改变。
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    NSLog(@"%s -- %ld", __FUNCTION__,(long)fromInterfaceOrientation);
//    NSLog(@"%@", NSStringFromCGSize(self.view.frame.size)); //这里打印的size 还是横竖屏后的size，横竖屏动画结束后才进行调用
//    NSLog(@"frame == %@  center == %@", NSStringFromCGRect(self.view.frame), NSStringFromCGPoint(self.view.center));
}

// 调用此方法时superview.bounds未改变
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
//    NSLog(@"%s --  %f", __FUNCTION__,duration);
//    NSLog(@"%@", NSStringFromCGSize(self.view.frame.size)); //这里打印的size 还是未横竖屏时的size
    NSLog(@"frame == %@  center == %@", NSStringFromCGRect(self.view.frame), NSStringFromCGPoint(self.view.center));
    [UIView animateWithDuration:duration animations:^{
        CGRect recordRect = self.RecordingBtn.frame;
        CGRect playRect = self.playingBtn.frame;
        CGRect downloadRect = self.downloadingBtn.frame;
        CGRect wxSVRect = self.wxSmartVideoBtn.frame;
        CGFloat width = (CGRectGetHeight(self.view.frame) - 60) / 3;
        recordRect.size.width = width;
        playRect.size.width = width;
        playRect.origin.x = 20 + recordRect.origin.x + width;
        downloadRect.size.width = width;
        downloadRect.origin.x = 20 + playRect.origin.x + width;
        self.RecordingBtn.frame = recordRect;
        self.playingBtn.frame = playRect;
        self.downloadingBtn.frame = downloadRect;
        wxSVRect.size.width = CGRectGetHeight(self.view.frame);
        self.wxSmartVideoBtn.frame = wxSVRect;
    }];
    
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:{
            // 竖立 {0, 64}, {320, 504}
           // 横屏 {{0, 32}, {568, 288}}
        // 横屏后，width = 504 + 64     height = 320 - 32
            [UIView animateWithDuration:duration animations:^{
                self.tempView.frame = CGRectMake(0, 0, CGRectGetHeight(self.view.frame) + 64, CGRectGetWidth(self.view.frame) - 32);
            }];
        }
            break;
        case UIInterfaceOrientationPortrait: {
            [UIView animateWithDuration:duration animations:^{
                self.tempView.frame = CGRectMake(0, 200, CGRectGetWidth(self.view.frame), 300);
            }];
        }
            break;
        default:
 
            break;
    }
 
}

- (BOOL)isSimulator {
#if TARGET_OS_SIMULATOR
    return YES;
#else
    return NO;
#endif
}
@end
