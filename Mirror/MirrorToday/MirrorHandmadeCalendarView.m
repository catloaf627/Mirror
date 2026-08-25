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
#import "MirrorDayModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MirrorHandmadeCalendarDateHandler)(NSDate *date);
typedef void (^MirrorHandmadeCalendarLayoutHandler)(void);

@interface MirrorHandmadeCalendarView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, copy, nullable) MirrorHandmadeCalendarDateHandler dateSelectionHandler;
@property (nonatomic, copy, nullable) MirrorHandmadeCalendarLayoutHandler layoutChangeHandler;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<UIColor *> *> *recordColorsByDateKey;
@property (nonatomic, copy) NSDictionary<NSString *, MirrorDayModel *> *specialDaysByDateKey;
@property (nonatomic, assign) BOOL weekStartsOnMonday;

- (instancetype)initWithSelectedDate:(NSDate *)selectedDate;
- (void)reloadCalendar;
- (CGFloat)preferredHeight;

@end

@interface MirrorHandmadeCalendarDayCell : UIControl

@property (nonatomic, strong, nullable) NSDate *date;
@property (nonatomic, copy) NSString *dateKey;
@property (nonatomic, assign) BOOL inVisibleMonth;
@property (nonatomic, assign) BOOL showsToday;
@property (nonatomic, assign) BOOL showsSelectedDate;
@property (nonatomic, strong, nullable) UIColor *specialDayColor;
@property (nonatomic, copy) NSString *specialDayIconName;
@property (nonatomic, copy) NSArray<UIColor *> *recordColors;

- (void)setDayText:(NSString *)dayText;

@end

@implementation MirrorHandmadeCalendarDayCell {
    UILabel *_dayLabel;
    UIImageView *_iconView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        _recordColors = @[];
        _dayLabel = [UILabel new];
        _dayLabel.textAlignment = NSTextAlignmentCenter;
        _dayLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        [self addSubview:_dayLabel];

        _iconView = [UIImageView new];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.hidden = YES;
        [self addSubview:_iconView];
    }
    return self;
}

- (void)setDayText:(NSString *)dayText
{
    _dayLabel.text = dayText;
    [self updateSpecialDayIcon];
}

- (void)setInVisibleMonth:(BOOL)inVisibleMonth
{
    _inVisibleMonth = inVisibleMonth;
    [self updateTextColor];
    [self updateSpecialDayIcon];
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
    [self updateTextColor];
    [self updateSpecialDayIcon];
    [self setNeedsDisplay];
}

- (void)setSpecialDayIconName:(NSString *)specialDayIconName
{
    _specialDayIconName = [specialDayIconName copy] ?: @"";
    [self updateSpecialDayIcon];
}

- (void)setRecordColors:(NSArray<UIColor *> *)recordColors
{
    if (![recordColors isKindOfClass:NSArray.class]) {
        _recordColors = @[];
        [self updateTextColor];
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
    [self updateTextColor];
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
    _iconView.frame = CGRectInset(_dayLabel.frame, labelSide * 0.14, labelSide * 0.14);
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }

    CGRect dateRect = _dayLabel.frame;
    if (CGRectGetWidth(dateRect) <= 0 || CGRectGetHeight(dateRect) <= 0) {
        return;
    }

    NSArray<UIColor *> *backgroundColors = [self decorationBackgroundColors];
    if (backgroundColors.count > 0) {
        UIBezierPath *clipPath = [UIBezierPath bezierPathWithRoundedRect:dateRect cornerRadius:6];
        CGContextSaveGState(context);
        [clipPath addClip];

        CGFloat segmentHeight = CGRectGetHeight(dateRect) / backgroundColors.count;
        [backgroundColors enumerateObjectsUsingBlock:^(UIColor *color, NSUInteger index, BOOL *stop) {
            if (![color isKindOfClass:UIColor.class]) {
                return;
            }
            CGFloat y = CGRectGetMinY(dateRect) + segmentHeight * index;
            CGFloat height = index == backgroundColors.count - 1 ? CGRectGetMaxY(dateRect) - y : segmentHeight;
            CGRect segmentRect = CGRectMake(CGRectGetMinX(dateRect), y, CGRectGetWidth(dateRect), height);
            CGContextSetFillColorWithColor(context, color.CGColor);
            CGContextFillRect(context, segmentRect);
        }];
        CGContextRestoreGState(context);
    }

    if (self.showsSelectedDate) {
        CGFloat lineWidth = 1.6;
        CGRect outlineRect = CGRectInset(dateRect, lineWidth / 2.0, lineWidth / 2.0);
        if (CGRectGetWidth(outlineRect) > 0 && CGRectGetHeight(outlineRect) > 0) {
            CGContextSetStrokeColorWithColor(context, [UIColor mirrorColorNamed:MirrorColorTypeText].CGColor);
            CGContextSetLineWidth(context, lineWidth);
            UIBezierPath *outlinePath = [UIBezierPath bezierPathWithRoundedRect:outlineRect cornerRadius:6 - lineWidth / 2.0];
            [outlinePath stroke];
        }
    }
}

- (void)updateTextColor
{
    UIColor *baseColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    if (!self.inVisibleMonth) {
        _dayLabel.textColor = UIColor.clearColor;
    } else if ([self.specialDayColor isKindOfClass:UIColor.class]) {
        _dayLabel.textColor = self.specialDayColor;
    } else {
        _dayLabel.textColor = baseColor;
    }
    _dayLabel.backgroundColor = UIColor.clearColor;
}

- (NSArray<UIColor *> *)decorationBackgroundColors
{
    if (self.recordColors.count > 0) {
        return self.recordColors;
    }
    return @[];
}

- (void)updateSpecialDayIcon
{
    UIImage *iconImage = nil;
    if (self.inVisibleMonth && self.specialDayIconName.length > 0) {
        iconImage = [UIImage systemImageNamed:self.specialDayIconName];
    }

    BOOL showsIcon = [iconImage isKindOfClass:UIImage.class];
    _iconView.hidden = !showsIcon;
    _dayLabel.hidden = showsIcon;
    _iconView.image = showsIcon ? [iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] : nil;
    _iconView.tintColor = [self.specialDayColor isKindOfClass:UIColor.class] ? self.specialDayColor : [UIColor mirrorColorNamed:MirrorColorTypeText];
}

@end

@implementation MirrorHandmadeCalendarView {
    UIView *_swipeGestureView;
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
    NSInteger _visibleWeekCount;
    BOOL _didHandleMonthPan;
}

- (instancetype)initWithSelectedDate:(NSDate *)selectedDate
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _selectedDate = selectedDate ?: [NSDate now];
        _visibleMonthDate = _selectedDate;
        _weekStartsOnMonday = [MirrorSettings appliedWeekStarsOnMonday];
        _recordColorsByDateKey = @{};
        _specialDaysByDateKey = @{};
        _visibleWeekCount = 6;
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

- (void)setSpecialDaysByDateKey:(NSDictionary<NSString *,MirrorDayModel *> *)specialDaysByDateKey
{
    _specialDaysByDateKey = [specialDaysByDateKey copy] ?: @{};
    [self reloadCalendar];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat width = MAX(0, CGRectGetWidth(self.bounds));
    CGFloat headerHeight = 48;
    CGFloat weekdayHeight = 28;
    CGFloat dayGridTop = headerHeight + weekdayHeight;
    NSInteger rowCount = MAX(1, _visibleWeekCount);
    CGFloat dayGridHeight = MAX(0, CGRectGetHeight(self.bounds) - dayGridTop);

    _swipeGestureView.frame = self.bounds;
    _headerView.frame = CGRectMake(0, 0, width, headerHeight);
    _previousMonthButton.frame = CGRectMake(0, 4, 44, 40);
    _nextMonthButton.frame = CGRectMake(MAX(0, width - 44), 4, 44, 40);
    _monthLabel.frame = CGRectMake(50, 4, MAX(0, width - 100), 40);
    _weekdayStackView.frame = CGRectMake(0, headerHeight, width, weekdayHeight);
    _daysContainerView.frame = CGRectMake(0, dayGridTop, width, dayGridHeight);

    CGFloat cellWidth = width / 7.0;
    CGFloat cellHeight = dayGridHeight / rowCount;
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

    NSDate *visibleMonthDate = _visibleMonthDate ?: [NSDate now];
    NSInteger previousVisibleWeekCount = _visibleWeekCount;
    _visibleWeekCount = [self visibleWeekCountForMonthDate:visibleMonthDate];
    NSDate *firstVisibleDate = [self firstDateInGridForMonthDate:visibleMonthDate];
    NSUInteger visibleCellCount = MIN(_dayCells.count, MAX(1, _visibleWeekCount) * 7);
    for (NSUInteger index = 0; index < _dayCells.count; index++) {
        MirrorHandmadeCalendarDayCell *cell = _dayCells[index];
        if (![cell isKindOfClass:MirrorHandmadeCalendarDayCell.class]) {
            continue;
        }
        BOOL shouldShowCell = index < visibleCellCount;
        cell.hidden = !shouldShowCell;
        if (!shouldShowCell) {
            cell.date = nil;
            cell.dateKey = @"";
            cell.specialDayColor = nil;
            cell.specialDayIconName = @"";
            cell.recordColors = @[];
            [cell setDayText:@""];
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
        MirrorDayModel *specialDay = self.specialDaysByDateKey[dateKey];
        UIColor *specialDayColor = nil;
        NSString *specialDayIconName = @"";
        if ([specialDay isKindOfClass:MirrorDayModel.class]) {
            specialDayColor = [UIColor mirrorSystemColorNamed:specialDay.color];
            specialDayIconName = [self specialDayIconNameFromStoredIconName:specialDay.icon];
        }
        NSArray<UIColor *> *recordColors = self.recordColorsByDateKey[dateKey];
        if (![recordColors isKindOfClass:NSArray.class]) {
            recordColors = @[];
        }

        BOOL inVisibleMonth = components.month == visibleComponents.month;
        cell.date = inVisibleMonth ? date : nil;
        cell.dateKey = inVisibleMonth ? dateKey : @"";
        cell.inVisibleMonth = inVisibleMonth;
        cell.showsToday = inVisibleMonth && [_calendar isDateInToday:date];
        cell.showsSelectedDate = inVisibleMonth && [_calendar isDate:date inSameDayAsDate:self.selectedDate ?: [NSDate now]];
        cell.specialDayColor = inVisibleMonth ? specialDayColor : nil;
        cell.specialDayIconName = inVisibleMonth ? specialDayIconName : @"";
        cell.recordColors = inVisibleMonth ? recordColors : @[];
        [cell setDayText:inVisibleMonth ? [NSString stringWithFormat:@"%ld", (long)components.day] : @""];
    }

    [self setNeedsLayout];
    if (previousVisibleWeekCount != _visibleWeekCount && self.layoutChangeHandler) {
        self.layoutChangeHandler();
    }
}

- (CGFloat)preferredHeight
{
    CGFloat headerHeight = 48;
    CGFloat weekdayHeight = 28;
    CGFloat weekRowHeight = 48;
    return headerHeight + weekdayHeight + MAX(1, _visibleWeekCount) * weekRowHeight;
}

- (NSString *)specialDayIconNameFromStoredIconName:(NSString *)storedIconName
{
    if (storedIconName.length > 0 && [UIImage systemImageNamed:storedIconName]) {
        return storedIconName;
    }
    return @"star.fill";
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
    self.backgroundColor = UIColor.clearColor;

    _swipeGestureView = [UIView new];
    _swipeGestureView.backgroundColor = UIColor.clearColor;
    _swipeGestureView.userInteractionEnabled = YES;
    [self addSubview:_swipeGestureView];
    [self setupSwipeGestures];

    _headerView = [UIView new];
    [_swipeGestureView addSubview:_headerView];

    _previousMonthButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_previousMonthButton setImage:[UIImage systemImageNamed:@"chevron.left"] forState:UIControlStateNormal];
    [_previousMonthButton addTarget:self action:@selector(showPreviousMonth) forControlEvents:UIControlEventTouchUpInside];
    _previousMonthButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    [_headerView addSubview:_previousMonthButton];

    _monthLabel = [UILabel new];
    _monthLabel.textAlignment = NSTextAlignmentCenter;
    _monthLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
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
    [_swipeGestureView addSubview:_weekdayStackView];
    [self reloadWeekdayTitles];

    _daysContainerView = [UIView new];
    [_swipeGestureView addSubview:_daysContainerView];

    NSMutableArray<MirrorHandmadeCalendarDayCell *> *cells = [NSMutableArray arrayWithCapacity:42];
    for (NSUInteger index = 0; index < 42; index++) {
        MirrorHandmadeCalendarDayCell *cell = [MirrorHandmadeCalendarDayCell new];
        [cell addTarget:self action:@selector(dayCellTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_daysContainerView addSubview:cell];
        [cells addObject:cell];
    }
    _dayCells = cells;
}

- (void)setupSwipeGestures
{
    UIPanGestureRecognizer *monthPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleCalendarMonthPan:)];
    monthPanGesture.cancelsTouchesInView = YES;
    monthPanGesture.delegate = self;
    [_swipeGestureView addGestureRecognizer:monthPanGesture];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        return YES;
    }

    UIPanGestureRecognizer *panGesture = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint velocity = [panGesture velocityInView:_swipeGestureView];
    return fabs(velocity.x) > fabs(velocity.y) * 1.4 && fabs(velocity.x) > 120;
}

- (void)reloadWeekdayTitles
{
    [_weekdayStackView.arrangedSubviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSArray<NSString *> *weekdayKeys = self.weekStartsOnMonday ? @[@"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday", @"sunday"] : @[@"sunday", @"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday"];
    for (NSString *key in weekdayKeys) {
        UILabel *label = [UILabel new];
        label.text = [MirrorLanguage mirror_stringWithKey:key];
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
        label.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight];
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

- (NSInteger)visibleWeekCountForMonthDate:(NSDate *)monthDate
{
    if (!_calendar) {
        [self setupCalendarHelpers];
    }
    NSDateComponents *monthComponents = [_calendar components:NSCalendarUnitYear | NSCalendarUnitMonth fromDate:monthDate ?: [NSDate now]];
    monthComponents.day = 1;
    monthComponents.calendar = _calendar;
    monthComponents.timeZone = _calendar.timeZone;
    NSDate *firstDayOfMonth = monthComponents.date;
    if (!firstDayOfMonth) {
        return 6;
    }

    NSRange dayRange = [_calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDayOfMonth];
    if (dayRange.length == 0) {
        return 6;
    }

    NSInteger firstWeekday = [_calendar component:NSCalendarUnitWeekday fromDate:firstDayOfMonth];
    NSInteger leadingDays = (firstWeekday - _calendar.firstWeekday + 7) % 7;
    NSInteger weekCount = ceil((leadingDays + dayRange.length) / 7.0);
    return MIN(MAX(weekCount, 4), 6);
}

- (void)showPreviousMonth
{
    [self moveVisibleMonthByOffset:-1];
}

- (void)showNextMonth
{
    [self moveVisibleMonthByOffset:1];
}

- (void)handleCalendarMonthPan:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        return;
    }

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        _didHandleMonthPan = NO;
        return;
    }
    if (_didHandleMonthPan || (gestureRecognizer.state != UIGestureRecognizerStateChanged && gestureRecognizer.state != UIGestureRecognizerStateEnded)) {
        return;
    }

    CGPoint translation = [gestureRecognizer translationInView:_swipeGestureView];
    CGPoint velocity = [gestureRecognizer velocityInView:_swipeGestureView];
    if (fabs(translation.x) < 46 && fabs(velocity.x) < 420) {
        return;
    }

    _didHandleMonthPan = YES;
    if (translation.x < 0 || velocity.x < -420) {
        [self moveVisibleMonthByOffset:1];
    } else {
        [self moveVisibleMonthByOffset:-1];
    }
}

- (void)moveVisibleMonthByOffset:(NSInteger)offset
{
    if (!_calendar) {
        [self setupCalendarHelpers];
    }
    NSDateComponents *components = [NSDateComponents new];
    components.month = offset;
    _visibleMonthDate = [_calendar dateByAddingComponents:components toDate:_visibleMonthDate ?: [NSDate now] options:0];
    [self triggerLightFeedback];
    [self reloadCalendar];
}

- (void)dayCellTapped:(MirrorHandmadeCalendarDayCell *)cell
{
    if (!cell.date) {
        return;
    }
    [self triggerLightFeedback];
    self.selectedDate = cell.date;
    if (self.dateSelectionHandler) {
        self.dateSelectionHandler(cell.date);
    }
}

- (void)triggerLightFeedback
{
    UIImpactFeedbackGenerator *feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedbackGenerator impactOccurred];
}

@end

NS_ASSUME_NONNULL_END
