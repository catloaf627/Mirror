//
//  MirrorSettings.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/10.
//

#import "MirrorSettings.h"
#import "UIColor+MirrorColor.h"

static NSString * const kMirrorPreferredLanguageKey = @"MirrorUserPreferredLanguage";

@implementation MirrorSettings

+ (BOOL)appliedDarkMode
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredDarkMode"];
}

+ (void)switchTheme
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredDarkMode"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MirrorUserPreferredDarkMode"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MirrorUserPreferredDarkMode"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchThemeNotification object:nil];
}

+ (BOOL)appliedChinese
{
    return [MirrorSettings preferredLanguageKey] == MirrorLanguageKeySimplifiedChinese;
}

+ (BOOL)hasPreferredLanguage
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kMirrorPreferredLanguageKey] != nil;
}

+ (MirrorLanguageKey)preferredLanguageKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id languageKey = [defaults objectForKey:kMirrorPreferredLanguageKey];
    if ([languageKey respondsToSelector:@selector(integerValue)]) {
        NSInteger value = [languageKey integerValue];
        if (value >= MirrorLanguageKeyEnglish && value <= MirrorLanguageKeyRussian) return (MirrorLanguageKey)value;
    }

    if ([defaults boolForKey:@"MirrorUserPreferredChinese"]) {
        [defaults setInteger:MirrorLanguageKeySimplifiedChinese forKey:kMirrorPreferredLanguageKey];
        return MirrorLanguageKeySimplifiedChinese;
    }
    return MirrorLanguageKeyEnglish;
}

+ (void)changeLanguageWithKey:(MirrorLanguageKey)languageKey
{
    if (languageKey < MirrorLanguageKeyEnglish || languageKey > MirrorLanguageKeyRussian) return;
    BOOL languageChanged = [MirrorSettings preferredLanguageKey] != languageKey;
    
    [[NSUserDefaults standardUserDefaults] setInteger:languageKey forKey:kMirrorPreferredLanguageKey];
    [[NSUserDefaults standardUserDefaults] setBool:languageKey == MirrorLanguageKeySimplifiedChinese forKey:@"MirrorUserPreferredChinese"];
    if (languageChanged) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchLanguageNotification object:nil];
    }
}

+ (BOOL)appliedWeekStarsOnMonday
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredWeekStartsOnMonday"];
}

+ (void)switchWeekStartsOn
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredWeekStartsOnMonday"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MirrorUserPreferredWeekStartsOnMonday"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MirrorUserPreferredWeekStartsOnMonday"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchWeekStartsOnNotification object:nil];
}

+ (BOOL)appliedPieChartRecord
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredPiechartRecord"];
}

+ (void)switchChartTypeRecord
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredPiechartRecord"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MirrorUserPreferredPiechartRecord"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MirrorUserPreferredPiechartRecord"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchChartTypeRecordNotification object:nil];
}

// 按照时间长短更新颜色深浅
+ (BOOL)appliedHeatmap
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredHeatmap"];
}

+ (void)switchHeatmap
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredHeatmap"]) {
        // 打开热力图
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MirrorUserPreferredHeatmap"];
        NSArray *allColorType = @[@(MirrorColorTypeCellPinkPulse), @(MirrorColorTypeCellOrangePulse), @(MirrorColorTypeCellYellowPulse), @(MirrorColorTypeCellGreenPulse), @(MirrorColorTypeCellTealPulse), @(MirrorColorTypeCellBluePulse), @(MirrorColorTypeCellPurplePulse),@(MirrorColorTypeCellGrayPulse)];
        NSInteger randomColorType = [allColorType[arc4random() % allColorType.count] integerValue];
        [[NSUserDefaults standardUserDefaults] setInteger:randomColorType forKey:@"MirrorUserPreferredHeatmapColor"]; // 随机保存一个颜色
    } else {
        // 关闭热力图
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MirrorUserPreferredHeatmap"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchShowShadeNotification object:nil];
}

+ (NSInteger)preferredHeatmapColor
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:@"MirrorUserPreferredHeatmapColor"];
}

+ (NSString *)userMotto
{
    NSString *motto = [[NSUserDefaults standardUserDefaults] stringForKey:@"MirrorUserMotto"];
    if (motto==nil) {
        return @"Mirror, mirror on the wall, who is the smartest of them all?";
    } else {
        return motto;
    }
}

+ (void)saveUserMotto:(NSString *)motto
{
    [[NSUserDefaults standardUserDefaults] setObject:motto forKey:@"MirrorUserMotto"];
}

@end
