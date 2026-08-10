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
    for (id key in onedaydata.allKeys) {
        CGFloat percentage = [onedaydata[key] longValue] / (double)maxtime;
        if (percentage <= 0) continue;
        
        CGFloat barHeight = MAX(kMinimumVisibleBarHeight, percentage * drawableHeight);
        CGFloat barX = (self.bounds.size.width - kBarWidth) / 2;
        CGFloat barY = kBarWidth / 2 + drawableHeight - barHeight;
        
        UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(barX, barY, kBarWidth, barHeight)];
        bar.backgroundColor = [UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:key].color];
        bar.alpha = 0.55;
        bar.layer.cornerRadius = kBarWidth / 2;
        [self.contentView addSubview:bar];
    }
}

@end
