//
//  MBSmartVideoView.h
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface MBSmartVideoView : UIView

/*
 videoURL,      NSString   本地链接
 videoDuration, NSString   6
 videoSize: NSString  390kb
 videoFirstFrame: UIImage  视频第一帧
 };
 **/
@property (nonatomic, copy) void(^finishedRecordBlock)(NSDictionary *info);
@end
