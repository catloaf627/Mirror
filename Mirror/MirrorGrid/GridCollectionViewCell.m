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

@interface GridCollectionViewCell ()

@property (nonatomic, strong) UIImageView *specialDayIconView;

@end

@implementation GridCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configWithData:(NSMutableArray<MirrorReadModel *> *)data day:(MirrorDayModel *)day isSelected:(BOOL)isSelected
{
    _totalTime = 0;
    NSMutableArray<NSNumber *> *taskTimes = [NSMutableArray array];
    NSMutableArray<UIColor *> *taskColors = [NSMutableArray array];
    NSMutableArray<UIColor *> *taskPulseColors = [NSMutableArray array];
    for (int i=0; i<data.count; i++) {
        long taskTime = [MirrorTool getTotalTimeOfPeriods:data[i].records];
        if (taskTime > 0) {
            [taskTimes addObject:@(taskTime)];
            [taskColors addObject:[UIColor mirrorColorNamed:data[i].taskModel.color]];
            [taskPulseColors addObject:[UIColor mirrorColorPulsed:data[i].taskModel.color]];
        }
        _totalTime = _totalTime + taskTime;
    }
    
    if (_totalTime == 0) { // 无数据
        self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    } else { // 有数据
        UIColor *mixedColor = [self mixedColorWithTaskColors:taskColors taskTimes:taskTimes];
        if ([MirrorSettings appliedHeatmap]) {
            CGFloat alpha = MIN(1.0, 0.2 + floor(_totalTime / 3600) * 0.1);
            UIColor *mixedPulseColor = [self mixedColorWithTaskColors:taskPulseColors taskTimes:taskTimes];
            mixedColor = [self colorByBlendingColor:mixedColor withColor:mixedPulseColor progress:0.1]; // 最大值（>8小时）使用的是混合了一点pulse的color，否则只用mixed_tasks_colors太浅了
            self.backgroundColor = [mixedColor colorWithAlphaComponent:alpha];
        } else {
            self.backgroundColor = [mixedColor colorWithAlphaComponent:1];
        }
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
    
    [self updateSpecialDayIconWithDay:day];
}

- (void)updateSpecialDayIconWithDay:(MirrorDayModel *)day
{
    if (day.icon.length == 0) {
        self.specialDayIconView.hidden = YES;
        self.specialDayIconView.image = nil;
        return;
    }
    
    UIImage *iconImage = [[UIImage systemImageNamed:day.icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (!iconImage) {
        iconImage = [[UIImage systemImageNamed:@"star.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    self.specialDayIconView.hidden = NO;
    self.specialDayIconView.image = iconImage;
    self.specialDayIconView.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
}

- (UIImageView *)specialDayIconView
{
    if (!_specialDayIconView) {
        _specialDayIconView = [UIImageView new];
        _specialDayIconView.contentMode = UIViewContentModeScaleAspectFit;
        _specialDayIconView.hidden = YES;
        [self.contentView addSubview:_specialDayIconView];
    }
    return _specialDayIconView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat iconSide = MIN(self.contentView.bounds.size.width, self.contentView.bounds.size.height) * 0.64;
    self.specialDayIconView.frame = CGRectMake((self.contentView.bounds.size.width - iconSide) / 2,
                                               (self.contentView.bounds.size.height - iconSide) / 2,
                                               iconSide,
                                               iconSide);
}

- (UIColor *)colorByBlendingColor:(UIColor *)fromColor withColor:(UIColor *)toColor progress:(CGFloat)progress
{
    CGFloat fromRed = 0;
    CGFloat fromGreen = 0;
    CGFloat fromBlue = 0;
    CGFloat fromAlpha = 0;
    CGFloat toRed = 0;
    CGFloat toGreen = 0;
    CGFloat toBlue = 0;
    CGFloat toAlpha = 0;
    if (![fromColor getRed:&fromRed green:&fromGreen blue:&fromBlue alpha:&fromAlpha] ||
        ![toColor getRed:&toRed green:&toGreen blue:&toBlue alpha:&toAlpha]) {
        return fromColor;
    }
    CGFloat clampedProgress = MIN(1.0, MAX(0, progress));
    return [UIColor colorWithRed:fromRed + (toRed - fromRed) * clampedProgress
                           green:fromGreen + (toGreen - fromGreen) * clampedProgress
                            blue:fromBlue + (toBlue - fromBlue) * clampedProgress
                           alpha:fromAlpha + (toAlpha - fromAlpha) * clampedProgress];
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
