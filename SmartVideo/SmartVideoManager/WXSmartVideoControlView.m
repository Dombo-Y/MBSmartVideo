//
//  WXSmartVideoControlView.m
//  SmartVideo
//
//  Created by yindongbo on 2017/5/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "WXSmartVideoControlView.h"

@implementation WXSmartVideoControlView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        backBtn.backgroundColor = [UIColor blackColor];
        backBtn.frame = CGRectMake(20, 50, 50, 50);
        [self addSubview:backBtn];
        
        UIButton *controlBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        controlBtn.backgroundColor = [UIColor greenColor];
        controlBtn.frame = CGRectMake(0, 0, 50, 50);
        controlBtn.center = CGPointMake(frame.size.width/2, 100);
        [self addSubview:controlBtn];
        
        UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 20)];
        tipLabel.text = @"嘿嘿嘿嘿嘿嘿";
        tipLabel.textColor = [UIColor whiteColor];
        tipLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:tipLabel];
    }
    return self;
}
@end
