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

static CGFloat const kLineWidth = 5;

@implementation LineChartCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCellWithOnedaydata:(NSMutableDictionary<NSString *, NSNumber *> *)onedaydata
                     leftdaydata:(NSMutableDictionary<NSString *, NSNumber *> *)leftdaydata
                    rightdaydata:(NSMutableDictionary<NSString *, NSNumber *> *)rightdaydata
                         maxtime:(long)maxtime
{
    self.backgroundColor = [UIColor clearColor];
    // remove all subviews
    NSArray *viewsToRemove = [self subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    if (maxtime <= 0) return;
    CGFloat drawableHeight = MAX(self.bounds.size.height - kLineWidth, 0);
    // add new subviews
    for (id key in onedaydata.allKeys) {
        // point
        CGFloat percentage = [onedaydata[key] longValue] / (double)maxtime;
        CGFloat pointCenterY = kLineWidth / 2 + (1 - percentage) * drawableHeight;
        UIView *point = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2-kLineWidth/2, pointCenterY-kLineWidth/2, kLineWidth, kLineWidth)];
        point.backgroundColor = [UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:key].color];
        point.layer.cornerRadius = kLineWidth/2;
        [self addSubview:point];
        // leftday line
        if (leftdaydata != nil) {
            CGFloat percentage_left = [leftdaydata[key] longValue] / (double)maxtime;
            CGFloat leftPointCenterY = kLineWidth / 2 + (1 - percentage_left) * drawableHeight;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(kLineWidth/2,kLineWidth/2)];
            [path addLineToPoint:CGPointMake(-self.bounds.size.width+kLineWidth/2, leftPointCenterY-pointCenterY+kLineWidth/2)];
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = [path CGPath];
            shapeLayer.strokeColor = [[UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:key].color] CGColor];
            shapeLayer.lineWidth = kLineWidth;
            shapeLayer.fillColor = [[UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:key].color] CGColor];
            [point.layer addSublayer:shapeLayer];
        }
        // rightday line
        if (rightdaydata != nil) {
            CGFloat percentage_right = [rightdaydata[key] longValue] / (double)maxtime;
            CGFloat rightPointCenterY = kLineWidth / 2 + (1 - percentage_right) * drawableHeight;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(kLineWidth/2,kLineWidth/2)];
            [path addLineToPoint:CGPointMake(self.bounds.size.width+kLineWidth/2, rightPointCenterY-pointCenterY+kLineWidth/2)];
            CAShapeLayer *shapeLayer = [CAShapeLayer layer];
            shapeLayer.path = [path CGPath];
            shapeLayer.strokeColor = [[UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:key].color] CGColor];
            shapeLayer.lineWidth = kLineWidth;
            shapeLayer.fillColor = [[UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:key].color] CGColor];
            [point.layer addSublayer:shapeLayer];
        }
    }
}

@end
