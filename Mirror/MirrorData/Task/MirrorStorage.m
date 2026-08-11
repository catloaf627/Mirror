//
//  MirrorStorage.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/10/24.
//

#import "MirrorStorage.h"
#import "UIColor+MirrorColor.h"
#import "MirrorLanguage.h"
#import "MirrorTool.h"
#import "MirrorMacro.h"
#import <AudioToolbox/AudioToolbox.h>

static NSInteger const kMaxTaskCnt = 8;
static NSString * const kMirrorJSONFileName = @"mirror.json";
static NSString * const kMirrorICloudContainerIdentifier = @"iCloud.com.yuqingwang.dev.Mirror";

@interface MirrorStorage ()

// 将一条原始用户记录按“自然日”和查询范围切成 UI 片段；例如 2026-01-01 08:00 到 2026-01-03 08:00 会切出 1/1、1/2、1/3 三段，但不写回数据库。
+ (NSArray<MirrorRecordModel *> *)daySegmentsForRecord:(MirrorRecordModel *)record clippedToStart:(long)rangeStart end:(long)rangeEnd;

@end

@implementation MirrorStorage

#pragma mark - Time VC需要的信息

// 返回当前正在计时的任务名；例如最后一条 record 是“阅读 09:00-endTime 0”，返回“阅读”，否则返回空字符串。
+ (NSString *)isGoingOnTask
{
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage retriveMirrorRecords];
    if (allRecords.count > 0 && allRecords[allRecords.count-1].endTime == 0) {
        return allRecords[allRecords.count-1].taskName;
    }
    return @"";
}

// App 启动或回到前台时恢复 Live Activity；例如数据库最后一条是未结束的“跑步”，就用它的开始时间继续展示实时活动。
+ (void)resumeGoingOnLiveActivityIfNeeded
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    MirrorRecordModel *record = records.lastObject;
    if (record == nil || record.endTime != 0) {
        return;
    }

    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:record.taskName];
    NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:record.startTime];
    [MirrorStorage p_startLiveActivityWithTaskName:record.taskName startDate:startDate colorType:task.color];
}

// 取出任务列表，并在末尾追加一个“新增任务”的占位模型；例如真实任务有 A/B，返回 A/B/+。
+ (NSMutableArray<MirrorTaskModel *> *)tasksWithAddNew
{
    NSMutableArray <MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    NSMutableArray <MirrorTaskModel *> *tasksWithAddNew = [tasks mutableCopy];
    if (tasks.count < kMaxTaskCnt) {
        MirrorTaskModel *fakemodel = [[MirrorTaskModel alloc] initWithTitle:@"" createdTime:0 colorType:0 isHidden:NO isAddTask:YES];
        [tasksWithAddNew addObject:fakemodel];
    }
    return tasksWithAddNew;
}

#pragma mark - Actions

// 创建一个新任务并持久化；例如添加“英语/粉色”，会写入 tasks、发送 MirrorTaskCreateNotification 并播放点击音。
+ (void)createTask:(MirrorTaskModel *)task
{
    NSMutableArray <MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    [tasks addObject:task];
    NSLog(@"Create");
    [MirrorStorage saveMirrorTasks:tasks];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskCreateNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 删除一个任务及其所有原始记录；例如删除“英语”，会移除英语任务、英语的全部 periods，如果它正在计时还会结束 Live Activity。
+ (void)deleteTask:(NSString *)taskName
{
    BOOL deletesGoingOnTask = [[MirrorStorage isGoingOnTask] isEqualToString:taskName];
    // 删掉task
    NSMutableArray <MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    NSInteger deletedIndex = NSNotFound;
    for (int i=0; i<tasks.count; i++) {
        if ([tasks[i].taskName isEqualToString:taskName]) {
            NSLog(@"Delete task");
            deletedIndex = i;
            break;
        }
    }
    if (deletedIndex != NSNotFound) [tasks removeObjectAtIndex:deletedIndex];
    [MirrorStorage saveMirrorTasks:tasks];
    // 删掉这个task的所有records
    NSMutableArray <MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    NSMutableArray <MirrorRecordModel *> *validRecords = [NSMutableArray new];
    for (int i=0; i<records.count; i++) {
        if (![records[i].taskName isEqualToString:taskName]) {
            [validRecords addObject:records[i]];
        } else {
            NSLog(@"Delete record");
        }
    }
    [MirrorStorage saveMirrorRecords:validRecords];
    if (deletesGoingOnTask) {
        [MirrorStorage p_endLiveActivity];
    }
    // 通知
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskDeleteNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 将一个任务合并到另一个任务；例如把“英语”的所有记录改名为“学习”，再从任务列表删除“英语”。
+ (void)mergeTask:(NSString *)sourceTaskName toTask:(NSString *)targetTaskName
{
    if (sourceTaskName.length == 0 || targetTaskName.length == 0 || [sourceTaskName isEqualToString:targetTaskName]) {
        return;
    }
    
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    for (MirrorRecordModel *record in records) {
        if ([record.taskName isEqualToString:sourceTaskName]) {
            record.taskName = targetTaskName;
        }
    }
    [MirrorStorage saveMirrorRecords:records];
    
    NSMutableArray<MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    NSInteger sourceTaskIndex = NSNotFound;
    for (NSInteger index = 0; index < tasks.count; index++) {
        if ([tasks[index].taskName isEqualToString:sourceTaskName]) {
            sourceTaskIndex = index;
            break;
        }
    }
    if (sourceTaskIndex != NSNotFound) {
        [tasks removeObjectAtIndex:sourceTaskIndex];
    }
    [MirrorStorage saveMirrorTasks:tasks];
    
    NSLog(@"Merge task");
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskMergeNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 切换任务隐藏状态；例如把“工作”设为 hidden 后，Grid/History 这类隐藏过滤数据源不再统计它。
+ (void)switchHiddenTask:(NSString *)taskName
{
    NSMutableArray <MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    for (int i=0; i<tasks.count; i++) {
        if ([tasks[i].taskName isEqualToString:taskName]) {
            if (tasks[i].isHidden == NO) {
                NSLog(@"Hide");
                tasks[i].isHidden = YES;
            } else {
                NSLog(@"Cancel Hide");
                tasks[i].isHidden = NO;
            }
            break;
        }
    }
    [MirrorStorage saveMirrorTasks:tasks];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskHiddenNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 修改任务名称，并同步改所有原始记录里的 taskName；例如“英语”改成“English”，历史记录也会一起改名。
+ (void)editTask:(NSString *)oldName name:(NSString *)newName
{
    NSMutableArray <MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    for (int i=0; i<tasks.count; i++) {
        if ([tasks[i].taskName isEqualToString:oldName]) {
            NSLog(@"Edit name");
            tasks[i].taskName = newName;
            break;
        }
    }
    [MirrorStorage saveMirrorTasks:tasks];
    NSMutableArray <MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    for (int i=0; i<records.count; i++) {
        if ([records[i].taskName isEqualToString:oldName]) {
            NSLog(@"Edit record name");
            records[i].taskName = newName;
        }
    }
    [MirrorStorage saveMirrorRecords:records];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskEditNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}



// 修改任务颜色；例如把“阅读”的颜色改成 MirrorColorTypeBlue，只更新任务元数据，不改记录时间。
+ (void)editTask:(NSString *)taskName color:(MirrorColorType)color
{
    NSMutableArray <MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    for (int i=0; i<tasks.count; i++) {
        if ([tasks[i].taskName isEqualToString:taskName]) {
            NSLog(@"Edit color");
            tasks[i].color = color;
            break;
        }
    }
    [MirrorStorage saveMirrorTasks:tasks];
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskEditNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 保存任务排序；例如用户拖动后传入 [工作, 阅读, 运动]，后续图表也按这个顺序聚合展示。
+ (void)reorderTasks:(NSMutableArray <MirrorTaskModel *> *)taskArray
{
    [MirrorStorage saveMirrorTasks:taskArray]; // reorder 的话直接保存数组即可
    NSLog(@"Edit order");
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskChangeOrderNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 直接保存一段原始记录：内部模拟 start + stop；例如“阅读 08:00-09:30”保存为一条用户记录，不按天切库。
+ (void)savePeriodWithTaskname:(NSString *)taskName startAt:(NSDate *)startDate endAt:(NSDate *)endDate
{
    [MirrorStorage p_startTask:taskName at:startDate];
    [MirrorStorage p_stopTask:taskName at:endDate];
    NSLog(@"Save period start %@, end %@", [MirrorTool timeFromDate:startDate printTimeStamp:NO],  [MirrorTool timeFromDate:endDate printTimeStamp:NO]);
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskStopNotification object:nil userInfo:nil]; // 直接保存的也报stop
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 插入一条原始记录；例如 Today 页点 23:45 添加 1 小时，会保存为 23:45-00:45 一条记录，UI 数据源再按天切。
+ (void)insertPeriodWithTaskname:(NSString *)taskName startAt:(NSDate *)startDate endAt:(NSDate *)endDate
{
    NSDate *dateWithoutSeconds = [self dateWithoutSeconds:startDate];
    NSDate *endDateWithoutSeconds = [self dateWithoutSeconds:endDate];
    long startTime = round([dateWithoutSeconds timeIntervalSince1970]);
    long endTime = round([endDateWithoutSeconds timeIntervalSince1970]);
    if (endTime - startTime < kMinSeconds) {
        return;
    }
    MirrorRecordModel *newRecord = [[MirrorRecordModel alloc] initWithTitle:taskName startTime:startTime endTime:endTime];
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    [records addObject:newRecord];
    [records sortUsingComparator:^NSComparisonResult(MirrorRecordModel *record1, MirrorRecordModel *record2) {
        if (record1.startTime < record2.startTime) return NSOrderedAscending;
        if (record1.startTime > record2.startTime) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    [MirrorStorage saveMirrorRecords:records];
    NSLog(@"Insert period start %@, end %@", [MirrorTool timeFromDate:startDate printTimeStamp:NO], [MirrorTool timeFromDate:endDate printTimeStamp:NO]);
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskStopNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 按查询范围和自然日切 UI 片段；例如原始记录 1/1 08:00-1/3 08:00，查询 1/2 00:00-1/3 00:00 时只返回 1/2 全天片段。
+ (NSArray<MirrorRecordModel *> *)daySegmentsForRecord:(MirrorRecordModel *)record clippedToStart:(long)rangeStart end:(long)rangeEnd
{
    if (record.endTime == 0) {
        return @[];
    }
    long startTime = MAX(record.startTime, rangeStart);
    long endTime = MIN(record.endTime, rangeEnd);
    if (endTime - startTime < kMinSeconds) {
        return @[];
    }

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSMutableArray<MirrorRecordModel *> *records = [NSMutableArray new];
    long currentStartTime = startTime;
    NSDate *currentStartDate = [NSDate dateWithTimeIntervalSince1970:currentStartTime];
    while (currentStartTime < endTime) {
        NSDate *nextDayDate = [gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:currentStartDate options:0];
        NSDate *nextDayStartDate = [gregorian startOfDayForDate:nextDayDate];
        long nextDayStartTime = round([nextDayStartDate timeIntervalSince1970]);
        long currentEndTime = MIN(endTime, nextDayStartTime);
        if (currentEndTime - currentStartTime >= kMinSeconds) {
            MirrorRecordModel *segment = [[MirrorRecordModel alloc] initWithTitle:record.taskName startTime:currentStartTime endTime:currentEndTime];
            segment.originalIndex = record.originalIndex;
            segment.note = record.note;
            [records addObject:segment];
        }
        currentStartTime = currentEndTime;
        currentStartDate = [NSDate dateWithTimeIntervalSince1970:currentStartTime];
    }
    return records;
}

// 开始计时的公开入口；例如点击“阅读”开始，会新增 endTime=0 的原始记录、启动 Live Activity、发通知。
+ (void)startTask:(NSString *)taskName at:(NSDate *)accurateDate
{
    [MirrorStorage p_startTask:taskName at:accurateDate];
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:taskName];
    NSDate *date = [self dateWithoutSeconds:accurateDate];
    [MirrorStorage p_startLiveActivityWithTaskName:taskName startDate:date colorType:task.color];
    NSLog(@"Start at %@", [MirrorTool timeFromDate:accurateDate printTimeStamp:NO]);
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskStartNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 只写入“正在计时”的原始记录，不发通知也不启动 Live Activity；例如内部创建“阅读 09:00-endTime 0”。
+ (void)p_startTask:(NSString *)taskName at:(NSDate *)accurateDate
{
    NSDate *date = [self dateWithoutSeconds:accurateDate];
    NSMutableArray <MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    MirrorRecordModel *newRecord = [[MirrorRecordModel alloc] initWithTitle:taskName startTime:round([date timeIntervalSince1970]) endTime:0];
    [records addObject:newRecord];
    [MirrorStorage saveMirrorRecords:records];
}

// 停止计时的公开入口；例如 09:00 开始“阅读”、10:15 停止，会把最后一条原始记录结束在 10:15 并发停止通知。
+ (void)stopTask:(NSString *)taskName at:(NSDate *)accurateDate
{
    [MirrorStorage p_stopTask:taskName at:accurateDate];
    [MirrorStorage p_endLiveActivity];
    NSLog(@"Stop at %@", [MirrorTool timeFromDate:accurateDate printTimeStamp:NO]);
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorTaskStopNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 只结束最后一条正在计时的原始记录；例如跨天 1/1 23:00 到 1/2 01:00 仍保存为一条 raw record，不在这里切分。
+ (void)p_stopTask:(NSString *)taskName at:(NSDate *)accurateDate // 这里taskname没用
{
    NSDate *date = [self dateWithoutSeconds:accurateDate];
    NSMutableArray <MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (records.count == 0) {
        return;
    }
    MirrorRecordModel *recordToBeEditted = records[records.count-1]; // 最后(新)一个record
    long start = recordToBeEditted.startTime;
    long end = [date timeIntervalSince1970];
    long length = end - start;
    NSLog(@"%@计时结束 %ld", taskName, length);
    
    if (end <= start || length < kMinSeconds) {
        [records removeObjectAtIndex:records.count-1];
        [MirrorStorage saveMirrorRecords:records];
        return;
    }

    recordToBeEditted.endTime = round([date timeIntervalSince1970]);
    records[records.count - 1] = recordToBeEditted;
    [MirrorStorage saveMirrorRecords:records];
}

// 检查新任务名是否已存在；例如已有“阅读”时再输入“阅读”，返回 TaskNameExistsTypeExistsInCurrentTasks。
+ (TaskNameExistsType)taskNameExists:(NSString *)newTaskName
{
    NSMutableArray <MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    for (int i=0; i<tasks.count; i++) {
        if ([tasks[i].taskName isEqualToString:newTaskName]) {
            return TaskNameExistsTypeExistsInCurrentTasks;
        }
    }
    return TaskNameExistsTypeValid;
}

// 删除第 index 条原始记录；例如删除 records[3]，会直接从 raw data 移除这一整条记录，而不是删除某个 UI 切片。
+ (void)deletePeriodAtIndex:(NSInteger)index
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    BOOL deletesGoingOnTask = index >= 0 && index < records.count && records[index].endTime == 0;
    [records removeObjectAtIndex:index];
    [MirrorStorage saveMirrorRecords:records];
    if (deletesGoingOnTask) {
        [MirrorStorage p_endLiveActivity];
    }
    NSLog(@"Period deleted");
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorPeriodDeleteNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 通过 Swift Live Activity 管理器启动实时活动；例如“阅读 09:00”会传 taskName、开始时间戳和颜色。
+ (void)p_startLiveActivityWithTaskName:(NSString *)taskName startDate:(NSDate *)startDate colorType:(NSInteger)colorType
{
    Class manager = NSClassFromString(@"MirrorLiveActivityManager");
    SEL selector = @selector(startWithTaskName:startTimestamp:colorType:);
    if (![manager respondsToSelector:selector]) {
        return;
    }

    void (*startActivity)(id, SEL, NSString *, NSTimeInterval, NSInteger) = (void *)[manager methodForSelector:selector];
    startActivity(manager, selector, taskName, [startDate timeIntervalSince1970], colorType);
}

// 结束当前 Live Activity；例如用户停止计时或删除正在计时任务时调用。
+ (void)p_endLiveActivity
{
    Class manager = NSClassFromString(@"MirrorLiveActivityManager");
    SEL selector = @selector(end);
    if (![manager respondsToSelector:selector]) {
        return;
    }

    void (*endActivity)(id, SEL) = (void *)[manager methodForSelector:selector];
    endActivity(manager, selector);
}

// 修改某条原始记录的单侧时间；例如把 records[2] 的 startTime 改成 08:30，endTime 保持不变。
+ (void)editPeriodIsStartTime:(BOOL)isStartTime to:(long)timestamp periodIndex:(NSInteger)index
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (isStartTime) {
        records[index].startTime = timestamp;
    } else {
        records[index].endTime = timestamp;
    }
    [MirrorStorage saveMirrorRecords:records];
    NSLog(@"Period is edited");
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorPeriodEditNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 同时修改某条原始记录的开始和结束时间，并重新排序；例如把 records[4] 改为 1/1 08:00-1/3 08:00，仍是一条 raw record。
+ (void)editPeriodAtIndex:(NSInteger)index startAt:(NSDate *)startDate endAt:(NSDate *)endDate
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (index < 0 || index >= records.count) return;
    
    NSDate *dateWithoutSeconds = [self dateWithoutSeconds:startDate];
    NSDate *endDateWithoutSeconds = [self dateWithoutSeconds:endDate];
    if ([endDateWithoutSeconds timeIntervalSince1970] - [dateWithoutSeconds timeIntervalSince1970] < kMinSeconds) return;
    records[index].startTime = round([dateWithoutSeconds timeIntervalSince1970]);
    records[index].endTime = round([endDateWithoutSeconds timeIntervalSince1970]);
    [records sortUsingComparator:^NSComparisonResult(MirrorRecordModel *record1, MirrorRecordModel *record2) {
        if (record1.startTime < record2.startTime) return NSOrderedAscending;
        if (record1.startTime > record2.startTime) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    [MirrorStorage saveMirrorRecords:records];
    NSLog(@"Period is edited");
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorPeriodEditNotification object:nil userInfo:nil];
    AudioServicesPlaySystemSound((SystemSoundID)kAudioClick);
}

// 修改某条原始记录的备注；例如给 records[2] 写入一段用户备注，最多保留 200 个字符。
+ (void)editPeriodNote:(NSString *)note periodIndex:(NSInteger)index
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (index < 0 || index >= records.count) return;
    
    records[index].note = note;
    [MirrorStorage saveMirrorRecords:records];
    NSLog(@"Period note is edited");
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorPeriodEditNotification object:nil userInfo:nil];
}

#pragma mark - Local database

// 保存完整任务数组，同时保留当前 records 和时区设置；例如只改任务顺序时用这个方法落盘。
+ (void)saveMirrorTasks:(NSMutableArray<MirrorTaskModel *> *)tasks
{
    [MirrorStorage replaceAllDataWithTasks:tasks records:[MirrorStorage retriveMirrorRecords] secondsFromGMT:[MirrorStorage retriveSecondsFromGMT]];
}

// 从本地 JSON 读取任务数组；例如启动后恢复“阅读/工作/运动”的任务配置，失败时返回空数组。
+ (NSMutableArray<MirrorTaskModel *> *)retriveMirrorTasks
{
    NSMutableArray<MirrorTaskModel *> *tasks = nil;
    NSMutableArray<MirrorRecordModel *> *records = nil;
    NSNumber *secondsFromGMT = nil;
    if ([MirrorStorage parseJSONDictionary:[MirrorStorage jsonDictionaryFromDisk] tasks:&tasks records:&records secondsFromGMT:&secondsFromGMT]) {
        return tasks;
    } else {
        return [NSMutableArray new];
    }
}

// 保存完整原始记录数组，同时保留当前 tasks 和时区设置；例如删除一条 period 后用它写回 raw records。
+ (void)saveMirrorRecords:(NSMutableArray<MirrorRecordModel *> *)records
{
    [MirrorStorage replaceAllDataWithTasks:[MirrorStorage retriveMirrorTasks] records:records secondsFromGMT:[MirrorStorage retriveSecondsFromGMT]];
}

// 从本地 JSON 读取原始用户记录，并补上 originalIndex；例如跨天 1/1-1/3 的记录在这里仍只是一条。
+ (NSMutableArray<MirrorRecordModel *> *)retriveMirrorRecords
{
    NSMutableArray<MirrorTaskModel *> *tasks = nil;
    NSMutableArray<MirrorRecordModel *> *records = nil;
    NSNumber *secondsFromGMT = nil;
    if ([MirrorStorage parseJSONDictionary:[MirrorStorage jsonDictionaryFromDisk] tasks:&tasks records:&records secondsFromGMT:&secondsFromGMT]) {
        for (int i=0; i<records.count; i++) {
            records[i].originalIndex = i;
        }
        return records;
    } else {
        return [NSMutableArray new];
    }
}

// 保存新的时区偏移元数据，不修改任何用户原始时间戳；例如从北京改到纽约，只更新 JSON 里的 seconds，调用方负责通知 UI 刷新。
+ (void)saveSecondsFromGMT:(NSNumber *)secondFromGMT
{
    if ([[MirrorStorage retriveSecondsFromGMT] isEqualToNumber:secondFromGMT]) {
        return;
    }
    [MirrorStorage replaceAllDataWithTasks:[MirrorStorage retriveMirrorTasks] records:[MirrorStorage retriveMirrorRecords] secondsFromGMT:secondFromGMT];
}

// 读取保存数据时使用的时区偏移；例如 JSON 里 SECONDS=-28800 就返回 -28800，旧数据缺失时用系统当前时区。
+ (NSNumber *)retriveSecondsFromGMT
{
    NSMutableArray<MirrorTaskModel *> *tasks = nil;
    NSMutableArray<MirrorRecordModel *> *records = nil;
    NSNumber *secondFromGMT = nil;
    if ([MirrorStorage parseJSONDictionary:[MirrorStorage jsonDictionaryFromDisk] tasks:&tasks records:&records secondsFromGMT:&secondFromGMT]) {
        return secondFromGMT;
    } else {
        return @([NSTimeZone systemTimeZone].secondsFromGMT);
    }
}

// 导出当前完整数据为 JSON；例如设置页导出文件时，会包含 tasks、raw records 和 secondsFromGMT。
+ (NSData *)exportJSONData
{
    return [NSJSONSerialization dataWithJSONObject:[MirrorStorage jsonDictionaryWithTasks:[MirrorStorage retriveMirrorTasks] records:[MirrorStorage retriveMirrorRecords] secondsFromGMT:[MirrorStorage retriveSecondsFromGMT]] options:NSJSONWritingPrettyPrinted error:nil];
}

// 只校验外部 JSON 是否能导入，不写入；例如用户选中文件后先检查字段类型是否完整。
+ (BOOL)canImportJSONData:(NSData *)data
{
    NSDictionary *jsonDictionary = [MirrorStorage jsonDictionaryFromData:data];
    return [MirrorStorage parseJSONDictionary:jsonDictionary tasks:nil records:nil secondsFromGMT:nil];
}

// 从外部 JSON 覆盖导入全部数据；例如导入备份文件成功后，本地 tasks/records/时区都会替换。
+ (BOOL)importJSONData:(NSData *)data
{
    NSMutableArray<MirrorTaskModel *> *tasks = nil;
    NSMutableArray<MirrorRecordModel *> *records = nil;
    NSNumber *secondsFromGMT = nil;
    NSDictionary *jsonDictionary = [MirrorStorage jsonDictionaryFromData:data];
    if (![MirrorStorage parseJSONDictionary:jsonDictionary tasks:&tasks records:&records secondsFromGMT:&secondsFromGMT]) {
        return NO;
    }
    [MirrorStorage replaceAllDataWithTasks:tasks records:records secondsFromGMT:secondsFromGMT];
    return YES;
}

// 读取 iCloud 备份里的记录数量；例如设置页显示“云端有 128 条记录”，读取失败时返回 nil。
+ (NSNumber *)iCloudRecordCount
{
    NSMutableArray<MirrorRecordModel *> *records = nil;
    if ([MirrorStorage parseJSONDictionary:[MirrorStorage jsonDictionaryFromICloud] tasks:nil records:&records secondsFromGMT:nil]) {
        return @(records.count);
    }
    return nil;
}

// 从 iCloud 备份覆盖导入全部数据；例如用户点“从 iCloud 下载”后替换本地 JSON。
+ (BOOL)importDataFromICloud
{
    NSMutableArray<MirrorTaskModel *> *tasks = nil;
    NSMutableArray<MirrorRecordModel *> *records = nil;
    NSNumber *secondsFromGMT = nil;
    if (![MirrorStorage parseJSONDictionary:[MirrorStorage jsonDictionaryFromICloud] tasks:&tasks records:&records secondsFromGMT:&secondsFromGMT]) {
        return NO;
    }
    
    [MirrorStorage replaceAllDataWithTasks:tasks records:records secondsFromGMT:secondsFromGMT];
    return YES;
}

// 用传入的 tasks、raw records、时区重写整份数据；例如删除任务后把新数组写入本地缓存并异步同步 iCloud。
+ (void)replaceAllDataWithTasks:(NSMutableArray<MirrorTaskModel *> *)tasks records:(NSMutableArray<MirrorRecordModel *> *)records secondsFromGMT:(NSNumber *)secondsFromGMT
{
    NSData *data = [NSJSONSerialization dataWithJSONObject:[MirrorStorage jsonDictionaryWithTasks:tasks records:records secondsFromGMT:secondsFromGMT] options:NSJSONWritingPrettyPrinted error:nil];
    if (!data) return;
    
    [data writeToFile:[MirrorStorage jsonFilePath] atomically:YES];
    [MirrorStorage saveJSONDataToICloud:data];
}

// 返回本地缓存 JSON 路径；例如 .../Library/Caches/mirror.json。
+ (NSString *)jsonFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    return [path stringByAppendingPathComponent:kMirrorJSONFileName];
}

// 异步把 JSON 写入 iCloud Documents；例如每次本地保存后同步 mirror.json，失败只记录日志不阻塞 UI。
+ (void)saveJSONDataToICloud:(NSData *)data
{
    NSData *dataCopy = [data copy];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSURL *documentsURL = [MirrorStorage iCloudDocumentsURL];
        if (!documentsURL) {
            NSLog(@"iCloud Documents is unavailable");
            return;
        }
        
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtURL:documentsURL withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Create iCloud Documents folder failed: %@", error);
            return;
        }
        
        NSURL *fileURL = [documentsURL URLByAppendingPathComponent:kMirrorJSONFileName];
        if (![dataCopy writeToURL:fileURL options:NSDataWritingAtomic error:&error]) {
            NSLog(@"Save mirror data to iCloud failed: %@", error);
        }
    });
}

// 返回 iCloud 容器下的 Documents 目录；例如 iCloud.com.yuqingwang.dev.Mirror/Documents，不可用时返回 nil。
+ (NSURL *)iCloudDocumentsURL
{
    NSURL *containerURL = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:kMirrorICloudContainerIdentifier];
    if (!containerURL) return nil;
    return [containerURL URLByAppendingPathComponent:@"Documents" isDirectory:YES];
}

// 从本地 mirror.json 读出字典；例如 App 启动时所有 retrive 方法最终都会走这里解析本地缓存。
+ (NSDictionary *)jsonDictionaryFromDisk
{
    NSData *data = [NSData dataWithContentsOfFile:[MirrorStorage jsonFilePath] options:0 error:nil];
    return [MirrorStorage jsonDictionaryFromData:data];
}

// 从 iCloud mirror.json 读出字典；例如下载云端备份时先触发下载，再把文件内容转成 NSDictionary。
+ (NSDictionary *)jsonDictionaryFromICloud
{
    NSURL *documentsURL = [MirrorStorage iCloudDocumentsURL];
    if (!documentsURL) return nil;
    
    NSURL *fileURL = [documentsURL URLByAppendingPathComponent:kMirrorJSONFileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) return nil;
    
    NSError *error = nil;
    [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:fileURL error:&error];
    if (error) {
        NSLog(@"Start downloading iCloud mirror data failed: %@", error);
    }
    
    NSData *data = [NSData dataWithContentsOfURL:fileURL options:NSDataReadingMappedIfSafe error:&error];
    if (error) {
        NSLog(@"Read iCloud mirror data failed: %@", error);
        return nil;
    }
    
    return [MirrorStorage jsonDictionaryFromData:data];
}

// 把 NSData 解析成 JSON 字典；例如导入文件不是 JSON 或顶层不是字典时返回 nil。
+ (NSDictionary *)jsonDictionaryFromData:(NSData *)data
{
    if (!data) return nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![jsonObject isKindOfClass:NSDictionary.class]) return nil;
    return jsonObject;
}

// 把模型数组编码成持久化字典；例如 task 写 task_name/color，record 写 start_time/end_time，最终组成 version/tasks/records/seconds。
+ (NSDictionary *)jsonDictionaryWithTasks:(NSMutableArray<MirrorTaskModel *> *)tasks records:(NSMutableArray<MirrorRecordModel *> *)records secondsFromGMT:(NSNumber *)secondsFromGMT
{
    NSMutableArray *jsonTasks = [NSMutableArray new];
    for (MirrorTaskModel *task in tasks) {
        [jsonTasks addObject:@{
            @"task_name": task.taskName ?: @"",
            @"is_hidden": @(task.isHidden),
            @"color": @(task.color),
            @"created_time": @(task.createdTime)
        }];
    }

    NSMutableArray *jsonRecords = [NSMutableArray new];
    for (MirrorRecordModel *record in records) {
        [jsonRecords addObject:@{
            @"task_name": record.taskName ?: @"",
            @"start_time": @(record.startTime),
            @"end_time": @(record.endTime),
            @"note": record.note ?: @""
        }];
    }

    return @{
        @"version": @1,
        TASKS: jsonTasks,
        RECORDS: jsonRecords,
        SECONDS: secondsFromGMT ?: @([NSTimeZone systemTimeZone].secondsFromGMT)
    };
}

// 严格解析持久化字典为模型；例如缺少 task_name 或 start_time 类型不是 NSNumber 时返回 NO，避免导入坏数据。
+ (BOOL)parseJSONDictionary:(NSDictionary *)jsonDictionary tasks:(NSMutableArray<MirrorTaskModel *> **)tasks records:(NSMutableArray<MirrorRecordModel *> **)records secondsFromGMT:(NSNumber **)secondsFromGMT
{
    if (![jsonDictionary isKindOfClass:NSDictionary.class]) return NO;

    NSArray *jsonTasks = jsonDictionary[TASKS];
    NSArray *jsonRecords = jsonDictionary[RECORDS];
    NSNumber *jsonSecondsFromGMT = jsonDictionary[SECONDS];
    if (![jsonTasks isKindOfClass:NSArray.class] || ![jsonRecords isKindOfClass:NSArray.class] || ![jsonSecondsFromGMT isKindOfClass:NSNumber.class]) {
        return NO;
    }

    NSMutableArray<MirrorTaskModel *> *parsedTasks = [NSMutableArray new];
    for (NSDictionary *jsonTask in jsonTasks) {
        if (![jsonTask isKindOfClass:NSDictionary.class]) return NO;
        NSString *taskName = jsonTask[@"task_name"];
        NSNumber *isHidden = jsonTask[@"is_hidden"];
        NSNumber *color = jsonTask[@"color"];
        NSNumber *createdTime = jsonTask[@"created_time"];
        if (![taskName isKindOfClass:NSString.class] || ![isHidden isKindOfClass:NSNumber.class] || ![color isKindOfClass:NSNumber.class] || ![createdTime isKindOfClass:NSNumber.class]) {
            return NO;
        }
        MirrorTaskModel *task = [[MirrorTaskModel alloc] initWithTitle:taskName createdTime:[createdTime longValue] colorType:[color integerValue] isHidden:[isHidden boolValue] isAddTask:NO];
        [parsedTasks addObject:task];
    }

    NSMutableArray<MirrorRecordModel *> *parsedRecords = [NSMutableArray new];
    for (NSDictionary *jsonRecord in jsonRecords) {
        if (![jsonRecord isKindOfClass:NSDictionary.class]) return NO;
        NSString *taskName = jsonRecord[@"task_name"];
        NSNumber *startTime = jsonRecord[@"start_time"];
        NSNumber *endTime = jsonRecord[@"end_time"];
        NSString *note = jsonRecord[@"note"];
        if (![taskName isKindOfClass:NSString.class] || ![startTime isKindOfClass:NSNumber.class] || ![endTime isKindOfClass:NSNumber.class]) {
            return NO;
        }
        if (note != nil && ![note isKindOfClass:NSString.class]) {
            return NO;
        }
        MirrorRecordModel *record = [[MirrorRecordModel alloc] initWithTitle:taskName startTime:[startTime longValue] endTime:[endTime longValue]];
        record.note = note ?: @"";
        [parsedRecords addObject:record];
    }

    if (tasks) *tasks = parsedTasks;
    if (records) *records = parsedRecords;
    if (secondsFromGMT) *secondsFromGMT = jsonSecondsFromGMT;
    return YES;
}

#pragma mark - 取出部分数据

// 读取原始记录并过滤隐藏任务；例如“工作”被隐藏后，它的 raw records 不会进入 Grid/History 统计数据源。
+ (NSMutableArray<MirrorRecordModel *> *)p_retriveMirrorRecordsWithoutHidden
{
    NSMutableArray<MirrorTaskModel *> *allTasks = [MirrorStorage retriveMirrorTasks];
    NSMutableDictionary *taskHiddenState = [NSMutableDictionary new];
    for (int i=0; i<allTasks.count; i++) {
        MirrorTaskModel *task = allTasks[i];
        if (task.isHidden) {
            [taskHiddenState setValue:@(YES) forKey:task.taskName];
        } else {
            [taskHiddenState setValue:@(NO) forKey:task.taskName];
        }
    }
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage retriveMirrorRecords];
    NSMutableArray<MirrorRecordModel *> *allRecordsWithoutHidden = [NSMutableArray new];
    for (int i=0; i<allRecords.count; i++) {
        MirrorRecordModel *record = allRecords[i];
        if ([taskHiddenState[record.taskName] boolValue]) {
            // 这条record被隐藏
        } else {
            [allRecordsWithoutHidden addObject:record];
        }
    }
    return allRecordsWithoutHidden;
}


// 按任务名取任务模型；例如传入“阅读”返回它的颜色、隐藏状态、创建时间，找不到时返回 nil。
+ (MirrorTaskModel *)getTaskModelFromDB:(NSString *)taskName
{
    NSMutableArray<MirrorTaskModel *> *allTasks = [MirrorStorage retriveMirrorTasks];
    MirrorTaskModel *targetTask = nil;
    for (int i=0; i<allTasks.count; i++) {
        MirrorTaskModel *task = allTasks[i];
        if ([task.taskName isEqualToString:taskName]) {
            targetTask = task;
            break;
        }
    }
    return targetTask;
}

// 取出一个任务从古至今的所有原始记录；例如“阅读”跨三天的一条记录仍返回一条，用于任务总时长/记录列表。
+ (NSMutableArray<MirrorRecordModel *> *)getAllTaskRecords:(NSString *)taskName
{
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage retriveMirrorRecords];
    NSMutableArray<MirrorRecordModel *> *taskRecords = [NSMutableArray new];
    for (int recordIndex=0; recordIndex<allRecords.count; recordIndex++) {
        MirrorRecordModel *record = allRecords[recordIndex];
        if ([record.taskName isEqualToString:taskName]) {
            MirrorRecordModel *recordCopy = [[MirrorRecordModel alloc] initWithTitle:record.taskName startTime:record.startTime endTime:record.endTime];
            recordCopy.originalIndex = record.originalIndex;
            recordCopy.note = record.note;
            [taskRecords addObject:recordCopy];
        }
    }
    return taskRecords;
}

// 取出 Today 页时间轴数据，会把和今天有交集的 raw records 切成今天范围内的 UI 片段；例如 1/1 23:00-1/2 01:00 在 1/2 返回 00:00-01:00。
+ (NSMutableArray<MirrorRecordModel *> *)getTodayData
{
    // TODAY timestamp
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDate *startOfDay = [gregorian startOfDayForDate:[NSDate now]];
    NSDate *startOfNextDay = [gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfDay options:0];
    long startTime = round([startOfDay timeIntervalSince1970]);
    long endTime = round([startOfNextDay timeIntervalSince1970]);
    
    BOOL printDetailsToDebug = NO; // debug用
    NSMutableArray<MirrorRecordModel *> *targetRecords = [NSMutableArray<MirrorRecordModel *> new];
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage retriveMirrorRecords];

    for (int recordIndex=(int)allRecords.count-1; recordIndex>=0; recordIndex--) {
        MirrorRecordModel *record = allRecords[recordIndex];
        if (printDetailsToDebug) {
            NSLog(@"period数据：[%@,%@]，选取的时间段：[%@,%@]", [MirrorTool timeFromTimestamp:record.startTime printTimeStamp:NO], [MirrorTool timeFromTimestamp:record.endTime printTimeStamp:NO], [MirrorTool timeFromTimestamp:startTime printTimeStamp:NO], [MirrorTool timeFromTimestamp:endTime printTimeStamp:NO]);
        }
        if (record.endTime == 0) {
            if (printDetailsToDebug) NSLog(@"✖️正在计时中，不管");
            continue;
        }
        // r.end < starttime
        else if (record.endTime < startTime) {
            if (printDetailsToDebug) NSLog(@"✖️完整地发生在start time之前，不管");
            break; // 正常情况下倒序找到today以后，发现record.endTime已经早于今日零点，这时候break就可以了，可以少循环一轮
        }
        // endtime <= r.start
        else if (endTime <= record.startTime) {
            if (printDetailsToDebug) NSLog(@"✖️完整地发生在end time之后，不管");
        }
        // 和今天有交集，按今天范围切出UI展示片段
        else if (record.startTime < endTime && startTime < record.endTime) {
            if (printDetailsToDebug) NSLog(@"✔️和选取时间段有交集");
            [targetRecords addObjectsFromArray:[self daySegmentsForRecord:record clippedToStart:startTime end:endTime]];
        }
    }
    return [[[targetRecords reverseObjectEnumerator] allObjects] mutableCopy]; // 倒序
}

// 取出指定时间范围内的图表数据，先按范围/自然日切 UI 片段，再按任务顺序包装成 MirrorReadModel；例如查询一周时，跨天 raw record 会贡献到多天统计里。
+ (NSMutableArray<MirrorReadModel *> *)getAllRecordsInTaskOrderWithStart:(long)startTime end:(long)endTime shouldHideHidden:(BOOL)shouldHideHidden
{
    BOOL printDetailsToDebug = NO; // debug用
    NSMutableDictionary<NSString *, NSMutableArray<MirrorRecordModel *> *> *dict = [NSMutableDictionary<NSString *, NSMutableArray<MirrorRecordModel *> *> new];
    NSMutableArray<MirrorRecordModel *> *allRecords = shouldHideHidden ? [MirrorStorage p_retriveMirrorRecordsWithoutHidden] : [MirrorStorage retriveMirrorRecords];

    for (int recordIndex=0; recordIndex<allRecords.count; recordIndex++) {
        MirrorRecordModel *record = allRecords[recordIndex];
        if (printDetailsToDebug) {
            NSLog(@"period数据：[%@,%@]，选取的时间段：[%@,%@]", [MirrorTool timeFromTimestamp:record.startTime printTimeStamp:NO], [MirrorTool timeFromTimestamp:record.startTime printTimeStamp:NO], [MirrorTool timeFromTimestamp:startTime printTimeStamp:NO], [MirrorTool timeFromTimestamp:endTime printTimeStamp:NO]);
        }
        if (record.endTime == 0) {
            if (printDetailsToDebug) NSLog(@"✖️正在计时中，不管");
            continue;
        }
        // r.end < starttime
        else if (record.endTime < startTime) {
            if (printDetailsToDebug) NSLog(@"✖️完整地发生在start time之前，不管");
        }
        // endtime <= r.start
        else if (endTime <= record.startTime) {
            if (printDetailsToDebug) NSLog(@"✖️完整地发生在end time之后，不管");
        }
        // 和选取时间段有交集，按天切出UI统计片段
        else if (record.startTime < endTime && startTime < record.endTime) {
            if (printDetailsToDebug) NSLog(@"✔️和选取时间段有交集");
            NSArray<MirrorRecordModel *> *segments = [self daySegmentsForRecord:record clippedToStart:startTime end:endTime];
            if (segments.count > 0) {
                NSMutableArray<MirrorRecordModel *> *value = dict[record.taskName] ?: [NSMutableArray<MirrorRecordModel *> new];
                [value addObjectsFromArray:segments];
                [dict setValue:value forKey:record.taskName];
            }
        }
    }
    NSMutableArray<MirrorReadModel *> *res = [NSMutableArray new];
    NSMutableArray<MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    for (int i=0 ;i<tasks.count; i++) { // 按照任务在mirror_task里的顺序
        MirrorTaskModel *task = tasks[i];
        if ([dict.allKeys containsObject:task.taskName]) { // 这个task在时间段内有数据
            MirrorReadModel *chartModel = [[MirrorReadModel alloc] initWithTask:task records:dict[task.taskName]];
            [res addObject:chartModel];
        }
    }
    return res;
}

// 生成 Grid 数据源，key 是 yyyy-MM-dd，value 是当天按任务顺序排列的 MirrorReadModel
// 它包含所有未隐藏 records （按照0点）拆分后的数据
/*
{
@"2026-01-02": @[
    MirrorReadModel(TaskA, TaskA 在这一天的 records),
    MirrorReadModel(TaskB, TaskB 在这一天的 records)
],
@"2026-01-03": @[
     MirrorReadModel(TaskB, TaskB 在这一天的 records),
     MirrorReadModel(TaskC, TaskC 在这一天的 records)
]
}
 */
+ (NSMutableDictionary<NSString*, NSMutableArray<MirrorReadModel *> *> *)getGridData
{
    NSMutableDictionary<NSString*, NSMutableArray<MirrorReadModel *> *> *gridData = [NSMutableDictionary<NSString*, NSMutableArray<MirrorReadModel *> *> new];
    
    NSMutableArray<MirrorTaskModel *> *allTasks = [MirrorStorage retriveMirrorTasks];
    NSMutableArray<MirrorRecordModel *> *rawRecords = [MirrorStorage p_retriveMirrorRecordsWithoutHidden];
    NSMutableArray<MirrorRecordModel *> *allRecords = [NSMutableArray new];
    for (MirrorRecordModel *record in rawRecords) {
        [allRecords addObjectsFromArray:[self daySegmentsForRecord:record clippedToStart:record.startTime end:record.endTime]];
    }
     
    if (allRecords.count == 0) return gridData;
    
    NSString *key = [self keyOfTime:allRecords[0].startTime];
    NSMutableArray<MirrorRecordModel *> *recordsInTimeOrder = [NSMutableArray new];
    for (int recordIndex=0; recordIndex<allRecords.count; recordIndex++) {
        MirrorRecordModel *record = allRecords[recordIndex];
        if (![[self keyOfTime:record.startTime] isEqualToString:key]) { // 下一天了
            // sort
            NSMutableArray<MirrorReadModel *> *oneday = [NSMutableArray new];
            for (int i=0; i<allTasks.count; i++) {
                NSMutableArray<MirrorRecordModel *> *recordsInTaskOrder = [NSMutableArray new];
                for (int j=0; j<recordsInTimeOrder.count; j++) {
                    if ([recordsInTimeOrder[j].taskName isEqualToString:allTasks[i].taskName]) {
                        [recordsInTaskOrder addObject:recordsInTimeOrder[j]];
                    }
                }
                if (recordsInTaskOrder.count != 0) {
                    MirrorReadModel *oneDayOneTask = [[MirrorReadModel alloc] initWithTask:allTasks[i] records:recordsInTaskOrder];
                    [oneday addObject:oneDayOneTask];
                }
            }
            // save
            [gridData setValue:oneday forKey:key];
            // next loop
            key = [self keyOfTime:record.startTime];
            recordsInTimeOrder = [NSMutableArray new];
            [recordsInTimeOrder addObject:record];
        } else { // 还在这一天
            [recordsInTimeOrder addObject:record];
        }
    }
    
    // sort
    NSMutableArray<MirrorReadModel *> *oneday = [NSMutableArray new];
    for (int i=0; i<allTasks.count; i++) {
        NSMutableArray<MirrorRecordModel *> *recordsInTaskOrder = [NSMutableArray new];
        for (int j=0; j<recordsInTimeOrder.count; j++) {
            if ([recordsInTimeOrder[j].taskName isEqualToString:allTasks[i].taskName]) {
                [recordsInTaskOrder addObject:recordsInTimeOrder[j]];
            }
        }
        if (recordsInTaskOrder.count != 0) {
            MirrorReadModel *oneDayOneTask = [[MirrorReadModel alloc] initWithTask:allTasks[i] records:recordsInTaskOrder];
            [oneday addObject:oneDayOneTask];
        }
    }
    // save
    [gridData setValue:oneday forKey:key];
    
    return gridData;
}


#pragma mark - Privates

// 把任意时间戳转成自然日 key；例如 2026-01-02 18:30 转成 “2026-01-02”，供 Grid 字典查找。
+ (NSString *)keyOfTime:(long)timestamp
{
    NSDate *originalDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:originalDate];
}

// 去掉 NSDate 的秒；例如 08:30:45 变为 08:30:00，保证用户添加/编辑记录时按分钟存储。
+ (NSDate *)dateWithoutSeconds:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth| NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute| NSCalendarUnitSecond fromDate:date];
    components.timeZone = [NSTimeZone systemTimeZone];
    components.second = 0;
    NSDate *dateWithoutSeconds = [gregorian dateFromComponents:components];
    return dateWithoutSeconds;
}

// 生成压力测试记录，不直接写库；例如把现有 records 往前复制 500 轮、每轮偏移 11 周，用来测试大数据量滚动/统计性能。
+ (NSMutableArray<MirrorRecordModel *> *)pressureTestRecords // 压力测试，让当前数据翻倍
{
    NSInteger times = 500; // 想让数据量翻多少倍
    NSInteger offset = 11; // 每个数据往前走多少周
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    NSMutableArray<MirrorRecordModel *> *fakeRecords = [NSMutableArray new];
    BOOL shouldBreak = NO;
    for (int i=0; i<times; i++) {
        NSMutableArray<MirrorRecordModel *> *newRecords = [NSMutableArray new];;
        for (int j=0; j<records.count; j++) {
            CGFloat startTime =records[j].startTime - offset*7*86400*i;
            CGFloat endTime = records[j].endTime - offset*7*86400*i;
            if (startTime<0 || endTime<0) {
                shouldBreak = YES;
                break;
            }
            MirrorRecordModel *newRecord = [[MirrorRecordModel alloc] initWithTitle:records[j].taskName startTime:startTime endTime:endTime];
            [newRecords addObject:newRecord];
        }
        if (shouldBreak) break;
        [fakeRecords insertObjects:newRecords atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, newRecords.count)]];
        NSLog(@"循环到了第%d轮, 已经生成了%lu条数据", i, (unsigned long)fakeRecords.count);
    }
    return fakeRecords;
}

// 调试另一种按天聚合的数据结构并打印；例如输出 {2026-01-02: {阅读: 3600, 工作: 7200}}，目前不参与正式功能。
+ (void)anotherDataStructureTest // 一种以某天0点时间为key的数据存储方式（字典存储），还没用在app里
{
    NSMutableDictionary<NSString *, NSMutableDictionary *> *data = [NSMutableDictionary new];

    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];

    for (int i=0; i<records.count; i++) {
        NSString *onedayKey = [MirrorStorage keyOfTime:records[i].startTime];
        if ([data.allKeys containsObject:onedayKey]) { //存过这天的records
            NSMutableDictionary *onedayValue = data[onedayKey];
            NSString *tasknameKey = records[i].taskName;
            if ([onedayValue.allKeys containsObject:tasknameKey]) { // 存过这天这个任务的时间
                NSInteger value = [data[onedayKey][tasknameKey] integerValue];
                value = value + (records[i].endTime - records[i].startTime);
                [onedayValue setValue:@(value) forKey:tasknameKey];
                [data setValue:onedayValue forKey:onedayKey];
            } else { // 没存过今天这个任务的时间
                [onedayValue setValue:@(records[i].endTime - records[i].startTime) forKey:tasknameKey];
                [data setValue:onedayValue forKey:onedayKey];
            }
        } else { // 没存过今天的records
            NSMutableDictionary *onedayValue = [NSMutableDictionary new];;
            [onedayValue setValue:@(records[i].endTime - records[i].startTime) forKey:records[i].taskName];
            [data setValue:onedayValue forKey:onedayKey];
        }
    }
    NSLog(@"%@", data);
}

@end
