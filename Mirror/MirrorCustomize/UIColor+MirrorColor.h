//
//  UIColor+MirrorColor.h
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM (NSInteger, MirrorUserInterfaceStyle) {
    MirrorUserInterfaceStyleLight,
    MirrorUserInterfaceStyleDark,
};

typedef NS_ENUM(NSInteger, MirrorColorType) {
    
    MirrorColorTypeCellPink =  0,
    MirrorColorTypeCellPinkPulse =  1,
    MirrorColorTypeCellOrange = 2,
    MirrorColorTypeCellOrangePulse = 3,
    MirrorColorTypeCellYellow = 4,
    MirrorColorTypeCellYellowPulse = 5,
    MirrorColorTypeCellGreen = 6,
    MirrorColorTypeCellGreenPulse = 7,
    MirrorColorTypeCellTeal = 8,
    MirrorColorTypeCellTealPulse = 9,
    MirrorColorTypeCellBlue = 10,
    MirrorColorTypeCellBluePulse = 11,
    MirrorColorTypeCellPurple = 12,
    MirrorColorTypeCellPurplePulse = 13,
    MirrorColorTypeCellGray = 14,
    MirrorColorTypeCellGrayPulse = 15,
    
    // 后续添加颜色从这里添加
    
    MirrorColorTypeBackground,               // 主背景色
    MirrorColorTypeTabbarIconText,           // tabbar item 未选中的颜色
    MirrorColorTypeTabbarIconTextHightlight, // tabbar item 被选中的颜色
    MirrorColorTypeText,                     // 文字颜色
    MirrorColorTypeTextHint,                 // 文字备注颜色
    MirrorColorTypeShadow,                   // 阴影颜色
    MirrorColorTypeAddTaskCellBG,            // add task cell的背景颜色
    MirrorColorTypeAddTaskCellPlus,          // add task cell的加号颜色
};

@interface UIColor (MirrorColor)

+ (UIColor *)mirrorColorNamed:(MirrorColorType)colorType;
+ (UIColor *)mirrorColorPulsed:(MirrorColorType)colorType;
+ (NSString *)getEmoji:(MirrorColorType)color;
+ (NSString *)getLongEmoji:(MirrorColorType)color;

@end

NS_ASSUME_NONNULL_END
