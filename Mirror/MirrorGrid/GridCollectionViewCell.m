//
//  GridCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/2.
//

#import "GridCollectionViewCell.h"
#import "MirrorTool.h"
#import "UIColor+MirrorColor.h"
#import "MirrorSettings.h"

@implementation GridCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configWithData:(NSMutableArray<MirrorReadModel *> *)data isSelected:(BOOL)isSelected
{
    _totalTime = 0;
    NSMutableArray<NSNumber *> *taskTimes = [NSMutableArray array];
    NSMutableArray<UIColor *> *taskColors = [NSMutableArray array];
    for (int i=0; i<data.count; i++) {
        long taskTime = [MirrorTool getTotalTimeOfPeriods:data[i].records];
        if (taskTime > 0) {
            [taskTimes addObject:@(taskTime)];
            [taskColors addObject:[UIColor mirrorColorNamed:data[i].taskModel.color]];
        }
        _totalTime = _totalTime + taskTime;
    }
    
    if (_totalTime == 0) { // 无数据
        self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    } else { // 有数据
        CGFloat alpha = [MirrorSettings appliedHeatmap] ? MIN(1.0, 0.2 + floor(_totalTime / 3600) * 0.1) : 1;
        self.backgroundColor = [[self mixedColorWithTaskColors:taskColors taskTimes:taskTimes] colorWithAlphaComponent: alpha];
    }
    if (isSelected) {
        self.layer.borderColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint].CGColor;
        self.layer.borderWidth = 2;
        self.layer.cornerRadius = 2;
    } else {
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 0;
        self.layer.cornerRadius = 2;
    }
}

- (UIColor *)mixedColorWithTaskColors:(NSMutableArray<UIColor *> *)taskColors taskTimes:(NSMutableArray<NSNumber *> *)taskTimes
{
    if (taskColors.count == 0 || taskTimes.count == 0 || _totalTime == 0) {
        return [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    }
    
    CGFloat mixedRed = 0;
    CGFloat mixedGreen = 0;
    CGFloat mixedBlue = 0;
    CGFloat mixedAlpha = 0;
    
    for (int i=0; i<taskColors.count; i++) {
        CGFloat red = 0;
        CGFloat green = 0;
        CGFloat blue = 0;
        CGFloat colorAlpha = 0;
        if (![taskColors[i] getRed:&red green:&green blue:&blue alpha:&colorAlpha]) {
            return taskColors.firstObject;
        }
        
        CGFloat weight = taskTimes[i].doubleValue / (CGFloat)_totalTime;
        mixedRed += red * weight;
        mixedGreen += green * weight;
        mixedBlue += blue * weight;
        mixedAlpha += colorAlpha * weight;
    }
    
    return [UIColor colorWithRed:mixedRed green:mixedGreen blue:mixedBlue alpha:mixedAlpha];
}

@end
