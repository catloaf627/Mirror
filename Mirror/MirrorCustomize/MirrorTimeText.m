//
//  MirrorTimeText.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/25.
//

#import "MirrorTimeText.h"
#import "MirrorLanguage.h"

@implementation MirrorTimeText

+ (NSString *)getPreciseTimeString
{
    NSDate *now = [NSDate now];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:now];
    components.timeZone = [NSTimeZone systemTimeZone];
    NSString *timeString = @"";
    timeString = [[timeString stringByAppendingString:[@(components.year) stringValue]] stringByAppendingString:@"-"];
    timeString = [[timeString stringByAppendingString:[@(components.month) stringValue]] stringByAppendingString:@"-"];
    timeString = [[timeString stringByAppendingString:[@(components.day) stringValue]] stringByAppendingString:@"-"];
    timeString = [[timeString stringByAppendingString:[@(components.hour) stringValue]] stringByAppendingString:@"-"];
    timeString = [[timeString stringByAppendingString:[@(components.minute) stringValue]] stringByAppendingString:@"-"];
    timeString = [timeString stringByAppendingString:[@(components.second) stringValue]];
    return timeString;
}

+ (NSString *)Xh:(long)timeInterval
{
    NSInteger numOfHours = timeInterval / 3600;
    if (numOfHours > 0) {
        if (numOfHours == 1) {
            return [MirrorLanguage mirror_stringWithKey:@"hour" with1Placeholder:[@(numOfHours) stringValue]];
        } else {
            return [MirrorLanguage mirror_stringWithKey:@"hours" with1Placeholder:[@(numOfHours) stringValue]];
        }
    } else {
        return @"";
    }
}

// 1h 23m | 1时23分 —> lasted后面的标记
+ (NSString *)XdXhXmXsShortWithstart:(long)start end:(long)end
{
    long timeInterval = end - start;
    NSInteger numOfHours = timeInterval / 3600;
    NSInteger numOfMins = (timeInterval % 3600) / 60;
    NSInteger numOfSeconds = (timeInterval % 3600) % 60;
    NSString *res = @"";
    if (numOfHours > 0) {
        NSString *str = [MirrorLanguage mirror_stringWithKey:@"h" with1Placeholder:[@(numOfHours) stringValue]];
        res = [res stringByAppendingString:str];
    }
    if (numOfMins > 0) {
        NSString *str = [MirrorLanguage mirror_stringWithKey:@"m" with1Placeholder:[@(numOfMins) stringValue]];
        res = [res stringByAppendingString:str];
    }
    if (numOfSeconds > 0) {
        NSString *str = [MirrorLanguage mirror_stringWithKey:@"s" with1Placeholder:[@(numOfSeconds) stringValue]];
        res = [res stringByAppendingString:str];
    }
    return res;
}

// 1h 23m | 1时23分 —> 柱状图上的标记
+ (NSString *)XdXhXmXsShort:(long)timeInterval
{
    NSInteger numOfHours = timeInterval / 3600;
    NSInteger numOfMins = (timeInterval % 3600) / 60;
    NSInteger numOfSeconds = (timeInterval % 3600) % 60;
    NSString *res = @"";
    if (numOfHours > 0) {
        NSString *str = [MirrorLanguage mirror_stringWithKey:@"h" with1Placeholder:[@(numOfHours) stringValue]];
        res = [res stringByAppendingString:str];
    }
    if (numOfMins > 0) {
        NSString *str = [MirrorLanguage mirror_stringWithKey:@"m" with1Placeholder:[@(numOfMins) stringValue]];
        res = [res stringByAppendingString:str];
    }
    if (numOfSeconds > 0) {
        NSString *str = [MirrorLanguage mirror_stringWithKey:@"s" with1Placeholder:[@(numOfSeconds) stringValue]];
        res = [res stringByAppendingString:str];
    }
    return res;
}

// 1hour 23 mins | 1小时23分钟 —> total后面的标记
+ (NSString *)XdXhXmXsFull:(long)timeInterval
{
    NSInteger numOfHours = timeInterval / 3600;
    NSInteger numOfMins = (timeInterval % 3600) / 60;
    NSInteger numOfSeconds = (timeInterval % 3600) % 60;
    NSString *res = @"";
    if (numOfHours > 0) {
        NSString *str = @"";
        if (numOfHours == 1) {
            str = [MirrorLanguage mirror_stringWithKey:@"hour" with1Placeholder:[@(numOfHours) stringValue]];
        } else {
            str = [MirrorLanguage mirror_stringWithKey:@"hours" with1Placeholder:[@(numOfHours) stringValue]];
        }
        res = [res stringByAppendingString:str];
    }
    if (numOfMins > 0) {
        NSString *str = @"";
        if (numOfMins == 1) {
            str = [MirrorLanguage mirror_stringWithKey:@"min" with1Placeholder:[@(numOfMins) stringValue]];
        } else {
            str = [MirrorLanguage mirror_stringWithKey:@"mins" with1Placeholder:[@(numOfMins) stringValue]];
        }
        res = [res stringByAppendingString:str];
    }
    if (numOfSeconds > 0) {
        NSString *str = @"";
        if (numOfMins == 1) {
            str = [MirrorLanguage mirror_stringWithKey:@"second" with1Placeholder:[@(numOfSeconds) stringValue]];
        } else {
            str = [MirrorLanguage mirror_stringWithKey:@"seconds" with1Placeholder:[@(numOfSeconds) stringValue]];
        }
        res = [res stringByAppendingString:str];
    }
    return res;
}

// Thu, Apr 25, 2023 | 2023年4月23日 周日 -> 所有历史记录的日期标记
+ (NSString *)YYYYmmddWeekdayWithStart:(long)start
{
    // setup
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday) fromDate:[NSDate dateWithTimeIntervalSince1970:start]];
    components.timeZone = [NSTimeZone systemTimeZone];
    // details
    long year = (long)components.year;
    long month = (long)components.month;
    long day = (long)components.day;
    long week = (long)components.weekday;
    
    return [MirrorLanguage mirror_dateStringWithYear:year month:month day:day weekday:week];
}

// Thu, Apr 25, 2023 | 2023年4月23日 周日 -> 柱状图区间切换的标记（一天）、Today下方的日期标记
+ (NSString *)YYYYmmddWeekday:(NSDate *)date
{
    // setup
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday) fromDate:date];
    components.timeZone = [NSTimeZone systemTimeZone];
    // details
    long year = (long)components.year;
    long month = (long)components.month;
    long day = (long)components.day;
    long week = (long)components.weekday;
    
    return [MirrorLanguage mirror_dateStringWithYear:year month:month day:day weekday:week];
}

// Apr 25, 2023 | 2023年4月23日 -> 柱状图区间切换的标记（区间）
+ (NSString *)YYYYmmdd:(NSDate *)date
{
    // setup
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    components.timeZone = [NSTimeZone systemTimeZone];
    // details
    long year = (long)components.year;
    long month = (long)components.month;
    long day = (long)components.day;
    
    return [MirrorLanguage mirror_dateStringWithYear:year month:month day:day];
}

// Apr 2023 | 2023年4月 -> 格子图标记
+ (NSString *)YYYYmm:(NSDate *)date
{
    // setup
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    components.timeZone = [NSTimeZone systemTimeZone];
    // details
    long year = (long)components.year;
    long month = (long)components.month;
    
    return [MirrorLanguage mirror_monthStringWithYear:year month:month];
}



@end
