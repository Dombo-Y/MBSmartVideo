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
@interface SmartViewController ()

@property (nonatomic, copy) NSString *videoUrll;
@end

@implementation SmartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)action:(UIButton *)sender {
    MBSmartVideoView *smart = [[MBSmartVideoView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    [self.navigationController.view addSubview:smart];
    
    [smart setFinishedRecordBlock:^(NSDictionary *info) {
        self.videoUrll = [[info objectForKey:@"videoURL"] description];
    }];
}


- (IBAction)playVideo:(UIButton *)sender {
    if (self.videoUrll.length >0)
    {
        MBPlaySmartVideoViewController *playVC =[[MBPlaySmartVideoViewController alloc] init];
        playVC.videoUrlString = self.videoUrll;
        [self.navigationController pushViewController:playVC animated:YES];
    }
}

@end
