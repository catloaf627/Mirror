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
