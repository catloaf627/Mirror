//
//  LineChartCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2024/3/6.
//

#import "LineChartCollectionViewCell.h"
#import "MirrorStorage.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>

static CGFloat const kBarWidth = 5;
static CGFloat const kMinimumVisibleBarHeight = 2;

@implementation LineChartCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCellWithOnedaydata:(NSMutableDictionary<NSString *, NSNumber *> *)onedaydata
                         maxtime:(long)maxtime
{
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    NSArray *viewsToRemove = [self.contentView subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    if (maxtime <= 0) return;
    
    CGFloat drawableHeight = MAX(self.bounds.size.height - kBarWidth, 0);
    CGFloat accumulatedHeight = 0;
    NSArray<NSString *> *taskNames = [onedaydata.allKeys sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
    NSMutableArray<NSString *> *visibleTaskNames = [NSMutableArray new];
    for (NSString *taskName in taskNames) {
        if ([onedaydata[taskName] longValue] > 0) {
            [visibleTaskNames addObject:taskName];
        }
    }
    
    for (NSInteger index = 0; index < visibleTaskNames.count; index++) {
        NSString *taskName = visibleTaskNames[index];
        CGFloat percentage = [onedaydata[taskName] longValue] / (double)maxtime;
        
        CGFloat barHeight = MAX(kMinimumVisibleBarHeight, percentage * drawableHeight);
        barHeight = MIN(barHeight, drawableHeight - accumulatedHeight);
        if (barHeight <= 0) break;
        
        CGFloat barX = (self.bounds.size.width - kBarWidth) / 2;
        CGFloat barY = kBarWidth / 2 + drawableHeight - accumulatedHeight - barHeight;
        
        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(barX, barY, kBarWidth, barHeight)];
        bar.backgroundColor = [UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:taskName].color];
        bar.layer.cornerRadius = kBarWidth / 2;
        bar.layer.masksToBounds = YES;
        
        CACornerMask maskedCorners = 0;
        if (index == 0) {
            maskedCorners |= kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
        }
        if (index == visibleTaskNames.count - 1) {
            maskedCorners |= kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
        }
        bar.layer.maskedCorners = maskedCorners;
        
        [self.contentView addSubview:bar];
        accumulatedHeight += barHeight;
    }
}

@end
