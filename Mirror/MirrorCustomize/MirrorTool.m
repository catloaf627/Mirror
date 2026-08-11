//
//  MirrorTool.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/5.
//

#import "MirrorTool.h"
#import "MirrorLanguage.h"
#import "MirrorSettings.h"

@implementation MirrorTool

// Formats a date for debug-style display; for example 2026.6.27,Sat,9:30:0 or 2026.6.27,Sat,9:30:0，(1782552600).
+ (NSString *)timeFromDate:(NSDate *)date printTimeStamp:(BOOL)printTimeStamp
{
    // setup
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:date];
    components.timeZone = [NSTimeZone systemTimeZone];
    // details
    long year = (long)components.year;
    long month = (long)components.month;
    long week = (long)components.weekday;
    long day = (long)components.day;
    long hour = (long)components.hour;
    long minute = (long)components.minute;
    long second = (long)components.second;
    // print
    NSString *weekday = @"unknow";
    if (week == 1) weekday = @"Sun";
    if (week == 2) weekday = @"Mon";
    if (week == 3) weekday = @"Tue";
    if (week == 4) weekday = @"Wed";
    if (week == 5) weekday = @"Thu";
    if (week == 6) weekday = @"Fri";
    if (week == 7) weekday = @"Sat";
    if (printTimeStamp) {
        return [NSString stringWithFormat: @"%ld.%ld.%ld,%@,%ld:%ld:%ld，(%ld)", year, month, day, weekday, hour, minute, second, (long)[date timeIntervalSince1970]];
    } else {
        return [NSString stringWithFormat: @"%ld.%ld.%ld,%@,%ld:%ld:%ld", year, month, day, weekday, hour, minute, second];
    }
}

// Formats a Unix timestamp for debug-style display; for example 2026.6.27,Sat,9:30:0 or 2026.6.27,Sat,9:30:0，(1782552600).
+ (NSString *)timeFromTimestamp:(long)timestamp printTimeStamp:(BOOL)printTimeStamp
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    // setup
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:date];
    components.timeZone = [NSTimeZone systemTimeZone];
    // details
    long year = (long)components.year;
    long month = (long)components.month;
    long week = (long)components.weekday;
    long day = (long)components.day;
    long hour = (long)components.hour;
    long minute = (long)components.minute;
    long second = (long)components.second;
    // print
    NSString *weekday = @"unknow";
    if (week == 1) weekday = @"Sun";
    if (week == 2) weekday = @"Mon";
    if (week == 3) weekday = @"Tue";
    if (week == 4) weekday = @"Wed";
    if (week == 5) weekday = @"Thu";
    if (week == 6) weekday = @"Fri";
    if (week == 7) weekday = @"Sat";
    if (printTimeStamp) {
        return [NSString stringWithFormat: @"%ld.%ld.%ld,%@,%ld:%ld:%ld，(%ld)", year, month, day, weekday, hour, minute, second, (long)[date timeIntervalSince1970]];
    } else {
        return [NSString stringWithFormat: @"%ld.%ld.%ld,%@,%ld:%ld:%ld", year, month, day, weekday, hour, minute, second];
    }
}

// Formats the timeline left-side month/day; for example Jun 27.
+ (NSString *)timelineMonthDayTextForTimestamp:(long)timestamp
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.timeZone = [NSTimeZone systemTimeZone];
    formatter.locale = [MirrorTool formatterLocaleForCurrentLanguage];
    [formatter setLocalizedDateFormatFromTemplate:@"MMM d"];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

// Formats the timeline left-side year; for example 2026.
+ (NSString *)timelineYearTextForTimestamp:(long)timestamp
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.timeZone = [NSTimeZone systemTimeZone];
    formatter.locale = [MirrorTool formatterLocaleForCurrentLanguage];
    [formatter setLocalizedDateFormatFromTemplate:@"yyyy"];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

// Returns the locale used by app date formatters; for example en, zh-Hans, es, fr, ja, or ko.
+ (NSLocale *)formatterLocaleForCurrentLanguage
{
    NSString *localeIdentifier = [MirrorLanguage mirror_stringWithKey:@"locale_Identifier"];
    if (localeIdentifier.length == 0) {
        localeIdentifier = @"en";
    }
    return [NSLocale localeWithLocaleIdentifier:localeIdentifier];
}

// Returns today's offset from the configured week start; for example Wednesday returns 2 when weeks start Monday.
+ (long)getDayGapFromTheFirstDayThisWeek
{
    BOOL weekStartsOnMonday = [MirrorSettings appliedWeekStarsOnMonday];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
    components.timeZone = [NSTimeZone systemTimeZone];
    switch (components.weekday) {
        case 1:
            return weekStartsOnMonday ? 6:0;
        case 2:
            return weekStartsOnMonday ? 0:1;
        case 3:
            return weekStartsOnMonday ? 1:2;
        case 4:
            return weekStartsOnMonday ? 2:3;
        case 5:
            return weekStartsOnMonday ? 3:4;
        case 6:
            return weekStartsOnMonday ? 4:5;
        case 7:
            return weekStartsOnMonday ? 5:6;
        default:
            return components.weekday - 1; // 出错
    }
}

// Sums completed period durations in seconds; for example 09:30-10:30 plus 11:00-11:30 returns 5400.
+ (long)getTotalTimeOfPeriods:(NSMutableArray<MirrorRecordModel *> *)periods
{
    long seconds = 0;
    for (int i=0; i<periods.count; i++) {
        MirrorRecordModel *period = periods[i];
        if (period.endTime != 0) {
            seconds = seconds + (period.endTime - period.startTime);
        }
    }
    return seconds;
}

@end
