//
//  Macro.h
//  SmartVideo
//
//  Created by yindongbo on 16/12/19.
//  Copyright © 2016年 Nxin. All rights reserved.
//

#ifndef Macro_h
#define Macro_h

#define SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height
#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width

#define RGBColor(r,g,b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f]

#define kWeakSelf(self)  __weak __typeof(&*self)weakSelf = self;


#define kSYSTEM_VERSION_iOS8Later  [SYSTEM_VERSION integerValue] >=8

#define kSYSTEM_VERSION_iOS9Later  [SYSTEM_VERSION integerValue] >=9

#define kSYSTEM_VERSION_iOS10Later [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] integerValue] >= 10

#endif /* Macro_h */
