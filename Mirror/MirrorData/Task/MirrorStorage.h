//
//  MirrorStorage.h
//  Mirror
//
//  Created by Yuqing Wang on 2022/10/24.
//

#import <Foundation/Foundation.h>
#import "MirrorReadModel.h"
#import "MirrorDayModel.h"
#import "MirrorScheduleModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TaskNameExistsType) {
    TaskNameExistsTypeValid, // 库里没有这个taskname，taskname合格
    TaskNameExistsTypeExistsInCurrentTasks,
};

@interface MirrorStorage : NSObject

// TimeVC用

+ (NSString *)isGoingOnTask; // 返回为空意味着没有正在进行的task

+ (NSDate * _Nullable)goingOnTaskStartDate;

+ (NSDate * _Nullable)goingOnTaskAccurateStartDate;

+ (NSDate * _Nullable)goingOnTaskMaximumEndDate;

+ (NSString *)goingOnTaskNote;

+ (void)saveGoingOnTaskNote:(NSString *)note;

+ (NSMutableArray<MirrorTaskModel *> *)tasksWithAddNew;

// Actions

+ (void)createTask:(MirrorTaskModel *)task;

+ (void)deleteTask:(NSString *)taskName;

+ (void)mergeTask:(NSString *)sourceTaskName toTask:(NSString *)targetTaskName;

+ (void)mergeTask:(NSString *)sourceTaskName toTask:(NSString *)targetTaskName shouldPrefixRecordNotes:(BOOL)shouldPrefixRecordNotes;

+ (void)switchHiddenTask:(NSString *)taskName;

+ (void)editTask:(NSString *)oldName name:(NSString *)newName;

+ (void)editTask:(NSString *)taskName color:(MirrorColorType)color;

+ (void)reorderTasks:(NSMutableArray <MirrorTaskModel *> *)taskArray;

+ (void)insertPeriodWithTaskname:(NSString *)taskName startAt:(NSDate *)startDate endAt:(NSDate *)endDate;

+ (BOOL)createSchedule:(MirrorScheduleModel *)schedule;

+ (void)editSchedule:(MirrorScheduleModel *)schedule scheduleIndex:(NSInteger)index;

+ (void)deleteScheduleAtIndex:(NSInteger)index;

+ (void)startTask:(NSString *)taskName at:(NSDate *)accurateDate;

+ (void)stopTask:(NSString *)taskName at:(NSDate *)accurateDate;

+ (void)cancelGoingOnTask;

+ (NSDictionary * _Nullable)finishGoingOnTaskIfExceededMaximumEndDate;

+ (void)resumeGoingOnLiveActivityIfNeeded;

+ (TaskNameExistsType)taskNameExists:(NSString *)newTaskName;

// Period

+ (void)deletePeriodAtIndex:(NSInteger)index;

+ (void)editPeriodIsStartTime:(BOOL)isStartTime to:(long)timestamp periodIndex:(NSInteger)index;

+ (void)editPeriodStartTime:(long)startTimestamp endTime:(long)endTimestamp periodIndex:(NSInteger)index;

+ (void)editPeriodTaskName:(NSString *)taskName periodIndex:(NSInteger)index;

+ (void)editPeriodWithRecord:(MirrorRecordModel *)record periodIndex:(NSInteger)index;

+ (void)editPeriodNote:(NSString *)note periodIndex:(NSInteger)index;

// Retrive
+ (NSMutableArray<MirrorTaskModel *> *)retriveMirrorTasks;

+ (NSMutableArray<MirrorRecordModel *> *)retriveMirrorRecords;

+ (NSMutableArray<MirrorScheduleModel *> *)retriveMirrorSchedules;

+ (NSMutableArray<MirrorDayModel *> *)retriveMirrorDays;

+ (void)saveMirrorDays:(NSMutableArray<MirrorDayModel *> *)days;

+ (void)createMirrorDay:(MirrorDayModel *)day;

+ (void)editMirrorDay:(MirrorDayModel *)day atIndex:(NSInteger)index;

+ (void)deleteMirrorDayAtIndex:(NSInteger)index;

+ (NSNumber *)retriveSecondsFromGMT;

+ (void)saveSecondsFromGMT:(NSNumber *)secondFromGMT;

+ (NSData * _Nullable)exportJSONData;

+ (BOOL)canImportJSONData:(NSData *)data;

+ (BOOL)importJSONData:(NSData *)data;

+ (NSNumber * _Nullable)iCloudTaskCount;

+ (NSNumber * _Nullable)iCloudRecordCount;

+ (NSNumber * _Nullable)iCloudDayCount;

+ (BOOL)importDataFromICloud;

+ (void)replaceAllDataWithTasks:(NSMutableArray<MirrorTaskModel *> *)tasks records:(NSMutableArray<MirrorRecordModel *> *)records secondsFromGMT:(NSNumber *)secondsFromGMT;

+ (void)replaceAllDataWithTasks:(NSMutableArray<MirrorTaskModel *> *)tasks records:(NSMutableArray<MirrorRecordModel *> *)records days:(NSMutableArray<MirrorDayModel *> *)days secondsFromGMT:(NSNumber *)secondsFromGMT;

/*
 取出一个taskmodel
 {英语, 未归档, 粉色, 2023年5月1日创建}
 适用场景：想要得到归档信息、颜色信息、创建日期
 */
+ (MirrorTaskModel *)getTaskModelFromDB:(NSString *)taskName;

/*
 取出【某任务】从古至今的所有records
 {originalIndex, 🌸, 05:00, 06:00}, {originalIndex, 🌸, 08:00, 09:00}, {originalIndex, 🌸, 11:00, 12:00}...
 适用场景：某任务totaltime、某任务所有records页面
 */
+ (NSMutableArray<MirrorRecordModel *> *)getAllTaskRecords:(NSString *)taskName;

/*
 取出今天【所有任务】所有records，按照时间顺序
 {originalIndex, 🌸, 05:00, 06:00}, {originalIndex, 🪀, 06:00, 07:00}, {originalIndex, 🌸, 07:00, 08:00}..
 适用场景：目前只有today的record展示用到这个方法
 */
+ (NSMutableArray<MirrorRecordModel *> *)getTodayData;

+ (NSMutableArray<MirrorRecordModel *> *)getOneDayDataForDate:(NSDate *)date;

+ (NSMutableArray<MirrorScheduleModel *> *)getOneDaySchedulesForDate:(NSDate *)date;

/*
 取出【所有任务】从【某时间】到【某时间】的所有records，并按照优先级排序 （如顺序为🪀、🌸）
 【🪀, {originalIndex, 🪀, 06:00, 07:00}】  【🌸, {originalIndex, 🌸, 05:00, 06:00},
                                                  {originalIndex, 🌸, 07:00, 08:00}..】
 适用场景：饼图，柱形图，legend
 */
+ (NSMutableArray<MirrorReadModel *> *)getAllRecordsInTaskOrderWithStart:(long)startTime end:(long)endTime shouldHideHidden:(BOOL)shouldHideHidden;

/*
 取出【所有任务】的所有records，并按照天来切割、并且在一天的范围内按照优先级排序（🪀、🌸、👾），切割好后通过日期字符串作为key来存储（yyyy-MM-dd）
 2023-05-01 =  【🪀, {originalIndex, 🪀, 06:00, 07:00}】  【🌸, {originalIndex, 🌸, 05:00, 06:00},
                                                                {originalIndex, 🌸, 07:00, 08:00}..】
 2023-05-02 =  【🪀, {originalIndex, 🪀, 06:00, 07:00}】  【🌸, {originalIndex, 🌸, 05:00, 06:00},    【👾, {originalIndex, 👾, 05:00, 06:00}
                                                                {originalIndex, 🌸, 07:00, 08:00}..】       {originalIndex, 👾, 09:00, 10:00}
                                                                                                            {originalIndex, 👾, 11:00, 12:00}..】
 适用场景：Grid vc
 */
+ (NSMutableDictionary<NSString*, NSMutableArray<MirrorReadModel *> *> *)getGridData;

@end

NS_ASSUME_NONNULL_END
