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
    self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    // remove all subviews
    NSArray *viewsToRemove = [self subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    // add new subviews
    for (id key in onedaydata.allKeys) {
        // point
        CGFloat percentage = [onedaydata[key] longValue] / (double)maxtime;
        UIView *point = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width/2-kLineWidth/2, (1-percentage)*self.frame.size.height-kLineWidth/2, kLineWidth, kLineWidth)];
        point.backgroundColor = [UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:key].color];
        point.layer.cornerRadius = kLineWidth/2;
        [self addSubview:point];
        // leftday line
        if (leftdaydata != nil) {
            CGFloat percentage_left = [leftdaydata[key] longValue] / (double)maxtime;
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(kLineWidth/2,kLineWidth/2)];
            [path addLineToPoint:CGPointMake(-self.frame.size.width+kLineWidth/2, (percentage*self.frame.size.height-percentage_left*self.frame.size.height)+kLineWidth/2)];
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
            UIBezierPath *path = [UIBezierPath bezierPath];
            [path moveToPoint:CGPointMake(kLineWidth/2,kLineWidth/2)];
            [path addLineToPoint:CGPointMake(self.frame.size.width+kLineWidth/2, (percentage*self.frame.size.height-percentage_right*self.frame.size.height)+kLineWidth/2)];
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
