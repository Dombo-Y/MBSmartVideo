//
//  MBActionSheetView.h
//  SmartVideo
//
//  Created by yindongbo on 17/1/5.
//  Copyright © 2017年 Nxin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MBActionSheetView;
@class ActionSheetModel;
@class ActionSheetButton;
@protocol MBActionSheetDelegate <NSObject>

- (void)mbActionSheet:(MBActionSheetView *)actionSheet clickItem:(ActionSheetButton *)item;
@end

@interface MBActionSheetView : UIView

@property (nonatomic, strong) NSMutableArray <ActionSheetModel *> *dataArray;
@property (nonatomic, weak)id <MBActionSheetDelegate>delegate;

@property (nonatomic, strong) ActionSheetModel *sentToFriendModel;
@property (nonatomic, strong) ActionSheetModel *saveModel;
@property (nonatomic, strong) ActionSheetModel *collectionModel;
@property (nonatomic, strong) ActionSheetModel *identifyQR;
@property (nonatomic, strong) ActionSheetModel *editModel;
@end




#pragma mark - ActionSheetModel
typedef NS_ENUM(NSInteger, ActionSheetModelType) {
    ActionSheetModel_SentToFriend = 1,
    ActionSheetModel_Save,
    ActionSheetModel_Collection,
    ActionSheetModel_IdentifyQR,
    ActionSheetModel_Edit
};

@interface ActionSheetModel : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) ActionSheetModelType type;
@end



#pragma mark - ActionSheetButton
@interface ActionSheetButton : UIButton

@property (nonatomic, strong) ActionSheetModel *model;
@end
