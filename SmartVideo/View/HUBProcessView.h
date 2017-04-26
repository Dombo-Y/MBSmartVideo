//
//  HUBProcessView.h
//  SmartVideo
//
//  Created by yindongbo on 2017/4/24.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HUBProcessView : UIView



+ (instancetype)shareHUBProcess;

@property (nonatomic, assign) CGFloat process;



- (void)showHubProcess:(CGFloat)process ;
- (void)hidenHubProcess;

- (void)setProgressWidth:(CGFloat)width;
@end
