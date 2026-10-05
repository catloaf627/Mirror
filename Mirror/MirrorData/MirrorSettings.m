//
//  MirrorSettings.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/10.
//

#import "MirrorSettings.h"
#import "UIColor+MirrorColor.h"

static NSString * const kMirrorPreferredLanguageKey = @"MirrorUserPreferredLanguage";
static NSString * const kMirrorPreferredDarkModeKey = @"MirrorUserPreferredDarkMode";
static NSString * const kMirrorPreferredGridChartModeKey = @"MirrorUserPreferredGridChartMode";
static NSString * const kMirrorPreferredPiechartRecordKey = @"MirrorUserPreferredPiechartRecord";
static NSString * const kMirrorPreferredChartRangeKey = @"MirrorUserPreferredChartRange";
static NSString * const kMirrorAppGroupIdentifier = @"group.com.yuqingwang.dev.Mirror";

@implementation MirrorSettings

+ (BOOL)appliedDarkMode
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kMirrorPreferredDarkModeKey];
}

+ (void)switchTheme
{
    BOOL darkMode = ![[NSUserDefaults standardUserDefaults] boolForKey:kMirrorPreferredDarkModeKey];
    [[NSUserDefaults standardUserDefaults] setBool:darkMode forKey:kMirrorPreferredDarkModeKey];
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:kMirrorAppGroupIdentifier];
    [sharedDefaults setBool:darkMode forKey:kMirrorPreferredDarkModeKey];
    [sharedDefaults synchronize];

    Class reloadManager = NSClassFromString(@"MirrorWidgetReloadManager");
    SEL selector = @selector(reloadScheduleWidget);
    if (reloadManager && [reloadManager respondsToSelector:selector]) {
        IMP imp = [reloadManager methodForSelector:selector];
        void (*func)(id, SEL) = (void *)imp;
        func(reloadManager, selector);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchThemeNotification object:nil];
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

+ (MirrorGridChartMode)appliedGridChartMode
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id chartMode = [defaults objectForKey:kMirrorPreferredGridChartModeKey];
    if ([chartMode respondsToSelector:@selector(integerValue)]) {
        NSInteger value = [chartMode integerValue];
        if (value >= 0 && value <= 3) {
            return (MirrorGridChartMode)value;
        }
    }
    return (MirrorGridChartMode)0;
}

+ (void)switchGridChartMode
{
    NSInteger chartMode = [self appliedGridChartMode];
    MirrorGridChartMode nextChartMode = (MirrorGridChartMode)((chartMode + 1) % 4);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:nextChartMode forKey:kMirrorPreferredGridChartModeKey];
    [defaults setBool:nextChartMode == MirrorGridChartModePieChart forKey:kMirrorPreferredPiechartRecordKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchChartTypeRecordNotification object:nil];
}

+ (NSArray<NSString *> *)chartRangeTitles
{
    return @[@"1W", @"1M", @"3M", @"6M", @"YTD", @"1Y", @"ALL"];
}

+ (MirrorChartRange)appliedChartRange
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id chartRange = [defaults objectForKey:kMirrorPreferredChartRangeKey];
    if ([chartRange respondsToSelector:@selector(integerValue)]) {
        NSInteger value = [chartRange integerValue];
        if (value >= MirrorChartRangeOneWeek && value <= MirrorChartRangeAll) {
            return (MirrorChartRange)value;
        }
    }
    return MirrorChartRangeOneWeek;
}

+ (void)saveChartRange:(MirrorChartRange)chartRange
{
    if (chartRange < MirrorChartRangeOneWeek || chartRange > MirrorChartRangeAll) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:chartRange forKey:kMirrorPreferredChartRangeKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSwitchChartRangeNotification object:nil];
}

+ (BOOL)appliedPieChartRecord
{
    return [self appliedGridChartMode] == MirrorGridChartModePieChart;
}

+ (void)switchChartTypeRecord
{
    [self switchGridChartMode];
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
