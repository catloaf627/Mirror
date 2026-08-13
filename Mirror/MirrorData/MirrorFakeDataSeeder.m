//
//  MirrorFakeDataSeeder.m
//  Mirror
//

#import "MirrorFakeDataSeeder.h"
#import "MirrorTaskModel.h"
#import "MirrorRecordModel.h"
#import "MirrorStorage.h"
#import "MirrorLanguage.h"
#import "MirrorSettings.h"
#import "UIColor+MirrorColor.h"
#import "MirrorMacro.h"

#define ML(en, zh, es, fr, ja, ko) @[en, zh, es, fr, ja, ko]

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

+ (void)seedFakeData
{
    NSArray<MirrorFakeTaskPlan *> *plans = [self fakeTaskPlans];
    NSSet<NSString *> *fakeTaskNames = [self allLocalizedFakeTaskNames];

    NSMutableArray<MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    NSMutableArray<MirrorTaskModel *> *filteredTasks = [NSMutableArray new];
    for (MirrorTaskModel *task in tasks) {
        if (![fakeTaskNames containsObject:task.taskName]) {
            [filteredTasks addObject:task];
        }
    }

    NSDate *endDate = [self startOfToday];
    NSDate *startDate = [self dateByAddingYears:-1 toDate:endDate];

    for (MirrorFakeTaskPlan *plan in plans) {
        MirrorTaskModel *task = [[MirrorTaskModel alloc] initWithTitle:plan.name
                                                           createdTime:(long)[startDate timeIntervalSince1970]
                                                             colorType:plan.color
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
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Gym"] color:MirrorColorTypeCellBlue createdHour:7 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Tennis"] color:MirrorColorTypeCellGreen createdHour:18 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Swim"] color:MirrorColorTypeCellTeal createdHour:17 createdMinute:45],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Code"] color:MirrorColorTypeCellYellow createdHour:9 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Cook"] color:MirrorColorTypeCellPurple createdHour:18 createdMinute:30],
        [[MirrorFakeTaskPlan alloc] initWithName:[self localizedSampleTaskNameWithEnglishName:@"Read"] color:MirrorColorTypeCellPink createdHour:21 createdMinute:30]
    ];
}

+ (NSSet<NSString *> *)allLocalizedFakeTaskNames
{
    NSMutableSet<NSString *> *taskNames = [NSMutableSet new];
    for (NSString *englishName in [self fakeTaskEnglishNames]) {
        for (NSString *localizedName in [self localizedSampleTaskNamesForEnglishName:englishName]) {
            [taskNames addObject:localizedName];
        }
    }
    return taskNames;
}

+ (NSArray<NSString *> *)fakeTaskEnglishNames
{
    return @[@"Gym", @"Tennis", @"Swim", @"Code", @"Cook", @"Read", @"Study"];
}

// 每天的 fake record 生成规则：
// 1. 每月 2 号到随机的 3/4/5 号视为生理期，不生成运动和编程。
// 2. 非生理期每天早上生成一条运动：偶数 dayIndex 健身；非健身日夏天游泳、冬天网球，其他季节游泳/网球按概率切换。
// 3. 运动时间在 7 点左右，周末有概率推迟到 8/9 点，运动时长 1.5 到 2 小时。
// 4. 编程从运动结束后 1 到 2 小时开始，时长 1 到 8 小时，偶尔偷懒缩短或跳过。
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
        if ([self randomValueForDayIndex:dayIndex salt:37 modulo:7] >= 2) {
            NSInteger codeDuration = 60 + [self randomValueForDayIndex:dayIndex salt:41 modulo:421];
            if ([self randomPercentForDayIndex:dayIndex salt:43] < 14) {
                codeDuration = 45 + [self randomValueForDayIndex:dayIndex salt:47 modulo:76];
            }
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
                    languageKey:[MirrorSettings preferredLanguageKey]
                      fallback:englishName];
}

+ (NSArray<NSString *> *)localizedSampleTaskNamesForEnglishName:(NSString *)englishName
{
    NSDictionary<NSString *, NSArray<NSString *> *> *taskNames = @{
        @"Gym": ML(@"Gym", @"健身", @"Gimnasio", @"Sport", @"ジム", @"운동"),
        @"Tennis": ML(@"Tennis", @"网球", @"Tenis", @"Tennis", @"テニス", @"테니스"),
        @"Code": ML(@"Code", @"编程", @"Programar", @"Coder", @"コーディング", @"코딩"),
        @"Swim": ML(@"Swim", @"游泳", @"Nadar", @"Natation", @"水泳", @"수영"),
        @"Read": ML(@"Read", @"阅读", @"Leer", @"Lire", @"読書", @"독서"),
        @"Cook": ML(@"Cook", @"做饭", @"Cocinar", @"Cuisiner", @"料理", @"요리"),
        @"Study": ML(@"Study", @"学习", @"Estudiar", @"Étudier", @"勉強", @"공부")
    };
    return taskNames[englishName] ?: ML(englishName, englishName, englishName, englishName, englishName, englishName);
}

+ (NSString *)gymNoteForWorkoutIndex:(NSInteger)workoutIndex dayIndex:(NSInteger)dayIndex
{
    // 健身每次都有 note，按练背日、练腿日、练肩日循环；小概率追加状态很好/状态不好。
    NSArray<NSArray<NSString *> *> *workoutNotes = @[
        ML(@"back day", @"练背日", @"día de espalda", @"jour dos", @"背中の日", @"등 운동일"),
        ML(@"leg day", @"练腿日", @"día de pierna", @"jour jambes", @"脚の日", @"하체 운동일"),
        ML(@"shoulder day", @"练肩日", @"día de hombros", @"jour épaules", @"肩の日", @"어깨 운동일")
    ];
    NSArray<NSString *> *baseNote = workoutNotes[workoutIndex % workoutNotes.count];
    NSString *note = [self localizedValue:baseNote
                              languageKey:[MirrorSettings preferredLanguageKey]
                                fallback:baseNote.firstObject];
    NSInteger statusRoll = [self randomPercentForDayIndex:dayIndex salt:83];
    if (statusRoll < 15) {
        NSArray<NSString *> *goodStatus = ML(@"feeling great", @"状态很好", @"muy buenas sensaciones", @"très bonnes sensations", @"調子がとても良い", @"컨디션 좋음");
        NSString *status = [self localizedValue:goodStatus
                                    languageKey:[MirrorSettings preferredLanguageKey]
                                      fallback:goodStatus.firstObject];
        return [note stringByAppendingFormat:@" · %@", status];
    }
    if (statusRoll < 30) {
        NSArray<NSString *> *badStatus = ML(@"low energy", @"状态不好", @"poca energía", @"petite forme", @"調子が悪い", @"컨디션 안 좋음");
        NSString *status = [self localizedValue:badStatus
                                    languageKey:[MirrorSettings preferredLanguageKey]
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
        ML(@"forehand and backhand basics", @"练习正反手", @"derecha y revés básicos", @"bases coup droit et revers", @"フォアとバックの基礎", @"포핸드와 백핸드 기본"),
        ML(@"footwork and split step", @"脚步和分腿垫步", @"pies y split step", @"jeu de jambes et split step", @"フットワークとスプリットステップ", @"풋워크와 스플릿 스텝"),
        ML(@"serve toss and rhythm", @"发球抛球和节奏", @"lanzamiento y ritmo del saque", @"lancer et rythme au service", @"サーブのトスとリズム", @"서브 토스와 리듬"),
        ML(@"cross-court rally", @"斜线对拉", @"peloteo cruzado", @"diagonales", @"クロスラリー", @"크로스 랠리"),
        ML(@"backhand slice", @"反手切削", @"revés cortado", @"revers slicé", @"バックハンドスライス", @"백핸드 슬라이스"),
        ML(@"net volleys", @"网前截击", @"voleas en la red", @"volées au filet", @"ネットボレー", @"네트 발리"),
        ML(@"approach shot", @"随球上网", @"golpe de aproximación", @"montée au filet", @"アプローチショット", @"어프로치 샷"),
        ML(@"second-serve topspin", @"二发上旋", @"segundo saque con topspin", @"deuxième service lifté", @"セカンドサーブのトップスピン", @"세컨 서브 탑스핀"),
        ML(@"down-the-line shots", @"直线变线", @"golpes paralelos", @"long de ligne", @"ストレートへの展開", @"다운더라인 전환"),
        ML(@"overheads and lobs", @"高压和挑高球", @"remates y globos", @"smashs et lobs", @"スマッシュとロブ", @"오버헤드와 로브"),
        ML(@"return practice", @"接发球", @"restos", @"retours de service", @"リターン練習", @"리턴 연습"),
        ML(@"point patterns", @"得分套路", @"patrones de punto", @"schémas de points", @"ポイントパターン", @"득점 패턴"),
        ML(@"match play", @"实战局", @"juego de partido", @"jeu en match", @"実戦形式", @"실전 게임")
    ];
    NSArray<NSString *> *note = progressNotes[monthIndex % progressNotes.count];
    NSString *localizedNote = [self localizedValue:note
                                       languageKey:[MirrorSettings preferredLanguageKey]
                                         fallback:note.firstObject];
    NSInteger statusRoll = [self randomPercentForDayIndex:dayIndex salt:97];
    if (statusRoll < 15) {
        NSArray<NSString *> *goodStatus = ML(@"feeling great", @"状态很好", @"muy buenas sensaciones", @"très bonnes sensations", @"調子がとても良い", @"컨디션 좋음");
        NSString *status = [self localizedValue:goodStatus
                                    languageKey:[MirrorSettings preferredLanguageKey]
                                      fallback:goodStatus.firstObject];
        return [localizedNote stringByAppendingFormat:@" · %@", status];
    }
    if (statusRoll < 30) {
        NSArray<NSString *> *badStatus = ML(@"low energy", @"状态不好", @"poca energía", @"petite forme", @"調子が悪い", @"컨디션 안 좋음");
        NSString *status = [self localizedValue:badStatus
                                    languageKey:[MirrorSettings preferredLanguageKey]
                                      fallback:badStatus.firstObject];
        return [localizedNote stringByAppendingFormat:@" · %@", status];
    }
    return localizedNote;
}

+ (NSString *)codeNoteForDayIndex:(NSInteger)dayIndex
{
    // 编程每次都有 note，从 10 种算法类型里按日期随机选择。
    NSArray<NSArray<NSString *> *> *notes = @[
        ML(@"binary tree", @"二叉树", @"árbol binario", @"arbre binaire", @"二分木", @"이진 트리"),
        ML(@"dynamic programming", @"动态规划", @"programación dinámica", @"programmation dynamique", @"動的計画法", @"동적 계획법"),
        ML(@"graph search", @"图搜索", @"búsqueda en grafos", @"recherche de graphe", @"グラフ探索", @"그래프 탐색"),
        ML(@"backtracking", @"回溯", @"backtracking", @"retour sur trace", @"バックトラッキング", @"백트래킹"),
        ML(@"sliding window", @"滑动窗口", @"ventana deslizante", @"fenêtre glissante", @"スライディングウィンドウ", @"슬라이딩 윈도우"),
        ML(@"two pointers", @"双指针", @"dos punteros", @"deux pointeurs", @"二ポインタ", @"투 포인터"),
        ML(@"heap and priority queue", @"堆和优先队列", @"heap y cola de prioridad", @"tas et file de priorité", @"ヒープと優先度付きキュー", @"힙과 우선순위 큐"),
        ML(@"greedy algorithm", @"贪心算法", @"algoritmo voraz", @"algorithme glouton", @"貪欲法", @"그리디 알고리즘"),
        ML(@"prefix sum", @"前缀和", @"suma prefija", @"somme préfixe", @"累積和", @"누적합"),
        ML(@"union find", @"并查集", @"union find", @"union-find", @"Union-Find", @"유니온 파인드")
    ];
    NSInteger noteIndex = [self randomValueForDayIndex:dayIndex salt:107 modulo:997] % notes.count;
    NSArray<NSString *> *note = notes[noteIndex];
    return [self localizedValue:note
                    languageKey:[MirrorSettings preferredLanguageKey]
                      fallback:note.firstObject];
}

+ (NSString *)cookNoteForDurationMinutes:(NSInteger)durationMinutes dayIndex:(NSInteger)dayIndex
{
    // 做饭每次都有 note，根据做饭时长分成快手菜、正常晚饭、复杂菜三档，再从对应菜名里随机选择。
    NSArray<NSArray<NSString *> *> *quickNotes = @[
        ML(@"tomato omelette", @"番茄炒蛋", @"tortilla de patata", @"omelette aux fines herbes", @"親子丼", @"김치볶음밥"),
        ML(@"garlic shrimp pasta", @"蒜香虾仁意面", @"pasta con gambas al ajillo", @"pâtes aux crevettes à l'ail", @"明太子パスタ", @"새우 오일 파스타"),
        ML(@"miso salmon bowl", @"味噌三文鱼饭", @"bowl de salmón", @"bol de saumon miso", @"鮭の味噌焼き丼", @"연어 덮밥")
    ];
    NSArray<NSArray<NSString *> *> *regularNotes = @[
        ML(@"chicken curry", @"咖喱鸡", @"pollo al curry", @"poulet au curry", @"チキンカレー", @"치킨 카레"),
        ML(@"braised pork ribs", @"红烧排骨", @"costillas guisadas", @"travers de porc mijotés", @"豚の角煮", @"돼지갈비찜"),
        ML(@"mapo tofu", @"麻婆豆腐", @"albóndigas con salsa brava", @"hachis parmentier", @"麻婆豆腐", @"마파두부"),
        ML(@"beef noodle soup", @"牛肉面", @"cocido ligero", @"pot-au-feu", @"肉うどん", @"소고기국밥")
    ];
    NSArray<NSArray<NSString *> *> *slowNotes = @[
        ML(@"kung pao shrimp", @"宫保虾球", @"paella de marisco", @"boeuf bourguignon", @"ビーフシチュー", @"갈비찜"),
        ML(@"stuffed roast chicken", @"香草烤鸡", @"pollo relleno al horno", @"poulet rôti farci", @"ローストチキン", @"통닭구이"),
        ML(@"seafood risotto", @"海鲜烩饭", @"arroz caldoso de marisco", @"risotto aux fruits de mer", @"海鮮リゾット", @"해산물 리조또")
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
                    languageKey:[MirrorSettings preferredLanguageKey]
                      fallback:note.firstObject];
}

+ (NSArray<NSDictionary<NSString *, id> *> *)readingBookPlans
{
    // 阅读书单按顺序推进；每本书配置一个预计读完所需总分钟数。
    return @[
        @{@"title": ML(@"Anna Karenina", @"安娜卡列尼娜", @"Anna Karénina", @"Anna Karénine", @"アンナ・カレーニナ", @"안나 카레니나"), @"minutes": @(40 * 60)},
        @{@"title": ML(@"War and Peace", @"战争与和平", @"Guerra y paz", @"Guerre et Paix", @"戦争と平和", @"전쟁과 평화"), @"minutes": @(55 * 60)},
        @{@"title": ML(@"Les Miserables", @"悲惨世界", @"Los miserables", @"Les Misérables", @"レ・ミゼラブル", @"레 미제라블"), @"minutes": @(48 * 60)},
        @{@"title": ML(@"The Brothers Karamazov", @"卡拉马佐夫兄弟", @"Los hermanos Karamázov", @"Les Frères Karamazov", @"カラマーゾフの兄弟", @"카라마조프가의 형제들"), @"minutes": @(34 * 60)},
        @{@"title": ML(@"One Hundred Years of Solitude", @"百年孤独", @"Cien años de soledad", @"Cent ans de solitude", @"百年の孤独", @"백년의 고독"), @"minutes": @(18 * 60)},
        @{@"title": ML(@"Pride and Prejudice", @"傲慢与偏见", @"Orgullo y prejuicio", @"Orgueil et Préjugés", @"高慢と偏見", @"오만과 편견"), @"minutes": @(12 * 60)},
        @{@"title": ML(@"Crime and Punishment", @"罪与罚", @"Crimen y castigo", @"Crime et Châtiment", @"罪と罰", @"죄와 벌"), @"minutes": @(22 * 60)},
        @{@"title": ML(@"Don Quixote", @"堂吉诃德", @"Don Quijote", @"Don Quichotte", @"ドン・キホーテ", @"돈키호테"), @"minutes": @(45 * 60)},
        @{@"title": ML(@"The Count of Monte Cristo", @"基督山伯爵", @"El conde de Montecristo", @"Le Comte de Monte-Cristo", @"モンテ・クリスト伯", @"몬테크리스토 백작"), @"minutes": @(42 * 60)},
        @{@"title": ML(@"Madame Bovary", @"包法利夫人", @"Madame Bovary", @"Madame Bovary", @"ボヴァリー夫人", @"마담 보바리"), @"minutes": @(10 * 60)}
    ];
}

+ (NSString *)readingNoteForBookIndex:(NSInteger)bookIndex
{
    // 阅读 note 只显示当前正在读的书名。
    NSArray<NSDictionary<NSString *, id> *> *books = [self readingBookPlans];
    NSDictionary<NSString *, id> *book = books[bookIndex % books.count];
    NSArray<NSString *> *title = book[@"title"];
    return [self localizedValue:title
                    languageKey:[MirrorSettings preferredLanguageKey]
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
        ML(@"1000m freestyle", @"自由泳1000米", @"1000 m libre", @"1000 m nage libre", @"自由形1000m", @"자유형 1000m"),
        ML(@"butterfly", @"蝶泳", @"mariposa", @"papillon", @"バタフライ", @"접영")
    ];
    NSInteger noteIndex = [self randomValueForDayIndex:dayIndex salt:103 modulo:97] % notes.count;
    NSArray<NSString *> *note = notes[noteIndex];
    return [self localizedValue:note
                    languageKey:[MirrorSettings preferredLanguageKey]
                      fallback:note.firstObject];
}

+ (NSString *)localizedValue:(NSArray<NSString *> *)translations languageKey:(NSInteger)languageKey fallback:(NSString *)fallback
{
    if (![translations isKindOfClass:NSArray.class] || translations.count == 0) {
        return fallback;
    }
    if (languageKey >= 0 && languageKey < translations.count) {
        return translations[languageKey];
    }
    return translations.firstObject;
}

+ (NSString *)englishTaskNameForLocalizedTaskName:(NSString *)taskName
{
    for (NSString *englishName in [self fakeTaskEnglishNames]) {
        if ([[self localizedSampleTaskNamesForEnglishName:englishName] containsObject:taskName]) {
            return englishName;
        }
    }
    return @"Code";
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

+ (void)saveTasks:(NSMutableArray<MirrorTaskModel *> *)tasks records:(NSMutableArray<MirrorRecordModel *> *)records
{
    [MirrorStorage replaceAllDataWithTasks:tasks records:records secondsFromGMT:@([NSTimeZone systemTimeZone].secondsFromGMT)];
}

@end
