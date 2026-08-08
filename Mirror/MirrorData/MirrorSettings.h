//
//  MirrorSettings.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/10.
//

#import <Foundation/Foundation.h>
#import "MirrorMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface MirrorSettings : NSObject

// Theme
+ (BOOL)appliedDarkMode;
+ (void)switchTheme;

// Language
+ (BOOL)appliedChinese;
+ (void)switchLanguage;
+ (NSInteger)preferredLanguageKey;
+ (void)changeLanguageWithKey:(NSInteger)languageKey;

// Week starts on
+ (BOOL)appliedWeekStarsOnMonday;
+ (void)switchWeekStartsOn;

// Show or hide original index
+ (BOOL)appliedShowIndex;
+ (void)switchShowIndex;

// Pie chart
+ (BOOL)appliedHistogramData;
+ (void)switchChartTypeData;
+ (BOOL)appliedPieChartRecord;
+ (void)switchChartTypeRecord;

// 按照时间长短更新颜色深浅(heatmap)
+ (BOOL)appliedHeatmap;
+ (void)switchHeatmap;
+ (NSInteger)preferredHeatmapColor;

// 座右铭
+ (NSString *)userMotto;
+ (void)saveUserMotto:(NSString *)motto;

// Span type: Day, week, month, year
+ (SpanType)spanType;
+ (void)changeSpanType:(SpanType)spanType;

@end

NS_ASSUME_NONNULL_END
