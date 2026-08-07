//
//  MirrorSettings.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/10.
//

#import "MirrorSettings.h"
#import "UIColor+MirrorColor.h"

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
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredChinese"];
}

+ (void)switchLanguage
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredChinese"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MirrorUserPreferredChinese"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MirrorUserPreferredChinese"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchLanguageNotification object:nil];
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

+ (BOOL)appliedHistogramData
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredHistogramData"];
}

+ (void)switchChartTypeData
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredHistogramData"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MirrorUserPreferredHistogramData"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MirrorUserPreferredHistogramData"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchChartTypeDataNotification object:nil];
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
        NSArray *allColorType = @[@(MirrorColorTypeCellPink), @(MirrorColorTypeCellOrange), @(MirrorColorTypeCellYellow), @(MirrorColorTypeCellGreen), @(MirrorColorTypeCellTeal), @(MirrorColorTypeCellBlue), @(MirrorColorTypeCellPurple),@(MirrorColorTypeCellGray)];
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

// Show original index

+ (BOOL)appliedShowIndex
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredShowIndex"];
}
+ (void)switchShowIndex
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"MirrorUserPreferredShowIndex"]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"MirrorUserPreferredShowIndex"];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"MirrorUserPreferredShowIndex"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchShowIndexNotification object:nil];
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

+ (SpanType)spanType
{
    NSNumber *spanType = [[NSUserDefaults standardUserDefaults] objectForKey:@"MirrorUserPreferredSpanType"];
    if (spanType==nil) {
        [[NSUserDefaults standardUserDefaults] setInteger:SpanTypeWeek forKey:@"MirrorUserPreferredSpanType"];
        return SpanTypeWeek; // 如果用户没有点过，默认展示week
    } else {
        return [spanType integerValue];
    }
}

+ (void)changeSpanType:(SpanType)spanType
{
    [[NSUserDefaults standardUserDefaults] setInteger:spanType forKey:@"MirrorUserPreferredSpanType"];
}

@end
