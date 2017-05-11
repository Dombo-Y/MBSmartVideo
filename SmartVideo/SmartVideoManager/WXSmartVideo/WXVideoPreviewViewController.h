//
//  WXVideoPreviewViewController.h
//  SmartVideo
//
//  Created by yindongbo on 2017/5/9.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WXVideoPreviewViewController : UIViewController

@property (nonatomic, copy) NSString *url;

@property (nonatomic, copy) void (^operateBlock)();

@property (nonatomic, strong) UIImage *img;
@end
