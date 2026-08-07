//
//  HeartFooter.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/3.
//

#import "HeartFooter.h"
#import <Masonry/Masonry.h>
#import "SplitLineView.h"
#import "MirrorMacro.h"
#import "UIColor+MirrorColor.h"
#import "MirrorTaskModel.h"
#import "MirrorRecordModel.h"
#import "MirrorTimeText.h"
#import "MirrorStorage.h"

@interface HeartFooter ()

@property (nonatomic, strong) SplitLineView *splitView;

@end

@implementation HeartFooter

- (void)config
{
    [self addSubview:self.splitView];
    [self.splitView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(20);
        make.centerX.offset(0);
        make.width.mas_equalTo(kScreenWidth);
        make.height.mas_equalTo(10);
    }];
    UITapGestureRecognizer *jsonRecognizer = [UITapGestureRecognizer new];
    jsonRecognizer.numberOfTouchesRequired = 2;
    jsonRecognizer.numberOfTapsRequired = 11;
    [jsonRecognizer addTarget:self action:@selector(exportJson)];
    [self addGestureRecognizer:jsonRecognizer];
}

- (void)exportJson
{
    NSMutableArray<MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    NSNumber *secondsFromGMT = [MirrorStorage retriveSecondsFromGMT];
    NSMutableArray *jsontasks = [NSMutableArray new];
    NSMutableArray *jsonrecords = [NSMutableArray new];
    NSString *jsonSecondsFromGMT = [@"seconds from GMT: " stringByAppendingString:[secondsFromGMT stringValue]];
    for (int i=0; i<tasks.count; i++) {
        NSString *taskInfo = @"";
        taskInfo = [[taskInfo stringByAppendingString:@"TASK."] stringByAppendingString:[@(i)stringValue]] ;
        taskInfo = [[taskInfo stringByAppendingString:@", taskName = "] stringByAppendingString:tasks[i].taskName];
        taskInfo = [[taskInfo stringByAppendingString:@", color = "] stringByAppendingString:[@(tasks[i].color) stringValue]];
        taskInfo = [[taskInfo stringByAppendingString:@", isArchived = "] stringByAppendingString:[@(tasks[i].isArchived) stringValue]];
        taskInfo = [[taskInfo stringByAppendingString:@", isHidden = "] stringByAppendingString:[@(tasks[i].isHidden) stringValue]];
        taskInfo = [[taskInfo stringByAppendingString:@", createdTime = "] stringByAppendingString:[@(tasks[i].createdTime) stringValue]];
        // 给人读的时间转换 - 开始
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDate *createdDate = [NSDate dateWithTimeIntervalSince1970:tasks[i].createdTime];
        NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:createdDate];
        components.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[secondsFromGMT integerValue]];
        NSString *createdString = @"";
        createdString = [[createdString stringByAppendingString:[@(components.year) stringValue]] stringByAppendingString:@"."];
        createdString = [[createdString stringByAppendingString:[@(components.month) stringValue]] stringByAppendingString:@"."];
        createdString = [[createdString stringByAppendingString:[@(components.day) stringValue]] stringByAppendingString:@"-"];
        createdString = [[createdString stringByAppendingString:[@(components.hour) stringValue]] stringByAppendingString:@":"];
        createdString = [[createdString stringByAppendingString:[@(components.minute) stringValue]] stringByAppendingString:@":"];
        createdString = [createdString stringByAppendingString:[@(components.second) stringValue]];
        taskInfo = [[[taskInfo stringByAppendingString:@"("] stringByAppendingString:createdString] stringByAppendingString:@")"];
        // 给人读的时间转换 - 结束
        [jsontasks addObject:taskInfo];
    }
    for (int i=0; i<records.count; i++) {
        NSString *recordInfo = @"";
        recordInfo = [[recordInfo stringByAppendingString:@"RECORD."] stringByAppendingString:[@(i)stringValue]];
        recordInfo = [[recordInfo stringByAppendingString:@", taskName = "] stringByAppendingString:records[i].taskName];
        recordInfo = [[recordInfo stringByAppendingString:@", ["] stringByAppendingString:[@(records[i].startTime) stringValue]];
        recordInfo = [recordInfo stringByAppendingString:@", "];
        recordInfo = [[recordInfo stringByAppendingString:[@(records[i].endTime) stringValue]] stringByAppendingString:@"]"];
        // 给人读的时间转换 - 开始
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        // start string
        NSDate *startDate = [NSDate dateWithTimeIntervalSince1970:records[i].startTime];
        NSDateComponents *startComponents = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:startDate];
        startComponents.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[secondsFromGMT integerValue]];
        NSString *startString = @"";
        startString = [[startString stringByAppendingString:[@(startComponents.year) stringValue]] stringByAppendingString:@"."];
        startString = [[startString stringByAppendingString:[@(startComponents.month) stringValue]] stringByAppendingString:@"."];
        startString = [[startString stringByAppendingString:[@(startComponents.day) stringValue]] stringByAppendingString:@"-"];
        startString = [[startString stringByAppendingString:[@(startComponents.hour) stringValue]] stringByAppendingString:@":"];
        startString = [[startString stringByAppendingString:[@(startComponents.minute) stringValue]] stringByAppendingString:@":"];
        startString = [startString stringByAppendingString:[@(startComponents.second) stringValue]];
        // end string
        NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:records[i].endTime];
        NSDateComponents *endComponents = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:endDate];
        endComponents.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:[secondsFromGMT integerValue]];
        NSString *endString = @"";
        endString = [[endString stringByAppendingString:[@(endComponents.year) stringValue]] stringByAppendingString:@"."];
        endString = [[endString stringByAppendingString:[@(endComponents.month) stringValue]] stringByAppendingString:@"."];
        endString = [[endString stringByAppendingString:[@(endComponents.day) stringValue]] stringByAppendingString:@"-"];
        endString = [[endString stringByAppendingString:[@(endComponents.hour) stringValue]] stringByAppendingString:@":"];
        endString = [[endString stringByAppendingString:[@(endComponents.minute) stringValue]] stringByAppendingString:@":"];
        endString = [endString stringByAppendingString:[@(endComponents.second) stringValue]];
        // 给人读的时间转换 - 结束
        recordInfo = [[recordInfo stringByAppendingString:@", ["] stringByAppendingString:startString];
        recordInfo = [recordInfo stringByAppendingString:@", "];
        recordInfo = [[recordInfo stringByAppendingString:endString] stringByAppendingString:@"]"];
        [jsonrecords addObject:recordInfo];
    }
    
    NSData *jsondata = [NSJSONSerialization dataWithJSONObject:@[jsontasks, jsonrecords, jsonSecondsFromGMT] options:NSJSONWritingPrettyPrinted error:nil];
    // create url
    NSString *filename = @"mirror.json";
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:filename]];
    [jsondata writeToURL:url atomically:NO]; // 给data创建一个url：为了起名字
    NSArray *activityItems = @[url];
    UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    activityViewControntroller.excludedActivityTypes = @[];
    activityViewControntroller.popoverPresentationController.sourceView = self.delegate.view;
    activityViewControntroller.popoverPresentationController.sourceRect = CGRectMake(self.delegate.view.bounds.size.width/2, self.delegate.view.bounds.size.height/4, 0, 0);
    [self.delegate presentViewController:activityViewControntroller animated:true completion:nil];
}

- (SplitLineView *)splitView
{
    if (!_splitView) {
        _splitView = [[SplitLineView alloc] initWithImage:@"heart.fill" color:[UIColor mirrorColorNamed:MirrorColorTypeTextHint]];
    }
    return _splitView;
}

@end
