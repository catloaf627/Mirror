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
#import "PeriodEditAlertController.h"

#define kLeftRightSpacing (20*kWidthRatio)
#define kTimelineLeftWidth (52*kWidthRatio)
#define kTimelineRightPadding (12*kWidthRatio)
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
@property (nonatomic, strong) PeriodEditAlertController *editingPeriodAlert;
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

- (void)editPeriod:(UIButton *)sender
{
    NSInteger periodIndex = sender.tag;
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (periodIndex < 0 || periodIndex >= records.count) {
        return;
    }
    
    MirrorRecordModel *record = records[periodIndex];
    BOOL hasPreviousRecord = periodIndex - 1 >= 0;
    BOOL hasNextRecord = periodIndex + 1 <= records.count - 1;
    long minimumAxisTimestamp = hasPreviousRecord ? records[periodIndex - 1].endTime : record.startTime;
    long maximumAxisTimestamp = hasNextRecord ? records[periodIndex + 1].startTime : record.endTime;
    self.editingPeriodIndex = periodIndex;
    MirrorTaskModel *taskModel = [MirrorStorage getTaskModelFromDB:record.taskName];
    __weak typeof(self) weakSelf = self;
    PeriodEditAlertController *alert = [[PeriodEditAlertController alloc] initWithTitle:record.taskName
                                                                              axisColor:[UIColor mirrorColorNamed:taskModel.color]
                                                                       minimumTimestamp:minimumAxisTimestamp
                                                                       maximumTimestamp:maximumAxisTimestamp
                                                                         startTimestamp:record.startTime
                                                                           endTimestamp:record.endTime
                                                                           canDragStart:hasPreviousRecord
                                                                             canDragEnd:hasNextRecord
                                                                                   note:record.note
                                                                           valueChanged:^(BOOL isStartTime, long timestamp) {
        [weakSelf rangeAxisValueChangedIsStartTime:isStartTime timestamp:timestamp];
    } dismissed:^(NSString *note) {
        [weakSelf saveEditingNote:note periodIndex:periodIndex];
        weakSelf.editingPeriodAlert = nil;
    }];
    self.editingPeriodAlert = alert;
    [alert presentFromViewController:self];
}

- (void)saveEditingNote:(NSString *)note periodIndex:(NSInteger)periodIndex
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (periodIndex < 0 || periodIndex >= records.count) {
        return;
    }
    
    NSString *newNote = note ?: @"";
    NSString *oldNote = records[periodIndex].note ?: @"";
    if (![newNote isEqualToString:oldNote]) {
        [MirrorStorage editPeriodNote:newNote periodIndex:periodIndex];
    }
}

- (void)rangeAxisValueChangedIsStartTime:(BOOL)isStartTime timestamp:(long)timestamp
{
    if (isStartTime) {
        [self updateEditingStartTimestamp:timestamp];
    } else {
        [self updateEditingEndTimestamp:timestamp];
    }
}

- (void)updateEditingStartTimestamp:(long)timestamp
{
    TimelineRangeAxisView *rangeAxisView = self.editingPeriodAlert.rangeAxisView;
    if (rangeAxisView == nil) {
        return;
    }
    long minimumAxisTimestamp = rangeAxisView.canDragStart ? rangeAxisView.minimumTimestamp : timestamp;
    long maximumAxisTimestamp = rangeAxisView.canDragEnd ? rangeAxisView.maximumTimestamp : rangeAxisView.endTimestamp;
    [rangeAxisView configureWithMinimumTimestamp:minimumAxisTimestamp
                                maximumTimestamp:maximumAxisTimestamp
                                   startTimestamp:rangeAxisView.startTimestamp
                                     endTimestamp:rangeAxisView.endTimestamp
                                     canDragStart:rangeAxisView.canDragStart
                                       canDragEnd:rangeAxisView.canDragEnd];
    [MirrorStorage editPeriodIsStartTime:YES to:timestamp periodIndex:self.editingPeriodIndex];
}

- (void)updateEditingEndTimestamp:(long)timestamp
{
    TimelineRangeAxisView *rangeAxisView = self.editingPeriodAlert.rangeAxisView;
    if (rangeAxisView == nil) {
        return;
    }
    long minimumAxisTimestamp = rangeAxisView.canDragStart ? rangeAxisView.minimumTimestamp : rangeAxisView.startTimestamp;
    long maximumAxisTimestamp = rangeAxisView.canDragEnd ? rangeAxisView.maximumTimestamp : timestamp;
    [rangeAxisView configureWithMinimumTimestamp:minimumAxisTimestamp
                                maximumTimestamp:maximumAxisTimestamp
                                   startTimestamp:rangeAxisView.startTimestamp
                                     endTimestamp:rangeAxisView.endTimestamp
                                     canDragStart:rangeAxisView.canDragStart
                                       canDragEnd:rangeAxisView.canDragEnd];
    [MirrorStorage editPeriodIsStartTime:NO to:timestamp periodIndex:self.editingPeriodIndex];
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
    CGSize contentSize = CGSizeMake(width, newHourHeight * [self timelineHourCount]);
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
    NSInteger hourCount = [self timelineHourCount];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"H:mm";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    long dayStart = [self todayStartTimestamp];

    for (NSInteger hour = 0; hour <= hourCount; hour++) {
        CGFloat y = hour * self.hourHeight;
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse];
        line.alpha = 0.2;
        [self.timelineContentView addSubview:line];
        line.frame = CGRectMake(kTimelineLeftWidth, y, width - kTimelineLeftWidth - kTimelineRightPadding, 1);

        if (hour < hourCount) {
            UILabel *hourLabel = [UILabel new];
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:dayStart + hour * 3600];
            hourLabel.text = [formatter stringFromDate:date];
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
    long dayEnd = [self todayEndTimestamp];
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
        titleLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        titleLabel.font = [UIFont mirrorHintFont_Card];
        titleLabel.adjustsFontSizeToFitWidth = YES;
        titleLabel.attributedText = [self attributedTimelineTextForRecord:record font:titleLabel.font];
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

- (NSAttributedString *)attributedTimelineTextForRecord:(MirrorRecordModel *)record font:(UIFont *)font
{
    NSString *taskName = record.taskName ?: @"";
    NSString *note = record.note ?: @"";
    NSString *text = note.length > 0 ? [NSString stringWithFormat:@"%@  %@", taskName, note] : taskName;
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor mirrorColorNamed:MirrorColorTypeTextHint]
    }];
    [attributedText addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:font.pointSize] range:NSMakeRange(0, taskName.length)];
    return attributedText;
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
        taskLabel.textColor = [UIColor mirrorColorPulsed:task.color];
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
    for (MirrorRecordModel *record in [MirrorStorage retriveMirrorRecords]) {
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
    CGFloat clampedY = MIN(MAX(y, 0), self.hourHeight * [self timelineHourCount] - 1);
    NSInteger quarterHours = lround((clampedY / self.hourHeight) * 4.0);
    NSInteger maxQuarterHours = (([self todayEndTimestamp] - [self todayStartTimestamp]) / (15 * 60)) - 1;
    quarterHours = MIN(MAX(quarterHours, 0), maxQuarterHours);
    return [self todayStartTimestamp] + quarterHours * 15 * 60;
}

- (long)todayStartTimestamp
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    return round([[gregorian startOfDayForDate:[NSDate now]] timeIntervalSince1970]);
}

- (long)todayEndTimestamp
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDate *startOfDay = [gregorian startOfDayForDate:[NSDate now]];
    NSDate *startOfNextDay = [gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfDay options:0];
    return round([startOfNextDay timeIntervalSince1970]);
}

- (NSInteger)timelineHourCount
{
    NSInteger numOfHours = ([self todayEndTimestamp] - [self todayStartTimestamp]) / 3600;
    return numOfHours;
}

- (NSString *)shortTimeFromTimestamp:(long)timestamp
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"H:mm";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

- (NSString *)addRecordTitle
{
    return [NSString stringWithFormat:@"%@ %@", [MirrorLanguage mirror_stringWithKey:@"starts_at"], [self shortTimeFromTimestamp:self.pendingStartTimestamp]];
}

- (NSInteger)dayOffsetFromTodayForTimestamp:(long)timestamp
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDate *todayStartDate = [NSDate dateWithTimeIntervalSince1970:[self todayStartTimestamp]];
    NSDate *timestampDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDate *timestampStartDate = [gregorian startOfDayForDate:timestampDate];
    NSDateComponents *components = [gregorian components:NSCalendarUnitDay fromDate:todayStartDate toDate:timestampStartDate options:0];
    return components.day;
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
