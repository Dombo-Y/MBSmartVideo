//
//  HUBProcessView.m
//  SmartVideo
//
//  Created by yindongbo on 2017/4/24.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "HUBProcessView.h"

@implementation HUBProcessView {
    UILabel *_processLabel;
    CAShapeLayer *_trackLayer;
    CAShapeLayer *_progressLayer;
    CGFloat _progressWidth;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]){
        _progressWidth = 5;
        
        self.layer.borderWidth = 0.5;
        self.layer.cornerRadius = 5;
        [self.layer setMasksToBounds:YES];
        
        self.backgroundColor = [UIColor clearColor];
        UIView *bgView = [[UIView alloc] initWithFrame:self.bounds];
        bgView.backgroundColor = [UIColor whiteColor];
        [self addSubview:bgView];
        
        _processLabel = [[UILabel alloc] initWithFrame:self.bounds];
        [self addSubview:_processLabel];
        _processLabel.textAlignment = NSTextAlignmentCenter;
        
        CAShapeLayer *trackLayer = [CAShapeLayer new];
        trackLayer.fillColor = nil;
        trackLayer.frame = self.bounds;
        trackLayer.strokeColor = [UIColor blackColor].CGColor;
        trackLayer.lineWidth = _progressWidth;
        _trackLayer = trackLayer;
        [self.layer addSublayer:_trackLayer];
        
        CAShapeLayer *progressLayer = [CAShapeLayer new];
        progressLayer.fillColor = nil;
        progressLayer.lineCap = kCALineCapRound;
        progressLayer.frame = self.bounds;
        progressLayer.strokeColor = [UIColor colorWithRed:82.0 / 255.0
                                                    green:135.0 / 255.0
                                                     blue:237.0 / 255.0
                                                    alpha:1.0].CGColor;
        progressLayer.lineWidth = _progressWidth;
        _progressLayer = progressLayer;
        [self.layer addSublayer:_progressLayer];
        
        [self setTrackColor];
        [self setProgress];
        
 
    }
    return self;
}

+ (instancetype)shareHUBProcess {
    static HUBProcessView *hub;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hub = [[HUBProcessView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        CGSize size = [UIScreen mainScreen].bounds.size;
        hub.center = CGPointMake(size.width / 2, size.height/2);
    });
    return hub;
}

- (void)showHubProcess:(CGFloat)process {
    if (process == 0) {
        [self buildSelfAddWindow];
    }else {
        self.process = process;
    }
}

- (void)hidenHubProcess {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeFromSuperview];
        });
    });
}

- (void)buildSelfAddWindow {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *windows = [[UIApplication sharedApplication].delegate window];
        [windows addSubview:self];
    });
}

- (void)setProcess:(CGFloat)process {
    _process = process;
    NSLog(@"%f", process);
    _processLabel.text = [NSString stringWithFormat:@"%.2f%%",process * 100];
    [self setProgress];
}

#pragma mark - Set Property
-(void)setTrackColor{
    UIBezierPath *trackPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(50, 50)
                                                             radius:(self.bounds.size.width - _progressWidth)/ 2
                                                         startAngle:0
                                                           endAngle:M_PI * 2
                                                          clockwise:YES];;
    _trackLayer.path = trackPath.CGPath;
}


-(void)setProgress{
    UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(50, 50)
                                                                radius:(self.bounds.size.width - _progressWidth)/2
                                                            startAngle:-M_PI_2
                                                              endAngle:(M_PI * 2)*_process - M_PI_2
                                                             clockwise:YES];
    _progressLayer.path = progressPath.CGPath;
}

- (void)setProgressWidth:(CGFloat)width {
    _progressWidth = width;
    _trackLayer.lineWidth = _progressWidth;
    _progressLayer.lineWidth = _progressWidth;
}
@end
