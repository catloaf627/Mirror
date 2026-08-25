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

typedef void (^MirrorHandmadeCalendarDateHandler)(NSDate *date);
typedef void (^MirrorHandmadeCalendarLayoutHandler)(void);

@interface MirrorHandmadeCalendarView : UIView

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, copy) MirrorHandmadeCalendarDateHandler dateSelectionHandler;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<UIColor *> *> *recordColorsByDateKey;
@property (nonatomic, copy) NSDictionary<NSString *, MirrorDayModel *> *specialDaysByDateKey;
@property (nonatomic, assign) BOOL weekStartsOnMonday;
@property (nonatomic, copy) MirrorHandmadeCalendarLayoutHandler layoutChangeHandler;

- (instancetype)initWithSelectedDate:(NSDate *)selectedDate;
- (void)reloadCalendar;
- (CGFloat)preferredHeight;

@end

@interface TodayViewController () <UIGestureRecognizerDelegate>

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
@property (nonatomic, strong) MirrorHandmadeCalendarView *handmadeCalendarView;
@property (nonatomic, strong) NSDictionary<NSString *, NSMutableArray<MirrorReadModel *> *> *gridData;
@property (nonatomic, strong) NSDictionary<NSString *, MirrorDayModel *> *specialDaysByDateKey;

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSpecialDaysChanged) name:MirrorDayEditNotification object:nil];
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
    self.handmadeCalendarView = nil;
    self.gridData = nil;
    self.specialDaysByDateKey = nil;
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
    [self reloadSpecialDaysByDateKey];
    [self updateHandmadeCalendarData];
    [self.view addSubview:self.calendarPickerDismissView];
    [self.calendarPickerDismissView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    [self.view addSubview:self.calendarPickerContainerView];
    [self updateCalendarPickerContainerConstraints];
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
    [self updateSelectedDate:date dismissDatePicker:YES];
}

- (void)updateSelectedDate:(NSDate *)date dismissDatePicker:(BOOL)dismissDatePicker
{
    if (!date) {
        return;
    }
    self.selectedDate = date;
    if (dismissDatePicker) {
        [self dismissDatePicker];
    }
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

- (void)updateSpecialDaysButton
{
    NSMutableArray<MirrorDayModel *> *days = [MirrorStorage retriveMirrorDays];
    MirrorDayModel *selectedDay = [self specialDayFromDays:days dateStr:[self keyFromDate:self.selectedDate ?: [NSDate now]]];
    NSString *iconName = nil;
    UIColor *tintColor = nil;
    if (selectedDay) {
        // 当前日期是 special day：用当天保存的 icon 和颜色，保留 .fill。
        iconName = [self specialDaysButtonFilledIconNameFromStoredIconName:selectedDay.icon];
        tintColor = [UIColor mirrorSystemColorNamed:selectedDay.color];
    } else {
        // 当前日期不是 special day：使用默认图标和默认颜色。
        iconName = @"sparkles";
        tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    }
    UIImage *iconImage = [[UIImage systemImageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.specialDaysButton setImage:iconImage forState:UIControlStateNormal];
    self.specialDaysButton.tintColor = tintColor;
}

- (void)handleSpecialDaysChanged
{
    [self reloadSpecialDaysByDateKey];
    [self updateSpecialDaysButton];
    if (self.calendarPickerContainerView.superview) {
        [self updateHandmadeCalendarData];
    }
}

- (void)reloadSpecialDaysByDateKey
{
    NSMutableDictionary<NSString *, MirrorDayModel *> *daysByDateKey = [NSMutableDictionary new];
    for (MirrorDayModel *day in [MirrorStorage retriveMirrorDays]) {
        if (day.dateStr.length > 0) {
            daysByDateKey[day.dateStr] = day;
        }
    }
    self.specialDaysByDateKey = daysByDateKey;
}

- (MirrorDayModel *)specialDayFromDays:(NSArray<MirrorDayModel *> *)days dateStr:(NSString *)dateStr
{
    for (MirrorDayModel *day in days) {
        if ([day.dateStr isEqualToString:dateStr]) {
            return day;
        }
    }
    return nil;
}

- (NSString *)specialDaysButtonFilledIconNameFromStoredIconName:(NSString *)storedIconName
{
    if (storedIconName.length > 0 && [UIImage systemImageNamed:storedIconName]) {
        return storedIconName;
    }
    return @"star.fill";
}

- (void)updateTodayButtonState
{
    BOOL isToday = [self isSelectedDateToday];
    UIColor *textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    UIColor *buttonColor = isToday ? [textColor colorWithAlphaComponent:0] : textColor;
    self.todayButton.enabled = !isToday;
    self.todayButton.backgroundColor = UIColor.clearColor;
    self.todayButton.tintColor = buttonColor;
    [self.todayButton setTitleColor:buttonColor forState:UIControlStateNormal];
    [self.todayButton setImage:nil forState:UIControlStateNormal];
    [self.todayButton setTitle:[MirrorLanguage mirror_stringWithKey:@"today"] forState:UIControlStateNormal];
}

- (BOOL)isSelectedDateToday
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    return [calendar isDate:self.selectedDate ?: [NSDate now] inSameDayAsDate:[NSDate now]];
}

#pragma mark - Calendar Picker

- (void)handleWeekStartsOnChanged
{
    self.handmadeCalendarView.weekStartsOnMonday = [MirrorSettings appliedWeekStarsOnMonday];
}

- (void)updateHandmadeCalendarData
{
    self.handmadeCalendarView.selectedDate = self.selectedDate ?: [NSDate now];
    self.handmadeCalendarView.weekStartsOnMonday = [MirrorSettings appliedWeekStarsOnMonday];
    self.handmadeCalendarView.recordColorsByDateKey = [self handmadeCalendarRecordColorsByDateKey];
    self.handmadeCalendarView.specialDaysByDateKey = self.specialDaysByDateKey ?: @{};
    [self.handmadeCalendarView reloadCalendar];
}

- (NSDictionary<NSString *, NSArray<UIColor *> *> *)handmadeCalendarRecordColorsByDateKey
{
    NSMutableDictionary<NSString *, NSArray<UIColor *> *> *colorsByDateKey = [NSMutableDictionary new];
    if (![self.gridData isKindOfClass:NSDictionary.class]) {
        return colorsByDateKey;
    }

    [self.gridData enumerateKeysAndObjectsUsingBlock:^(NSString *dateKey, NSMutableArray<MirrorReadModel *> *records, BOOL *stop) {
        if (![dateKey isKindOfClass:NSString.class] || dateKey.length == 0 || ![records isKindOfClass:NSArray.class]) {
            return;
        }
        NSMutableArray<UIColor *> *colors = [NSMutableArray new];
        for (id object in records) {
            if (![object isKindOfClass:MirrorReadModel.class]) {
                continue;
            }
            MirrorReadModel *readModel = object;
            if (![readModel.records isKindOfClass:NSArray.class]) {
                continue;
            }
            if (![readModel.taskModel isKindOfClass:MirrorTaskModel.class]) {
                continue;
            }
            long taskTime = [MirrorTool getTotalTimeOfPeriods:readModel.records];
            if (taskTime > 0) {
                UIColor *color = [UIColor mirrorColorNamed:readModel.taskModel.color];
                if ([color isKindOfClass:UIColor.class]) {
                    [colors addObject:color];
                }
            }
        }
        if (colors.count > 0) {
            colorsByDateKey[dateKey] = colors;
        }
    }];
    return colorsByDateKey;
}


- (NSString *)keyFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:date];
}

#pragma mark - Getters

- (UIButton *)specialDaysButton
{
    if (!_specialDaysButton) {
        _specialDaysButton = [UIButton new];
        [_specialDaysButton addTarget:self action:@selector(showSpecialDays) forControlEvents:UIControlEventTouchUpInside];
        [self updateSpecialDaysButton];
    }
    return _specialDaysButton;
}

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
        _calendarPickerContainerView.backgroundColor = UIColor.clearColor;
        _calendarPickerContainerView.layer.cornerRadius = 8;
        _calendarPickerContainerView.layer.borderWidth = 1;
        _calendarPickerContainerView.layer.borderColor = [[UIColor mirrorColorNamed:MirrorColorTypeText] colorWithAlphaComponent:0.12].CGColor;
        _calendarPickerContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
        _calendarPickerContainerView.layer.shadowOpacity = 0.12;
        _calendarPickerContainerView.layer.shadowRadius = 12;
        _calendarPickerContainerView.layer.shadowOffset = CGSizeMake(0, 4);

        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
        blurView.userInteractionEnabled = NO;
        blurView.alpha = 0.9;
        blurView.clipsToBounds = YES;
        blurView.layer.cornerRadius = 8;
        [_calendarPickerContainerView addSubview:blurView];
        [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.offset(0);
        }];

        [_calendarPickerContainerView addSubview:self.handmadeCalendarView];
        [self.handmadeCalendarView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.insets(UIEdgeInsetsMake(8, 8, 8, 8));
        }];
    }
    return _calendarPickerContainerView;
}

- (MirrorHandmadeCalendarView *)handmadeCalendarView
{
    if (!_handmadeCalendarView) {
        _handmadeCalendarView = [[MirrorHandmadeCalendarView alloc] initWithSelectedDate:self.selectedDate ?: [NSDate now]];
        _handmadeCalendarView.weekStartsOnMonday = [MirrorSettings appliedWeekStarsOnMonday];
        __weak typeof(self) weakSelf = self;
        _handmadeCalendarView.dateSelectionHandler = ^(NSDate *date) {
            [weakSelf updateSelectedDate:date dismissDatePicker:NO];
        };
        _handmadeCalendarView.layoutChangeHandler = ^{
            [weakSelf updateCalendarPickerContainerConstraints];
        };
    }
    return _handmadeCalendarView;
}

- (UIButton *)todayButton
{
    if (!_todayButton) {
        _todayButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _todayButton.backgroundColor = UIColor.clearColor;
        _todayButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        _todayButton.titleLabel.font = [UIFont mirrorHintFont];
        _todayButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _todayButton.titleLabel.minimumScaleFactor = 0.75;
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
            make.height.mas_equalTo(30*kHeightRatio);
            make.width.mas_equalTo([self todayButtonWidth]);
        }];
        _todayButtonContainer.frame = CGRectMake(0, 0, [self todayButtonWidth], 44*kHeightRatio);
    }
    return _todayButtonContainer;
}

- (CGFloat)todayButtonWidth
{
    NSString *todayText = [MirrorLanguage mirror_stringWithKey:@"today"];
    CGFloat textWidth = [todayText sizeWithAttributes:@{NSFontAttributeName: [UIFont mirrorHintFont]}].width;
    return MAX(32*kWidthRatio, ceil(textWidth) + 8*kWidthRatio);
}

- (void)updateCalendarPickerContainerConstraints
{
    if (!self.calendarPickerContainerView.superview) {
        return;
    }
    [self.calendarPickerContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.timelineViewController.view.mas_top).offset(8);
        make.centerX.mas_equalTo(self.view);
        make.width.mas_equalTo([self calendarPickerWidth]);
        make.height.mas_equalTo([self calendarPickerHeight]);
    }];
}

- (CGFloat)calendarPickerWidth
{
    return MIN(kScreenWidth - 32*kWidthRatio, 380);
}

- (CGFloat)calendarPickerHeight
{
    CGFloat top = CGRectGetMinY(self.timelineViewController.view.frame) + 8;
    CGFloat bottomPadding = self.tabBarController.tabBar.frame.size.height + MirrorBottomSafeAreaHeight() + 12;
    CGFloat availableHeight = MAX(0, kScreenHeight - top - bottomPadding);
    CGFloat contentHeight = [self.handmadeCalendarView preferredHeight] + 16;
    return MIN(contentHeight, availableHeight);
}

@end
