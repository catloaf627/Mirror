//
//  MirrorTimeText.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorTimeText : NSObject

// 此时此刻的精准时间字符串（export用）
+ (NSString *)getPreciseTimeString;

// 584 hours | 584 小时 —> 主页面cell上的标记
+ (NSString *)Xh:(long)timeInterval;

// 1h 23m | 1时23分 —> lasted后面的标记
+ (NSString *)XdXhXmXsShortWithstart:(long)start end:(long)end;

// 1h 23m | 1时23分 —> 柱状图上的标记
+ (NSString *)XdXhXmXsShort:(long)timeInterval;

// 1hour 23 mins | 16天1小时23分钟 —> total后面的标记
+ (NSString *)XdXhXmXsFull:(long)timeInterval;

// Thu, Apr 25, 2023 | 2023年4月23日 周日 -> 所有历史记录的日期标记
+ (NSString *)YYYYmmddWeekdayWithStart:(long)start;

// Thu, Apr 25, 2023 | 2023年4月23日 周日 -> 柱状图区间切换的标记（一天）、Today下方的日期标记
+ (NSString *)YYYYmmddWeekday:(NSDate *)date;

// Apr 25, 2023 | 2023年4月23日 -> 柱状图区间切换的标记（区间）
+ (NSString *)YYYYmmdd:(NSDate *)date;

// Apr 2023 | 2023年4月 -> 格子图标记
+ (NSString *)YYYYmm:(NSDate *)date;




@end

NS_ASSUME_NONNULL_END
