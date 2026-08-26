//
//  MirrorFakeDataSeeder.m
//  Mirror
//

#import "MirrorFakeDataSeeder.h"
#import "MirrorTaskModel.h"
#import "MirrorRecordModel.h"
#import "MirrorDayModel.h"
#import "MirrorStorage.h"
#import "MirrorLanguage.h"
#import "MirrorSettings.h"
#import "UIColor+MirrorColor.h"
#import "MirrorMacro.h"

#define ML(en, zh, es, fr, ja, ko, de, ru) @[en, zh, es, fr, ja, ko, de, ru]

static MirrorLanguageKey MirrorFakeDataSeedLanguageKey = MirrorLanguageKeyEnglish;
static BOOL MirrorFakeDataIsSeeding = NO;

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
@property (nonatomic, copy) NSArray<NSString *> *info;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, assign) MirrorSystemColorType color;

- (instancetype)initWithMonth:(NSInteger)month day:(NSInteger)day info:(NSArray<NSString *> *)info icon:(NSString *)icon color:(MirrorSystemColorType)color;

@end

@implementation MirrorFakeSpecialDayPlan

- (instancetype)initWithMonth:(NSInteger)month day:(NSInteger)day info:(NSArray<NSString *> *)info icon:(NSString *)icon color:(MirrorSystemColorType)color
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
    MirrorFakeDataSeedLanguageKey = [MirrorSettings preferredLanguageKey];
    MirrorFakeDataIsSeeding = YES;

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
    MirrorFakeDataIsSeeding = NO;
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
    return [self localizedValue:[self localizedSampleTaskNamesForEnglishName:englishName]
                    languageKey:[self fakeDataLanguageKey]
                      fallback:englishName];
}

+ (NSArray<NSString *> *)localizedSampleTaskNamesForEnglishName:(NSString *)englishName
{
    NSDictionary<NSString *, NSArray<NSString *> *> *taskNames = @{
        @"Gym": ML(@"Gym", @"健身", @"Gimnasio", @"Musculation", @"ジム", @"운동", @"Fitness", @"Тренировка"),
        @"Tennis": ML(@"Tennis", @"网球", @"Tenis", @"Tennis", @"テニス", @"테니스", @"Tennis", @"Теннис"),
        @"Code": ML(@"Code", @"编程", @"Programar", @"Coder", @"コーディング", @"코딩", @"Programmieren", @"Код"),
        @"Swim": ML(@"Swim", @"游泳", @"Nadar", @"Natation", @"水泳", @"수영", @"Schwimmen", @"Плавание"),
        @"Read": ML(@"Read", @"阅读", @"Leer", @"Lire", @"読書", @"독서", @"Lesen", @"Чтение"),
        @"Cook": ML(@"Cook", @"做饭", @"Cocinar", @"Cuisiner", @"料理", @"요리", @"Kochen", @"Готовка")
    };
    return taskNames[englishName] ?: ML(englishName, englishName, englishName, englishName, englishName, englishName, englishName, englishName);
}

+ (NSArray<MirrorFakeSpecialDayPlan *> *)fakeSpecialDayPlans
{
    return @[
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:1 day:8 info:ML(@"got a car", @"提车啦", @"coche nuevo", @"nouvelle voiture", @"車を手に入れた", @"차를 샀어요", @"Auto bekommen", @"купил машину") icon:@"car.fill" color:MirrorSystemColorTypeGreen],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:2 day:7 info:ML(@"graduated", @"毕业啦", @"graduación", @"diplôme obtenu", @"卒業した", @"졸업했어요", @"Abschluss gemacht", @"выпуск") icon:@"graduationcap.fill" color:MirrorSystemColorTypeBlue],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:3 day:22 info:ML(@"got a job", @"找到工作", @"conseguí trabajo", @"nouveau travail", @"仕事が決まった", @"취업했어요", @"Job bekommen", @"нашел работу") icon:@"briefcase.fill" color:MirrorSystemColorTypeMint],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:4 day:17 info:ML(@"got cats", @"接猫回家", @"adoptamos gatos", @"chats à la maison", @"猫を迎えた", @"고양이를 데려온 날", @"Katzen adoptiert", @"забрали кошек домой") icon:@"cat.fill" color:MirrorSystemColorTypePurple],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:5 day:15 info:ML(@"learned butterfly", @"会游蝶泳了", @"aprendí mariposa", @"papillon appris", @"バタフライが泳げるようになった", @"접영을 할 수 있게 됐어요", @"Schmetterling gelernt", @"научился баттерфляю") icon:@"figure.pool.swim" color:MirrorSystemColorTypeOrange],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:6 day:27 info:ML(@"my birthday", @"我的生日", @"mi cumpleaños", @"mon anniversaire", @"自分の誕生日", @"내 생일", @"mein Geburtstag", @"мой день рождения") icon:@"birthday.cake.fill" color:MirrorSystemColorTypeYellow],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:7 day:19 info:ML(@"watched the World Cup", @"看世界杯", @"vimos el Mundial", @"Coupe du monde", @"ワールドカップを見た", @"월드컵 본 날", @"die WM geschaut", @"смотрел чемпионат мира") icon:@"soccerball" color:MirrorSystemColorTypeMint],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:8 day:19 info:ML(@"moved to a new home", @"搬新家", @"mudanza a una casa nueva", @"déménagement", @"新居へ引っ越し", @"새집으로 이사", @"in ein neues Zuhause gezogen", @"переехал в новый дом") icon:@"chandelier.fill" color:MirrorSystemColorTypeGreen],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:9 day:13 info:ML(@"got abs", @"练出腹肌！", @"conseguí abdominales", @"abdos dessinés", @"腹筋が割れた", @"복근 만들기 성공!", @"Bauchmuskeln bekommen!", @"появился пресс!") icon:@"dumbbell.fill" color:MirrorSystemColorTypeOrange],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:10 day:28 info:ML(@"won the 3.0 tennis tournament", @"网球比赛3.0冠军", @"campeón del torneo de tenis 3.0", @"champion du tournoi de tennis 3.0", @"テニス大会3.0優勝", @"테니스 대회 3.0 우승", @"das 3.0-Tennisturnier gewonnen", @"выиграл теннисный турнир 3.0") icon:@"medal.fill" color:MirrorSystemColorTypePurple],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:11 day:11 info:ML(@"wedding", @"婚礼", @"boda", @"mariage", @"結婚式", @"결혼식", @"Hochzeit", @"свадьба") icon:@"heart.fill" color:MirrorSystemColorTypeRed],
        [[MirrorFakeSpecialDayPlan alloc] initWithMonth:12 day:12 info:ML(@"launched my own website", @"创建了自己的网站", @"creé mi sitio web", @"créé mon site web", @"自分のサイトを作った", @"내 웹사이트를 만들었어요", @"meine eigene Website gestartet", @"запустил свой сайт") icon:@"globe" color:MirrorSystemColorTypeOrange]
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
            
            NSString *info = [self localizedValue:plan.info
                                      languageKey:[self fakeDataLanguageKey]
                                        fallback:plan.info.firstObject];
            MirrorDayModel *day = [[MirrorDayModel alloc] initWithDateStr:dateKey
                                                                      info:info
                                                                      icon:plan.icon
                                                                     color:plan.color];
            [days addObject:day];
        }
    }
    
    NSArray<NSString *> *todayInfo = ML(@"downloaded Mirror.ly", @"下载了 Mirror.ly", @"descargué Mirror.ly", @"Mirror.ly téléchargé", @"Mirror.lyをダウンロード", @"Mirror.ly 다운로드", @"Mirror.ly heruntergeladen", @"скачал Mirror.ly");
    NSString *localizedTodayInfo = [self localizedValue:todayInfo
                                           languageKey:[self fakeDataLanguageKey]
                                             fallback:todayInfo.firstObject];
    MirrorDayModel *today = [[MirrorDayModel alloc] initWithDateStr:todayKey
                                                               info:localizedTodayInfo
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
    NSArray<NSArray<NSString *> *> *workoutNotes = @[
        ML(@"back day", @"练背日", @"día de espalda", @"jour dos", @"背中の日", @"등 운동일", @"Rückentag", @"день спины"),
        ML(@"leg day", @"练腿日", @"día de pierna", @"jour jambes", @"脚の日", @"하체 운동일", @"Beintag", @"день ног"),
        ML(@"shoulder day", @"练肩日", @"día de hombros", @"jour épaules", @"肩の日", @"어깨 운동일", @"Schultertag", @"день плеч")
    ];
    NSArray<NSString *> *baseNote = workoutNotes[workoutIndex % workoutNotes.count];
    NSString *note = [self localizedValue:baseNote
                              languageKey:[self fakeDataLanguageKey]
                                fallback:baseNote.firstObject];
    NSInteger statusRoll = [self randomPercentForDayIndex:dayIndex salt:83];
    if (statusRoll < 15) {
        NSArray<NSString *> *goodStatus = ML(@"feeling great", @"状态很好", @"muy buenas sensaciones", @"très bonnes sensations", @"調子がとても良い", @"컨디션 좋음", @"fühle mich großartig", @"отличное самочувствие");
        NSString *status = [self localizedValue:goodStatus
                                    languageKey:[self fakeDataLanguageKey]
                                      fallback:goodStatus.firstObject];
        return [note stringByAppendingFormat:@" · %@", status];
    }
    if (statusRoll < 30) {
        NSArray<NSString *> *badStatus = ML(@"low energy", @"状态不好", @"poca energía", @"petite forme", @"調子が悪い", @"컨디션 안 좋음", @"wenig Energie", @"мало энергии");
        NSString *status = [self localizedValue:badStatus
                                    languageKey:[self fakeDataLanguageKey]
                                      fallback:badStatus.firstObject];
        return [note stringByAppendingFormat:@" · %@", status];
    }
    return note;
}

+ (NSString *)tennisNoteForMonthIndex:(NSInteger)monthIndex dayIndex:(NSInteger)dayIndex
{
    // 网球 1/3 概率生成 note，内容按生成数据开始后的月份推进；有 note 时小概率追加状态很好/状态不好。
    if ([self randomValueForDayIndex:dayIndex salt:89 modulo:3] != 0) {
        return nil;
    }

    NSArray<NSArray<NSString *> *> *progressNotes = @[
        ML(@"forehand and backhand basics", @"练习正反手", @"derecha y revés básicos", @"bases coup droit et revers", @"フォアとバックの基礎", @"포핸드와 백핸드 기본", @"Grundlagen von Vorhand und Rückhand", @"основы форхенда и бэкхенда"),
        ML(@"footwork and split step", @"脚步和分腿垫步", @"pies y split step", @"jeu de jambes et split step", @"フットワークとスプリットステップ", @"풋워크와 스플릿 스텝", @"Beinarbeit und Split Step", @"работа ног и сплит-степ"),
        ML(@"serve toss and rhythm", @"发球抛球和节奏", @"lanzamiento y ritmo del saque", @"lancer et rythme au service", @"サーブのトスとリズム", @"서브 토스와 리듬", @"Aufwurftechnik und Rhythmus beim Aufschlag", @"подброс и ритм подачи"),
        ML(@"cross-court rally", @"斜线对拉", @"peloteo cruzado", @"diagonales", @"クロスラリー", @"크로스 랠리", @"Crosscourt-Rallye", @"кроссовый розыгрыш"),
        ML(@"backhand slice", @"反手切削", @"revés cortado", @"revers slicé", @"バックハンドスライス", @"백핸드 슬라이스", @"Rückhand-Slice", @"резаный бэкхенд"),
        ML(@"net volleys", @"网前截击", @"voleas en la red", @"volées au filet", @"ネットボレー", @"네트 발리", @"Volleys am Netz", @"удары с лета у сетки"),
        ML(@"approach shot", @"随球上网", @"golpe de aproximación", @"montée au filet", @"アプローチショット", @"어프로치 샷", @"Angriffsschlag", @"подходящий удар"),
        ML(@"second-serve topspin", @"二发上旋", @"segundo saque con topspin", @"deuxième service lifté", @"セカンドサーブのトップスピン", @"세컨 서브 탑스핀", @"Topspin beim zweiten Aufschlag", @"топспин на второй подаче"),
        ML(@"down-the-line shots", @"直线变线", @"golpes paralelos", @"long de ligne", @"ストレートへの展開", @"다운더라인 전환", @"Longline-Schläge", @"удары по линии"),
        ML(@"overheads and lobs", @"高压和挑高球", @"remates y globos", @"smashs et lobs", @"スマッシュとロブ", @"오버헤드와 로브", @"Überkopfbälle und Lobs", @"смэши и свечи"),
        ML(@"return practice", @"接发球", @"restos", @"retours de service", @"リターン練習", @"리턴 연습", @"Return-Training", @"тренировка приема"),
        ML(@"point patterns", @"得分套路", @"patrones de punto", @"schémas de points", @"ポイントパターン", @"득점 패턴", @"Punktmuster", @"розыгрыш очков"),
        ML(@"match play", @"实战局", @"juego de partido", @"jeu en match", @"実戦形式", @"실전 게임", @"Matchpraxis", @"игровая практика")
    ];
    NSArray<NSString *> *note = progressNotes[monthIndex % progressNotes.count];
    NSString *localizedNote = [self localizedValue:note
                                       languageKey:[self fakeDataLanguageKey]
                                         fallback:note.firstObject];
    NSInteger statusRoll = [self randomPercentForDayIndex:dayIndex salt:97];
    if (statusRoll < 15) {
        NSArray<NSString *> *goodStatus = ML(@"feeling great", @"状态很好", @"muy buenas sensaciones", @"très bonnes sensations", @"調子がとても良い", @"컨디션 좋음", @"fühle mich großartig", @"отличное самочувствие");
        NSString *status = [self localizedValue:goodStatus
                                    languageKey:[self fakeDataLanguageKey]
                                      fallback:goodStatus.firstObject];
        return [localizedNote stringByAppendingFormat:@" · %@", status];
    }
    if (statusRoll < 30) {
        NSArray<NSString *> *badStatus = ML(@"low energy", @"状态不好", @"poca energía", @"petite forme", @"調子が悪い", @"컨디션 안 좋음", @"wenig Energie", @"мало энергии");
        NSString *status = [self localizedValue:badStatus
                                    languageKey:[self fakeDataLanguageKey]
                                      fallback:badStatus.firstObject];
        return [localizedNote stringByAppendingFormat:@" · %@", status];
    }
    return localizedNote;
}

+ (NSString *)codeNoteForDayIndex:(NSInteger)dayIndex
{
    // 编程每次都有 note，从 10 种算法类型里按日期随机选择。
    NSArray<NSArray<NSString *> *> *notes = @[
        ML(@"binary tree", @"二叉树", @"árbol binario", @"arbre binaire", @"二分木", @"이진 트리", @"Binärbaum", @"бинарное дерево"),
        ML(@"dynamic programming", @"动态规划", @"programación dinámica", @"programmation dynamique", @"動的計画法", @"동적 계획법", @"Dynamische Programmierung", @"динамическое программирование"),
        ML(@"graph search", @"图搜索", @"búsqueda en grafos", @"recherche de graphe", @"グラフ探索", @"그래프 탐색", @"Graphsuche", @"поиск в графе"),
        ML(@"backtracking", @"回溯", @"backtracking", @"retour sur trace", @"バックトラッキング", @"백트래킹", @"Backtracking", @"бэктрекинг"),
        ML(@"sliding window", @"滑动窗口", @"ventana deslizante", @"fenêtre glissante", @"スライディングウィンドウ", @"슬라이딩 윈도우", @"Sliding Window", @"скользящее окно"),
        ML(@"two pointers", @"双指针", @"dos punteros", @"deux pointeurs", @"二ポインタ", @"투 포인터", @"Zwei Zeiger", @"два указателя"),
        ML(@"heap and priority queue", @"堆和优先队列", @"heap y cola de prioridad", @"tas et file de priorité", @"ヒープと優先度付きキュー", @"힙과 우선순위 큐", @"Heap und Prioritätswarteschlange", @"куча и очередь с приоритетом"),
        ML(@"greedy algorithm", @"贪心算法", @"algoritmo voraz", @"algorithme glouton", @"貪欲法", @"그리디 알고리즘", @"Greedy-Algorithmus", @"жадный алгоритм"),
        ML(@"prefix sum", @"前缀和", @"suma prefija", @"somme préfixe", @"累積和", @"누적합", @"Präfixsumme", @"префиксная сумма"),
        ML(@"union find", @"并查集", @"union find", @"union-find", @"Union-Find", @"유니온 파인드", @"Union-Find", @"система непересекающихся множеств")
    ];
    NSInteger noteIndex = [self randomValueForDayIndex:dayIndex salt:107 modulo:997] % notes.count;
    NSArray<NSString *> *note = notes[noteIndex];
    return [self localizedValue:note
                    languageKey:[self fakeDataLanguageKey]
                      fallback:note.firstObject];
}

+ (NSString *)cookNoteForDurationMinutes:(NSInteger)durationMinutes dayIndex:(NSInteger)dayIndex
{
    // 做饭每次都有 note，根据做饭时长分成快手菜、正常晚饭、复杂菜三档，再从对应菜名里随机选择。
    // 不是直接翻译，而是文化对应
    NSArray<NSArray<NSString *> *> *quickNotes = @[
        ML(@"omelette", @"番茄炒蛋", @"tortilla de patata", @"omelette aux fines herbes", @"親子丼", @"김치볶음밥", @"Abendbrot", @"бутерброд"),
        ML(@"scrambled eggs", @"蒜香虾仁意面", @"pasta con gambas al ajillo", @"pâtes aux crevettes à l'ail", @"明太子パスタ", @"새우 오일 파스타", @"Rührei", @"яичница"),
        ML(@"pasta salad", @"味噌三文鱼饭", @"bowl de salmón", @"bol de saumon miso", @"鮭の味噌焼き丼", @"연어 덮밥", @"Nudelsalat", @"гречка с грибами")
    ];
    NSArray<NSArray<NSString *> *> *regularNotes = @[
        ML(@"chicken curry", @"咖喱鸡", @"pollo al curry", @"poulet au curry", @"チキンカレー", @"치킨 카레", @"Hähnchencurry", @"курица карри"),
        ML(@"roast chicken", @"红烧排骨", @"costillas guisadas", @"travers de porc mijotés", @"豚の角煮", @"돼지갈비찜", @"Schweinebraten", @"котлеты с пюре"),
        ML(@"spaghetti bolognese", @"麻婆豆腐", @"albóndigas con salsa brava", @"hachis parmentier", @"麻婆豆腐", @"마파두부", @"Käsespätzle", @"пельмени"),
        ML(@"beef stew", @"牛肉面", @"cocido ligero", @"pot-au-feu", @"肉うどん", @"소고기국밥", @"Rindergulasch", @"борщ")
    ];
    NSArray<NSArray<NSString *> *> *slowNotes = @[
        ML(@"Sunday roast", @"宫保虾球", @"paella de marisco", @"boeuf bourguignon", @"ビーフシチュー", @"갈비찜", @"Sauerbraten", @"бефстроганов"),
        ML(@"stuffed roast chicken", @"香草烤鸡", @"pollo relleno al horno", @"poulet rôti farci", @"ローストチキン", @"통닭구이", @"gefülltes Brathähnchen", @"фаршированная запеченная курица"),
        ML(@"seafood risotto", @"海鲜烩饭", @"arroz caldoso de marisco", @"risotto aux fruits de mer", @"海鮮リゾット", @"해산물 리조또", @"Meeresfrüchte-Risotto", @"ризотто с морепродуктами")
    ];

    NSArray<NSArray<NSString *> *> *notes = quickNotes;
    NSInteger salt = 109;
    if (durationMinutes >= 70) {
        notes = slowNotes;
        salt = 113;
    } else if (durationMinutes >= 45) {
        notes = regularNotes;
        salt = 111;
    }

    NSInteger noteIndex = [self randomValueForDayIndex:dayIndex salt:salt modulo:997] % notes.count;
    NSArray<NSString *> *note = notes[noteIndex];
    return [self localizedValue:note
                    languageKey:[self fakeDataLanguageKey]
                      fallback:note.firstObject];
}

+ (NSArray<NSDictionary<NSString *, id> *> *)readingBookPlans
{
    // 阅读书单按顺序推进；每本书配置一个预计读完所需总分钟数。
    return @[
        @{@"title": ML(@"Anna Karenina", @"安娜卡列尼娜", @"Anna Karénina", @"Anna Karénine", @"アンナ・カレーニナ", @"안나 카레니나", @"Anna Karenina", @"Анна Каренина"), @"minutes": @(40 * 60)},
        @{@"title": ML(@"War and Peace", @"战争与和平", @"Guerra y paz", @"Guerre et Paix", @"戦争と平和", @"전쟁과 평화", @"Krieg und Frieden", @"Война и мир"), @"minutes": @(55 * 60)},
        @{@"title": ML(@"Les Miserables", @"悲惨世界", @"Los miserables", @"Les Misérables", @"レ・ミゼラブル", @"레 미제라블", @"Die Elenden", @"Отверженные"), @"minutes": @(48 * 60)},
        @{@"title": ML(@"The Brothers Karamazov", @"卡拉马佐夫兄弟", @"Los hermanos Karamázov", @"Les Frères Karamazov", @"カラマーゾフの兄弟", @"카라마조프가의 형제들", @"Die Brüder Karamasow", @"Братья Карамазовы"), @"minutes": @(34 * 60)},
        @{@"title": ML(@"One Hundred Years of Solitude", @"百年孤独", @"Cien años de soledad", @"Cent ans de solitude", @"百年の孤独", @"백년의 고독", @"Hundert Jahre Einsamkeit", @"Сто лет одиночества"), @"minutes": @(18 * 60)},
        @{@"title": ML(@"Pride and Prejudice", @"傲慢与偏见", @"Orgullo y prejuicio", @"Orgueil et Préjugés", @"高慢と偏見", @"오만과 편견", @"Stolz und Vorurteil", @"Гордость и предубеждение"), @"minutes": @(12 * 60)},
        @{@"title": ML(@"Crime and Punishment", @"罪与罚", @"Crimen y castigo", @"Crime et Châtiment", @"罪と罰", @"죄와 벌", @"Schuld und Sühne", @"Преступление и наказание"), @"minutes": @(22 * 60)},
        @{@"title": ML(@"Don Quixote", @"堂吉诃德", @"Don Quijote", @"Don Quichotte", @"ドン・キホーテ", @"돈키호테", @"Don Quijote", @"Дон Кихот"), @"minutes": @(45 * 60)},
        @{@"title": ML(@"The Count of Monte Cristo", @"基督山伯爵", @"El conde de Montecristo", @"Le Comte de Monte-Cristo", @"モンテ・クリスト伯", @"몬테크리스토 백작", @"Der Graf von Monte Christo", @"Граф Монте-Кристо"), @"minutes": @(42 * 60)},
        @{@"title": ML(@"Madame Bovary", @"包法利夫人", @"Madame Bovary", @"Madame Bovary", @"ボヴァリー夫人", @"마담 보바리", @"Madame Bovary", @"Madame Bovary"), @"minutes": @(10 * 60)}
    ];
}

+ (NSString *)readingNoteForBookIndex:(NSInteger)bookIndex
{
    // 阅读 note 只显示当前正在读的书名。
    NSArray<NSDictionary<NSString *, id> *> *books = [self readingBookPlans];
    NSDictionary<NSString *, id> *book = books[bookIndex % books.count];
    NSArray<NSString *> *title = book[@"title"];
    return [self localizedValue:title
                    languageKey:[self fakeDataLanguageKey]
                      fallback:title.firstObject];
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

    NSArray<NSArray<NSString *> *> *notes = @[
        ML(@"1000m freestyle", @"自由泳1000米", @"1000 m libre", @"1000 m nage libre", @"自由形1000m", @"자유형 1000m", @"1000 m Freistil", @"1000 м вольным стилем"),
        ML(@"butterfly", @"蝶泳", @"mariposa", @"papillon", @"バタフライ", @"접영", @"Schmetterling", @"баттерфляй")
    ];
    NSInteger noteIndex = [self randomValueForDayIndex:dayIndex salt:103 modulo:97] % notes.count;
    NSArray<NSString *> *note = notes[noteIndex];
    return [self localizedValue:note
                    languageKey:[self fakeDataLanguageKey]
                      fallback:note.firstObject];
}

+ (MirrorLanguageKey)fakeDataLanguageKey
{
    return MirrorFakeDataIsSeeding ? MirrorFakeDataSeedLanguageKey : [MirrorSettings preferredLanguageKey];
}

+ (NSString *)localizedValue:(NSArray<NSString *> *)translations languageKey:(MirrorLanguageKey)languageKey fallback:(NSString *)fallback
{
    if (![translations isKindOfClass:NSArray.class] || translations.count == 0) {
        return fallback;
    }
    if (languageKey >= 0 && languageKey < translations.count) {
        return translations[languageKey];
    }
    return translations.firstObject;
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
