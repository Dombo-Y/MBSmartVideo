//
//  MBActionSheetView.m
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import "MBActionSheetView.h"

#define SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width
#define RGBColor(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]
@interface MBActionSheetView()

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *actionSheetView;
@end

@implementation MBActionSheetView

#pragma mark - DataModel
- (ActionSheetModel *)editModel {
    if (!_editModel)
    {
        _editModel = [ActionSheetModel new];
        _editModel.name = @"删除";
        _editModel.type = ActionSheetModel_Edit;
    }
    return _editModel;
}

- (ActionSheetModel *)sentToFriendModel {
    if (!_sentToFriendModel)
    {
        _sentToFriendModel = [ActionSheetModel new];
        _sentToFriendModel.name = @"发送给朋友";
        _sentToFriendModel.type = ActionSheetModel_SentToFriend;
    }
    return _sentToFriendModel;
}

- (ActionSheetModel *)saveModel {
    if (!_saveModel)
    {
        _saveModel = [ActionSheetModel new];
        _saveModel.name = @"保存到本机";
        _saveModel.type = ActionSheetModel_Save;
    }
    return _saveModel;
}

- (ActionSheetModel *)collectionModel {
    if (!_collectionModel)
    {
        _collectionModel = [ActionSheetModel new];
        _collectionModel.name = @"收藏";
        _collectionModel.type = ActionSheetModel_Collection;
    }
    return _collectionModel;
}

- (ActionSheetModel *)identifyQR {
    if (!_identifyQR)
    {
        _identifyQR = [ActionSheetModel new];
        _identifyQR.name = @"识别图中二维码";
        _identifyQR.type = ActionSheetModel_IdentifyQR;
    }
    return  _identifyQR;
}

#pragma mark - View
-(UIView *)backgroundView {
    if (!_backgroundView)
    {
        _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
        _backgroundView.backgroundColor = [UIColor blackColor];
        _backgroundView.alpha = .3f;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
        [_backgroundView addGestureRecognizer:tap];
    }
    return _backgroundView;
}

#pragma mark - DataSource
- (void)setDataArray:(NSMutableArray *)dataArray {
    _dataArray = dataArray;
    [self setUI];
}

#pragma mark - Layout
- (void)setUI {
    [self addSubview:self.backgroundView];
    
    CGFloat height = 50;
    CGFloat interval = 5;
    CGFloat actionSheetHeight = height * (self.dataArray.count + 1) +interval;
    
    self.actionSheetView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height, SCREEN_WIDTH, actionSheetHeight)];
    [self addSubview:self.actionSheetView];
    
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.actionSheetView.frame.size.width, self.actionSheetView.frame.size.height)];
    toolbar.barStyle = UIBarStyleDefault;
    [self.actionSheetView addSubview:toolbar];
    
    ActionSheetButton *cancelBtn = [ActionSheetButton buttonWithType:UIButtonTypeCustom];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn setBackgroundImage:[UIColor clearColor].image forState:UIControlStateNormal];
    [cancelBtn setBackgroundImage:RGBColor(175, 175, 175).image forState:UIControlStateHighlighted];
    [cancelBtn setTitleColor:RGBColor(51, 51, 51) forState:UIControlStateNormal];
    [cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:18]];
    [cancelBtn setTag:666];
    [cancelBtn setFrame:CGRectMake(0, actionSheetHeight - height, SCREEN_WIDTH, height)];
    [cancelBtn addTarget:self action:@selector(clickItem:) forControlEvents:UIControlEventTouchUpInside];
    [self.actionSheetView addSubview:cancelBtn];
    
    UIView *intervalView = [[UIView alloc] initWithFrame:CGRectMake(0, cancelBtn.frame.origin.y - interval, self.frame.size.width, interval)];
    intervalView.backgroundColor = RGBColor(114, 114, 114);
    intervalView.alpha = 0.3f;
    [self.actionSheetView addSubview:intervalView];
    
    for (NSInteger i = 0; i < self.dataArray.count; i ++)
    {
        ActionSheetButton * button = [ActionSheetButton buttonWithType:UIButtonTypeCustom];
        button.model = [self.dataArray objectAtIndex:i];
        button.frame = CGRectMake(0,i * height, SCREEN_WIDTH, height);
        [button setBackgroundImage:[UIColor clearColor].image forState:UIControlStateNormal];
        [button setTitleColor:RGBColor(51, 51, 51) forState:UIControlStateNormal];
        [button setBackgroundImage:RGBColor(175, 175, 175).image forState:UIControlStateHighlighted];
        [button.titleLabel setFont:[UIFont systemFontOfSize:18]];
        [button addTarget:self action:@selector(clickItem:) forControlEvents:UIControlEventTouchUpInside];
        [self.actionSheetView addSubview:button];
        
        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectMake(0, button.frame.size.height - 0.5, SCREEN_WIDTH, 0.5)];
        bottomLine.backgroundColor = RGBColor(155, 155, 155);
        [button addSubview:bottomLine];
    }
    
    [self showSheetView];
}

#pragma mark - Action
- (void)clickItem:(ActionSheetButton *)item {

    [self hiddenSheetView];

    if (self.delegate && [self.delegate respondsToSelector:@selector(mbActionSheet:clickItem:)])
    {
        [self.delegate mbActionSheet:self clickItem:item];
    }
}

#pragma mark - Animate
- (void)showSheetView {
    CGRect sheetFrame = self.actionSheetView.frame;
    sheetFrame.origin.y = self.frame.size.height - self.actionSheetView.frame.size.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.actionSheetView.frame = sheetFrame;
    }];
}

- (void)tapAction {
    [self hiddenSheetView];
}

- (void)hiddenSheetView {
    CGRect actionSheetFrame = self.actionSheetView.frame;
    actionSheetFrame.origin.y = self.frame.size.height;
    
    [self.backgroundView removeFromSuperview];
    [UIView animateWithDuration:0.2 animations:^{
        self.actionSheetView.frame = actionSheetFrame;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}
@end


#pragma mark - Button -
@implementation ActionSheetButton
- (void)setModel:(ActionSheetModel *)model {
    _model = model;
    
    [self setTitle:model.name forState:UIControlStateNormal];
    
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.frame =  CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    toolbar.barStyle = UIBarStyleBlackTranslucent;
    [self addSubview:toolbar];
}
@end

#pragma mark - Model -
@implementation ActionSheetModel

@end
