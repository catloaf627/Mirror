//
//  SliceLayer.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/9.
//

#import "SliceLayer.h"

@implementation SliceLayer

- (void)create {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:_centerPoint];
    [path addArcWithCenter:_centerPoint radius:_radius startAngle:_startAngle endAngle:_endAngle clockwise:YES];
    [path closePath];
    self.path = path.CGPath;
    self.strokeColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG].CGColor;
    self.fillColor = [UIColor mirrorColorNamed:self.colorType].CGColor;
}
 
- (void)setSelected:(BOOL)selected {
    _selected = selected;
    CGPoint newCenterPoint = _centerPoint;
    if (selected) {
        CGFloat offset = self.pieWidth/20;
        newCenterPoint = CGPointMake(_centerPoint.x + cosf((_startAngle + _endAngle) / 2) * offset, _centerPoint.y + sinf((_startAngle + _endAngle) / 2) * offset);
        _textLayer = [CATextLayer layer];
        CGFloat x = newCenterPoint.x + cosf((_startAngle + _endAngle)/2) * (self.pieWidth/3);
        CGFloat y = newCenterPoint.y + sinf((_startAngle + _endAngle)/2) * (self.pieWidth/3);
        CGFloat w = self.showsOnlyPercentageText ? self.pieWidth * 0.7 : self.pieWidth/2;
        CGFloat h = self.showsOnlyPercentageText ? self.pieWidth/6 : self.pieWidth/10;
        _textLayer.frame = CGRectMake(x-w/2, y-h/2 , w, h);
        _textLayer.alignmentMode = kCAAlignmentCenter;
        _textLayer.string = self.text;
        _textLayer.fontSize = self.showsOnlyPercentageText ? h * 0.7 : h/2;
        _textLayer.foregroundColor = [UIColor mirrorColorPulsed:self.colorType].CGColor;
        _textLayer.contentsScale = [UIScreen mainScreen].scale; // 解决catextlayer文字模糊的问题
        [self.superlayer addSublayer:_textLayer]; // 添加在superlayer上，否则text会被slice切割
    }
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:newCenterPoint];
    [path addArcWithCenter:newCenterPoint radius:_radius startAngle:_startAngle endAngle:_endAngle clockwise:YES];
    [path closePath];
    self.path = path.CGPath;
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath = @"path";
    animation.toValue = path;
    animation.duration = 0.3;
    [self addAnimation:animation forKey:nil];
}


@end
