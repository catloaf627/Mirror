//
//  MirrorSettings.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/10.
//

#import <Foundation/Foundation.h>
#import "MirrorMacro.h"
#import "MirrorLanguage.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MirrorGridChartMode) {
    MirrorGridChartModeBubbles = 0,
    MirrorGridChartModeProgressList = 1,
    MirrorGridChartModePieChart = 2,
    MirrorGridChartModeLineChart = 3,
};

typedef NS_ENUM(NSInteger, MirrorChartRange) {
    MirrorChartRangeOneWeek = 0,
    MirrorChartRangeOneMonth,
    MirrorChartRangeThreeMonths,
    MirrorChartRangeSixMonths,
    MirrorChartRangeYearToDate,
    MirrorChartRangeOneYear,
    MirrorChartRangeAll
};

@interface MirrorSettings : NSObject

// Theme
+ (BOOL)appliedDarkMode;
+ (void)switchTheme;

// Language
+ (BOOL)hasPreferredLanguage;
+ (MirrorLanguageKey)preferredLanguageKey;
+ (void)changeLanguageWithKey:(MirrorLanguageKey)languageKey;

// Week starts on
+ (BOOL)appliedWeekStarsOnMonday;
+ (void)switchWeekStartsOn;

// Grid chart mode
+ (MirrorGridChartMode)appliedGridChartMode;
+ (void)switchGridChartMode;
+ (NSArray<NSString *> *)chartRangeTitles;
+ (MirrorChartRange)appliedChartRange;
+ (void)saveChartRange:(MirrorChartRange)chartRange;

// Pie chart
+ (BOOL)appliedPieChartRecord;
+ (void)switchChartTypeRecord;

// 按照时间长短更新颜色深浅(heatmap)
+ (BOOL)appliedHeatmap;
+ (void)switchHeatmap;
+ (NSInteger)preferredHeatmapColor;

// 座右铭
+ (NSString *)userMotto;
+ (void)saveUserMotto:(NSString *)motto;

@end

NS_ASSUME_NONNULL_END
