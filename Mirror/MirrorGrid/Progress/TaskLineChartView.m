//
//  TaskLineChartView.m
//  Mirror
//

#import "TaskLineChartView.h"
#import "MirrorMacro.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorLanguage.h"
#import "MirrorTimeText.h"
#import "MirrorSettings.h"
#import <Masonry/Masonry.h>

static CGFloat const kLineChartTopInset = 10;
static CGFloat const kLineChartBottomInset = 0;
static CGFloat const kLineChartLeftInset = 0;
static CGFloat const kLineChartRightInset = 0;
static CGFloat const kLineChartRangeControlHeight = 30;
static CGFloat const kLineChartRangeControlSpacing = 6;

@interface TaskLineChartCanvasView : UIView

@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *data;
@property (nonatomic, strong) NSArray<NSString *> *dateKeys;
@property (nonatomic, assign) NSInteger selectedDateIndex;

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data dateKeys:(NSArray<NSString *> *)dateKeys;

@end

@interface TaskLineChartView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UISegmentedControl *rangeSegmentedControl;
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
        [self addSubview:self.rangeSegmentedControl];
        [self.rangeSegmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.mas_equalTo(self);
            make.height.mas_equalTo(kLineChartRangeControlHeight*kHeightRatio);
        }];
        [self addSubview:self.scrollView];
        [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.mas_equalTo(self);
            make.top.mas_equalTo(self.rangeSegmentedControl.mas_bottom).offset(kLineChartRangeControlSpacing*kHeightRatio);
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
    self.rangeSegmentedControl.selectedSegmentIndex = [MirrorSettings appliedChartRange];
    [self.canvasView updateWithData:data dateKeys:dateKeys];
    [self updateCanvasWidth];
}

- (void)chartRangeChanged:(UISegmentedControl *)sender
{
    [MirrorSettings saveChartRange:(MirrorChartRange)sender.selectedSegmentIndex];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (void)updateCanvasWidth
{
    CGFloat visibleWidth = CGRectGetWidth(self.scrollView.bounds);
    [self.canvasWidthConstraint setOffset:visibleWidth];
    self.scrollView.scrollEnabled = NO;
    [self.scrollView setContentOffset:CGPointZero animated:NO];
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
        self.selectedDateIndex = NSNotFound;
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;
}

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data dateKeys:(NSArray<NSString *> *)dateKeys
{
    self.data = data;
    self.dateKeys = dateKeys;
    if (self.selectedDateIndex >= dateKeys.count) {
        self.selectedDateIndex = NSNotFound;
    }
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
    [self drawSelectionInRect:plotRect secondsByTask:secondsByTask];
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

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    if (self.dateKeys.count == 0) {
        self.selectedDateIndex = NSNotFound;
        [self setNeedsDisplay];
        return;
    }
    CGRect plotRect = UIEdgeInsetsInsetRect(self.bounds, UIEdgeInsetsMake(kLineChartTopInset * kHeightRatio,
                                                                          kLineChartLeftInset * kWidthRatio,
                                                                          kLineChartBottomInset * kHeightRatio,
                                                                          kLineChartRightInset * kWidthRatio));
    CGPoint point = [recognizer locationInView:self];
    CGFloat step = self.dateKeys.count > 1 ? CGRectGetWidth(plotRect) / (self.dateKeys.count - 1) : 0;
    NSInteger nearestIndex = 0;
    CGFloat nearestDistance = CGFLOAT_MAX;
    for (NSInteger index = 0; index < self.dateKeys.count; index++) {
        CGFloat x = self.dateKeys.count > 1 ? CGRectGetMinX(plotRect) + step * index : CGRectGetMidX(plotRect);
        CGFloat distance = fabs(point.x - x);
        if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestIndex = index;
        }
    }
    self.selectedDateIndex = nearestIndex;
    [self setNeedsDisplay];
}

- (void)drawSelectionInRect:(CGRect)plotRect secondsByTask:(NSDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *)secondsByTask
{
    if (self.selectedDateIndex == NSNotFound || self.selectedDateIndex >= self.dateKeys.count) {
        return;
    }
    NSString *dateKey = self.dateKeys[self.selectedDateIndex];
    CGFloat step = self.dateKeys.count > 1 ? CGRectGetWidth(plotRect) / (self.dateKeys.count - 1) : 0;
    CGFloat x = self.dateKeys.count > 1 ? CGRectGetMinX(plotRect) + step * self.selectedDateIndex : CGRectGetMidX(plotRect);
    
    UIColor *lineColor = [[UIColor mirrorColorNamed:MirrorColorTypeTextHint] colorWithAlphaComponent:0.45];
    [lineColor setStroke];
    UIBezierPath *linePath = [UIBezierPath new];
    [linePath moveToPoint:CGPointMake(x, CGRectGetMinY(plotRect))];
    [linePath addLineToPoint:CGPointMake(x, CGRectGetMaxY(plotRect))];
    linePath.lineWidth = 0.5;
    [linePath stroke];
    
    NSArray<MirrorReadModel *> *summaryData = [self summaryDataForDateKey:dateKey secondsByTask:secondsByTask];
    [self drawSummaryTagWithDateKey:dateKey data:summaryData atX:x plotRect:plotRect];
}

- (NSArray<MirrorReadModel *> *)summaryDataForDateKey:(NSString *)dateKey secondsByTask:(NSDictionary<NSString *, NSDictionary<NSString *, NSNumber *> *> *)secondsByTask
{
    NSMutableArray<MirrorReadModel *> *summaryData = [NSMutableArray new];
    for (MirrorReadModel *readModel in self.data) {
        NSNumber *seconds = secondsByTask[readModel.taskModel.taskName][dateKey];
        if (seconds.longValue <= 0) {
            continue;
        }
        MirrorRecordModel *summaryRecord = [MirrorRecordModel new];
        summaryRecord.startTime = 0;
        summaryRecord.endTime = seconds.longValue;
        MirrorReadModel *summaryModel = [[MirrorReadModel alloc] initWithTask:readModel.taskModel records:[@[summaryRecord] mutableCopy]];
        [summaryData addObject:summaryModel];
    }
    return summaryData;
}

- (void)drawSummaryTagWithDateKey:(NSString *)dateKey data:(NSArray<MirrorReadModel *> *)summaryData atX:(CGFloat)x plotRect:(CGRect)plotRect
{
    CGFloat scale = kWidthRatio;
    CGFloat paddingX = 12 * scale;
    CGFloat paddingY = 9 * kHeightRatio;
    CGFloat rowHeight = 20 * kHeightRatio;
    CGFloat dotSize = 8 * scale;
    CGFloat dotTextSpacing = 10 * scale;
    CGFloat columnSpacing = 16 * scale;
    UIFont *titleFont = [UIFont mirrorLabelFont];
    UIFont *rowFont = [UIFont mirrorHintFont];
    UIColor *titleColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    UIColor *textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    NSString *title = [self titleTextForDateKey:dateKey];
    NSDictionary *titleAttributes = @{NSFontAttributeName: titleFont, NSForegroundColorAttributeName: titleColor};
    NSDictionary *rowAttributes = @{NSFontAttributeName: rowFont, NSForegroundColorAttributeName: textColor};
    CGFloat tagWidth = ceil([title sizeWithAttributes:titleAttributes].width) + 2 * paddingX;
    for (MirrorReadModel *readModel in summaryData) {
        NSString *name = readModel.taskModel.taskName ?: @"";
        NSString *time = [MirrorTimeText XdXhXmXsShort:readModel.records.firstObject.endTime];
        CGFloat rowWidth = dotSize + dotTextSpacing + ceil([name sizeWithAttributes:rowAttributes].width) + columnSpacing + ceil([time sizeWithAttributes:rowAttributes].width);
        tagWidth = MAX(tagWidth, rowWidth + 2 * paddingX);
    }
    CGRect visibleRect = [self visibleRectInCanvas];
    tagWidth = MIN(tagWidth, CGRectGetWidth(visibleRect) - 16 * scale);
    titleFont = [self font:titleFont fittingText:title maxWidth:tagWidth - 2 * paddingX minimumScale:0.72];
    titleAttributes = @{NSFontAttributeName: titleFont, NSForegroundColorAttributeName: titleColor};
    CGFloat tagHeight = paddingY * 2 + ceil(titleFont.lineHeight) + rowHeight * summaryData.count;
    CGFloat edgePadding = 8 * scale;
    CGFloat lineSpacing = 8 * scale;
    CGFloat availableLeftWidth = x - lineSpacing - CGRectGetMinX(visibleRect) - edgePadding;
    CGFloat availableRightWidth = CGRectGetMaxX(visibleRect) - x - lineSpacing - edgePadding;
    CGFloat tagX = availableRightWidth >= availableLeftWidth ? x + lineSpacing : x - lineSpacing - tagWidth;
    tagX = MIN(MAX(CGRectGetMinX(visibleRect) + edgePadding, tagX), CGRectGetMaxX(visibleRect) - tagWidth - edgePadding);
    CGFloat tagY = MAX(8 * kHeightRatio, CGRectGetMinY(plotRect) + 8 * kHeightRatio);
    CGRect tagRect = CGRectMake(tagX, tagY, tagWidth, tagHeight);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 2 * kHeightRatio), 8 * scale, [[UIColor blackColor] colorWithAlphaComponent:0.16].CGColor);
    UIBezierPath *backgroundPath = [UIBezierPath bezierPathWithRoundedRect:tagRect cornerRadius:7 * scale];
    [[UIColor mirrorColorNamed:MirrorColorTypeBackground] setFill];
    [backgroundPath fill];
    CGContextRestoreGState(context);
    
    [[UIColor colorWithWhite:0 alpha:0.12] setStroke];
    backgroundPath.lineWidth = 0.5;
    [backgroundPath stroke];
    
    CGRect titleRect = CGRectMake(CGRectGetMinX(tagRect) + paddingX,
                                  CGRectGetMinY(tagRect) + paddingY,
                                  tagWidth - 2 * paddingX,
                                  ceil(titleFont.lineHeight));
    [title drawInRect:titleRect withAttributes:titleAttributes];
    
    CGFloat rowY = CGRectGetMaxY(titleRect) + 5 * kHeightRatio;
    if (summaryData.count == 0) {
        return;
    }
    for (MirrorReadModel *readModel in summaryData) {
        CGFloat dotY = rowY + (rowHeight - dotSize) / 2;
        CGRect dotRect = CGRectMake(CGRectGetMinX(tagRect) + paddingX, dotY, dotSize, dotSize);
        UIBezierPath *dotPath = [UIBezierPath bezierPathWithRoundedRect:dotRect cornerRadius:3 * scale];
        [[UIColor mirrorColorNamed:readModel.taskModel.color] setFill];
        [dotPath fill];
        
        NSString *name = readModel.taskModel.taskName ?: @"";
        NSString *time = [MirrorTimeText XdXhXmXsShort:readModel.records.firstObject.endTime];
        CGFloat timeWidth = ceil([time sizeWithAttributes:rowAttributes].width);
        CGFloat textX = CGRectGetMaxX(dotRect) + dotTextSpacing;
        CGFloat timeX = CGRectGetMaxX(tagRect) - paddingX - timeWidth;
        [name drawInRect:CGRectMake(textX, rowY, MAX(0, timeX - textX - columnSpacing), rowHeight) withAttributes:rowAttributes];
        [time drawInRect:CGRectMake(timeX, rowY, timeWidth, rowHeight) withAttributes:rowAttributes];
        rowY += rowHeight;
    }
}

- (CGRect)visibleRectInCanvas
{
    if ([self.superview isKindOfClass:UIScrollView.class]) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        return CGRectMake(scrollView.contentOffset.x,
                          scrollView.contentOffset.y,
                          CGRectGetWidth(scrollView.bounds),
                          CGRectGetHeight(scrollView.bounds));
    }
    return self.bounds;
}

- (UIFont *)font:(UIFont *)font fittingText:(NSString *)text maxWidth:(CGFloat)maxWidth minimumScale:(CGFloat)minimumScale
{
    if (maxWidth <= 0 || text.length == 0) {
        return font;
    }
    CGFloat textWidth = [text sizeWithAttributes:@{NSFontAttributeName: font}].width;
    if (textWidth <= maxWidth) {
        return font;
    }
    CGFloat targetSize = MAX(font.pointSize * minimumScale, font.pointSize * maxWidth / textWidth);
    return [UIFont fontWithName:font.fontName size:targetSize] ?: [UIFont systemFontOfSize:targetSize];
}

- (NSString *)titleTextForDateKey:(NSString *)dateKey
{
    NSDate *date = [self dateFromKey:dateKey];
    if (!date) {
        return dateKey;
    }
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSDateComponents *components = [calendar components:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday fromDate:date];
    return [MirrorLanguage mirror_shortDateStringWithMonth:components.month day:components.day weekday:components.weekday];
}

- (NSDate *)dateFromKey:(NSString *)dateKey
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter dateFromString:dateKey];
}

@end
