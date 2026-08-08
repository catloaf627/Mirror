//
//  UIFont+MirrorFont.m
//  Mirror
//

#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"

@implementation UIFont (MirrorFont)

+ (UIFont *)mirrorTodayFont
{
    return [UIFont mirror_fontWithSize:37*kFontScale bold:NO];
}

+ (UIFont *)mirrorTitleFont
{
    return [UIFont mirror_fontWithSize:18*kFontScale bold:YES];
}

+ (UIFont *)mirrorSubtitleFont
{
    return [UIFont mirror_fontWithSize:18*kFontScale bold:NO];
}

+ (UIFont *)mirrorLabelFont
{
    return [UIFont mirror_fontWithSize:15*kFontScale bold:NO];
}

+ (UIFont *)mirrorHintFont
{
    return [UIFont mirror_fontWithSize:13*kFontScale bold:NO];
}

+ (UIFont *)mirror_fontWithSize:(CGFloat)fontSize bold:(BOOL)bold
{
    UIFont *font = [UIFont fontWithName:bold ? @"Trebuchet-BoldItalic":@"TrebuchetMS-Italic" size:fontSize];
    return font ?: [UIFont italicSystemFontOfSize:fontSize];
}

@end
