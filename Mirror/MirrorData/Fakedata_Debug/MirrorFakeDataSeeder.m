//
//  MirrorFakeDataSeeder.m
//  Mirror
//

#import "MirrorFakeDataSeeder.h"
#import "MirrorTaskModel.h"
#import "MirrorRecordModel.h"
#import "MirrorDayModel.h"
#import "MirrorStorage.h"
#import "UIColor+MirrorColor.h"
#import "MirrorMacro.h"

@interface MirrorFakeTaskPlan : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) MirrorColorType color;
@property (nonatomic, assign) NSInteger createdHour;
@property (nonatomic, assign) NSInteger createdMinute;

- (instancetype)initWithName:(NSString *)name color:(MirrorColorType)color createdHour:(NSInteger)createdHour createdMinute:(NSInteger)createdMinute;

@end

@implementation MirrorFakeTaskPlan

- (instancetype)initWithName:(NSString *)name color:(MirrorColorType)color createdHour:(NSInteger)createdHour createdMinute:(NSInteger)createdMinute
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _color = color;
        _createdHour = createdHour;
        _createdMinute = createdMinute;
    }
    return self;
}

@end

@interface MirrorFakeSpecialDayPlan : NSObject

@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, copy) NSString *info;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, assign) MirrorSystemColorType color;

- (instancetype)initWithMonth:(NSInteger)month day:(NSInteger)day info:(NSString *)info icon:(NSString *)icon color:(MirrorSystemColorType)color;

@end

@implementation MirrorFakeSpecialDayPlan

- (instancetype)initWithMonth:(NSInteger)month day:(NSInteger)day info:(NSString *)info icon:(NSString *)icon color:(MirrorSystemColorType)color
{
    self = [super init];
    if (self) {
        _month = month;
        _day = day;
        _info = [info copy];
        _icon = [icon copy];
        _color = color;
    }
    return self;
}

@end

@implementation MirrorFakeDataSeeder

+ (void)seedFakeData
{
    NSArray<MirrorFakeTaskPlan *> *plans = [self fakeTaskPlans];
    NSDate *endDate = [self startOfToday];
    NSDate *startDate = [self dateByAddingYears:-1 toDate:endDate];

    NSMutableArray<MirrorTaskModel *> *fakeTasks = [NSMutableArray new];
    for (MirrorFakeTaskPlan *plan in plans) {
        MirrorTaskModel *task = [[MirrorTaskModel alloc] initWithTitle:plan.name
                                                           createdTime:(long)[startDate timeIntervalSince1970]
                                                             colorType:plan.color
                                                              isHidden:NO
                                                             isAddTask:NO];
        [fakeTasks addObject:task];
    }

    NSMutableArray<MirrorRecordModel *> *fakeRecords = [NSMutableArray new];
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSInteger totalDays = [calendar components:NSCalendarUnitDay fromDate:startDate toDate:endDate options:0].day;
    NSInteger readingBookIndex = 0;
    NSInteger readingRemainingMinutes = [self readingBookDurationMinutesForBookIndex:readingBookIndex];
    for (NSInteger dayIndex = 0; dayIndex <= totalDays; dayIndex++) {
        NSDate *currentDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:dayIndex toDate:startDate options:0];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:currentDate];
        NSInteger monthIndex = [calendar components:NSCalendarUnitMonth fromDate:startDate toDate:currentDate options:0].month;
        [self appendRecordsForDateComponents:components dayIndex:dayIndex monthIndex:monthIndex records:fakeRecords readingBookIndex:&readingBookIndex readingRemainingMinutes:&readingRemainingMinutes];
        if (dayIndex == totalDays) {
            [self addRecordWithName:[self localizedSampleTaskNameWithEnglishName:@"Read"] components:components hour:22 minute:15 durationMinutes:45 note:[self readingNoteForBookIndex:readingBookIndex] records:fakeRecords];
            [self advanceReadingBookIndex:&readingBookIndex remainingMinutes:&readingRemainingMinutes byReadMinutes:45];
        }
    }

    [fakeRecords sortUsingComparator:^NSComparisonResult(MirrorRecordModel *first, MirrorRecordModel *second) {
        if (first.startTime < second.startTime) return NSOrderedAscending;
        if (first.startTime > second.startTime) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    NSMutableArray<MirrorDayModel *> *fakeDays = [self fakeSpecialDaysFromStartDate:startDate endDate:endDate];

    [self saveTasks:fakeTasks records:fakeRecords days:fakeDays];
    NSLog(@"Seeded fake Mirror data: %lu tasks, %lu records, %lu days", (unsigned long)plans.count, (unsigned long)fakeRecords.count, (unsigned long)fakeDays.count);
}

+ (NSArray<MirrorFakeTaskPlan *> *)fakeTaskPlans
{
    return @[
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Gym"] color:MirrorColorTypeCellBlue createdHour:7 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Tennis"] color:MirrorColorTypeCellGreen createdHour:18 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Swim"] color:MirrorColorTypeCellTeal createdHour:17 createdMinute:45],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Code"] color:MirrorColorTypeCellYellow createdHour:9 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Cook"] color:MirrorColorTypeCellPurple createdHour:18 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Read"] color:MirrorColorTypeCellPink createdHour:21 createdMinute:30]
    ];
}

// 每天的 fake record 生成规则：
// 1. 每月 2 号到随机的 3/4/5 号视为生理期，不生成运动和编程。
// 2. 非生理期每天早上生成一条运动：偶数 dayIndex 健身；非健身日夏天游泳、冬天网球，其他季节游泳/网球按概率切换。
// 3. 运动时间在 7 点左右，周末有概率推迟到 8/9 点，运动时长 1.5 到 2 小时。
// 4. 编程从运动结束后 1 到 2 小时开始，时长 1 到 6 小时，偶尔偷懒跳过。
// 5. 做饭基本每天晚饭时间生成，18 到 19 点开始，持续 20 到 90 分钟。
// 6. 当天比较 chill 时晚上生成阅读；阅读 note 由连续书单进度决定。
+ (void)appendRecordsForDateComponents:(NSDateComponents *)components dayIndex:(NSInteger)dayIndex monthIndex:(NSInteger)monthIndex records:(NSMutableArray<MirrorRecordModel *> *)records readingBookIndex:(NSInteger *)readingBookIndex readingRemainingMinutes:(NSInteger *)readingRemainingMinutes
{
    NSInteger month = components.month;
    NSInteger day = components.day;
    NSInteger weekday = components.weekday;
    BOOL isWeekend = weekday == 1 || weekday == 7;
    BOOL isSummer = month >= 6 && month <= 8;
    BOOL isWinter = month == 12 || month <= 2;

    BOOL isPeriodDay = day >= 2 && day <= [self periodEndDayForComponents:components];
    NSInteger recordCount = 0;

    if (!isPeriodDay) {
        NSString *movementTaskName = nil;
        BOOL isGymDay = dayIndex % 2 == 0;
        if (isGymDay) {
            movementTaskName = @"Gym";
        } else if (isSummer) {
            movementTaskName = @"Swim";
        } else if (isWinter) {
            movementTaskName = @"Tennis";
        } else {
            movementTaskName = [self randomPercentForDayIndex:dayIndex salt:11] < 48 ? @"Swim" : @"Tennis";
        }

        NSInteger movementHour = 7;
        if (isWeekend && [self randomPercentForDayIndex:dayIndex salt:13] < 38) {
            movementHour = [self randomPercentForDayIndex:dayIndex salt:17] < 55 ? 8 : 9;
        }
        NSInteger movementMinute = [self randomValueForDayIndex:dayIndex salt:19 modulo:4] * 10;
        NSInteger movementDuration = 90 + [self randomValueForDayIndex:dayIndex salt:23 modulo:31];
        NSString *movementNote = nil;
        if ([movementTaskName isEqualToString:@"Gym"]) {
            movementNote = [self gymNoteForWorkoutIndex:dayIndex / 2 dayIndex:dayIndex];
        } else if ([movementTaskName isEqualToString:@"Tennis"]) {
            movementNote = [self tennisNoteForMonthIndex:monthIndex dayIndex:dayIndex];
        } else if ([movementTaskName isEqualToString:@"Swim"]) {
            movementNote = [self swimNoteForDayIndex:dayIndex];
        }
        [self addRecordWithName:[self localizedSampleTaskNameWithEnglishName:movementTaskName] components:components hour:movementHour minute:movementMinute durationMinutes:movementDuration note:movementNote records:records];
        recordCount += 1;

        NSInteger movementEndMinutes = movementHour * 60 + movementMinute + movementDuration;
        NSInteger codeStartMinutes = movementEndMinutes + 60 + [self randomValueForDayIndex:dayIndex salt:31 modulo:61];
        BOOL shouldCode = [self randomValueForDayIndex:dayIndex salt:37 modulo:7] >= 2;
        BOOL isLazyCodeDay = [self randomPercentForDayIndex:dayIndex salt:43] < 14;
        if (shouldCode && !isLazyCodeDay) {
            NSInteger codeDuration = 60 + [self randomValueForDayIndex:dayIndex salt:41 modulo:301];
            NSInteger latestCodeEnd = 17 * 60 + 45;
            codeDuration = MIN(codeDuration, MAX(60, latestCodeEnd - codeStartMinutes));
            if (codeDuration >= 60 && codeStartMinutes < 18 * 60) {
                [self addRecordWithName:[self localizedSampleTaskNameWithEnglishName:@"Code"] components:components hour:codeStartMinutes / 60 minute:codeStartMinutes % 60 durationMinutes:codeDuration note:[self codeNoteForDayIndex:dayIndex] records:records];
                recordCount += 1;
            }
        }
    }

    if ([self randomPercentForDayIndex:dayIndex salt:53] < 94) {
        NSInteger cookStart = 18 * 60 + [self randomValueForDayIndex:dayIndex salt:59 modulo:61];
        NSInteger cookDuration = 20 + [self randomValueForDayIndex:dayIndex salt:61 modulo:71];
        [self addRecordWithName:[self localizedSampleTaskNameWithEnglishName:@"Cook"] components:components hour:cookStart / 60 minute:cookStart % 60 durationMinutes:cookDuration note:[self cookNoteForDurationMinutes:cookDuration dayIndex:dayIndex] records:records];
        recordCount += 1;
    }

    BOOL isChillDay = recordCount <= 2 || [self randomPercentForDayIndex:dayIndex salt:67] < 28;
    if (isChillDay) {
        NSInteger readDuration = 25 + [self randomValueForDayIndex:dayIndex salt:71 modulo:56];
        NSInteger readStart = (isWeekend ? 20 : 21) * 60 + [self randomValueForDayIndex:dayIndex salt:73 modulo:46];
        [self addRecordWithName:[self localizedSampleTaskNameWithEnglishName:@"Read"] components:components hour:readStart / 60 minute:readStart % 60 durationMinutes:readDuration note:[self readingNoteForBookIndex:*readingBookIndex] records:records];
        [self advanceReadingBookIndex:readingBookIndex remainingMinutes:readingRemainingMinutes byReadMinutes:readDuration];
    }
}

+ (void)addRecordWithName:(NSString *)name components:(NSDateComponents *)components hour:(NSInteger)hour minute:(NSInteger)minute durationMinutes:(NSInteger)durationMinutes records:(NSMutableArray<MirrorRecordModel *> *)records
{
    [self addRecordWithName:name components:components hour:hour minute:minute durationMinutes:durationMinutes note:nil records:records];
}

+ (void)addRecordWithName:(NSString *)name components:(NSDateComponents *)components hour:(NSInteger)hour minute:(NSInteger)minute durationMinutes:(NSInteger)durationMinutes note:(NSString *)note records:(NSMutableArray<MirrorRecordModel *> *)records
{
    NSDate *dayStartDate = [self dateWithYear:components.year month:components.month day:components.day hour:0 minute:0];
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSDate *nextDayStartDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:dayStartDate options:0];
    long startTime = round([[self dateWithYear:components.year month:components.month day:components.day hour:hour minute:minute] timeIntervalSince1970]);
    long duration = durationMinutes * 60;
    long dayEnd = round([nextDayStartDate timeIntervalSince1970]);
    long endTime = startTime + duration;

    // 如果同一天已有记录重叠，就把新记录顺延到上一条记录结束后。
    BOOL didMoveRecord = YES;
    while (didMoveRecord) {
        didMoveRecord = NO;
        for (MirrorRecordModel *record in records) {
            if ([self startTime:startTime endTime:endTime overlapsRecord:record]) {
                startTime = record.endTime;
                endTime = startTime + duration;
                didMoveRecord = YES;
            }
        }
    }

    // 不生成跨天记录，也不生成未来记录。
    long now = round([[NSDate date] timeIntervalSince1970]);
    if (endTime > dayEnd || endTime >= now) {
        return;
    }

    MirrorRecordModel *record = [[MirrorRecordModel alloc] initWithTitle:name
                                                                startTime:startTime
                                                                  endTime:endTime];
    record.note = note ?: @"";
    [records addObject:record];
}

+ (NSInteger)periodEndDayForComponents:(NSDateComponents *)components
{
    NSUInteger seed = (NSUInteger)(components.year * 97 + components.month * 31);
    return 3 + (seed % 3);
}

+ (NSInteger)randomPercentForDayIndex:(NSInteger)dayIndex salt:(NSInteger)salt
{
    return [self randomValueForDayIndex:dayIndex salt:salt modulo:100];
}

+ (NSInteger)randomValueForDayIndex:(NSInteger)dayIndex salt:(NSInteger)salt modulo:(NSInteger)modulo
{
    if (modulo <= 0) {
        return 0;
    }
    NSUInteger seed = 2166136261u;
    seed = (seed ^ (NSUInteger)dayIndex) * 16777619u;
    seed = (seed ^ (NSUInteger)salt) * 16777619u;
    return (NSInteger)(seed % (NSUInteger)modulo);
}

+ (NSString *)localizedSampleTaskNameWithEnglishName:(NSString *)englishName
{
    return [self chineseSampleTaskNameWithEnglishName:englishName];
}

+ (NSString *)chineseSampleTaskNameWithEnglishName:(NSString *)englishName
{
    NSDictionary<NSString *, NSString *> *taskNames = @{
        @"Gym": @"健身",
        @"Tennis": @"网球",
        @"Code": @"编程",
        @"Swim": @"游泳",
        @"Read": @"阅读",
        @"Cook": @"做饭"
    };
    return taskNames[englishName] ?: englishName;
}

+ (NSArray<MirrorFakeSpecialDayPlan *> *)fakeSpecialDayPlans
{
    return @[
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:1 day:8 info:@"提车啦" icon:@"car.fill" color:MirrorSystemColorTypeGreen],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:2 day:7 info:@"毕业啦" icon:@"graduationcap.fill" color:MirrorSystemColorTypeBlue],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:3 day:22 info:@"找到工作" icon:@"briefcase.fill" color:MirrorSystemColorTypeMint],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:4 day:17 info:@"接猫回家" icon:@"cat.fill" color:MirrorSystemColorTypePurple],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:5 day:15 info:@"会游蝶泳了" icon:@"figure.pool.swim" color:MirrorSystemColorTypeOrange],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:6 day:27 info:@"我的生日" icon:@"birthday.cake.fill" color:MirrorSystemColorTypeYellow],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:7 day:19 info:@"看世界杯" icon:@"soccerball" color:MirrorSystemColorTypeMint],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:8 day:19 info:@"搬新家" icon:@"chandelier.fill" color:MirrorSystemColorTypeGreen],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:9 day:13 info:@"练出腹肌！" icon:@"dumbbell.fill" color:MirrorSystemColorTypeOrange],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:10 day:28 info:@"网球比赛3.0冠军" icon:@"medal.fill" color:MirrorSystemColorTypePurple],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:11 day:11 info:@"婚礼" icon:@"heart.fill" color:MirrorSystemColorTypeRed],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:12 day:12 info:@"创建了自己的网站" icon:@"globe" color:MirrorSystemColorTypeOrange]
    ];
}

+ (NSMutableArray<MirrorDayModel *> *)fakeSpecialDaysFromStartDate:(NSDate *)startDate endDate:(NSDate *)endDate
{
    NSMutableArray<MirrorDayModel *> *days = [NSMutableArray new];
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSDateComponents *startComponents = [calendar components:NSCalendarUnitYear fromDate:startDate];
    NSDateComponents *endComponents = [calendar components:NSCalendarUnitYear fromDate:endDate];
    NSString *todayKey = [self dateKeyFromDate:endDate];
    
    for (NSInteger year = startComponents.year; year <= endComponents.year; year++) {
        for (MirrorFakeSpecialDayPlan *plan in [self fakeSpecialDayPlans]) {
            NSDate *date = [self dateWithYear:year month:plan.month day:plan.day hour:0 minute:0];
            if (!date || [date compare:startDate] == NSOrderedAscending || [date compare:endDate] == NSOrderedDescending) {
                continue;
            }
            
            NSString *dateKey = [self dateKeyFromDate:date];
            if ([dateKey isEqualToString:todayKey]) {
                continue;
            }
            
            MirrorDayModel *day = [[MirrorDayModel alloc] initWithDateStr:dateKey
                                                                      info:plan.info
                                                                      icon:plan.icon
                                                                     color:plan.color];
            [days addObject:day];
        }
    }
    
    MirrorDayModel *today = [[MirrorDayModel alloc] initWithDateStr:todayKey
                                                               info:@"下载了 Mirror.ly"
                                                               icon:@"m.circle.fill"
                                                              color:MirrorSystemColorTypeGray];
    [days addObject:today];
    
    [days sortUsingComparator:^NSComparisonResult(MirrorDayModel *first, MirrorDayModel *second) {
        return [first.dateStr compare:second.dateStr];
    }];
    return days;
}

+ (NSString *)gymNoteForWorkoutIndex:(NSInteger)workoutIndex dayIndex:(NSInteger)dayIndex
{
    // 健身每次都有 note，按练背日、练腿日、练肩日循环；小概率追加状态很好/状态不好。
    NSArray<NSString *> *workoutNotes = @[
        @"练背日",
        @"练腿日",
        @"练肩日"
    ];
    NSString *note = workoutNotes[workoutIndex % workoutNotes.count];
    NSInteger statusRoll = [self randomPercentForDayIndex:dayIndex salt:83];
    if (statusRoll < 15) {
        return [note stringByAppendingString:@" · 状态很好"];
    }
    if (statusRoll < 30) {
        return [note stringByAppendingString:@" · 状态不好"];
    }
    return note;
}

+ (NSString *)tennisNoteForMonthIndex:(NSInteger)monthIndex dayIndex:(NSInteger)dayIndex
{
    // 网球 1/3 概率生成 note，内容按生成数据开始后的月份推进；有 note 时小概率追加状态很好/状态不好。
    if ([self randomValueForDayIndex:dayIndex salt:89 modulo:3] != 0) {
        return nil;
    }

    NSArray<NSString *> *progressNotes = @[
        @"练习正反手",
        @"脚步和分腿垫步",
        @"发球抛球和节奏",
        @"斜线对拉",
        @"反手切削",
        @"网前截击",
        @"随球上网",
        @"二发上旋",
        @"直线变线",
        @"高压和挑高球",
        @"接发球",
        @"得分套路",
        @"实战局"
    ];
    NSString *note = progressNotes[monthIndex % progressNotes.count];
    NSInteger statusRoll = [self randomPercentForDayIndex:dayIndex salt:97];
    if (statusRoll < 15) {
        return [note stringByAppendingString:@" · 状态很好"];
    }
    if (statusRoll < 30) {
        return [note stringByAppendingString:@" · 状态不好"];
    }
    return note;
}

+ (NSString *)codeNoteForDayIndex:(NSInteger)dayIndex
{
    // 编程每次都有 note，从 10 种算法类型里按日期随机选择。
    NSArray<NSString *> *notes = @[
        @"二叉树",
        @"动态规划",
        @"图搜索",
        @"回溯",
        @"滑动窗口",
        @"双指针",
        @"堆和优先队列",
        @"贪心算法",
        @"前缀和",
        @"并查集"
    ];
    NSInteger noteIndex = [self randomValueForDayIndex:dayIndex salt:107 modulo:997] % notes.count;
    return notes[noteIndex];
}

+ (NSString *)cookNoteForDurationMinutes:(NSInteger)durationMinutes dayIndex:(NSInteger)dayIndex
{
    // 做饭每次都有 note，根据做饭时长分成快手菜、正常晚饭、复杂菜三档，再从对应菜名里随机选择。
    // 不是直接翻译，而是文化对应
    NSArray<NSString *> *quickNotes = @[
        @"番茄炒蛋",
        @"蒜香虾仁意面",
        @"味噌三文鱼饭"
    ];
    NSArray<NSString *> *regularNotes = @[
        @"咖喱鸡",
        @"红烧排骨",
        @"麻婆豆腐",
        @"牛肉面"
    ];
    NSArray<NSString *> *slowNotes = @[
        @"宫保虾球",
        @"香草烤鸡",
        @"海鲜烩饭"
    ];

    NSArray<NSString *> *notes = quickNotes;
    NSInteger salt = 109;
    if (durationMinutes >= 70) {
        notes = slowNotes;
        salt = 113;
    } else if (durationMinutes >= 45) {
        notes = regularNotes;
        salt = 111;
    }

    NSInteger noteIndex = [self randomValueForDayIndex:dayIndex salt:salt modulo:997] % notes.count;
    return notes[noteIndex];
}

+ (NSArray<NSDictionary<NSString *, id> *> *)readingBookPlans
{
    // 阅读书单按顺序推进；每本书配置一个预计读完所需总分钟数。
    return @[
        @{@"title": @"安娜卡列尼娜", @"minutes": @(40 * 60)},
        @{@"title": @"战争与和平", @"minutes": @(55 * 60)},
        @{@"title": @"悲惨世界", @"minutes": @(48 * 60)},
        @{@"title": @"卡拉马佐夫兄弟", @"minutes": @(34 * 60)},
        @{@"title": @"百年孤独", @"minutes": @(18 * 60)},
        @{@"title": @"傲慢与偏见", @"minutes": @(12 * 60)},
        @{@"title": @"罪与罚", @"minutes": @(22 * 60)},
        @{@"title": @"堂吉诃德", @"minutes": @(45 * 60)},
        @{@"title": @"基督山伯爵", @"minutes": @(42 * 60)},
        @{@"title": @"包法利夫人", @"minutes": @(10 * 60)}
    ];
}

+ (NSString *)readingNoteForBookIndex:(NSInteger)bookIndex
{
    // 阅读 note 只显示当前正在读的书名。
    NSArray<NSDictionary<NSString *, id> *> *books = [self readingBookPlans];
    NSDictionary<NSString *, id> *book = books[bookIndex % books.count];
    return book[@"title"];
}

+ (NSInteger)readingBookDurationMinutesForBookIndex:(NSInteger)bookIndex
{
    NSArray<NSDictionary<NSString *, id> *> *books = [self readingBookPlans];
    NSDictionary<NSString *, id> *book = books[bookIndex % books.count];
    return [book[@"minutes"] integerValue];
}

+ (void)advanceReadingBookIndex:(NSInteger *)bookIndex remainingMinutes:(NSInteger *)remainingMinutes byReadMinutes:(NSInteger)readMinutes
{
    // 每条阅读记录扣掉本次阅读分钟数；当前书读完后切到下一本，10 本读完后回到第一本。
    if (bookIndex == NULL || remainingMinutes == NULL || readMinutes <= 0) {
        return;
    }

    *remainingMinutes -= readMinutes;
    NSInteger bookCount = [self readingBookPlans].count;
    while (*remainingMinutes <= 0) {
        *bookIndex = (*bookIndex + 1) % bookCount;
        *remainingMinutes += [self readingBookDurationMinutesForBookIndex:*bookIndex];
    }
}

+ (NSString *)swimNoteForDayIndex:(NSInteger)dayIndex
{
    // 游泳 1/3 概率生成 note，在自由泳 1000 米和蝶泳之间随机选择。
    if ([self randomValueForDayIndex:dayIndex salt:101 modulo:3] != 0) {
        return nil;
    }

    NSArray<NSString *> *notes = @[
        @"自由泳1000米",
        @"蝶泳"
    ];
    NSInteger noteIndex = [self randomValueForDayIndex:dayIndex salt:103 modulo:97] % notes.count;
    return notes[noteIndex];
}

+ (BOOL)startTime:(long)startTime endTime:(long)endTime overlapsRecord:(MirrorRecordModel *)record
{
    return startTime < record.endTime && endTime > record.startTime;
}

+ (NSDate *)startOfToday
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    return [calendar startOfDayForDate:[NSDate date]];
}

+ (NSDate *)dateByAddingYears:(NSInteger)years toDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    return [calendar dateByAddingUnit:NSCalendarUnitYear value:years toDate:date options:0];
}

+ (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day hour:(NSInteger)hour minute:(NSInteger)minute
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];

    NSDateComponents *components = [NSDateComponents new];
    components.calendar = calendar;
    components.timeZone = calendar.timeZone;
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = hour;
    components.minute = minute;
    components.second = 0;
    return [calendar dateFromComponents:components];
}

+ (NSString *)dateKeyFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:date];
}

+ (void)saveTasks:(NSMutableArray<MirrorTaskModel *> *)tasks records:(NSMutableArray<MirrorRecordModel *> *)records days:(NSMutableArray<MirrorDayModel *> *)days
{
    [MirrorStorage replaceAllDataWithTasks:tasks records:records days:days secondsFromGMT:@([NSTimeZone systemTimeZone].secondsFromGMT)];
}

@end
