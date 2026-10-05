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
#import "MirrorSettings.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"

// https://blog.csdn.net/lerryteng/article/details/51564197

@interface PiechartView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *sliceLayerArray;
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *data;
@property (nonatomic, assign) BOOL enableInteractive;
@property (nonatomic, strong) UISegmentedControl *rangeSegmentedControl;
@property (nonatomic, assign) CGFloat pieWidth;
@property (nonatomic, assign) CGSize lastDrawBoundsSize;
@property (nonatomic, assign) BOOL rangeSelectionActive;

- (void)addSliceSeparatorsWithAngles:(NSArray<NSNumber *> *)angles width:(CGFloat)width;

@end

@implementation PiechartView

+ (CGFloat)rangeControlHeight
{
    return 30*kHeightRatio;
}

+ (CGFloat)rangeControlSpacing
{
    return 6*kHeightRatio;
}

+ (CGFloat)maximumPieWidthForAvailableWidth:(CGFloat)availableWidth
{
    return availableWidth;
}

+ (CGFloat)totalWidthForPieWidth:(CGFloat)pieWidth
{
    return pieWidth;
}

+ (CGFloat)totalHeightForPieWidth:(CGFloat)pieWidth
{
    return [self rangeControlHeight] + [self rangeControlSpacing] + pieWidth;
}

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data width:(CGFloat)width enableInteractive:(BOOL)enableInteractive
{
    self = [super init];
    if (self) {
        self.sliceLayerArray = @[].mutableCopy;
        self.data = data;
        self.enableInteractive = enableInteractive;
        self.textFontScale = 1.0;
        self.pieWidth = width;
        _rangeSelectionActive = YES;
        [self addSubview:self.rangeSegmentedControl];
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePieTap:)];
        tapRecognizer.delegate = self;
        [self addGestureRecognizer:tapRecognizer];
        [self drawPiechartWithWidth:(CGFloat)width];
    }
    return self;
}

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data width:(CGFloat)width enableInteractive:(BOOL)enableInteractive
{
    self.data = data;
    self.enableInteractive = enableInteractive;
    self.pieWidth = width;
    [self updateRangeSegmentSelection];
    [self redrawPiechartIfPossible];
}

- (void)setRangeSelectionActive:(BOOL)active
{
    _rangeSelectionActive = active;
    [self updateRangeSegmentSelection];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.rangeSegmentedControl.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), [PiechartView rangeControlHeight]);
    if (!CGSizeEqualToSize(self.lastDrawBoundsSize, self.bounds.size)) {
        [self redrawPiechartIfPossible];
    }
}

- (void)redrawPiechartIfPossible
{
    if (CGRectGetWidth(self.bounds) <= 0 || CGRectGetHeight(self.bounds) <= 0 || self.pieWidth <= 0) {
        return;
    }
    [[self.layer.sublayers copy] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CALayer * subLayer = obj;
        if (subLayer != self.rangeSegmentedControl.layer) {
            [subLayer removeFromSuperlayer];
        }
    }];
    self.sliceLayerArray = @[].mutableCopy;
    self.lastDrawBoundsSize = self.bounds.size;
    [self drawPiechartWithWidth:self.pieWidth];
}

- (void)drawPiechartWithWidth:(CGFloat)width
{
    CGFloat pieOriginX = MAX((CGRectGetWidth(self.bounds) - width) / 2.0, 0);
    CGFloat pieOriginY = [PiechartView rangeControlHeight] + [PiechartView rangeControlSpacing];
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
        sliceLayer.centerPoint = CGPointMake(pieOriginX + width/2, pieOriginY + width/2);
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

    CGFloat pieOriginX = MAX((CGRectGetWidth(self.bounds) - width) / 2.0, 0);
    CGFloat pieOriginY = [PiechartView rangeControlHeight] + [PiechartView rangeControlSpacing];
    CGPoint centerPoint = CGPointMake(pieOriginX + width/2, pieOriginY + width/2);
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
    separatorLayer.frame = CGRectMake(0, 0, [PiechartView totalWidthForPieWidth:width], [PiechartView totalHeightForPieWidth:width]);
    separatorLayer.path = separatorPath.CGPath;
    separatorLayer.fillColor = UIColor.clearColor.CGColor;
    separatorLayer.strokeColor = separatorColor.CGColor;
    separatorLayer.lineWidth = 1;
    separatorLayer.lineCap = kCALineCapButt;
    [self.layer addSublayer:separatorLayer];

}

- (void)chartRangeChanged:(UISegmentedControl *)sender
{
    _rangeSelectionActive = YES;
    [MirrorSettings saveChartRange:(MirrorChartRange)sender.selectedSegmentIndex];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (void)updateRangeSegmentSelection
{
    self.rangeSegmentedControl.selectedSegmentIndex = self.rangeSelectionActive ? [MirrorSettings appliedChartRange] : UISegmentedControlNoSegment;
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    UIView *view = touch.view;
    while (view) {
        if (view == self.rangeSegmentedControl) {
            return NO;
        }
        view = view.superview;
    }
    return YES;
}

- (UISegmentedControl *)rangeSegmentedControl
{
    if (!_rangeSegmentedControl) {
        _rangeSegmentedControl = [[UISegmentedControl alloc] initWithItems:[MirrorSettings chartRangeTitles]];
        _rangeSegmentedControl.selectedSegmentIndex = [MirrorSettings appliedChartRange];
        if (@available(iOS 13.0, *)) {
            _rangeSegmentedControl.selectedSegmentTintColor = [[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight] colorWithAlphaComponent:0.14];
        }
        [_rangeSegmentedControl setTitleTextAttributes:@{
            NSFontAttributeName: [UIFont mirrorHintFont],
            NSForegroundColorAttributeName: [UIColor mirrorColorNamed:MirrorColorTypeTextHint]
        } forState:UIControlStateNormal];
        [_rangeSegmentedControl setTitleTextAttributes:@{
            NSFontAttributeName: [UIFont mirrorHintFont],
            NSForegroundColorAttributeName: [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight]
        } forState:UIControlStateSelected];
        [_rangeSegmentedControl addTarget:self action:@selector(chartRangeChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _rangeSegmentedControl;
}

@end
