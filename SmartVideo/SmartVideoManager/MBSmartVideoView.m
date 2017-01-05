//
//  MBSmartVideoView.m
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "MBSmartVideoView.h"
#import "MBSmartVideoRecorder.h"

typedef NS_ENUM(NSInteger, MBLongPressState) {
    MBLongPressStateIn,
    MBLongPressStateOut
};

@interface MBSmartVideoView ()


@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *preview;
@property (nonatomic, strong) UIView *processView;
@property (nonatomic, strong) UIView *controlView;

@property (nonatomic, strong) UIView *tipViewA; //上移取消
@property (nonatomic, strong) UIView *tipViewB; //松开取消

@property (nonatomic, strong) UIView *waitingEyeView;

@property (nonatomic, assign) AVCaptureVideoPreviewLayer *recorderLayer;

@property (nonatomic, strong) MBSmartVideoRecorder *recorder;

@property (nonatomic, assign) MBLongPressState state;

@property (nonatomic, assign, getter=isScale) BOOL scale;
@end

#define MAXDURATION 6
@implementation MBSmartVideoView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame])
    {
        [self setUI];
        [self configRecorder];
        [self.recorder setup];
        [self setCaptureUI];
        [self setTipUI];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.recorder startSession];
            [UIView animateWithDuration:0.25 animations:^{
                self.waitingEyeView.alpha = 0.f;
            } completion:^(BOOL finished) {
                self.waitingEyeView.hidden = YES;
            }];
        });
        [self addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

#pragma mark - LazyInit
- (UIView *)backgroundView {
    if (!_backgroundView)
    {
        _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = 0.4f;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRemove)];
        [_backgroundView addGestureRecognizer:tap];
    }
    return _backgroundView;
}

- (UIView *)preview {
    if (!_preview)
    {
        CGFloat ratio = 0.74666;//280/375;
        CGFloat height = ratio * SCREEN_WIDTH;
        _preview = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - height - 85, SCREEN_WIDTH, height)];
        _preview.backgroundColor = [UIColor blackColor];
    }
    return _preview;
}

- (UIView *)controlView {
    if (!_controlView)
    {
        _controlView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 85, SCREEN_WIDTH, 85)];
        _controlView.backgroundColor = [UIColor blackColor];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [_controlView addGestureRecognizer:longPress];
        
        UILabel *tipLabel = [[UILabel alloc] initWithFrame:_controlView.bounds];
        tipLabel.text = @"按住拍";
        tipLabel.textColor = [UIColor orangeColor];//[UIColor colorWithHexString:@"#ff501f"];
        tipLabel.font = [UIFont systemFontOfSize:18 weight:2];
        tipLabel.textAlignment = NSTextAlignmentCenter;
        [_controlView addSubview:tipLabel];
    }
    return _controlView;
}

- (UIView *)processView {
    if (!_processView)
    {
        _processView = [[UIView alloc] initWithFrame:CGRectMake(0, _preview.frame.size.height + _preview.frame.origin.y - 3, SCREEN_WIDTH, 3)];
        _processView.layer.backgroundColor = [UIColor orangeColor].CGColor;//[UIColor colorWithHexString:@"#ff511c"].CGColor;
    }
    return _processView;
}

- (UIView *)tipViewA {
    if (!_tipViewA)
    {
        _tipViewA = [[UIView alloc] initWithFrame:CGRectMake(0, _preview.frame.size.height - 45, 80, 25)];
        _tipViewA.backgroundColor =[UIColor clearColor];
        CGPoint tipViewCenter = _tipViewA.center;
        tipViewCenter.x = self.preview.center.x;
        _tipViewA.center = tipViewCenter;
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:_tipViewA.bounds];
        backgroundView.backgroundColor = [UIColor blackColor];
        backgroundView.alpha = 0.4;
        [_tipViewA addSubview:backgroundView];
        
        UIButton *tipButton = [[UIButton alloc] initWithFrame:_tipViewA.bounds];
        [tipButton setTitle:@"上移取消" forState:UIControlStateNormal];
        [tipButton setImage:[UIImage imageNamed:@"smartVideo_arrow"] forState:UIControlStateNormal];
        [tipButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [tipButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_tipViewA addSubview:tipButton];
        
        _tipViewA.hidden = YES;
    }
    return _tipViewA;
}

- (UIView *)tipViewB {
    if (!_tipViewB)
    {
        _tipViewB = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 25)];
        _tipViewB.backgroundColor = [UIColor clearColor];
 
        CGPoint tipViewBCenter = _tipViewB.center;
        tipViewBCenter.x = self.preview.center.x;
        _tipViewB.center = tipViewBCenter;
        
        CGRect tipViewBFrame = _tipViewB.frame;
        tipViewBFrame.origin.y = self.preview.frame.size.height - 170;
        _tipViewB.frame = tipViewBFrame;
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:_tipViewB.bounds];
        backgroundView.backgroundColor = [UIColor blackColor];//[UIColor colorWithHexString:@"#ebb81d"];
        backgroundView.alpha = 0.9;
        [_tipViewB addSubview:backgroundView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:_tipViewB.bounds];
        label.text = @"松开取消";
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:14];
        label.textAlignment = NSTextAlignmentCenter;
        [_tipViewB addSubview:label];
        
        _tipViewB.hidden = YES;
    }
    return _tipViewB;
}

- (UIView *)waitingEyeView {
    if (!_waitingEyeView)
    {
        _waitingEyeView = [[UIView alloc] initWithFrame:_preview.frame];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"smartVideo_eye"]];
        imageView.center = CGPointMake(_waitingEyeView.frame.size.width/2, _waitingEyeView.frame.size.height/2);
        [_waitingEyeView addSubview:imageView];
        _waitingEyeView.backgroundColor = [UIColor blackColor];
    }
    return _waitingEyeView;
}


#pragma mark - CustomMethod
- (void)setUI {
    [self addSubview:self.backgroundView];
    [self addSubview:self.preview];
    [self addSubview:self.waitingEyeView];
    [self addSubview:self.processView];
    [self addSubview:self.controlView];
}

- (void)setCaptureUI {
    self.recorderLayer = [self.recorder getPreviewLayer];
    self.recorderLayer.frame = CGRectMake(0, 15, self.preview.frame.size.width, self.preview.frame.size.height - 15);
    self.recorderLayer.backgroundColor = [UIColor grayColor].CGColor;
    [self.preview.layer addSublayer:self.recorderLayer];
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGR:)];
    tapGR.numberOfTapsRequired = 2;
    [self.preview addGestureRecognizer:tapGR];
}

- (void)setTipUI{
    [self.preview addSubview:self.tipViewA];
    [self.preview addSubview:self.tipViewB];
}

- (void)configRecorder {
    self.recorder = [MBSmartVideoRecorder sharedRecorder];
    self.recorder.maxDuration = MAXDURATION;
    self.recorder.cropSize = self.preview.frame.size;
    
    __weak __typeof(&*self)weakSelf = self;
    [self.recorder setFinishBlock:^(NSDictionary *info, RecorderFinishedReason reason)
    {
        switch (reason)
        {
            case RecorderFinishedReasonNormal:
            case RecorderFinishedReasonBeyondMaxDuration:
            {
                NSLog(@"%@", info);
                if (weakSelf.finishedRecordBlock)
                {
                    weakSelf.finishedRecordBlock(info);
                }
                [weakSelf removeSelf];
            }
                break;
            case RecorderFinishedReasonCancle:
            {
                NSLog(@"重置");
            }
                break;
        }
    }];
}

- (void)removeSelf {
    [self.recorder stopSession];
    [self removeFromSuperview];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"state"])
    {
        if (_state == MBLongPressStateIn)
        {
            self.processView.layer.backgroundColor = [UIColor orangeColor].CGColor;//[UIColor colorWithHexString:@"#ff511c"].CGColor;
        }
        else if (_state == MBLongPressStateOut)
        {
            self.processView.layer.backgroundColor = [UIColor yellowColor].CGColor;//[UIColor colorWithHexString:@"#ebb81d"].CGColor;
        }
    }
}

#pragma mark - AnimationMethod
- (void)beginAnimation {
    CABasicAnimation *scaleXAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    scaleXAnimation.duration = MAXDURATION;
    scaleXAnimation.fromValue = @(1.f);
    scaleXAnimation.toValue = @(0.f);
    [self.processView.layer addAnimation:scaleXAnimation forKey:@"scaleXAnimation"];
}

- (void)stopAnimation {
    [self.processView.layer removeAllAnimations];
    self.processView.layer.backgroundColor = [UIColor orangeColor].CGColor;//[UIColor colorWithHexString:@"#ff511c"].CGColor;
}

#pragma mark - UILongPress
- (void)longPress:(UILongPressGestureRecognizer *)longPress {
    switch (longPress.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            NSLog(@"开始");
            [self beginAnimation];
            self.tipViewA.hidden = NO;
            [self.recorder startCapture];
        }
            break;
        case UIGestureRecognizerStateEnded:
        {
            NSLog(@"结束 %ld", (long)_state);
            [self stopAnimation];
            if (_state == MBLongPressStateIn)
            {
                [self.recorder stopCapture];
            }
            else if (_state == MBLongPressStateOut)
            {
                [self.recorder cancelCapture];
            }
            self.tipViewA.hidden = YES;
            self.tipViewB.hidden = YES;
        }
            break;
        case UIGestureRecognizerStateChanged:
        {
            CGPoint point = [longPress locationInView:self];
            if (CGRectContainsPoint(self.controlView.frame, point))
            {
                self.state = MBLongPressStateIn;
                self.tipViewA.hidden = NO;
                self.tipViewB.hidden = YES;
            }
            else
            {
                self.state = MBLongPressStateOut;
                self.tipViewA.hidden = YES;
                self.tipViewB.hidden = NO;
            }
        }
            break;
        default:
            break;
    }
}

//双击 焦距调整
- (void)tapGR:(UITapGestureRecognizer *)tapGes {
    CGFloat scaleFactor = self.isScale ? 1 : 2.f;
    self.scale = !self.isScale;
    [self.recorder setScaleFactor:scaleFactor];
}

- (void)tapRemove {
    [self removeSelf];
}

#pragma mark - 
- (void)dealloc {
    [self removeObserver:self forKeyPath:@"state"];
}
@end
