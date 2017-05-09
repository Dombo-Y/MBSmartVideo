//
//  WXSmartVideoControlView.h
//  SmartVideo
//
//  Created by yindongbo on 2017/5/8.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WXSmartVideoControlView;
@protocol SmartVideoControlDelegate <NSObject>
@required
- (void)smartVideoControl:(WXSmartVideoControlView *)control gestureRecognizer:(UIGestureRecognizer *)gest;
 
@end

@interface WXSmartVideoControlView : UIView

@property (nonatomic, weak)id <SmartVideoControlDelegate>delegate;

@property (nonatomic, assign)NSInteger duration;
@end
