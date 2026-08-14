//
//  MirrorTool.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/5.
//

#import <Foundation/Foundation.h>
#import "MirrorRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MirrorTool : NSObject

+ (NSString *)timeFromDate:(NSDate *)date printTimeStamp:(BOOL)printTimeStamp;
+ (NSString *)timeFromTimestamp:(long)timestamp printTimeStamp:(BOOL)printTimeStamp;
+ (NSString *)timelineMonthDayTextForTimestamp:(long)timestamp;
+ (NSString *)timelineYearTextForTimestamp:(long)timestamp;
+ (NSLocale *)formatterLocaleForCurrentLanguage;
+ (long)getDayGapFromTheFirstDayThisWeek; // 本日0点与本周0点的天数差距（取决于本周的开始是算周一，还是算周日）
+ (long)getTotalTimeOfPeriods:(NSMutableArray<MirrorRecordModel *> *)periods;

@end

NS_ASSUME_NONNULL_END
