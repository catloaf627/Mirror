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
#import <QuartzCore/QuartzCore.h>

@interface GridCollectionViewCell ()

@property (nonatomic, strong) CAGradientLayer *taskColorLayer;

@end

@implementation GridCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.taskColorLayer.frame = self.bounds;
    self.taskColorLayer.cornerRadius = self.layer.cornerRadius;
}

- (void)configWithData:(NSMutableArray<MirrorDataModel *> *)data isSelected:(BOOL)isSelected
{
    CGFloat alpha = 0;
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
    if (_totalTime>0*3600) alpha = 0.2; // 最浅为0.2，再浅就看不清了
    if (_totalTime>1*3600) alpha = 0.3;
    if (_totalTime>2*3600) alpha = 0.4;
    if (_totalTime>3*3600) alpha = 0.5;
    if (_totalTime>4*3600) alpha = 0.6;
    if (_totalTime>5*3600) alpha = 0.7;
    if (_totalTime>6*3600) alpha = 0.8;
    if (_totalTime>7*3600) alpha = 0.9;
    if (_totalTime>8*3600) alpha = 1.0; // 8小时以上即为最深色块
    
    if (_totalTime == 0) { // 无数据
        [self removeTaskColorLayer];
        self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    } else if (![MirrorSettings appliedHeatmap] && alpha != 0) {  // 彩色模式 & 有数据
        self.backgroundColor = [UIColor clearColor];
        [self applyTaskColors:taskColors taskTimes:taskTimes];
    } else if ([MirrorSettings appliedHeatmap] && alpha != 0) {  // 深浅模式 & 有数据
        [self removeTaskColorLayer];
        self.backgroundColor = [[UIColor mirrorColorNamed:[MirrorSettings preferredHeatmapColor]] colorWithAlphaComponent:alpha];
    }
    if (isSelected) {
        self.layer.borderColor = [UIColor mirrorColorNamed:MirrorColorTypeText].CGColor;
        self.layer.borderWidth = 2;
        self.layer.cornerRadius = 2;
    } else {
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 0;
        self.layer.cornerRadius = 2;
    }
}

- (void)applyTaskColors:(NSMutableArray<UIColor *> *)taskColors taskTimes:(NSMutableArray<NSNumber *> *)taskTimes
{
    if (taskColors.count == 0 || taskTimes.count == 0 || _totalTime == 0) {
        [self removeTaskColorLayer];
        return;
    }
    
    NSMutableArray *colors = [NSMutableArray array];
    NSMutableArray<NSNumber *> *locations = [NSMutableArray array];
    CGFloat currentLocation = 0;
    
    for (int i=0; i<taskColors.count; i++) {
        CGFloat nextLocation = currentLocation + taskTimes[i].doubleValue / (CGFloat)_totalTime;
        if (i == taskColors.count - 1) {
            nextLocation = 1;
        }
        
        [colors addObject:(id)taskColors[i].CGColor];
        [locations addObject:@(currentLocation)];
        [colors addObject:(id)taskColors[i].CGColor];
        [locations addObject:@(nextLocation)];
        
        currentLocation = nextLocation;
    }
    
    if (!self.taskColorLayer) {
        self.taskColorLayer = [CAGradientLayer layer];
        self.taskColorLayer.startPoint = CGPointMake(0.5, 0);
        self.taskColorLayer.endPoint = CGPointMake(0.5, 1);
        [self.layer insertSublayer:self.taskColorLayer atIndex:0];
    }
    
    self.taskColorLayer.frame = self.bounds;
    self.taskColorLayer.cornerRadius = self.layer.cornerRadius;
    self.taskColorLayer.colors = colors;
    self.taskColorLayer.locations = locations;
}

- (void)removeTaskColorLayer
{
    [self.taskColorLayer removeFromSuperlayer];
    self.taskColorLayer = nil;
}

@end
