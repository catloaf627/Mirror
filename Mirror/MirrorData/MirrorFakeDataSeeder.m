//
//  MirrorFakeDataSeeder.m
//  Mirror
//

#import "MirrorFakeDataSeeder.h"
#import "MirrorTaskModel.h"
#import "MirrorRecordModel.h"
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

@implementation MirrorFakeDataSeeder

static NSInteger const kFakeDataStartYear = 2026;
static NSInteger const kFakeDataStartMonth = 1;
static NSInteger const kFakeDataStartDay = 1;
static NSInteger const kFakeDataEndYear = 2026;
static NSInteger const kFakeDataEndMonth = 8;
static NSInteger const kFakeDataEndDay = 9;

+ (void)seedFakeData
{
    NSArray<MirrorFakeTaskPlan *> *plans = [self fakeTaskPlans];
    NSSet<NSString *> *fakeTaskNames = [NSSet setWithArray:[plans valueForKey:@"name"]];

    NSMutableArray<MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    NSMutableArray<MirrorTaskModel *> *filteredTasks = [NSMutableArray new];
    for (MirrorTaskModel *task in tasks) {
        if (![fakeTaskNames containsObject:task.taskName]) {
            [filteredTasks addObject:task];
        }
    }

    NSDate *startDate = [self dateWithYear:kFakeDataStartYear month:kFakeDataStartMonth day:kFakeDataStartDay hour:0 minute:0];

    for (MirrorFakeTaskPlan *plan in plans) {
        MirrorTaskModel *task = [[MirrorTaskModel alloc] initWithTitle:plan.name
                                                           createdTime:(long)[startDate timeIntervalSince1970]
                                                             colorType:plan.color
                                                            isArchived:NO
                                                              isHidden:NO
                                                             isAddTask:NO];
        [filteredTasks addObject:task];
    }

    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    NSMutableArray<MirrorRecordModel *> *filteredRecords = [NSMutableArray new];
    for (MirrorRecordModel *record in records) {
        if (![fakeTaskNames containsObject:record.taskName]) {
            [filteredRecords addObject:record];
        }
    }

    NSMutableArray<MirrorRecordModel *> *fakeRecords = [NSMutableArray new];
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSDate *endDate = [self dateWithYear:kFakeDataEndYear month:kFakeDataEndMonth day:kFakeDataEndDay hour:0 minute:0];
    NSInteger totalDays = [calendar components:NSCalendarUnitDay fromDate:startDate toDate:endDate options:0].day;
    for (NSInteger dayIndex = 0; dayIndex <= totalDays; dayIndex++) {
        NSDate *currentDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:dayIndex toDate:startDate options:0];
        NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:currentDate];
        [self appendRecordsForDateComponents:components dayIndex:dayIndex records:fakeRecords];
    }

    [fakeRecords sortUsingComparator:^NSComparisonResult(MirrorRecordModel *first, MirrorRecordModel *second) {
        if (first.startTime < second.startTime) return NSOrderedAscending;
        if (first.startTime > second.startTime) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    [filteredRecords addObjectsFromArray:fakeRecords];
    [filteredRecords sortUsingComparator:^NSComparisonResult(MirrorRecordModel *first, MirrorRecordModel *second) {
        if (first.startTime < second.startTime) return NSOrderedAscending;
        if (first.startTime > second.startTime) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    [self saveTasks:filteredTasks records:filteredRecords];
    NSLog(@"Seeded fake Mirror data: %lu tasks, %lu records", (unsigned long)plans.count, (unsigned long)fakeRecords.count);
}

+ (NSArray<MirrorFakeTaskPlan *> *)fakeTaskPlans
{
    return @[
        [[MirrorFakeTaskPlan alloc] initWithName:@"Gym" color:MirrorColorTypeCellBlue createdHour:7 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:@"Tennis" color:MirrorColorTypeCellGreen createdHour:18 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:@"Code" color:MirrorColorTypeCellYellow createdHour:9 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:@"Swim" color:MirrorColorTypeCellTeal createdHour:17 createdMinute:45],
        [[MirrorFakeTaskPlan alloc] initWithName:@"Read" color:MirrorColorTypeCellPink createdHour:21 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:@"Study" color:MirrorColorTypeCellPurple createdHour:20 createdMinute:0]
    ];
}

+ (void)appendRecordsForDateComponents:(NSDateComponents *)components dayIndex:(NSInteger)dayIndex records:(NSMutableArray<MirrorRecordModel *> *)records
{
    NSInteger month = components.month;
    NSInteger weekday = components.weekday;
    BOOL isWeekend = weekday == 1 || weekday == 7;
    BOOL isWeekday = !isWeekend;
    BOOL isSummer = month >= 6 && month <= 8;
    BOOL isWinter = month == 12 || month <= 2;
    
    NSInteger dailyReadDuration = 25 + (dayIndex % 5) * 10;
    [self addRecordWithName:@"Read" components:components hour:isWeekend ? 20 : 21 minute:(dayIndex % 2) * 15 durationMinutes:dailyReadDuration records:records];

    if (dayIndex % 2 == 0) {
        NSInteger duration = 55 + ((dayIndex % 5 == 0) ? 10 : 0);
        [self addRecordWithName:@"Gym" components:components hour:7 minute:(dayIndex % 3) * 10 durationMinutes:duration records:records];
    }

    if ((isWinter && (weekday == 3 || weekday == 5 || (weekday == 7 && dayIndex % 2 == 0))) || (!isWinter && weekday == 7 && dayIndex % 3 != 0)) {
        NSInteger hour = isWeekend ? 10 : 18;
        NSInteger duration = isWinter ? 90 + (dayIndex % 2) * 15 : 75;
        [self addRecordWithName:@"Tennis" components:components hour:hour minute:30 durationMinutes:duration records:records];
    }

    if (isWeekday) {
        NSInteger duration = 150 + (dayIndex % 4) * 30;
        [self addRecordWithName:@"Code" components:components hour:9 minute:30 durationMinutes:duration records:records];
        if (weekday == 3 || weekday == 5) {
            [self addRecordWithName:@"Code" components:components hour:14 minute:0 durationMinutes:90 + (dayIndex % 3) * 20 records:records];
        }
    } else if (dayIndex % 5 == 0) {
        [self addRecordWithName:@"Code" components:components hour:15 minute:0 durationMinutes:80 records:records];
    }

    if ((isSummer && (weekday == 2 || weekday == 4 || weekday == 7 || dayIndex % 6 == 0)) || (!isSummer && dayIndex % 17 == 0)) {
        NSInteger hour = isSummer ? (isWeekend ? 11 : 17) : 16;
        NSInteger duration = isSummer ? 45 + (dayIndex % 3) * 15 : 40;
        [self addRecordWithName:@"Swim" components:components hour:hour minute:15 durationMinutes:duration records:records];
    }

    if (weekday == 3 || weekday == 5 || (weekday == 1 && dayIndex % 2 == 0)) {
        NSInteger duration = isWeekend ? 120 : 75 + (dayIndex % 3) * 15;
        [self addRecordWithName:@"Study" components:components hour:isWeekend ? 14 : 19 minute:0 durationMinutes:duration records:records];
    }

    if (components.year == kFakeDataEndYear && components.month == kFakeDataEndMonth && components.day == kFakeDataEndDay) {
        [self addRecordWithName:@"Read" components:components hour:22 minute:15 durationMinutes:45 records:records];
    }
}

+ (void)addRecordWithName:(NSString *)name components:(NSDateComponents *)components hour:(NSInteger)hour minute:(NSInteger)minute durationMinutes:(NSInteger)durationMinutes records:(NSMutableArray<MirrorRecordModel *> *)records
{
    NSDate *dayStartDate = [self dateWithYear:components.year month:components.month day:components.day hour:0 minute:0];
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSDate *nextDayStartDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:dayStartDate options:0];
    long startTime = round([[self dateWithYear:components.year month:components.month day:components.day hour:hour minute:minute] timeIntervalSince1970]);
    long duration = durationMinutes * 60;
    long dayEnd = round([nextDayStartDate timeIntervalSince1970]);
    long endTime = startTime + duration;

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

    if (endTime > dayEnd) {
        return;
    }

    MirrorRecordModel *record = [[MirrorRecordModel alloc] initWithTitle:name
                                                                startTime:startTime
                                                                  endTime:endTime];
    [records addObject:record];
}

+ (BOOL)startTime:(long)startTime endTime:(long)endTime overlapsRecord:(MirrorRecordModel *)record
{
    return startTime < record.endTime && endTime > record.startTime;
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

+ (void)saveTasks:(NSMutableArray<MirrorTaskModel *> *)tasks records:(NSMutableArray<MirrorRecordModel *> *)records
{
    [MirrorStorage replaceAllDataWithTasks:tasks records:records secondsFromGMT:@([NSTimeZone systemTimeZone].secondsFromGMT)];
}

@end
