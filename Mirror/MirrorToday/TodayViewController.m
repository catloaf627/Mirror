//
//  TodayViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/4.
//

#import "TodayViewController.h"
#import "MirrorTabsManager.h"
#import "MirrorNaviManager.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorMacro.h"
#import "TodayTotalHeader.h"
#import "OneDayTimelineViewController.h"
#import "MirrorTimeText.h"
#import "MirrorLanguage.h"
#import "UIFont+MirrorFont.h"
#import "MirrorStorage.h"
#import "MirrorReadModel.h"
#import "MirrorDayModel.h"
#import "SpecialDaysViewController.h"
#import "MirrorTool.h"
#import "MirrorSettings.h"

#define kLeftRightSpacing (20*kWidthRatio)

@interface TodayViewController () <UIGestureRecognizerDelegate, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate>

@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, assign) BOOL didHandleDatePan;
@property (nonatomic, assign) BOOL isAnimatingDateTransition;

// Navibar
@property (nonatomic, strong) UIButton *specialDaysButton;
@property (nonatomic, strong) UIButton *todayButton;
@property (nonatomic, strong) UIView *todayButtonContainer;

// UI
@property (nonatomic, strong) OneDayTimelineViewController *timelineViewController;
@property (nonatomic, strong) UIView *headerContainerView;
@property (nonatomic, strong) TodayTotalHeader *todayTotalHeader;
@property (nonatomic, strong) UIView *calendarPickerDismissView;
@property (nonatomic, strong) UIView *calendarPickerContainerView;
@property (nonatomic, strong) UICalendarView *calendarView;
@property (nonatomic, strong) UICalendarSelectionSingleDate *dateSelection;
@property (nonatomic, strong) NSDictionary<NSString *, NSMutableArray<MirrorReadModel *> *> *gridData;

@end

@implementation TodayViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 系统通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSignificantTimeChangeNotification object:nil];
        // 设置通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWeekStartsOnChanged) name:MirrorSwitchWeekStartsOnNotification object:nil]; // datepicker需要监听这个
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchShowIndexNotification object:nil];// 比其他vc多监听一个index通知
        // 数据通知 (直接数据驱动UI，本地数据变动必然导致这里的UI变动)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStopNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskMergeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskChangeOrderNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSpecialDaysChanged) name:MirrorDayCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSpecialDaysChanged) name:MirrorDayDeleteNotification object:nil];
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
    _isLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavigationItem];
}

- (void)restartVC
{
    // 更新tabbar
    [[MirrorTabsManager sharedInstance] updateTodayTabItemWithTabController:self.tabBarController];
    if (!_isLoaded) return;

    [self.timelineViewController willMoveToParentViewController:nil];
    [self.timelineViewController.view removeFromSuperview];
    [self.timelineViewController removeFromParentViewController];
    self.timelineViewController = nil;
    self.headerContainerView = nil;
    self.todayTotalHeader = nil;
    self.calendarPickerDismissView = nil;
    self.calendarPickerContainerView = nil;
    self.calendarView = nil;
    self.dateSelection = nil;
    self.gridData = nil;
    self.specialDaysButton = nil;
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
    /*
     调用reloadData后UI不刷新的bug折磨了我很久，一开始以为是其他页面遮挡了collection view导致的不刷新，多次改动collection view reload data的调用方式都没成功
     最后发现根本原因是：在整个页面还没有setupUI的时候就被通知reloadData
     */
    if (!_isLoaded) return;
    [self updateHeaderStateWithRecords:nil];
    [self.timelineViewController updateDate:self.selectedDate ?: [NSDate now]];
}

- (void)handleSpecialDaysChanged
{
    [self updateSpecialDaysButton];
    [self reloadData];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self updateHeaderStateWithRecords:nil];

    __weak typeof(self) weakSelf = self;
    OneDayTimelineViewController *timelineViewController = [[OneDayTimelineViewController alloc] initWithDate:self.selectedDate ?: [NSDate now]
                                                                                                  headerView:self.headerContainerView
                                                                                                headerHeight:kTodayHeaderHeight
                                                                                                headerInsets:UIEdgeInsetsMake(0, kLeftRightSpacing, 0, kLeftRightSpacing)
                                                                                         headerConfiguration:^(UIView *headerView, NSMutableArray<MirrorRecordModel *> *records) {
        [weakSelf updateHeaderStateWithRecords:records];
    }];
    self.timelineViewController = timelineViewController;
    [self addChildViewController:timelineViewController];
    [self.view addSubview:timelineViewController.view];
    [timelineViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.left.right.offset(0);
        make.bottom.offset(-self.tabBarController.tabBar.frame.size.height);
    }];
    [timelineViewController didMoveToParentViewController:self];
    [self addDateSwipeGestures];
}

#pragma mark - Actions

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
    [self dismissDatePicker];
    [self.timelineViewController dismissTransientEditingState];
    [self moveSelectedDateByDayOffset:dayOffset];
}

- (void)moveSelectedDateByDayOffset:(NSInteger)dayOffset
{
    if (dayOffset == 0 || self.isAnimatingDateTransition) {
        return;
    }

    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSDate *date = [calendar dateByAddingUnit:NSCalendarUnitDay value:dayOffset toDate:self.selectedDate ?: [NSDate now] options:0];
    [self updateSelectedDate:date animatedWithDayOffset:dayOffset];
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)goToToday
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [self dismissDatePicker];
    [self updateSelectedDate:[NSDate now]];
}

- (void)showDatePicker
{
    if (self.calendarPickerContainerView.superview) {
        [self dismissDatePicker];
        return;
    }

    self.gridData = [MirrorStorage getGridData];
    [self applyCalendarSettings];
    [self updateCalendarSelectionForSelectedDate];
    [self.calendarView reloadDecorationsForDateComponents:[self gridDateComponents] animated:NO];
    [self.view addSubview:self.calendarPickerDismissView];
    [self.calendarPickerDismissView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    [self.view addSubview:self.calendarPickerContainerView];
    [self.calendarPickerContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.timelineViewController.view.mas_top).offset(8);
        make.centerX.mas_equalTo(self.view);
        make.width.mas_equalTo(MIN(kScreenWidth - 40*kWidthRatio, 340));
        make.height.mas_equalTo(320);
    }];
    self.calendarPickerContainerView.alpha = 0;
    self.calendarPickerContainerView.transform = CGAffineTransformMakeScale(0.96, 0.96);
    [UIView animateWithDuration:0.18 animations:^{
        self.calendarPickerContainerView.alpha = 1;
        self.calendarPickerContainerView.transform = CGAffineTransformIdentity;
    }];
}

- (void)dismissDatePicker
{
    if (!self.calendarPickerContainerView.superview) {
        return;
    }

    [UIView animateWithDuration:0.16 animations:^{
        self.calendarPickerContainerView.alpha = 0;
        self.calendarPickerContainerView.transform = CGAffineTransformMakeScale(0.96, 0.96);
    } completion:^(BOOL finished) {
        self.calendarPickerContainerView.transform = CGAffineTransformIdentity;
        [self.calendarPickerContainerView removeFromSuperview];
        [self.calendarPickerDismissView removeFromSuperview];
    }];
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
    [self dismissDatePicker];
    [self updateHeaderStateWithRecords:nil];
    [self updateNavigationItem];
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

#pragma mark - Header

- (void)updateHeaderStateWithRecords:(NSMutableArray<MirrorRecordModel *> *)records
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    self.headerContainerView.backgroundColor = self.view.backgroundColor;
    self.todayTotalHeader.backgroundColor = self.view.backgroundColor;
    [self updateTodayButtonState];
    if (records) {
        __weak typeof(self) weakSelf = self;
        [self.todayTotalHeader configWithDate:self.selectedDate ?: [NSDate now] records:records datePickerHandler:^{
            [weakSelf showDatePicker];
        } specialDayTapHandler:^{
            [weakSelf showSpecialDays];
        }];
    }
}

- (void)updateNavigationItem
{
    [self updateSpecialDaysButton];
    [self updateTodayButtonState];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.specialDaysButton rightButton:self.todayButtonContainer];
}

- (void)showSpecialDays
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    SpecialDaysViewController *specialDaysVC = [[SpecialDaysViewController alloc] initWithFocusDateStr:[self keyFromDate:self.selectedDate ?: [NSDate now]]];
    [self.navigationController pushViewController:specialDaysVC animated:YES];
}

- (void)flashSpecialDaysButtonTwice
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    self.specialDaysButton.alpha = 1;
    [UIView animateKeyframesWithDuration:0.56 delay:0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.18 animations:^{
            self.specialDaysButton.alpha = 0.25;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.18 relativeDuration:0.18 animations:^{
            self.specialDaysButton.alpha = 1;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.18 animations:^{
            self.specialDaysButton.alpha = 0.25;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.68 relativeDuration:0.32 animations:^{
            self.specialDaysButton.alpha = 1;
        }];
    } completion:^(BOOL finished) {
        self.specialDaysButton.alpha = 1;
    }];
}

- (void)updateSpecialDaysButton
{
    NSMutableArray<MirrorDayModel *> *days = [MirrorStorage retriveMirrorDays];
    MirrorDayModel *latestDay = days.lastObject;
    NSString *iconName = [self specialDaysButtonIconNameFromStoredIconName:latestDay.icon];
    UIImage *iconImage = [[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.specialDaysButton setImage:iconImage forState:UIControlStateNormal];
    self.specialDaysButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
}

- (NSString *)specialDaysButtonIconNameFromStoredIconName:(NSString *)storedIconName
{
    if (storedIconName.length == 0) {
        return @"star";
    }
    
    NSString *outlineIconName = storedIconName;
    if ([storedIconName hasSuffix:@".fill"]) {
        outlineIconName = [storedIconName substringToIndex:storedIconName.length - @".fill".length];
    }
    
    if ([UIImage systemImageNamed:outlineIconName]) {
        return outlineIconName;
    }
    if ([UIImage systemImageNamed:storedIconName]) {
        return storedIconName;
    }
    return @"star";
}

- (void)updateTodayButtonState
{
    BOOL isToday = [self isSelectedDateToday];
    UIColor *textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    self.todayButton.enabled = !isToday;
    self.todayButton.backgroundColor = UIColor.clearColor;
    UIImage *image = [[UIImage systemImageNamed:[self todayCalendarSymbolName]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.todayButton setImage:image forState:UIControlStateNormal];
    self.todayButton.tintColor = isToday ? [textColor colorWithAlphaComponent:0.35] : textColor;
}

- (BOOL)isSelectedDateToday
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    return [calendar isDate:self.selectedDate ?: [NSDate now] inSameDayAsDate:[NSDate now]];
}

#pragma mark - Calendar Picker

- (NSCalendar *)calendarForCurrentSettings
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    calendar.firstWeekday = [MirrorSettings appliedWeekStarsOnMonday] ? 2 : 1;
    return calendar;
}

- (void)applyCalendarSettings
{
    self.calendarView.calendar = [self calendarForCurrentSettings];
    self.calendarView.locale = [MirrorTool formatterLocaleForCurrentLanguage];
}

- (void)handleWeekStartsOnChanged
{
    if (!_calendarView) {
        return;
    }
    [self applyCalendarSettings];
    [self updateCalendarSelectionForSelectedDate];
    if (self.calendarPickerContainerView.superview) {
        [self.calendarView reloadDecorationsForDateComponents:[self gridDateComponents] animated:NO];
    }
}

- (void)updateCalendarSelectionForSelectedDate
{
    NSDateComponents *components = [self.calendarView.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.selectedDate ?: [NSDate now]];
    [self.calendarView setVisibleDateComponents:components animated:NO];
    [self.dateSelection setSelectedDate:components animated:NO];
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

- (UICalendarViewDecoration *)calendarView:(UICalendarView *)calendarView decorationForDateComponents:(NSDateComponents *)dateComponents API_AVAILABLE(ios(16.0))
{
    NSDate *date = dateComponents.date;
    if (!date) return nil;

    long totalTime = 0;
    NSMutableArray<NSNumber *> *taskTimes = [NSMutableArray array];
    NSMutableArray<UIColor *> *taskColors = [NSMutableArray array];
    [self getTaskTimes:taskTimes taskColors:taskColors totalTime:&totalTime forDate:date];
    if (totalTime == 0 || taskTimes.count == 0 || taskColors.count == 0) return nil;

    CGFloat barHeight = 6;
    CGFloat minWidth = barHeight;
    CGFloat maxWidth = 30;
    CGFloat hours = totalTime / 3600.0;
    CGFloat barWidth = minWidth;
    if (hours >= 8) {
        barWidth = maxWidth;
    } else if (hours > 1) {
        barWidth = minWidth + (maxWidth - minWidth) * ((hours - 1) / 7.0);
    }

    return [UICalendarViewDecoration decorationWithCustomViewProvider:^UIView * _Nonnull{
        UIView *barView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, barWidth, barHeight)];
        barView.layer.cornerRadius = barHeight / 2;
        barView.clipsToBounds = YES;

        CGFloat currentX = 0;
        for (NSInteger index = 0; index < taskTimes.count; index++) {
            CGFloat segmentWidth = index == taskTimes.count - 1 ? barWidth - currentX : barWidth * (taskTimes[index].doubleValue / (CGFloat)totalTime);
            if (segmentWidth <= 0) {
                continue;
            }
            UIView *segmentView = [[UIView alloc] initWithFrame:CGRectMake(currentX, 0, segmentWidth, barHeight)];
            segmentView.backgroundColor = taskColors[index];
            [barView addSubview:segmentView];
            currentX += segmentWidth;
        }
        return barView;
    }];
}

- (BOOL)dateSelection:(UICalendarSelectionSingleDate *)selection canSelectDate:(NSDateComponents *)dateComponents API_AVAILABLE(ios(16.0))
{
    return dateComponents != nil;
}

- (void)dateSelection:(UICalendarSelectionSingleDate *)selection didSelectDate:(NSDateComponents *)dateComponents API_AVAILABLE(ios(16.0))
{
    NSDate *date = dateComponents.date;
    if (!date) return;
    [self updateSelectedDate:date];
}

- (void)getTaskTimes:(NSMutableArray<NSNumber *> *)taskTimes taskColors:(NSMutableArray<UIColor *> *)taskColors totalTime:(long *)totalTime forDate:(NSDate *)date
{
    NSMutableArray<MirrorReadModel *> *data = self.gridData[[self keyFromDate:date]];
    if (data.count == 0) return;

    for (MirrorReadModel *readModel in data) {
        long taskTime = [MirrorTool getTotalTimeOfPeriods:readModel.records];
        if (taskTime > 0) {
            [taskTimes addObject:@(taskTime)];
            [taskColors addObject:[UIColor mirrorColorNamed:readModel.taskModel.color]];
        }
        *totalTime += taskTime;
    }
}

- (NSString *)keyFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:date];
}

#pragma mark - Getters

- (UIView *)headerContainerView
{
    if (!_headerContainerView) {
        _headerContainerView = [UIView new];
        _headerContainerView.clipsToBounds = YES;
        [_headerContainerView addSubview:self.todayTotalHeader];
        [self.todayTotalHeader mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.offset(0);
        }];
    }
    return _headerContainerView;
}

- (TodayTotalHeader *)todayTotalHeader
{
    if (!_todayTotalHeader) {
        _todayTotalHeader = [TodayTotalHeader new];
    }
    return _todayTotalHeader;
}

- (UIView *)calendarPickerDismissView
{
    if (!_calendarPickerDismissView) {
        _calendarPickerDismissView = [UIView new];
        _calendarPickerDismissView.backgroundColor = UIColor.clearColor;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissDatePicker)];
        [_calendarPickerDismissView addGestureRecognizer:tapGesture];
    }
    return _calendarPickerDismissView;
}

- (UIView *)calendarPickerContainerView
{
    if (!_calendarPickerContainerView) {
        _calendarPickerContainerView = [UIView new];
        _calendarPickerContainerView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _calendarPickerContainerView.layer.cornerRadius = 8;
        _calendarPickerContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
        _calendarPickerContainerView.layer.shadowOpacity = 0.12;
        _calendarPickerContainerView.layer.shadowRadius = 12;
        _calendarPickerContainerView.layer.shadowOffset = CGSizeMake(0, 4);
        [_calendarPickerContainerView addSubview:self.calendarView];
        [self.calendarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.insets(UIEdgeInsetsMake(8, 8, 8, 8));
        }];
    }
    return _calendarPickerContainerView;
}

- (UICalendarView *)calendarView API_AVAILABLE(ios(16.0))
{
    if (!_calendarView) {
        _calendarView = [UICalendarView new];
        _calendarView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _calendarView.calendar = [self calendarForCurrentSettings];
        _calendarView.locale = [MirrorTool formatterLocaleForCurrentLanguage];
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
        NSDateComponents *components = [self.calendarView.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.selectedDate ?: [NSDate now]];
        [_dateSelection setSelectedDate:components animated:NO];
    }
    return _dateSelection;
}

- (UIButton *)todayButton
{
    if (!_todayButton) {
        _todayButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _todayButton.backgroundColor = UIColor.clearColor;
        _todayButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_todayButton addTarget:self action:@selector(goToToday) forControlEvents:UIControlEventTouchUpInside];
    }
    return _todayButton;
}

- (UIButton *)specialDaysButton
{
    if (!_specialDaysButton) {
        _specialDaysButton = [UIButton new];
        [_specialDaysButton addTarget:self action:@selector(showSpecialDays) forControlEvents:UIControlEventTouchUpInside];
        [self updateSpecialDaysButton];
    }
    return _specialDaysButton;
}

- (UIView *)todayButtonContainer
{
    if (!_todayButtonContainer) {
        _todayButtonContainer = [UIView new];
        [_todayButtonContainer addSubview:self.todayButton];
        [self.todayButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.right.offset(0);
            make.height.mas_equalTo(30*kHeightRatio);
            make.width.mas_equalTo([self todayButtonWidth]);
        }];
        _todayButtonContainer.frame = CGRectMake(0, 0, [self todayButtonWidth], 44*kHeightRatio);
    }
    return _todayButtonContainer;
}

- (CGFloat)todayButtonWidth
{
    return 32*kWidthRatio;
}

- (NSString *)todayCalendarSymbolName
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSInteger day = [calendar component:NSCalendarUnitDay fromDate:[NSDate now]];
    return [NSString stringWithFormat:@"%ld.calendar", (long)day];
}

@end
