//
//  UIColor+MirrorColor.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import "UIColor+MirrorColor.h"
#import "MirrorSettings.h"

@implementation UIColor (MirrorColor)

+ (UIColor *)mirrorColorNamed:(MirrorColorType)colorType
{
    BOOL isLight = ![MirrorSettings appliedDarkMode];
    switch (colorType) {
        case MirrorColorTypeBackground:
            return isLight ? [UIColor whiteColor] : [UIColor blackColor];
        case MirrorColorTypeTabbarIconText:
            return [UIColor grayColor];
        case MirrorColorTypeTabbarIconTextHightlight:
            return isLight ? [UIColor blackColor] : [UIColor whiteColor];
        case MirrorColorTypeText:
            return isLight ? [UIColor blackColor] : [UIColor whiteColor];
        case MirrorColorTypeTextHint: // 和cell gray pulse一样
            return isLight ? [UIColor mirror_darkGray] : [UIColor mirror_lightGray];
        case MirrorColorTypeShadow:
            return [UIColor grayColor];
        case MirrorColorTypeAddTaskCellBG:
            return isLight ? [UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1] : [UIColor colorWithRed:15/255.0 green:15/255.0 blue:15/255.0 alpha:1];
        case MirrorColorTypeAddTaskCellPlus:
            return isLight ? [UIColor colorWithRed:200/255.0 green: 200/255.0  blue:200/255.0 alpha:1] : [UIColor colorWithRed:55/255.0 green: 55/255.0  blue:55/255.0 alpha:1];
        case MirrorColorTypeCellPink:
            return isLight ? [UIColor mirror_lightPink] : [UIColor mirror_darkPink];
        case MirrorColorTypeCellPinkPulse:
            return isLight ? [UIColor mirror_darkPink] : [UIColor mirror_lightPink];
        case MirrorColorTypeCellOrange:
            return isLight ? [UIColor mirror_lightOrange] : [UIColor mirror_darkOrange];
        case MirrorColorTypeCellOrangePulse:
            return isLight ? [UIColor mirror_darkOrange] : [UIColor mirror_lightOrange];
        case MirrorColorTypeCellYellow:
            return isLight ? [UIColor mirror_lightYellow] : [UIColor mirror_darkYellow];
        case MirrorColorTypeCellYellowPulse:
            return isLight ? [UIColor mirror_darkYellow] : [UIColor mirror_lightYellow];
        case MirrorColorTypeCellGreen:
            return isLight ? [UIColor mirror_lightGreen] : [UIColor mirror_darkGreen];
        case MirrorColorTypeCellGreenPulse:
            return isLight ? [UIColor mirror_darkGreen] : [UIColor mirror_lightGreen];
        case MirrorColorTypeCellTeal:
            return isLight ? [UIColor mirror_lightTeal] : [UIColor mirror_darkTeal];
        case MirrorColorTypeCellTealPulse:
            return isLight ? [UIColor mirror_darkTeal] : [UIColor mirror_lightTeal];
        case MirrorColorTypeCellBlue:
            return isLight ? [UIColor mirror_lightBlue] : [UIColor mirror_darkBlue];
        case MirrorColorTypeCellBluePulse:
            return isLight ? [UIColor mirror_darkBlue] : [UIColor mirror_lightBlue];
        case MirrorColorTypeCellPurple:
            return isLight ? [UIColor mirror_lightPurple] : [UIColor mirror_darkPurple];
        case MirrorColorTypeCellPurplePulse:
            return isLight ? [UIColor mirror_darkPurple] : [UIColor mirror_lightPurple];
        case MirrorColorTypeCellGray:
            return isLight ? [UIColor mirror_lightGray] : [UIColor mirror_darkGray];
        case MirrorColorTypeCellGrayPulse:
            return isLight ? [UIColor mirror_darkGray] : [UIColor mirror_lightGray];
        default:
            return [UIColor clearColor];
    }
}

+ (UIColor *)mirrorSystemColorNamed:(MirrorSystemColorType)colorType
{
    switch (colorType) {
        case MirrorSystemColorTypeRed:
            return [UIColor systemRedColor];
        case MirrorSystemColorTypeOrange:
            return [UIColor systemOrangeColor];
        case MirrorSystemColorTypeYellow:
            return [UIColor systemYellowColor];
        case MirrorSystemColorTypeGreen:
            return [UIColor systemGreenColor];
        case MirrorSystemColorTypeMint:
            if (@available(iOS 15.0, *)) {
                return [UIColor systemMintColor];
            }
            return [UIColor systemTealColor];
        case MirrorSystemColorTypeBlue:
            return [UIColor systemBlueColor];
        case MirrorSystemColorTypePurple:
            return [UIColor systemPurpleColor];
        case MirrorSystemColorTypeGray:
            return [UIColor systemGrayColor];
    }
}

// Only 8 colors can be pulsed.

+ (UIColor *)mirrorColorPulsed:(MirrorColorType)colorType
{
    switch (colorType) {
        case MirrorColorTypeCellPink:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellPinkPulse];
        case MirrorColorTypeCellOrange:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellOrangePulse];
        case MirrorColorTypeCellYellow:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellYellowPulse];
        case MirrorColorTypeCellGreen:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellGreenPulse];
        case MirrorColorTypeCellTeal:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellTealPulse];
        case MirrorColorTypeCellBlue:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellBluePulse];
        case MirrorColorTypeCellPurple:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellPurplePulse];
        case MirrorColorTypeCellGray:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse];
            
        case MirrorColorTypeCellPinkPulse:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellPink];
        case MirrorColorTypeCellOrangePulse:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellOrange];
        case MirrorColorTypeCellYellowPulse:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellYellow];
        case MirrorColorTypeCellGreenPulse:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellGreen];
        case MirrorColorTypeCellTealPulse:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellTeal];
        case MirrorColorTypeCellBluePulse:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellBlue];
        case MirrorColorTypeCellPurplePulse:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellPurple];
        case MirrorColorTypeCellGrayPulse:
            return [UIColor mirrorColorNamed:MirrorColorTypeCellGray];
        default:
            return [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    }
}

+ (UIColor *)mirror_lightPink
{
    return [UIColor colorWithRed:226/255.0 green:207/255.0 blue:210/255.0 alpha:1]; // 莫兰迪粉 #E2CFD2
}

+ (UIColor *)mirror_darkPink
{
    return [UIColor colorWithRed:90/255.0 green:48/255.0 blue:53/255.0 alpha:1]; // 莫兰迪深粉 #5A3035
}

+ (UIColor *)mirror_lightOrange
{
    return [UIColor colorWithRed:228/255.0 green:212/255.0 blue:204/255.0 alpha:1]; // 莫兰迪橘 #E4D4CC
}

+ (UIColor *)mirror_darkOrange
{
    return [UIColor colorWithRed:90/255.0 green:52/255.0 blue:36/255.0 alpha:1]; // 莫兰迪深橘 #5A3424
}

+ (UIColor *)mirror_lightYellow
{
    return [UIColor colorWithRed:229/255.0 green:218/255.0 blue:200/255.0 alpha:1]; // 莫兰迪黄 #E5DAC8
}

+ (UIColor *)mirror_darkYellow
{
    return [UIColor colorWithRed:93/255.0 green:69/255.0 blue:42/255.0 alpha:1]; // 莫兰迪深黄（棕）#5D452A
}

+ (UIColor *)mirror_lightGreen
{
    return [UIColor colorWithRed:213/255.0 green:225/255.0 blue:211/255.0 alpha:1]; // 莫兰迪绿 #D5E1D3
}

+ (UIColor *)mirror_darkGreen
{
    return [UIColor colorWithRed:51/255.0 green:64/255.0 blue:45/255.0 alpha:1]; // 莫兰迪深绿 #33402D
}

+ (UIColor *)mirror_lightTeal
{
    return [UIColor colorWithRed:205/255.0 green:222/255.0 blue:225/255.0 alpha:1]; // 莫兰迪青 #CDDEE1
}

+ (UIColor *)mirror_darkTeal
{
    return [UIColor colorWithRed:33/255.0 green:74/255.0 blue:80/255.0 alpha:1]; // 莫兰迪深青 #214A50
}

+ (UIColor *)mirror_lightBlue
{
    return [UIColor colorWithRed:206/255.0 green:216/255.0 blue:228/255.0 alpha:1]; // 莫兰迪蓝 #CED8E4
}

+ (UIColor *)mirror_darkBlue
{
    return [UIColor colorWithRed:53/255.0 green:64/255.0 blue:76/255.0 alpha:1]; // 莫兰迪深蓝 #35404C
}

+ (UIColor *)mirror_lightPurple
{
    return [UIColor colorWithRed:220/255.0 green:211/255.0 blue:228/255.0 alpha:1]; // 莫兰迪紫 #DCD3E4
}

+ (UIColor *)mirror_darkPurple
{
    return [UIColor colorWithRed:57/255.0 green:54/255.0 blue:74/255.0 alpha:1]; // 莫兰迪深紫 #39364A
}

+ (UIColor *)mirror_lightGray
{
    return [UIColor colorWithRed:218/255.0 green:218/255.0 blue:218/255.0 alpha:1]; // 莫兰迪灰 #DADADA
}

+ (UIColor *)mirror_darkGray
{
    return [UIColor colorWithRed:61/255.0 green:61/255.0 blue:61/255.0 alpha:1]; // 莫兰迪深灰 #3D3D3D
}

@end
