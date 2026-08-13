//
//  CalendarViewController.m
//  Mirror
//

#import "CalendarViewController.h"
#import "OneDayTimelineViewController.h"
#import "MirrorNaviManager.h"
#import "MirrorStorage.h"
#import "MirrorTool.h"
#import "MirrorSettings.h"
#import "MirrorTimeText.h"
#import "MirrorLanguage.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"
#import <Masonry/Masonry.h>

#define kLeftRightSpacing (20*kWidthRatio)
#define kDatePickerHeaderHeight (44*kHeightRatio)

@interface CalendarPickerViewController : UIViewController <UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate>

- (instancetype)initWithSelectedDate:(NSDate *)selectedDate selectionHandler:(void (^)(NSDate *date))selectionHandler;

@end

@interface CalendarPickerViewController ()

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, copy) void (^selectionHandler)(NSDate *date);
@property (nonatomic, strong) UICalendarView *calendarView;
@property (nonatomic, strong) UICalendarSelectionSingleDate *dateSelection;
@property (nonatomic, strong) NSDictionary<NSString *, NSMutableArray<MirrorReadModel *> *> *gridData;

@end

@implementation CalendarPickerViewController

- (instancetype)initWithSelectedDate:(NSDate *)selectedDate selectionHandler:(void (^)(NSDate *date))selectionHandler
{
    self = [super init];
    if (self) {
        _selectedDate = selectedDate ?: [NSDate now];
        _selectionHandler = [selectionHandler copy];
        _gridData = [MirrorStorage getGridData];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSignificantTimeChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStopNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskMergeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskChangeOrderNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskHiddenNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.calendarView];
    [self.calendarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
}

- (void)reloadData
{
    NSArray<NSDateComponents *> *previousDateComponents = [self gridDateComponents];
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    self.calendarView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    self.calendarView.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    self.calendarView.calendar.timeZone = [NSTimeZone systemTimeZone];
    self.gridData = [MirrorStorage getGridData];
    NSMutableArray<NSDateComponents *> *dateComponents = [previousDateComponents mutableCopy];
    [dateComponents addObjectsFromArray:[self gridDateComponents]];
    if (@available(iOS 16.0, *)) {
        [self.calendarView reloadDecorationsForDateComponents:dateComponents animated:NO];
    }
}

- (NSArray<NSDateComponents *> *)gridDateComponents
{
    NSMutableArray<NSDateComponents *> *components = [NSMutableArray new];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    for (NSString *key in self.gridData.allKeys) {
        NSDate *date = [formatter dateFromString:key];
        if (!date) {
            continue;
        }
        [components addObject:[calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date]];
    }
    return components;
}

- (UICalendarView *)calendarView API_AVAILABLE(ios(16.0))
{
    if (!_calendarView) {
        _calendarView = [UICalendarView new];
        _calendarView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _calendarView.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        _calendarView.calendar.timeZone = [NSTimeZone systemTimeZone];
        _calendarView.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _calendarView.delegate = self;
        _calendarView.wantsDateDecorations = YES;
        _calendarView.selectionBehavior = self.dateSelection;
    }
    return _calendarView;
}

- (UICalendarSelectionSingleDate *)dateSelection API_AVAILABLE(ios(16.0))
{
    if (!_dateSelection) {
        _dateSelection = [[UICalendarSelectionSingleDate alloc] initWithDelegate:self];
        NSDateComponents *components = [self.calendarView.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.selectedDate];
        [_dateSelection setSelectedDate:components animated:NO];
    }
    return _dateSelection;
}

#pragma mark - UICalendarViewDelegate

- (UICalendarViewDecoration *)calendarView:(UICalendarView *)calendarView decorationForDateComponents:(NSDateComponents *)dateComponents API_AVAILABLE(ios(16.0))
{
    NSDate *date = dateComponents.date;
    if (!date) return nil;

    UIColor *color = [self gridColorForDate:date];
    if (!color) return nil;
    CGFloat decorationWidth = [self gridDecorationWidthForDate:date];

    return [UICalendarViewDecoration decorationWithCustomViewProvider:^UIView * _Nonnull{
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, decorationWidth, 6)];
        backgroundView.backgroundColor = color;
        backgroundView.layer.cornerRadius = 3;
        backgroundView.clipsToBounds = YES;
        return backgroundView;
    }];
}

#pragma mark - UICalendarSelectionSingleDateDelegate

- (BOOL)dateSelection:(UICalendarSelectionSingleDate *)selection canSelectDate:(NSDateComponents *)dateComponents API_AVAILABLE(ios(16.0))
{
    return dateComponents != nil;
}

- (void)dateSelection:(UICalendarSelectionSingleDate *)selection didSelectDate:(NSDateComponents *)dateComponents API_AVAILABLE(ios(16.0))
{
    NSDate *date = dateComponents.date;
    if (!date) return;
    if (self.selectionHandler) {
        self.selectionHandler(date);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Color

- (UIColor *)gridColorForDate:(NSDate *)date
{
    NSMutableArray<MirrorReadModel *> *data = self.gridData[[self keyFromDate:date]];
    if (data.count == 0) return nil;

    long totalTime = 0;
    NSMutableArray<NSNumber *> *taskTimes = [NSMutableArray array];
    NSMutableArray<UIColor *> *taskColors = [NSMutableArray array];
    for (MirrorReadModel *readModel in data) {
        long taskTime = [MirrorTool getTotalTimeOfPeriods:readModel.records];
        if (taskTime > 0) {
            [taskTimes addObject:@(taskTime)];
            [taskColors addObject:[UIColor mirrorColorNamed:readModel.taskModel.color]];
        }
        totalTime += taskTime;
    }
    if (totalTime == 0) return nil;

    UIColor *mixedColor = [self mixedColorWithTaskColors:taskColors taskTimes:taskTimes totalTime:totalTime];
    return [mixedColor colorWithAlphaComponent:1];
}

- (CGFloat)gridDecorationWidthForDate:(NSDate *)date
{
    NSMutableArray<MirrorReadModel *> *data = self.gridData[[self keyFromDate:date]];
    long totalTime = 0;
    for (MirrorReadModel *readModel in data) {
        totalTime += [MirrorTool getTotalTimeOfPeriods:readModel.records];
    }
    if (totalTime == 0) return 0;

    CGFloat widthRatio = MIN(1.0, 0.2 + floor(totalTime / 3600) * 0.1);
    return 28 * widthRatio;
}

- (UIColor *)mixedColorWithTaskColors:(NSMutableArray<UIColor *> *)taskColors taskTimes:(NSMutableArray<NSNumber *> *)taskTimes totalTime:(long)totalTime
{
    if (taskColors.count == 0 || taskTimes.count == 0 || totalTime == 0) {
        return [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    }

    CGFloat mixedRed = 0;
    CGFloat mixedGreen = 0;
    CGFloat mixedBlue = 0;
    CGFloat mixedAlpha = 0;
    for (int i=0; i<taskColors.count; i++) {
        CGFloat red = 0;
        CGFloat green = 0;
        CGFloat blue = 0;
        CGFloat colorAlpha = 0;
        if (![taskColors[i] getRed:&red green:&green blue:&blue alpha:&colorAlpha]) {
            return taskColors.firstObject;
        }

        CGFloat weight = taskTimes[i].doubleValue / (CGFloat)totalTime;
        mixedRed += red * weight;
        mixedGreen += green * weight;
        mixedBlue += blue * weight;
        mixedAlpha += colorAlpha * weight;
    }

    return [UIColor colorWithRed:mixedRed green:mixedGreen blue:mixedBlue alpha:mixedAlpha];
}

- (NSString *)keyFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:date];
}

@end

@interface CalendarViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) UIView *dateHeaderView;
@property (nonatomic, strong) UIButton *dateButton;
@property (nonatomic, strong) UIButton *todayButton;
@property (nonatomic, strong) UIView *todayButtonContainer;
@property (nonatomic, strong) OneDayTimelineViewController *timelineViewController;
@property (nonatomic, assign) BOOL didHandleDatePan;
@property (nonatomic, assign) BOOL isAnimatingDateTransition;
@property (nonatomic, assign) BOOL isLoaded;

@end

@implementation CalendarViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSignificantTimeChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStopNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskMergeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskChangeOrderNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskHiddenNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.selectedDate = [NSDate now];
    [self p_setupUI];
    self.isLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavigationItem];
}

- (void)restartVC
{
    if (!self.isLoaded) {
        return;
    }

    [self.timelineViewController willMoveToParentViewController:nil];
    [self.timelineViewController.view removeFromSuperview];
    [self.timelineViewController removeFromParentViewController];
    self.timelineViewController = nil;
    self.dateHeaderView = nil;
    self.dateButton = nil;
    self.todayButton = nil;
    self.todayButtonContainer = nil;
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    if (self.tabBarController.selectedIndex == 1) {
        [self updateNavigationItem];
    }
    [self p_setupUI];
}

- (void)reloadData
{
    if (!self.isLoaded) {
        return;
    }

    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self updateDateHeaderState];
    [self updateDateHeaderColors];
    [self.timelineViewController updateDate:self.selectedDate ?: [NSDate now]];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];

    OneDayTimelineViewController *timelineViewController = [[OneDayTimelineViewController alloc] initWithDate:self.selectedDate
                                                                                                  headerView:self.dateHeaderView
                                                                                                headerHeight:kDatePickerHeaderHeight
                                                                                                headerInsets:UIEdgeInsetsMake(0, kLeftRightSpacing, 8*kHeightRatio, kLeftRightSpacing)
                                                                                         headerConfiguration:nil];
    self.timelineViewController = timelineViewController;
    [self addChildViewController:timelineViewController];
    [self.view addSubview:timelineViewController.view];
    [timelineViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.left.right.bottom.offset(0);
    }];
    [timelineViewController didMoveToParentViewController:self];
    [self addDateSwipeGestures];
}

#pragma mark - Actions

- (void)showCalendarPicker
{
    __weak typeof(self) weakSelf = self;
    CalendarPickerViewController *pickerVC = [[CalendarPickerViewController alloc] initWithSelectedDate:self.selectedDate selectionHandler:^(NSDate *date) {
        [weakSelf updateSelectedDate:date];
    }];
    pickerVC.modalPresentationStyle = UIModalPresentationPopover;
    pickerVC.preferredContentSize = CGSizeMake(360, 340);
    UIPopoverPresentationController *popover = pickerVC.popoverPresentationController;
    popover.sourceView = self.dateButton;
    popover.sourceRect = self.dateButton.bounds;
    popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    [self presentViewController:pickerVC animated:YES completion:nil];
}

- (void)handleDatePan:(UIPanGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        self.didHandleDatePan = NO;
        return;
    }
    if (gestureRecognizer.state != UIGestureRecognizerStateChanged || self.didHandleDatePan) {
        return;
    }

    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGPoint velocity = [gestureRecognizer velocityInView:self.view];
    if (fabs(translation.x) < 40*kWidthRatio && fabs(velocity.x) < 300*kWidthRatio) {
        return;
    }

    self.didHandleDatePan = YES;
    NSInteger dayOffset = translation.x < 0 ? 1 : -1;
    [self moveSelectedDateByDayOffset:dayOffset];
}

- (void)moveSelectedDateByDayOffset:(NSInteger)dayOffset
{
    if (dayOffset == 0 || self.isAnimatingDateTransition) {
        return;
    }

    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:dayOffset toDate:self.selectedDate options:0];
    [self updateSelectedDate:date animatedWithDayOffset:dayOffset];
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)goToToday
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [self updateSelectedDate:[NSDate now]];
}

- (void)addDateSwipeGestures
{
    UIPanGestureRecognizer *datePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleDatePan:)];
    datePan.delegate = self;
    [self.timelineViewController.view addGestureRecognizer:datePan];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        return YES;
    }

    CGPoint location = [gestureRecognizer locationInView:self.view];
    if (location.x <= 24*kWidthRatio) {
        return NO;
    }

    UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint velocity = [pan velocityInView:self.view];
    return fabs(velocity.x) > fabs(velocity.y);
}

- (void)updateSelectedDate:(NSDate *)date
{
    if (!date) {
        return;
    }
    self.selectedDate = date;
    [self updateDateHeaderState];
    [self.timelineViewController updateDate:date];
}

- (void)updateSelectedDate:(NSDate *)date animatedWithDayOffset:(NSInteger)dayOffset
{
    if (!date || dayOffset == 0) {
        return;
    }
    if (UIAccessibilityIsReduceMotionEnabled()) {
        [self updateSelectedDate:date];
        return;
    }

    UIView *timelineView = self.timelineViewController.view;
    UIView *snapshotView = [timelineView snapshotViewAfterScreenUpdates:NO];
    if (!snapshotView) {
        [self updateSelectedDate:date];
        return;
    }

    self.isAnimatingDateTransition = YES;
    self.view.userInteractionEnabled = NO;
    snapshotView.frame = timelineView.frame;
    [self.view addSubview:snapshotView];

    CGFloat width = CGRectGetWidth(timelineView.bounds);
    CGFloat incomingOffset = dayOffset > 0 ? width : -width;
    CGFloat outgoingOffset = -incomingOffset;
    timelineView.transform = CGAffineTransformMakeTranslation(incomingOffset, 0);
    [self updateSelectedDate:date];
    [self.view layoutIfNeeded];

    [UIView animateWithDuration:0.28
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        snapshotView.transform = CGAffineTransformMakeTranslation(outgoingOffset, 0);
        timelineView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        timelineView.transform = CGAffineTransformIdentity;
        [snapshotView removeFromSuperview];
        self.view.userInteractionEnabled = YES;
        self.isAnimatingDateTransition = NO;
    }];
}

#pragma mark - Getters

- (UIView *)dateHeaderView
{
    if (!_dateHeaderView) {
        _dateHeaderView = [UIView new];
        [_dateHeaderView addSubview:self.dateButton];
        [self.dateButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.offset(0);
        }];
        [self updateDateHeaderState];
    }
    return _dateHeaderView;
}

- (UIButton *)dateButton
{
    if (!_dateButton) {
        _dateButton = [UIButton new];
        _dateButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _dateButton.titleLabel.font = [UIFont mirrorTitleFont];
        UIImage *iconImage = [[UIImage systemImageNamed:@"calendar"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_dateButton setImage:iconImage forState:UIControlStateNormal];
        _dateButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8*kWidthRatio);
        _dateButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8*kWidthRatio, 0, 0);
        [_dateButton addTarget:self action:@selector(showCalendarPicker) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dateButton;
}

- (UIButton *)todayButton
{
    if (!_todayButton) {
        _todayButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _todayButton.titleLabel.font = [UIFont mirrorButtonFont];
        _todayButton.layer.cornerRadius = 8*kWidthRatio;
        _todayButton.clipsToBounds = YES;
        [_todayButton setTitle:[MirrorLanguage mirror_stringWithKey:@"today"] forState:UIControlStateNormal];
        [_todayButton addTarget:self action:@selector(goToToday) forControlEvents:UIControlEventTouchUpInside];
    }
    return _todayButton;
}

- (UIView *)todayButtonContainer
{
    if (!_todayButtonContainer) {
        _todayButtonContainer = [UIView new];
        [_todayButtonContainer addSubview:self.todayButton];
        [self.todayButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.right.offset(0);
            make.height.mas_equalTo(24*kHeightRatio);
            make.width.mas_equalTo([self todayButtonWidth]);
        }];
        _todayButtonContainer.frame = CGRectMake(0, 0, [self todayButtonWidth], 44*kHeightRatio);
    }
    return _todayButtonContainer;
}

- (CGFloat)todayButtonWidth
{
    CGSize titleSize = [[MirrorLanguage mirror_stringWithKey:@"today"] sizeWithAttributes:@{NSFontAttributeName: [UIFont mirrorButtonFont]}];
    return ceil(titleSize.width) + 24*kWidthRatio;
}

- (void)updateDateHeaderState
{
    [_dateButton setTitle:[MirrorTimeText YYYYmmddWeekday:self.selectedDate ?: [NSDate now]] forState:UIControlStateNormal];
    [self updateDateHeaderColors];
    [self updateNavigationItem];
}

- (void)updateDateHeaderColors
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    self.dateHeaderView.backgroundColor = self.view.backgroundColor;
    self.dateButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    [self.dateButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeText] forState:UIControlStateNormal];
    self.todayButton.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    [self.todayButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeBackground] forState:UIControlStateNormal];
}

- (void)updateNavigationItem
{
    UIView *rightButton = [self isSelectedDateToday] ? nil : self.todayButtonContainer;
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"calendar"] leftButton:nil rightButton:rightButton];
}

- (BOOL)isSelectedDateToday
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    return [calendar isDate:self.selectedDate ?: [NSDate now] inSameDayAsDate:[NSDate now]];
}

@end
