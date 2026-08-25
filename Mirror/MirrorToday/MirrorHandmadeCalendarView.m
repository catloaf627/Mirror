//
//  MirrorHandmadeCalendarView.m
//  Mirror
//
//  A standalone handmade calendar view.
//

#import <UIKit/UIKit.h>
#import "MirrorSettings.h"
#import "MirrorTool.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorLanguage.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MirrorHandmadeCalendarDateHandler)(NSDate *date);

@interface MirrorHandmadeCalendarView : UIView

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, copy, nullable) MirrorHandmadeCalendarDateHandler dateSelectionHandler;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<UIColor *> *> *recordColorsByDateKey;
@property (nonatomic, copy) NSDictionary<NSString *, UIColor *> *specialDayColorsByDateKey;
@property (nonatomic, assign) BOOL weekStartsOnMonday;

- (instancetype)initWithSelectedDate:(NSDate *)selectedDate;
- (void)reloadCalendar;

@end

@interface MirrorHandmadeCalendarDayCell : UIControl

@property (nonatomic, strong, nullable) NSDate *date;
@property (nonatomic, copy) NSString *dateKey;
@property (nonatomic, assign) BOOL inVisibleMonth;
@property (nonatomic, assign) BOOL showsToday;
@property (nonatomic, assign) BOOL showsSelectedDate;
@property (nonatomic, strong, nullable) UIColor *specialDayColor;
@property (nonatomic, copy) NSArray<UIColor *> *recordColors;

- (void)setDayText:(NSString *)dayText;

@end

@implementation MirrorHandmadeCalendarDayCell {
    UILabel *_dayLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        _recordColors = @[];
        _dayLabel = [UILabel new];
        _dayLabel.textAlignment = NSTextAlignmentCenter;
        _dayLabel.font = [UIFont mirrorHintFont];
        [self addSubview:_dayLabel];
    }
    return self;
}

- (void)setDayText:(NSString *)dayText
{
    _dayLabel.text = dayText;
}

- (void)setInVisibleMonth:(BOOL)inVisibleMonth
{
    _inVisibleMonth = inVisibleMonth;
    [self updateTextColor];
}

- (void)setShowsToday:(BOOL)showsToday
{
    _showsToday = showsToday;
    [self setNeedsDisplay];
}

- (void)setShowsSelectedDate:(BOOL)showsSelectedDate
{
    _showsSelectedDate = showsSelectedDate;
    [self updateTextColor];
    [self setNeedsDisplay];
}

- (void)setSpecialDayColor:(nullable UIColor *)specialDayColor
{
    _specialDayColor = specialDayColor;
    [self setNeedsDisplay];
}

- (void)setRecordColors:(NSArray<UIColor *> *)recordColors
{
    if (![recordColors isKindOfClass:NSArray.class]) {
        _recordColors = @[];
        [self setNeedsDisplay];
        return;
    }

    NSMutableArray<UIColor *> *validColors = [NSMutableArray new];
    for (id color in recordColors) {
        if ([color isKindOfClass:UIColor.class]) {
            [validColors addObject:color];
        }
    }
    _recordColors = validColors;
    [self setNeedsDisplay];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat labelSide = MAX(0, MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)) * 0.58);
    _dayLabel.frame = CGRectMake((CGRectGetWidth(self.bounds) - labelSide) / 2.0,
                                 4,
                                 labelSide,
                                 labelSide);
    _dayLabel.layer.cornerRadius = labelSide / 2.0;
    _dayLabel.layer.masksToBounds = YES;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }

    if (self.showsToday && !self.showsSelectedDate) {
        CGRect todayRect = CGRectInset(_dayLabel.frame, 1.5, 1.5);
        if (CGRectGetWidth(todayRect) > 0 && CGRectGetHeight(todayRect) > 0) {
            CGContextSetStrokeColorWithColor(context, [UIColor mirrorColorNamed:MirrorColorTypeText].CGColor);
            CGContextSetLineWidth(context, 1.0);
            CGContextStrokeEllipseInRect(context, todayRect);
        }
    }

    CGFloat decorationY = CGRectGetMaxY(_dayLabel.frame) + 4;
    if (self.specialDayColor) {
        CGFloat side = 6;
        CGRect dotRect = CGRectMake((CGRectGetWidth(self.bounds) - side) / 2.0, decorationY, side, side);
        CGContextSetFillColorWithColor(context, self.specialDayColor.CGColor);
        CGContextFillEllipseInRect(context, dotRect);
        return;
    }

    if (self.recordColors.count == 0) {
        return;
    }

    CGFloat barHeight = 5;
    CGFloat barWidth = MIN(28, CGRectGetWidth(self.bounds) - 10);
    if (barWidth <= 0 || CGRectGetHeight(self.bounds) <= decorationY) {
        return;
    }
    CGRect barRect = CGRectMake((CGRectGetWidth(self.bounds) - barWidth) / 2.0, decorationY, barWidth, barHeight);
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRoundedRect:barRect cornerRadius:barHeight / 2.0];
    CGContextSaveGState(context);
    [clipPath addClip];

    CGFloat segmentWidth = barWidth / MAX(self.recordColors.count, 1);
    [self.recordColors enumerateObjectsUsingBlock:^(UIColor *color, NSUInteger index, BOOL *stop) {
        if (![color isKindOfClass:UIColor.class]) {
            return;
        }
        CGRect segmentRect = CGRectMake(CGRectGetMinX(barRect) + segmentWidth * index,
                                        CGRectGetMinY(barRect),
                                        index == self.recordColors.count - 1 ? CGRectGetMaxX(barRect) - (CGRectGetMinX(barRect) + segmentWidth * index) : segmentWidth,
                                        barHeight);
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, segmentRect);
    }];
    CGContextRestoreGState(context);
}

- (void)updateTextColor
{
    UIColor *baseColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    _dayLabel.textColor = self.inVisibleMonth ? baseColor : [baseColor colorWithAlphaComponent:0.28];
    _dayLabel.backgroundColor = self.showsSelectedDate ? baseColor : UIColor.clearColor;
    if (self.showsSelectedDate) {
        _dayLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    }
}

@end

@implementation MirrorHandmadeCalendarView {
    UIView *_headerView;
    UIButton *_previousMonthButton;
    UIButton *_nextMonthButton;
    UILabel *_monthLabel;
    UIStackView *_weekdayStackView;
    UIView *_daysContainerView;
    NSArray<MirrorHandmadeCalendarDayCell *> *_dayCells;
    NSDate *_visibleMonthDate;
    NSCalendar *_calendar;
    NSDateFormatter *_monthFormatter;
    NSDateFormatter *_dateKeyFormatter;
}

- (instancetype)initWithSelectedDate:(NSDate *)selectedDate
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _selectedDate = selectedDate ?: [NSDate now];
        _visibleMonthDate = _selectedDate;
        _weekStartsOnMonday = [MirrorSettings appliedWeekStarsOnMonday];
        _recordColorsByDateKey = @{};
        _specialDayColorsByDateKey = @{};
        [self setupCalendarHelpers];
        [self setupViews];
        [self reloadCalendar];
    }
    return self;
}

- (void)setSelectedDate:(NSDate *)selectedDate
{
    _selectedDate = selectedDate ?: [NSDate now];
    _visibleMonthDate = _selectedDate;
    [self reloadCalendar];
}

- (void)setWeekStartsOnMonday:(BOOL)weekStartsOnMonday
{
    _weekStartsOnMonday = weekStartsOnMonday;
    _calendar.firstWeekday = weekStartsOnMonday ? 2 : 1;
    [self reloadWeekdayTitles];
    [self reloadCalendar];
}

- (void)setRecordColorsByDateKey:(NSDictionary<NSString *,NSArray<UIColor *> *> *)recordColorsByDateKey
{
    _recordColorsByDateKey = [recordColorsByDateKey copy] ?: @{};
    [self reloadCalendar];
}

- (void)setSpecialDayColorsByDateKey:(NSDictionary<NSString *,UIColor *> *)specialDayColorsByDateKey
{
    _specialDayColorsByDateKey = [specialDayColorsByDateKey copy] ?: @{};
    [self reloadCalendar];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat width = MAX(0, CGRectGetWidth(self.bounds));
    CGFloat headerHeight = 48;
    CGFloat weekdayHeight = 28;
    CGFloat dayGridTop = headerHeight + weekdayHeight;
    CGFloat dayGridHeight = MAX(0, CGRectGetHeight(self.bounds) - dayGridTop);

    _headerView.frame = CGRectMake(0, 0, width, headerHeight);
    _previousMonthButton.frame = CGRectMake(0, 4, 44, 40);
    _nextMonthButton.frame = CGRectMake(MAX(0, width - 44), 4, 44, 40);
    _monthLabel.frame = CGRectMake(50, 4, MAX(0, width - 100), 40);
    _weekdayStackView.frame = CGRectMake(0, headerHeight, width, weekdayHeight);
    _daysContainerView.frame = CGRectMake(0, dayGridTop, width, dayGridHeight);

    CGFloat cellWidth = width / 7.0;
    CGFloat cellHeight = dayGridHeight / 6.0;
    [_dayCells enumerateObjectsUsingBlock:^(MirrorHandmadeCalendarDayCell *cell, NSUInteger index, BOOL *stop) {
        NSUInteger row = index / 7;
        NSUInteger column = index % 7;
        cell.frame = CGRectMake(cellWidth * column, cellHeight * row, cellWidth, cellHeight);
    }];
}

- (void)reloadCalendar
{
    if (!_calendar || !_monthFormatter || !_dateKeyFormatter) {
        [self setupCalendarHelpers];
    }
    if (![_dayCells isKindOfClass:NSArray.class] || _dayCells.count == 0) {
        return;
    }

    _calendar.firstWeekday = self.weekStartsOnMonday ? 2 : 1;
    _monthFormatter.locale = [MirrorTool formatterLocaleForCurrentLanguage];
    _dateKeyFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    _monthLabel.text = [_monthFormatter stringFromDate:_visibleMonthDate ?: [NSDate now]];

    NSDate *firstVisibleDate = [self firstDateInGridForMonthDate:_visibleMonthDate ?: [NSDate now]];
    for (NSUInteger index = 0; index < _dayCells.count; index++) {
        MirrorHandmadeCalendarDayCell *cell = _dayCells[index];
        if (![cell isKindOfClass:MirrorHandmadeCalendarDayCell.class]) {
            continue;
        }
        NSDateComponents *offset = [NSDateComponents new];
        offset.day = index;
        NSDate *date = [_calendar dateByAddingComponents:offset toDate:firstVisibleDate options:0] ?: firstVisibleDate;
        if (![date isKindOfClass:NSDate.class]) {
            continue;
        }
        NSDateComponents *components = [_calendar components:NSCalendarUnitDay | NSCalendarUnitMonth fromDate:date];
        NSDateComponents *visibleComponents = [_calendar components:NSCalendarUnitMonth fromDate:_visibleMonthDate ?: [NSDate now]];
        NSString *dateKey = [_dateKeyFormatter stringFromDate:date];
        if (![dateKey isKindOfClass:NSString.class]) {
            dateKey = @"";
        }
        UIColor *specialDayColor = self.specialDayColorsByDateKey[dateKey];
        if (![specialDayColor isKindOfClass:UIColor.class]) {
            specialDayColor = nil;
        }
        NSArray<UIColor *> *recordColors = self.recordColorsByDateKey[dateKey];
        if (![recordColors isKindOfClass:NSArray.class]) {
            recordColors = @[];
        }

        cell.date = date;
        cell.dateKey = dateKey;
        cell.inVisibleMonth = components.month == visibleComponents.month;
        cell.showsToday = [_calendar isDateInToday:date];
        cell.showsSelectedDate = [_calendar isDate:date inSameDayAsDate:self.selectedDate ?: [NSDate now]];
        cell.specialDayColor = specialDayColor;
        cell.recordColors = recordColors;
        [cell setDayText:[NSString stringWithFormat:@"%ld", (long)components.day]];
    }

    [self setNeedsLayout];
}

- (void)setupCalendarHelpers
{
    _calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    _calendar.timeZone = [NSTimeZone systemTimeZone];
    _calendar.firstWeekday = self.weekStartsOnMonday ? 2 : 1;

    _monthFormatter = [NSDateFormatter new];
    _monthFormatter.dateFormat = @"LLLL yyyy";
    _monthFormatter.timeZone = _calendar.timeZone;

    _dateKeyFormatter = [NSDateFormatter new];
    _dateKeyFormatter.dateFormat = @"yyyy-MM-dd";
    _dateKeyFormatter.timeZone = _calendar.timeZone;
    _dateKeyFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
}

- (void)setupViews
{
    self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];

    _headerView = [UIView new];
    [self addSubview:_headerView];

    _previousMonthButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_previousMonthButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    [_previousMonthButton addTarget:self action:@selector(showPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
    _previousMonthButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    [_headerView addSubview:_previousMonthButton];

    _monthLabel = [UILabel new];
    _monthLabel.textAlignment = NSTextAlignmentCenter;
    _monthLabel.font = [UIFont mirrorHintFont];
    _monthLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    [_headerView addSubview:_monthLabel];

    _nextMonthButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_nextMonthButton setImage:[UIImage systemImageNamed:@"chevron.right"] forState:UIControlStateNormal];
    [_nextMonthButton addTarget:self action:@selector(showNextMonth) forControlEvents:UIControlEventTouchUpInside];
    _nextMonthButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    [_headerView addSubview:_nextMonthButton];

    _weekdayStackView = [[UIStackView alloc] initWithFrame:CGRectZero];
    _weekdayStackView.axis = UILayoutConstraintAxisHorizontal;
    _weekdayStackView.distribution = UIStackViewDistributionFillEqually;
    [self addSubview:_weekdayStackView];
    [self reloadWeekdayTitles];

    _daysContainerView = [UIView new];
    [self addSubview:_daysContainerView];

    NSMutableArray<MirrorHandmadeCalendarDayCell *> *cells = [NSMutableArray arrayWithCapacity:42];
    for (NSUInteger index = 0; index < 42; index++) {
        MirrorHandmadeCalendarDayCell *cell = [MirrorHandmadeCalendarDayCell new];
        [cell addTarget:self action:@selector(dayCellTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_daysContainerView addSubview:cell];
        [cells addObject:cell];
    }
    _dayCells = cells;
}

- (void)reloadWeekdayTitles
{
    [_weekdayStackView.arrangedSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSArray<NSString *> *weekdayKeys = self.weekStartsOnMonday ? @[@"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday", @"sunday"] : @[@"sunday", @"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday"];
    for (NSString *key in weekdayKeys) {
        UILabel *label = [UILabel new];
        label.text = [MirrorLanguage mirror_stringWithKey:key];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont mirrorHintFont];
        label.textColor = [[UIColor mirrorColorNamed:MirrorColorTypeText] colorWithAlphaComponent:0.58];
        [_weekdayStackView addArrangedSubview:label];
    }
}

- (NSDate *)firstDateInGridForMonthDate:(NSDate *)monthDate
{
    NSDateComponents *monthComponents = [_calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:monthDate];
    monthComponents.day = 1;
    monthComponents.calendar = _calendar;
    monthComponents.timeZone = _calendar.timeZone;
    NSDate *firstDayOfMonth = monthComponents.date ?: monthDate;
    NSInteger weekday = [_calendar component:NSCalendarUnitWeekday fromDate:firstDayOfMonth];
    NSInteger leadingDays = (weekday - _calendar.firstWeekday + 7) % 7;
    NSDateComponents *offset = [NSDateComponents new];
    offset.day = -leadingDays;
    return [_calendar dateByAddingComponents:offset toDate:firstDayOfMonth options:0] ?: firstDayOfMonth;
}

- (void)showPreviousMonth
{
    [self moveVisibleMonthByOffset:-1];
}

- (void)showNextMonth
{
    [self moveVisibleMonthByOffset:1];
}

- (void)moveVisibleMonthByOffset:(NSInteger)offset
{
    NSDateComponents *components = [NSDateComponents new];
    components.month = offset;
    _visibleMonthDate = [_calendar dateByAddingComponents:components toDate:_visibleMonthDate ?: [NSDate now] options:0];
    [self reloadCalendar];
}

- (void)dayCellTapped:(MirrorHandmadeCalendarDayCell *)cell
{
    if (!cell.date) {
        return;
    }
    self.selectedDate = cell.date;
    if (self.dateSelectionHandler) {
        self.dateSelectionHandler(cell.date);
    }
}

@end

NS_ASSUME_NONNULL_END
