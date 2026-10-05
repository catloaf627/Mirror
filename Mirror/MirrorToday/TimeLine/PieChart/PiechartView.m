//
//  PiechartView.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/9.
//

#import "PiechartView.h"
#import "MirrorTaskModel.h"
#import "MirrorStorage.h"
#import "SliceLayer.h"
#import "MirrorTool.h"
#import <Masonry/Masonry.h>
#import "MirrorMacro.h"
#import "MirrorTimeText.h"
#import "MirrorLanguage.h"
#import "UIColor+MirrorColor.h"

// https://blog.csdn.net/lerryteng/article/details/51564197

@interface PiechartView ()

@property (nonatomic, strong) NSMutableArray *sliceLayerArray;
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *data;
@property (nonatomic, assign) BOOL enableInteractive;

- (void)addSliceSeparatorsWithAngles:(NSArray<NSNumber *> *)angles width:(CGFloat)width;

@end

@implementation PiechartView

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data width:(CGFloat)width enableInteractive:(BOOL)enableInteractive
{
    self = [super init];
    if (self) {
        self.sliceLayerArray = @[].mutableCopy;
        self.data = data;
        self.enableInteractive = enableInteractive;
        self.textFontScale = 1.0;
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePieTap:)];
        [self addGestureRecognizer:tapRecognizer];
        [self drawPiechartWithWidth:(CGFloat)width];
    }
    return self;
}

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data width:(CGFloat)width enableInteractive:(BOOL)enableInteractive
{
    [[self.layer.sublayers copy] makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    self.sliceLayerArray = @[].mutableCopy;
    self.data = data;
    self.enableInteractive = enableInteractive;
    [self drawPiechartWithWidth:width];
}

- (void)drawPiechartWithWidth:(CGFloat)width
{
    CGFloat startAngle = 1.5 * M_PI; // 0点方向开始 角度范围将被限制在[1.5 * M_PI, 3.5 * M_PI]
    CGFloat endAngle = 0;
    NSMutableArray *percentages = [NSMutableArray new];
    NSMutableArray *colors = [NSMutableArray new];
    NSMutableArray *texts = [NSMutableArray new];
    long totalTime = 0;
    for (int i=0; i<self.data.count; i++) {
        MirrorReadModel *chartModel = self.data[i];
        [percentages addObject:@([MirrorTool getTotalTimeOfPeriods:chartModel.records])];
        totalTime = totalTime + [MirrorTool getTotalTimeOfPeriods:chartModel.records];
        colors[i] = @(chartModel.taskModel.color);
        NSString *hourText = [MirrorTimeText XdXhXmXsShort:[MirrorTool getTotalTimeOfPeriods:chartModel.records]];
        texts[i] = hourText;
    }

    for (int i=0; i<percentages.count; i++) {
        percentages[i] = totalTime ? @([percentages[i] doubleValue]/(double)totalTime) : @0;
        NSString *percentageText = [NSString stringWithFormat:@"%1.f%%", [percentages[i] floatValue]  * 100];
        texts[i] = self.showsOnlyPercentageText ? percentageText : [texts[i] stringByAppendingFormat:@"(%@)", percentageText];
    }
    NSMutableArray<NSNumber *> *separatorAngles = [NSMutableArray new];
    for (int i=0; i<percentages.count; i++) {
        CGFloat percentage = [percentages[i] floatValue];
        CGFloat angle = percentage * M_PI * 2;
        if (angle > 0) {
            [separatorAngles addObject:@(startAngle)];
        }
        endAngle = angle + startAngle;
        
        SliceLayer *sliceLayer = [[SliceLayer alloc] init];
        sliceLayer.startAngle = startAngle;
        sliceLayer.endAngle = endAngle;
        sliceLayer.radius = width/2;
        sliceLayer.centerPoint = CGPointMake(width/2, width/2);
        sliceLayer.pieWidth = width;
        sliceLayer.colorType = [colors[i] intValue];
        sliceLayer.text = texts[i];
        sliceLayer.tag = i;
        sliceLayer.showsOnlyPercentageText = self.showsOnlyPercentageText;
        sliceLayer.textFontScale = self.textFontScale;
        [sliceLayer create];
        [self.layer addSublayer:sliceLayer];
        [self.sliceLayerArray addObject:sliceLayer];

        startAngle = endAngle;
    }

    if (self.sliceLayerArray.count > 1) {
        [self addSliceSeparatorsWithAngles:separatorAngles width:width];
    }

}

- (void)addSliceSeparatorsWithAngles:(NSArray<NSNumber *> *)angles width:(CGFloat)width
{
    if (angles.count == 0) return;

    CGPoint centerPoint = CGPointMake(width/2, width/2);
    CGFloat radius = width/2;
    UIColor *separatorColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];

    UIBezierPath *separatorPath = [UIBezierPath bezierPath];
    for (NSNumber *angleNumber in angles) {
        CGFloat angle = [angleNumber doubleValue];
        CGPoint edgePoint = CGPointMake(centerPoint.x + cos(angle) * radius, centerPoint.y + sin(angle) * radius);
        [separatorPath moveToPoint:centerPoint];
        [separatorPath addLineToPoint:edgePoint];
    }

    CAShapeLayer *separatorLayer = [CAShapeLayer layer];
    separatorLayer.frame = CGRectMake(0, 0, width, width);
    separatorLayer.path = separatorPath.CGPath;
    separatorLayer.fillColor = UIColor.clearColor.CGColor;
    separatorLayer.strokeColor = separatorColor.CGColor;
    separatorLayer.lineWidth = 1;
    separatorLayer.lineCap = kCALineCapButt;
    [self.layer addSublayer:separatorLayer];

}

- (void)handlePieTap:(UITapGestureRecognizer *)recognizer
{
    if (!self.enableInteractive) return;
    CGPoint touchPoint = [recognizer locationInView:self];
    for (int i=0; i<self.sliceLayerArray.count; i++) {
        SliceLayer *slice = self.sliceLayerArray[i];
        if (CGPathContainsPoint(slice.path, 0, touchPoint, YES) && !slice.selected) {
            slice.selected = YES;
            [self.delegate highlightTaskname:self.data[slice.tag].taskModel.taskName];
        } else {
            slice.selected = NO;
            [self.delegate cancelHighlightTaskname:self.data[slice.tag].taskModel.taskName];
            [slice.textLayer removeFromSuperlayer];
        }
    }
}

@end
