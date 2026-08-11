//
//  UIFont+MirrorFont.m
//  Mirror
//

#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"

@implementation UIFont (MirrorFont)

+ (UIFont *)mirrorTitleFont_Card
{
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:16*kWidthRatio];
}

+ (UIFont *)mirrorHintFont_Card
{
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:10*kWidthRatio];
}


+ (UIFont *)mirrorButtonFont
{
    return [UIFont fontWithName:@"TrebuchetMS-Italic" size:16*kWidthRatio];
}

+ (UIFont *)mirrorTodayFont
{
    return [UIFont mirror_fontWithSize:37*kWidthRatio bold:NO];
}

+ (UIFont *)mirrorTitleFont
{
    return [UIFont mirror_fontWithSize:18*kWidthRatio bold:YES];
}

+ (UIFont *)mirrorSubtitleFont
{
    return [UIFont mirror_fontWithSize:18*kWidthRatio bold:NO];
}

+ (UIFont *)mirrorHighlightFont
{
    return [UIFont mirror_fontWithSize:16*kWidthRatio bold:YES];
}

+ (UIFont *)mirrorLabelFont
{
    return [UIFont mirror_fontWithSize:15*kWidthRatio bold:NO];
}

+ (UIFont *)mirrorHintFont
{
    return [UIFont mirror_fontWithSize:13*kWidthRatio bold:NO];
}

+ (UIFont *)mirrorMinFont
{
    return [UIFont mirror_fontWithSize:10*kWidthRatio bold:NO];
}

+ (UIFont *)mirror_fontWithSize:(CGFloat)fontSize bold:(BOOL)bold
{
    UIFont *font = [UIFont fontWithName:bold ? @"Trebuchet-BoldItalic":@"TrebuchetMS-Italic" size:fontSize];
    return font ?: [UIFont italicSystemFontOfSize:fontSize];
}

@end
