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
#import "MirrorSettings.h"
#import "LeftAnimation.h"
#import "SettingsViewController.h"
#import "MirrorLanguage.h"
#import "TodayTotalHeader.h"
#import "MirrorStorage.h"
#import "UIFont+MirrorFont.h"

#define kLeftRightSpacing (20*kWidthRatio)
#define kTimelineLeftWidth (52*kWidthRatio)
#define kTimelineRightPadding (12*kWidthRatio)
#define kTimelineRecordSpacing (6*kHeightRatio)
#define kTimelineMinimumTinyRecordHeight 10
#define kTimelineTinyRecordThresholdSeconds (10 * 60)
#define kTimelineTextHiddenThresholdSeconds (45 * 60)

@interface TodayViewController () <UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate, UIEditMenuInteractionDelegate>

@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, assign) BOOL didScrollToDefaultHours;
@property (nonatomic, assign) CGFloat hourHeight;
@property (nonatomic, assign) long pendingStartTimestamp;
@property (nonatomic, assign) NSInteger selectedPeriodIndex;
@property (nonatomic, assign) NSInteger editingPeriodIndex;
@property (nonatomic, assign) BOOL isRecordEditMenuVisible;
@property (nonatomic, assign) BOOL shouldSuppressNextTaskPicker;
@property (nonatomic, strong) UIDatePicker *editingStartPicker;
@property (nonatomic, strong) UIDatePicker *editingEndPicker;
@property (nonatomic, strong) UITapGestureRecognizer *editingDismissTapRecognizer;
@property (nonatomic, weak) UIEditMenuInteraction *visibleRecordEditMenuInteraction API_AVAILABLE(ios(16.0));

// Navibar
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactiveTransition;

// Data source
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *todayData;

// UI
@property (nonatomic, strong) TodayTotalHeader *todayHeader;
@property (nonatomic, strong) UIScrollView *timelineScrollView;
@property (nonatomic, strong) UIView *timelineContentView;
@property (nonatomic, strong) UIView *taskPickerOverlayView;

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
    [self p_setupUI];
    _isLoaded = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateTimelineSizeIfNeeded];
}

- (void)restartVC
{
    // 更新tabbar
    [[MirrorTabsManager sharedInstance] updateTodayTabItemWithTabController:self.tabBarController];
    if (!_isLoaded) return;
    // 将vc.view里的所有subviews全部置为nil
    self.todayHeader = nil;
    self.timelineScrollView = nil;
    self.timelineContentView = nil;
    self.taskPickerOverlayView = nil;
    self.didScrollToDefaultHours = NO;
    self.hourHeight = 0;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 更新navibar
    if (self.tabBarController.selectedIndex == 1) {
        [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:nil];
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
    self.todayData = [MirrorStorage getTodayData];
    [self.todayHeader configWithRecords:self.todayData];
    [self renderTimeline];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];

    [self.view addSubview:self.todayHeader];
    [self.todayHeader configWithRecords:self.todayData];
    [self.todayHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.left.offset(kLeftRightSpacing);
        make.right.offset(-kLeftRightSpacing);
        make.height.mas_equalTo(kTodayHeaderHeight);
    }];

    [self.view addSubview:self.timelineScrollView];
    [self.timelineScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.todayHeader.mas_bottom);
        make.left.right.offset(0);
        make.bottom.offset(-self.tabBarController.tabBar.frame.size.height);
    }];

    [self.timelineScrollView addSubview:self.timelineContentView];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTimeline:)];
    tapRecognizer.delegate = self;
    [self.timelineContentView addGestureRecognizer:tapRecognizer];

    UIScreenEdgePanGestureRecognizer *edgeRecognizer = [UIScreenEdgePanGestureRecognizer new];
    edgeRecognizer.edges = UIRectEdgeLeft;
    [edgeRecognizer addTarget:self action:@selector(edgeGestureRecognizerAction:)];
    [self.view addGestureRecognizer:edgeRecognizer];
}

#pragma mark - Actions

- (void)goToSettings
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    SettingsViewController * settingsVC = [[SettingsViewController alloc] init];
    settingsVC.transitioningDelegate = self;
    settingsVC.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:settingsVC animated:YES completion:nil];
}

- (void)tapTimeline:(UITapGestureRecognizer *)tapRecognizer
{
    if ([self dismissVisibleRecordEditMenuIfNeeded] || self.shouldSuppressNextTaskPicker) {
        self.shouldSuppressNextTaskPicker = NO;
        return;
    }
    // 震动反馈
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc]
        initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];
    // 显示添加task的逻辑
    CGPoint point = [tapRecognizer locationInView:self.timelineContentView];
    if ([self pointHitsRecordView:point]) {
        return;
    }
    self.pendingStartTimestamp = [self timestampForTimelineY:point.y];
    [self showTaskPickerAtPoint:point];
}

- (void)showEditMenu:(UITapGestureRecognizer *)recognizer
{
    // 震动反馈
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc]
        initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];
    // 显示编辑菜单的逻辑
    UIView *view = recognizer.view;
    self.selectedPeriodIndex = view.tag;
    UIEditMenuInteraction *editMenuInteraction = nil;
    for (id<UIInteraction> interaction in view.interactions) {
        if ([interaction isKindOfClass:[UIEditMenuInteraction class]]) {
            editMenuInteraction = (UIEditMenuInteraction *)interaction;
            break;
        }
    }
    if (!editMenuInteraction) {
        return;
    }
    
    CGPoint point = [recognizer locationInView:view];
    UIEditMenuConfiguration *configuration = [UIEditMenuConfiguration configurationWithIdentifier:nil sourcePoint:point];
    [editMenuInteraction presentEditMenuWithConfiguration:configuration];
}

- (UIMenu *)recordMenuForPeriodIndex:(NSInteger)periodIndex
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (periodIndex < 0 || periodIndex >= records.count) {
        return nil;
    }
    
    UIAction *editAction = [UIAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"edit"] image:nil identifier:nil handler:^(__kindof UIAction *action) {
        UIButton *button = [UIButton new];
        button.tag = periodIndex;
        [self editPeriod:button];
    }];
    UIAction *deleteAction = [UIAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [MirrorStorage deletePeriodAtIndex:periodIndex];
    }];
    deleteAction.attributes = UIMenuElementAttributesDestructive;
    return [UIMenu menuWithTitle:@"" children:@[editAction, deleteAction]];
}

- (UIMenu *)editMenuInteraction:(UIEditMenuInteraction *)interaction menuForConfiguration:(UIEditMenuConfiguration *)configuration suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0))
{
    return [self recordMenuForPeriodIndex:self.selectedPeriodIndex];
}

- (void)editMenuInteraction:(UIEditMenuInteraction *)interaction willPresentMenuForConfiguration:(UIEditMenuConfiguration *)configuration animator:(id<UIEditMenuInteractionAnimating>)animator API_AVAILABLE(ios(16.0))
{
    self.isRecordEditMenuVisible = YES;
    self.visibleRecordEditMenuInteraction = interaction;
}

- (void)editMenuInteraction:(UIEditMenuInteraction *)interaction willDismissMenuForConfiguration:(UIEditMenuConfiguration *)configuration animator:(id<UIEditMenuInteractionAnimating>)animator API_AVAILABLE(ios(16.0))
{
    if (interaction == self.visibleRecordEditMenuInteraction) {
        self.isRecordEditMenuVisible = NO;
        self.visibleRecordEditMenuInteraction = nil;
        self.shouldSuppressNextTaskPicker = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.isRecordEditMenuVisible) {
                self.shouldSuppressNextTaskPicker = NO;
            }
        });
    }
}

- (void)deletePeriod:(UIButton *)sender
{
    NSInteger periodIndex = sender.tag;
    UIAlertController* deleteButtonAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete_period_?"] message:nil preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [MirrorStorage deletePeriodAtIndex:periodIndex];
    }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];

    [deleteButtonAlert addAction:cancelAction];
    [deleteButtonAlert addAction:deleteAction];
    [self presentViewController:deleteButtonAlert animated:YES completion:nil];
}

- (void)editPeriod:(UIButton *)sender
{
    NSInteger periodIndex = sender.tag;
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (periodIndex < 0 || periodIndex >= records.count) {
        return;
    }
    
    MirrorRecordModel *record = records[periodIndex];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:record.taskName message:@"\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    
    UIDatePicker *startPicker = [UIDatePicker new];
    startPicker.datePickerMode = UIDatePickerModeTime;
    startPicker.timeZone = [NSTimeZone systemTimeZone];
    startPicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    startPicker.date = [NSDate dateWithTimeIntervalSince1970:record.startTime];
    startPicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:record.endTime - kMinSeconds];
    [startPicker addTarget:self action:@selector(startPickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    if (periodIndex - 1 >= 0) {
        startPicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:records[periodIndex - 1].endTime];
    } else {
        startPicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:[self todayStartTimestamp]];
    }
    
    UIDatePicker *endPicker = [UIDatePicker new];
    endPicker.datePickerMode = UIDatePickerModeTime;
    endPicker.timeZone = [NSTimeZone systemTimeZone];
    endPicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    endPicker.date = [NSDate dateWithTimeIntervalSince1970:record.endTime];
    endPicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:record.startTime + kMinSeconds];
    [endPicker addTarget:self action:@selector(endPickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    if (periodIndex + 1 <= records.count - 1) {
        endPicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:records[periodIndex + 1].startTime];
    } else {
        endPicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:[self todayStartTimestamp] + 24 * 3600];
    }
    
    self.editingPeriodIndex = periodIndex;
    self.editingStartPicker = startPicker;
    self.editingEndPicker = endPicker;
    
    UILabel *startLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"starts_at"]];
    UILabel *endLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"ends_at"]];
    UIView *contentView = alertController.view;
    [contentView addSubview:startLabel];
    [contentView addSubview:startPicker];
    [contentView addSubview:endLabel];
    [contentView addSubview:endPicker];
    
    [startLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(24);
        make.top.offset(58);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(30);
    }];
    [startPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(startLabel.mas_right).offset(8);
        make.centerY.mas_equalTo(startLabel);
        make.right.offset(-24);
        make.height.mas_equalTo(34);
    }];
    [endLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(startLabel);
        make.top.mas_equalTo(startLabel.mas_bottom).offset(8);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(30);
    }];
    [endPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(endLabel.mas_right).offset(8);
        make.centerY.mas_equalTo(endLabel);
        make.right.offset(-24);
        make.height.mas_equalTo(34);
    }];
    
    [self presentViewController:alertController animated:YES completion:^{
        [self addEditingDismissTapRecognizer];
    }];
}

- (void)addEditingDismissTapRecognizer
{
    if (self.editingDismissTapRecognizer != nil) {
        return;
    }
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissEditingPeriodAlert:)];
    tapRecognizer.cancelsTouchesInView = NO;
    self.editingDismissTapRecognizer = tapRecognizer;
    [self.view.window addGestureRecognizer:tapRecognizer];
}

- (void)dismissEditingPeriodAlert:(UITapGestureRecognizer *)tapRecognizer
{
    UIViewController *presentedViewController = self.presentedViewController;
    UIView *alertView = presentedViewController.view;
    CGPoint tapPoint = [tapRecognizer locationInView:alertView];
    if (CGRectContainsPoint(alertView.bounds, tapPoint)) {
        return;
    }
    [self removeEditingDismissTapRecognizer];
    self.editingStartPicker = nil;
    self.editingEndPicker = nil;
    [presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)removeEditingDismissTapRecognizer
{
    [self.view.window removeGestureRecognizer:self.editingDismissTapRecognizer];
    self.editingDismissTapRecognizer = nil;
}

- (void)startPickerValueChanged:(UIDatePicker *)picker
{
    NSDate *minimumEndDate = [picker.date dateByAddingTimeInterval:kMinSeconds];
    self.editingEndPicker.minimumDate = minimumEndDate;
    if ([self.editingEndPicker.date compare:minimumEndDate] == NSOrderedAscending) {
        self.editingEndPicker.date = minimumEndDate;
        [MirrorStorage editPeriodIsStartTime:NO to:round([minimumEndDate timeIntervalSince1970]) periodIndex:self.editingPeriodIndex];
    }
    [MirrorStorage editPeriodIsStartTime:YES to:round([picker.date timeIntervalSince1970]) periodIndex:self.editingPeriodIndex];
}

- (void)endPickerValueChanged:(UIDatePicker *)picker
{
    NSDate *maximumStartDate = [picker.date dateByAddingTimeInterval:-kMinSeconds];
    self.editingStartPicker.maximumDate = maximumStartDate;
    if ([self.editingStartPicker.date compare:maximumStartDate] == NSOrderedDescending) {
        self.editingStartPicker.date = maximumStartDate;
        [MirrorStorage editPeriodIsStartTime:YES to:round([maximumStartDate timeIntervalSince1970]) periodIndex:self.editingPeriodIndex];
    }
    [MirrorStorage editPeriodIsStartTime:NO to:round([picker.date timeIntervalSince1970]) periodIndex:self.editingPeriodIndex];
}

#pragma mark - Timeline

- (void)updateTimelineSizeIfNeeded
{
    CGFloat visibleHeight = CGRectGetHeight(self.timelineScrollView.bounds);
    CGFloat width = CGRectGetWidth(self.timelineScrollView.bounds);
    if (visibleHeight <= 0 || width <= 0) {
        return;
    }

    CGFloat newHourHeight = visibleHeight / 12.0;
    CGSize contentSize = CGSizeMake(width, newHourHeight * 24.0);
    BOOL needsRender = fabs(self.hourHeight - newHourHeight) > 0.5 || !CGSizeEqualToSize(self.timelineScrollView.contentSize, contentSize);
    if (!needsRender) {
        return;
    }

    self.hourHeight = newHourHeight;
    self.timelineScrollView.contentSize = contentSize;
    self.timelineContentView.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);
    [self renderTimeline];

    if (!self.didScrollToDefaultHours) {
        [self.timelineScrollView setContentOffset:CGPointMake(0, self.hourHeight * 7.0) animated:NO];
        self.didScrollToDefaultHours = YES;
    }
}

- (void)renderTimeline
{
    if (self.hourHeight <= 0 || CGRectGetWidth(self.timelineContentView.bounds) <= 0) {
        return;
    }

    [self.timelineContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self renderHourLines];
    [self renderRecords];
}

- (void)renderHourLines
{
    CGFloat width = CGRectGetWidth(self.timelineContentView.bounds);
    for (NSInteger hour = 0; hour <= 24; hour++) {
        CGFloat y = hour * self.hourHeight;
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse];
        line.alpha = 0.2;
        [self.timelineContentView addSubview:line];
        line.frame = CGRectMake(kTimelineLeftWidth, y, width - kTimelineLeftWidth - kTimelineRightPadding, 1);

        if (hour < 24) {
            UILabel *hourLabel = [UILabel new];
            hourLabel.text = [NSString stringWithFormat:@"%02ld:00", (long)hour];
            hourLabel.font = [UIFont mirrorMinFont];
            hourLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
            hourLabel.alpha = 0.5;
            hourLabel.textAlignment = NSTextAlignmentRight;
            [self.timelineContentView addSubview:hourLabel];
            hourLabel.frame = CGRectMake(0, y - 10, kTimelineLeftWidth - 8*kWidthRatio, 20);
        }
    }
}

- (void)renderRecords
{
    long dayStart = [self todayStartTimestamp];
    long dayEnd = dayStart + 24 * 3600;
    CGFloat recordX = kTimelineLeftWidth;
    CGFloat recordWidth = CGRectGetWidth(self.timelineContentView.bounds) - recordX - kTimelineRightPadding;

    for (MirrorRecordModel *record in [MirrorStorage retriveMirrorRecords]) {
        long start = MAX(record.startTime, dayStart);
        long end = MIN(record.endTime, dayEnd);
        if (end <= start) {
            continue;
        }

        long duration = end - start;
        CGFloat top = ((CGFloat)(start - dayStart) / 3600.0) * self.hourHeight;
        CGFloat height = ((CGFloat)duration / 3600.0) * self.hourHeight;
        if (duration < kTimelineTinyRecordThresholdSeconds) {
            height = MAX(height, kTimelineMinimumTinyRecordHeight);
        }
        BOOL showsText = duration >= kTimelineTextHiddenThresholdSeconds;
        UIView *recordView = [self recordViewWithRecord:record frame:CGRectMake(recordX, top, recordWidth, height) showsText:showsText];
        [self.timelineContentView addSubview:recordView];
    }
}

- (UIView *)recordViewWithRecord:(MirrorRecordModel *)record frame:(CGRect)frame showsText:(BOOL)showsText
{
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:record.taskName];
    UIColor *recordColor = task ? [UIColor mirrorColorNamed:task.color] : [UIColor mirrorColorNamed:MirrorColorTypeCellGray];

    UIView *recordView = [[UIView alloc] initWithFrame:frame];
    recordView.accessibilityIdentifier = @"TodayTimelineRecordView";
    recordView.layer.cornerRadius = 5;
    recordView.layer.masksToBounds = YES;
    recordView.backgroundColor = recordColor;

    UIView *foregroundView = [[UIView alloc] initWithFrame:recordView.bounds];
    foregroundView.backgroundColor = recordColor;
    foregroundView.layer.cornerRadius = 5;
    foregroundView.layer.masksToBounds = YES;
    foregroundView.tag = record.originalIndex;
    if (@available(iOS 16.0, *)) {
        UIEditMenuInteraction *editMenuInteraction = [[UIEditMenuInteraction alloc] initWithDelegate:self];
        [foregroundView addInteraction:editMenuInteraction];
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showEditMenu:)];
        tapRecognizer.delegate = self;
        [foregroundView addGestureRecognizer:tapRecognizer];
    }
    [recordView addSubview:foregroundView];

    if (showsText) {
        UILabel *titleLabel = [UILabel new];
        titleLabel.text = [NSString stringWithFormat:@"%@  %@", record.taskName, [self timeTextForRecord:record]];
        titleLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        titleLabel.font = [UIFont mirrorHintFont_Card];
        titleLabel.adjustsFontSizeToFitWidth = YES;
        [foregroundView addSubview:titleLabel];

        CGFloat labelPadding = 5*kWidthRatio;
        CGFloat labelHeight = 15*kWidthRatio;
        titleLabel.frame = CGRectMake(
            labelPadding,
            labelPadding,
            CGRectGetWidth(frame) - 2*labelPadding,
            labelHeight
        );
    }

    return recordView;
}

#pragma mark - Add Records

- (void)showTaskPickerAtPoint:(CGPoint)point
{
    NSMutableArray<MirrorTaskModel *> *tasks = [MirrorStorage tasksWithAddNew];
    NSMutableArray<MirrorTaskModel *> *availableTasks = [NSMutableArray new];
    for (MirrorTaskModel *task in tasks) {
        if (!task.isAddTaskModel) {
            [availableTasks addObject:task];
        }
    }

    if (availableTasks.count == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"no_task"] message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }

    [self showCompactTaskPickerWithTasks:availableTasks atPoint:point];
}

- (void)showCompactTaskPickerWithTasks:(NSArray<MirrorTaskModel *> *)tasks atPoint:(CGPoint)point
{
    [self dismissTaskPicker];

    CGRect bounds = self.view.bounds;
    CGFloat pickerWidth = 160*kWidthRatio;
    CGFloat titleHeight = 34;
    CGFloat rowHeight = 40;
    CGFloat pickerHeight = titleHeight + rowHeight*tasks.count + 8;
    CGPoint viewPoint = [self.timelineContentView convertPoint:point toView:self.view];
    CGFloat pickerX = MIN(MAX(viewPoint.x - pickerWidth/2, kLeftRightSpacing), CGRectGetWidth(bounds) - pickerWidth - kLeftRightSpacing);
    CGFloat pickerY = viewPoint.y + 8;
    if (pickerY + pickerHeight > CGRectGetHeight(bounds) - self.tabBarController.tabBar.frame.size.height) {
        pickerY = viewPoint.y - pickerHeight - 8;
    }
    pickerY = MAX(kLeftRightSpacing, pickerY);

    UIView *overlayView = [[UIView alloc] initWithFrame:bounds];
    overlayView.backgroundColor = UIColor.clearColor;
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTaskPicker)];
    tapRecognizer.delegate = self;
    [overlayView addGestureRecognizer:tapRecognizer];

    UIView *pickerView = [[UIView alloc] initWithFrame:CGRectMake(pickerX, pickerY, pickerWidth, pickerHeight)];
    pickerView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    pickerView.layer.cornerRadius = 12;
    pickerView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
    pickerView.layer.shadowOpacity = 0.18;
    pickerView.layer.shadowRadius = 8;
    pickerView.layer.shadowOffset = CGSizeMake(0, 3);
    [overlayView addSubview:pickerView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 8, pickerWidth - 28, titleHeight - 8)];
    titleLabel.text = [self addRecordTitle];
    titleLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    titleLabel.font = [UIFont mirrorHintFont];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    [pickerView addSubview:titleLabel];

    for (NSInteger index = 0; index < tasks.count; index++) {
        MirrorTaskModel *task = tasks[index];
        CGFloat rowY = titleHeight + rowHeight*index;
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, rowY, pickerWidth, rowHeight)];
        button.accessibilityIdentifier = task.taskName;
        [button addTarget:self action:@selector(taskPickerDidSelectTask:) forControlEvents:UIControlEventTouchUpInside];
        [pickerView addSubview:button];

        UIView *colorDot = [[UIView alloc] initWithFrame:CGRectMake(14, rowY + 12, 16, 16)];
        colorDot.backgroundColor = [UIColor mirrorColorNamed:task.color];
        colorDot.layer.cornerRadius = 8;
        [pickerView addSubview:colorDot];

        UILabel *taskLabel = [[UILabel alloc] initWithFrame:CGRectMake(42, rowY, pickerWidth - 56, rowHeight)];
        taskLabel.text = task.taskName;
        taskLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        taskLabel.font = [UIFont mirrorTitleFont_Card];
        taskLabel.adjustsFontSizeToFitWidth = YES;
        [pickerView addSubview:taskLabel];
    }

    self.taskPickerOverlayView = overlayView;
    [self.view addSubview:overlayView];
}

- (void)taskPickerDidSelectTask:(UIButton *)sender
{
    NSString *taskName = sender.accessibilityIdentifier;
    [self dismissTaskPicker];
    if (taskName.length == 0) {
        return;
    }
    [self addRecordWithTaskName:taskName];
}

- (void)dismissTaskPicker
{
    [self.taskPickerOverlayView removeFromSuperview];
    self.taskPickerOverlayView = nil;
}

- (void)addRecordWithTaskName:(NSString *)taskName
{
    long start = self.pendingStartTimestamp;
    long end = [self endTimestampForNewRecordStartingAt:start];
    if (end - start < kMinSeconds) {
        return;
    }
    [MirrorStorage insertPeriodWithTaskname:taskName startAt:[NSDate dateWithTimeIntervalSince1970:start] endAt:[NSDate dateWithTimeIntervalSince1970:end]];
}

- (long)endTimestampForNewRecordStartingAt:(long)start // prevent overlap with period behind
{
    long end = start + 3600;
    for (MirrorRecordModel *record in self.todayData) {
        if (record.startTime >= start) {
            end = MIN(end, record.startTime);
            break;
        }
    }
    return end;
}

#pragma mark - Getters

- (TodayTotalHeader *)todayHeader
{
    if (!_todayHeader) {
        _todayHeader = [TodayTotalHeader new];
        _todayHeader.backgroundColor = self.view.backgroundColor;
    }
    return _todayHeader;
}

- (UIScrollView *)timelineScrollView
{
    if (!_timelineScrollView) {
        _timelineScrollView = [UIScrollView new];
        _timelineScrollView.backgroundColor = self.view.backgroundColor;
        _timelineScrollView.showsVerticalScrollIndicator = NO;
        _timelineScrollView.alwaysBounceVertical = YES;
    }
    return _timelineScrollView;
}

- (UIView *)timelineContentView
{
    if (!_timelineContentView) {
        _timelineContentView = [UIView new];
        _timelineContentView.backgroundColor = self.view.backgroundColor;
    }
    return _timelineContentView;
}

- (UIButton *)settingsButton
{
    if (!_settingsButton) {
        _settingsButton = [UIButton new];
        UIImage *iconImage = [[UIImage systemImageNamed:@"line.horizontal.3"]  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [_settingsButton setImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [_settingsButton addTarget:self action:@selector(goToSettings) forControlEvents:UIControlEventTouchUpInside];
    }
    return _settingsButton;
}

- (NSMutableArray<MirrorRecordModel *> *)todayData
{
    if (!_todayData) {
        _todayData = [MirrorStorage getTodayData];
    }
    return _todayData;
}

#pragma mark - Privates

- (BOOL)pointHitsRecordView:(CGPoint)point
{
    for (UIView *subview in self.timelineContentView.subviews) {
        if ([subview.accessibilityIdentifier isEqualToString:@"TodayTimelineRecordView"] && CGRectContainsPoint(subview.frame, point)) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)dismissVisibleRecordEditMenuIfNeeded
{
    if (!self.isRecordEditMenuVisible) {
        return NO;
    }
    if (@available(iOS 16.0, *)) {
        [self.visibleRecordEditMenuInteraction dismissMenu];
    }
    self.isRecordEditMenuVisible = NO;
    self.visibleRecordEditMenuInteraction = nil;
    self.shouldSuppressNextTaskPicker = NO;
    return YES;
}

- (long)timestampForTimelineY:(CGFloat)y
{
    CGFloat clampedY = MIN(MAX(y, 0), self.hourHeight * 24.0 - 1);
    NSInteger quarterHours = lround((clampedY / self.hourHeight) * 4.0);
    quarterHours = MIN(MAX(quarterHours, 0), 24 * 4 - 1);
    return [self todayStartTimestamp] + quarterHours * 15 * 60;
}

- (long)todayStartTimestamp
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
    components.timeZone = [NSTimeZone systemTimeZone];
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    return [[gregorian dateFromComponents:components] timeIntervalSince1970];
}

- (NSString *)timeTextForRecord:(MirrorRecordModel *)record
{
    return [NSString stringWithFormat:@"%@ - %@", [self shortTimeFromTimestamp:record.startTime], [self shortTimeFromTimestamp:record.endTime]];
}

- (NSString *)shortTimeFromTimestamp:(long)timestamp
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

- (NSString *)addRecordTitle
{
    return [NSString stringWithFormat:@"%@ %@", [MirrorLanguage mirror_stringWithKey:@"starts_at"], [self shortTimeFromTimestamp:self.pendingStartTimestamp]];
}

- (UILabel *)pickerLabelWithText:(NSString *)text
{
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont mirrorHintFont];
    label.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer.view == self.taskPickerOverlayView) {
        return touch.view == self.taskPickerOverlayView;
    }
    if (self.isRecordEditMenuVisible) {
        if (gestureRecognizer.view == self.timelineContentView) {
            return YES;
        }
        if ([gestureRecognizer.view.interactions containsObject:self.visibleRecordEditMenuInteraction]) {
            [self dismissVisibleRecordEditMenuIfNeeded];
            return NO;
        }
    }
    if (gestureRecognizer.view != self.timelineContentView) {
        return YES;
    }
    CGPoint point = [touch locationInView:self.timelineContentView];
    return ![self pointHitsRecordView:point];
}

#pragma mark - Animations

// 从左边缘滑动唤起settings
- (void)edgeGestureRecognizerAction:(UIScreenEdgePanGestureRecognizer *)pan
{
    //产生百分比
    CGFloat sheetWidth = self.view.frame.size.width * kLeftSheetRatio;
    CGFloat process = [pan translationInView:self.view].x / sheetWidth;
    
    process = MIN(1.0,(MAX(0.0, process)));
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.interactiveTransition = [UIPercentDrivenInteractiveTransition new];
        // 触发present转场动画
        [self goToSettings];
    }else if (pan.state == UIGestureRecognizerStateChanged){
        [self.interactiveTransition updateInteractiveTransition:process];
    }else if (pan.state == UIGestureRecognizerStateEnded
              || pan.state == UIGestureRecognizerStateCancelled){
        if (process > 0.3) {
            [ self.interactiveTransition finishInteractiveTransition];
        }else{
            [ self.interactiveTransition cancelInteractiveTransition];
        }
        self.interactiveTransition = nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    LeftAnimation *animation = [LeftAnimation new];
    animation.isPresent = YES;
    return animation;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactiveTransition;
}

@end
