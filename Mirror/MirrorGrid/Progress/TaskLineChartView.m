//
//  TaskLineChartView.m
//  Mirror
//

#import "TaskLineChartView.h"
#import "MirrorMacro.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import <Masonry/Masonry.h>

static CGFloat const kLineChartTopInset = 10;
static CGFloat const kLineChartBottomInset = 0;
static CGFloat const kLineChartLeftInset = 0;
static CGFloat const kLineChartRightInset = 0;
static CGFloat const kLineChartMinimumDateWidth = 28;

@interface TaskLineChartCanvasView : UIView

@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *data;
@property (nonatomic, strong) NSArray<NSString *> *dateKeys;

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data dateKeys:(NSArray<NSString *> *)dateKeys;

@end

@interface TaskLineChartView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) TaskLineChartCanvasView *canvasView;
@property (nonatomic, strong) MASConstraint *canvasWidthConstraint;
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *data;
@property (nonatomic, strong) NSArray<NSString *> *dateKeys;

@end

@implementation TaskLineChartView

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data dateKeys:(NSArray<NSString *> *)dateKeys
{
    self = [super init];
    if (self) {
        self.data = data;
        self.dateKeys = dateKeys;
        self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        [self addSubview:self.scrollView];
        [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self);
        }];
        [self.scrollView addSubview:self.canvasView];
        [self.canvasView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self.scrollView);
            make.height.mas_equalTo(self.scrollView);
            self.canvasWidthConstraint = make.width.mas_equalTo(0);
        }];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateCanvasWidth];
}

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data dateKeys:(NSArray<NSString *> *)dateKeys
{
    self.data = data;
    self.dateKeys = dateKeys;
    [self.canvasView updateWithData:data dateKeys:dateKeys];
    [self updateCanvasWidth];
}

- (void)updateCanvasWidth
{
    CGFloat minimumWidth = CGRectGetWidth(self.bounds);
    CGFloat contentWidth = MAX(minimumWidth, self.dateKeys.count * kLineChartMinimumDateWidth * kWidthRatio + kLineChartLeftInset + kLineChartRightInset);
    [self.canvasWidthConstraint setOffset:contentWidth];
    self.scrollView.scrollEnabled = contentWidth > minimumWidth + 1;
    CGFloat maxOffsetX = MAX(0, contentWidth - minimumWidth);
    if (!self.scrollView.scrollEnabled || self.scrollView.contentOffset.x > maxOffsetX) {
        [self.scrollView setContentOffset:CGPointMake(maxOffsetX, 0) animated:NO];
    }
}

#pragma mark - Getters

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.alwaysBounceHorizontal = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
    }
    return _scrollView;
}

- (TaskLineChartCanvasView *)canvasView
{
    if (!_canvasView) {
        _canvasView = [TaskLineChartCanvasView new];
        [_canvasView updateWithData:self.data dateKeys:self.dateKeys];
    }
    return _canvasView;
}

@end

@implementation TaskLineChartCanvasView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
    }
    return self;
}

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data dateKeys:(NSArray<NSString *> *)dateKeys
{
    self.data = data;
    self.dateKeys = dateKeys;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (self.dateKeys.count == 0 || self.data.count == 0) {
        return;
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }
    CGRect plotRect = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(kLineChartTopInset * kHeightRatio,
                                                                          kLineChartLeftInset * kWidthRatio,
                                                                          kLineChartBottomInset * kHeightRatio,
                                                                          kLineChartRightInset * kWidthRatio));
    if (CGRectGetWidth(plotRect) <= 0 || CGRectGetHeight(plotRect) <= 0) {
        return;
    }
    NSDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *secondsByTask = [self secondsByTaskByDate];
    CGFloat maxHours = [self maxCeilingHoursWithSecondsByTask:secondsByTask];
    [self drawHourLinesInRect:plotRect maxHours:maxHours];
    for (MirrorReadModel *readModel in self.data) {
        NSDictionary<NSString *, NSNumber *> *secondsByDate = secondsByTask[readModel.taskModel.taskName];
        if (secondsByDate.count == 0) {
            continue;
        }
        NSArray<NSValue *> *points = [self pointsWithSecondsByDate:secondsByDate plotRect:plotRect maxHours:maxHours];
        if (points.count == 0) {
            continue;
        }
        UIColor *taskColor = [UIColor mirrorColorNamed:readModel.taskModel.color];
        UIBezierPath *wavePath = [self smoothPathWithPoints:points];
        UIBezierPath *areaPath = [wavePath copy];
        CGPoint lastPoint = [points.lastObject CGPointValue];
        CGPoint firstPoint = [points.firstObject CGPointValue];
        [areaPath addLineToPoint:CGPointMake(lastPoint.x, CGRectGetMaxY(plotRect))];
        [areaPath addLineToPoint:CGPointMake(firstPoint.x, CGRectGetMaxY(plotRect))];
        [areaPath closePath];
        [[taskColor colorWithAlphaComponent:0.5] setFill];
        [areaPath fill];
        [taskColor setStroke];
        wavePath.lineWidth = 1.5 * kWidthRatio;
        [wavePath stroke];
    }
}

- (NSDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *)secondsByTaskByDate
{
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *> *result = [NSMutableDictionary new];
    for (MirrorReadModel *readModel in self.data) {
        NSMutableDictionary<NSString *, NSNumber *> *secondsByDate = [NSMutableDictionary new];
        for (NSString *dateKey in self.dateKeys) {
            secondsByDate[dateKey] = @(0);
        }
        for (MirrorRecordModel *record in readModel.records) {
            [self addRecord:record toSecondsByDate:secondsByDate];
        }
        result[readModel.taskModel.taskName] = secondsByDate;
    }
    return result;
}

- (void)addRecord:(MirrorRecordModel *)record toSecondsByDate:(NSMutableDictionary<NSString *, NSNumber *> *)secondsByDate
{
    for (NSString *dateKey in self.dateKeys) {
        NSDate *date = [self dateFromKey:dateKey];
        if (!date) {
            continue;
        }
        NSCalendar *calendar = [NSCalendar currentCalendar];
        calendar.timeZone = [NSTimeZone systemTimeZone];
        NSDate *nextDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
        long dayStart = (long)[date timeIntervalSince1970];
        long dayEnd = (long)[nextDate timeIntervalSince1970];
        long overlapStart = MAX(record.startTime, dayStart);
        long overlapEnd = MIN(record.endTime, dayEnd);
        if (overlapEnd > overlapStart) {
            long existing = [secondsByDate[dateKey] longValue];
            secondsByDate[dateKey] = @(existing + overlapEnd - overlapStart);
        }
    }
}

- (CGFloat)maxCeilingHoursWithSecondsByTask:(NSDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *)secondsByTask
{
    CGFloat maxHours = 0;
    for (NSDictionary<NSString *, NSNumber *> *secondsByDate in secondsByTask.allValues) {
        for (NSNumber *seconds in secondsByDate.allValues) {
            maxHours = MAX(maxHours, seconds.doubleValue / 3600.0);
        }
    }
    return MAX(1, ceil(maxHours));
}

- (NSArray<NSValue *> *)pointsWithSecondsByDate:(NSDictionary<NSString *, NSNumber *> *)secondsByDate plotRect:(CGRect)plotRect maxHours:(CGFloat)maxHours
{
    NSMutableArray<NSValue *> *points = [NSMutableArray new];
    CGFloat step = self.dateKeys.count > 1 ? CGRectGetWidth(plotRect) / (self.dateKeys.count - 1) : 0;
    for (NSInteger index = 0; index < self.dateKeys.count; index++) {
        NSString *dateKey = self.dateKeys[index];
        CGFloat hours = [secondsByDate[dateKey] doubleValue] / 3600.0;
        CGFloat normalized = maxHours > 0 ? MIN(1, MAX(0, hours / maxHours)) : 0;
        CGFloat x = self.dateKeys.count > 1 ? CGRectGetMinX(plotRect) + step * index : CGRectGetMidX(plotRect);
        CGFloat y = CGRectGetMaxY(plotRect) - CGRectGetHeight(plotRect) * normalized;
        [points addObject:[NSValue valueWithCGPoint:CGPointMake(x, y)]];
    }
    return points;
}

- (UIBezierPath *)smoothPathWithPoints:(NSArray<NSValue *> *)points
{
    UIBezierPath *path = [UIBezierPath new];
    CGPoint firstPoint = [points.firstObject CGPointValue];
    [path moveToPoint:firstPoint];
    if (points.count == 1) {
        return path;
    }
    for (NSInteger index = 0; index < points.count - 1; index++) {
        CGPoint previousPoint = index > 0 ? [points[index - 1] CGPointValue] : [points[index] CGPointValue];
        CGPoint currentPoint = [points[index] CGPointValue];
        CGPoint nextPoint = [points[index + 1] CGPointValue];
        CGPoint afterNextPoint = index + 2 < points.count ? [points[index + 2] CGPointValue] : nextPoint;
        CGFloat tension = 0.35;
        CGPoint controlPoint1 = CGPointMake(currentPoint.x + (nextPoint.x - previousPoint.x) * tension / 3.0,
                                            currentPoint.y + (nextPoint.y - previousPoint.y) * tension / 3.0);
        CGPoint controlPoint2 = CGPointMake(nextPoint.x - (afterNextPoint.x - currentPoint.x) * tension / 3.0,
                                            nextPoint.y - (afterNextPoint.y - currentPoint.y) * tension / 3.0);
        [path addCurveToPoint:nextPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    }
    return path;
}

- (void)drawHourLinesInRect:(CGRect)plotRect maxHours:(CGFloat)maxHours
{
    if (maxHours <= 0) {
        return;
    }
    UIColor *lineColor = [[UIColor mirrorColorNamed:MirrorColorTypeTextHint] colorWithAlphaComponent:0.16];
    [lineColor setStroke];
    NSInteger lineCount = MIN((NSInteger)maxHours, 6);
    for (NSInteger index = 0; index <= lineCount; index++) {
        CGFloat normalized = lineCount > 0 ? index / (CGFloat)lineCount : 0;
        CGFloat y = CGRectGetMaxY(plotRect) - CGRectGetHeight(plotRect) * normalized;
        UIBezierPath *linePath = [UIBezierPath new];
        [linePath moveToPoint:CGPointMake(CGRectGetMinX(plotRect), y)];
        [linePath addLineToPoint:CGPointMake(CGRectGetMaxX(plotRect), y)];
        linePath.lineWidth = 0.5;
        [linePath stroke];
    }
}

- (NSDate *)dateFromKey:(NSString *)dateKey
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter dateFromString:dateKey];
}

@end
