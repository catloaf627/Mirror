//
//  HistoryViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/19.
//

#import "HistoryViewController.h"
#import "MirrorMacro.h"
#import "MirrorSettings.h"
#import "MirrorTabsManager.h"
#import "MirrorNaviManager.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import <QuartzCore/QuartzCore.h>
#import "TaskProgressListView.h"
#import "LegendView.h"
#import "MirrorLanguage.h"
#import "MirrorSettings.h"
#import "PiechartView.h"
#import "RecordsTimelineViewController.h"
#import "MirrorTaskModel.h"
#import "MirrorTool.h"
#import "MirrorStorage.h"
#import "MirrorTimeText.h"
#import "UIFont+MirrorFont.h"
#import <limits.h>

#define kLeftRightSpacing (20*kWidthRatio)
#define kGapInLine (10*kHeightRatio)

@interface HistoryViewController () <TaskProgressListDelegate>

@property (nonatomic, assign) BOOL isLoaded;
// Navibar
@property (nonatomic, strong) UIButton *chartTypeButton;
// Data source
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *>  *data;
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *>  *legendData;
@property (nonatomic, assign) NSInteger offset;
// UI
@property (nonatomic, strong) UISegmentedControl *typeSwitch;
@property (nonatomic, strong) UIView *interactionView; //在这个view的范围内，点左侧offset-1,点右侧offset+1
@property (nonatomic, strong) UIImageView *leftArrow;
@property (nonatomic, strong) UIImageView *rightArrow;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) MASConstraint *dateLabelWidthConstraint;
@property (nonatomic, strong) UIView *rangeBarTrackView;
@property (nonatomic, strong) UIView *rangeBarSelectionView;
@property (nonatomic, strong) CAGradientLayer *rangeBarGradientLayer;
@property (nonatomic, strong) MASConstraint *rangeBarSelectionLeftConstraint;
@property (nonatomic, strong) MASConstraint *rangeBarSelectionWidthConstraint;
@property (nonatomic, assign) long selectedStartTime;
@property (nonatomic, assign) long selectedEndTime;
@property (nonatomic, strong) LegendView *legendView;
@property (nonatomic, strong) TaskProgressListView *taskProgressListView;
@property (nonatomic, strong) PiechartView *piechartView;
@property (nonatomic, strong) UILabel *emptyHintLabel;

@end

@implementation HistoryViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 系统通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSignificantTimeChangeNotification object:nil];
        // 设置通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchWeekStartsOnNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchChartTypeDataNotification object:nil];
        // 数据通知 (直接数据驱动UI，本地数据变动必然导致这里的UI变动)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskHiddenNotification object:nil];// 比其他vc多监听一个hidden通知
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    _isLoaded = YES;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateRangeBarGradientLayerFrame];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:nil rightButton:self.chartTypeButton];
}

- (void)restartVC
{
    // 更新tabbar
    [[MirrorTabsManager sharedInstance] updateHistoryTabItemWithTabController:self.tabBarController];
    if (!_isLoaded) return;
    // 将vc.view里的所有subviews全部置为nil
    self.typeSwitch = nil;
    self.interactionView = nil;
    self.leftArrow = nil;
    self.rightArrow = nil;
    self.dateLabel = nil;
    self.dateLabelWidthConstraint = nil;
    self.rangeBarTrackView = nil;
    self.rangeBarSelectionView = nil;
    self.rangeBarGradientLayer = nil;
    self.rangeBarSelectionLeftConstraint = nil;
    self.rangeBarSelectionWidthConstraint = nil;
    self.legendView = nil;
    self.taskProgressListView = nil;
    self.piechartView = nil;
    self.emptyHintLabel = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 更新navibar
    if (self.tabBarController.selectedIndex == 3) {
        [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:nil rightButton:self.chartTypeButton];
    }
    [self p_setupUI];
}

- (void)reloadData
{
    if (!_isLoaded) return;
    // 如果是chart type变了顺便更新一下tab和导航栏图标
    [[MirrorTabsManager sharedInstance] updateHistoryTabItemWithTabController:self.tabBarController];
    [self updateChartTypeButton];
    // data source
    [self updateData];
    
    // empty hint
    [self updateHint]; // reloaddata要顺便reload一下emptyhint的状态
    
    // legend
    [self.legendView updateWithData:self.legendData];
    [self.legendView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];
    
    // progress list
    [self.taskProgressListView updateWithData:self.data];
    self.taskProgressListView.hidden = [MirrorSettings appliedPieChartData];
    
    // piechart
    CGFloat width = MIN([[self leftWidthLeftHeight][0] floatValue], [[self leftWidthLeftHeight][1] floatValue]);
    self.piechartView.delegate = self.legendView;
    [self.piechartView updateWithData:self.data width:width enableInteractive:YES];
    if (self.piechartView.superview) { //security
        [self.piechartView mas_updateConstraints:^(MASConstraintMaker *make) {
            if (width == [[self leftWidthLeftHeight][0] floatValue]) { // 宽度小于高度
                make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine + ([[self leftWidthLeftHeight][1] floatValue]-[[self leftWidthLeftHeight][0] floatValue])/2);
                make.width.height.mas_equalTo(width);
            } else {
                make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine);
                make.width.height.mas_equalTo(width);
            }
        }];
    }
    self.piechartView.hidden = ![MirrorSettings appliedPieChartData];
    [self updateRangeBar];

}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self updateData];
    
    [self.view addSubview:self.typeSwitch];
    [self.typeSwitch mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.height.mas_equalTo(32 * kHeightRatio);
    }];

    [self.view addSubview:self.interactionView];
    [self.interactionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.typeSwitch.mas_bottom).offset(kGapInLine);
        make.height.mas_equalTo(60*kHeightRatio);
    }];
    [self.interactionView addSubview:self.leftArrow];
    [self.leftArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(kLeftRightSpacing);
        make.centerY.mas_equalTo(self.interactionView);
        make.left.mas_equalTo(self.interactionView).offset(kLeftRightSpacing);
    }];
    [self.interactionView addSubview:self.rightArrow];
    [self.rightArrow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(kLeftRightSpacing);
        make.centerY.mas_equalTo(self.interactionView);
        make.right.mas_equalTo(self.interactionView).offset(-kLeftRightSpacing);
    }];
    [self.interactionView addSubview:self.dateLabel];
    [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.bottom.mas_equalTo(_interactionView.mas_centerY).offset(-4);
        make.left.mas_equalTo(_leftArrow.mas_right);
        make.right.mas_equalTo(_rightArrow.mas_left);
    }];
    [self.interactionView addSubview:self.rangeBarTrackView];
    [self.rangeBarTrackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.mas_equalTo(_interactionView.mas_centerY).offset(4);
        make.height.mas_equalTo(8*kHeightRatio);
        make.left.mas_equalTo(_leftArrow.mas_right);
        make.right.mas_equalTo(_rightArrow.mas_left);
    }];
    [self.rangeBarTrackView addSubview:self.rangeBarSelectionView];
    [self.rangeBarSelectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.offset(0);
        self.rangeBarSelectionLeftConstraint = make.left.offset(0);
        self.rangeBarSelectionWidthConstraint = make.width.mas_equalTo(0);
    }];
    [self.view addSubview:self.legendView];
    [self.legendView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.rangeBarTrackView.mas_bottom).offset(kGapInLine);
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];
    [self.view addSubview:self.taskProgressListView];
    [self.taskProgressListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine);
        make.bottom.mas_equalTo(self.view).offset(-self.tabBarController.tabBar.frame.size.height - kGapInLine);
    }];
    self.taskProgressListView.hidden = [MirrorSettings appliedPieChartData];

    [self.view addSubview:self.piechartView];
    CGFloat width = MIN([[self leftWidthLeftHeight][0] floatValue], [[self leftWidthLeftHeight][1] floatValue]);
    [self.piechartView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (width == [[self leftWidthLeftHeight][0] floatValue]) { // 宽度小于高度，手动让piechart居中
            make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine + ([[self leftWidthLeftHeight][1] floatValue]-[[self leftWidthLeftHeight][0] floatValue])/2.0);
            make.centerX.offset(0);
            make.width.height.mas_equalTo(width);
        } else {
            make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine);
            make.centerX.offset(0);
            make.width.height.mas_equalTo(width);
        }
    }];
    self.piechartView.hidden = ![MirrorSettings appliedPieChartData];
    // empty hint
    [self.view addSubview:self.emptyHintLabel];
    [self.emptyHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.right.offset(0);
    }];
    UITapGestureRecognizer *tapRecognizer = [UITapGestureRecognizer new];
    [tapRecognizer addTarget:self action:@selector(tapGestureRecognizerAction:)];
    [self.interactionView addGestureRecognizer:tapRecognizer];
    [self addPeriodSwipeGestures];
    [self updateRangeBar];


}

#pragma mark - Actions

- (void)taskProgressListView:(TaskProgressListView *)taskProgressListView didSelectData:(MirrorReadModel *)data
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage getAllTaskRecords:data.taskModel.taskName];
    MirrorReadModel *allData = [[MirrorReadModel alloc] initWithTask:data.taskModel records:allRecords];
    RecordsTimelineViewController *recordsVC = [[RecordsTimelineViewController alloc] initWithData:allData highlightedRecords:data.records];
    [self.navigationController pushViewController:recordsVC animated:YES];
}

- (void)tapGestureRecognizerAction:(UITapGestureRecognizer *)tap // 热区范围为左右1/3
{
    CGPoint touchPoint = [tap locationInView:self.view];
    if (touchPoint.x < self.interactionView.frame.size.width/3) { // 左侧
        [self movePeriodByOffset:-1];
    } else if (touchPoint.x > 2 * self.interactionView.frame.size.width/3) { // 右侧
        [self movePeriodByOffset:1];
    }
    
}

- (void)addPeriodSwipeGestures
{
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handlePeriodSwipe:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipe];

    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handlePeriodSwipe:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipe];
}

- (void)handlePeriodSwipe:(UISwipeGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        [self movePeriodByOffset:1];
    } else if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
        [self movePeriodByOffset:-1];
    }
}

- (void)movePeriodByOffset:(NSInteger)offsetDelta
{
    if (offsetDelta == 0) {
        return;
    }
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
    self.offset = self.offset + offsetDelta;
    [self reloadData];
}

- (void)spanTypeChanged
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [MirrorSettings changeSpanType:[self spanTypeFromSelectedSegmentIndex:self.typeSwitch.selectedSegmentIndex]];
    self.offset = 0;
    [self reloadData];
}

- (void)switchChartType
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [MirrorSettings switchChartTypeData];
}

- (void)updateChartTypeButton
{
    UIImage *iconImage = [[UIImage systemImageNamed:@"chart.pie"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.chartTypeButton setImage:iconImage forState:UIControlStateNormal];
    self.chartTypeButton.tintColor = [MirrorSettings appliedPieChartData] ? [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight] : [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconText];
}

#pragma mark - update data

- (void)updateData
{
    long startTime = 0;
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
    components.timeZone = [NSTimeZone systemTimeZone];
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    SpanType spanType = [self currentSpanType];
    if (spanType == SpanTypeWeek) {
        long todayZero = [[gregorian dateFromComponents:components] timeIntervalSince1970];
        startTime = todayZero - [MirrorTool getDayGapFromTheFirstDayThisWeek] * 86400;
        if (self.offset != 0) {
            startTime = startTime + 7*86400*self.offset;
        }
    } else if (spanType == SpanTypeMonth) {
        components.day = 1;
        if (self.offset > 0) {
            for (int i=0;i<self.offset;i++) {
                if (components.month + 1 <= 12) {
                    components.month = components.month + 1;
                } else {
                    components.year = components.year + 1;
                    components.month = 1;
                }
            }
        }
        if (self.offset < 0) {
            for (int i=0;i<-self.offset;i++) {
                if (components.month - 1 >= 1) {
                    components.month = components.month - 1;
                } else {
                    components.year = components.year - 1;
                    components.month = 12;
                }
            }
        }
        startTime = [[gregorian dateFromComponents:components] timeIntervalSince1970];
    } else if (spanType == SpanTypeYear) {
        components.month = 1;
        components.day = 1;
        if (self.offset != 0) {
            components.year = components.year + self.offset;
        }
        startTime = [[gregorian dateFromComponents:components] timeIntervalSince1970];
    }
    
    long endTime = 0;
    if (spanType == SpanTypeWeek) {
        NSInteger numberOfDaysInWeek= 7;
        endTime = startTime + numberOfDaysInWeek*86400;
    } else if (spanType == SpanTypeMonth) {
        NSRange rng = [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:[NSDate dateWithTimeIntervalSince1970:startTime]];
        NSInteger numberOfDaysInMonth = rng.length;
        endTime = startTime + numberOfDaysInMonth*86400;
    } else if (spanType == SpanTypeYear) {
        NSRange rng = [[NSCalendar currentCalendar] rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitYear forDate:[NSDate dateWithTimeIntervalSince1970:startTime]];
        NSInteger numberOfDaysIYear = rng.length;
        endTime = startTime + numberOfDaysIYear*86400;
    }
    
    self.selectedStartTime = startTime;
    self.selectedEndTime = endTime;
    self.legendData = [MirrorStorage getAllRecordsInTaskOrderWithStart:startTime end:endTime shouldHideHidden:NO];
    self.data = [MirrorStorage getAllRecordsInTaskOrderWithStart:startTime end:endTime shouldHideHidden:YES];
    // update label
    NSString *startDate = [MirrorTimeText YYYYmmddWeekday:[NSDate dateWithTimeIntervalSince1970:startTime]];
    NSString *endDate = [MirrorTimeText YYYYmmddWeekday:[NSDate dateWithTimeIntervalSince1970:endTime-1]];// 这里减1是因为，period本身在读的时候取的是左闭右开，例如2023.4.17,Mon,00:00 - 2023.4.19,Wed,00:00间隔为2天，指的就是2023.4.17, 2023.4.18这两天，2023.4.19本身是不做数的。因此这里传日期的时候要减去1，将结束时间2023.4.19,Wed,00:00改为2023.4.18,Wed,23:59，这样传过去的label就只展示左闭右开区间里真实囊括的两天了。
    
    if ([startDate isEqualToString:endDate]) {
        [self updateSpanText:startDate];
    } else {
        startDate = [MirrorTimeText YYYYmmdd:[NSDate dateWithTimeIntervalSince1970:startTime]];
        endDate = [MirrorTimeText YYYYmmdd:[NSDate dateWithTimeIntervalSince1970:endTime-1]];
        NSString *combine  = [[startDate stringByAppendingString:@" - "] stringByAppendingString:endDate];
        [self updateSpanText:combine];
    }
}

- (void)updateSpanText:(NSString *)text
{
    self.dateLabel.text = text;
}

- (void)updateRangeBar
{
    NSArray<NSNumber *> *range = [self fullRecordsStartEndRange];
    if (range.count < 2 || self.selectedEndTime <= self.selectedStartTime) {
        self.rangeBarTrackView.hidden = YES;
        return;
    }

    long fullStartTime = range[0].longValue;
    long fullEndTime = range[1].longValue;
    long fullDuration = fullEndTime - fullStartTime;
    if (fullDuration <= 0) {
        self.rangeBarTrackView.hidden = YES;
        return;
    }

    CGFloat trackWidth = self.rangeBarTrackView.bounds.size.width;
    if (trackWidth <= 0) {
        trackWidth = self.view.frame.size.width - 4*kLeftRightSpacing;
    }
    CGFloat startRatio = (self.selectedStartTime - fullStartTime) / (CGFloat)fullDuration;
    CGFloat endRatio = (self.selectedEndTime - fullStartTime) / (CGFloat)fullDuration;
    startRatio = MIN(1, MAX(0, startRatio));
    endRatio = MIN(1, MAX(0, endRatio));

    CGFloat left = trackWidth * startRatio;
    CGFloat width = trackWidth * MAX(0, endRatio - startRatio);
    BOOL shouldHideRangeBar = width <= 0;
    CGFloat selectionWidth = MAX(8*kHeightRatio, width); // 最短的状态是一个球形
    if (left + selectionWidth > trackWidth) {
        left = MAX(0, trackWidth - selectionWidth);
    }
    BOOL shouldAnimate = !self.rangeBarTrackView.hidden && !shouldHideRangeBar && self.rangeBarTrackView.window;
    self.rangeBarTrackView.hidden = shouldHideRangeBar;
    [self.rangeBarSelectionLeftConstraint setOffset:left];
    [self.rangeBarSelectionWidthConstraint setOffset:selectionWidth];

    if (shouldAnimate) {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
            [self.rangeBarTrackView layoutIfNeeded];
            [self updateRangeBarGradientLayerFrame];
        } completion:^(BOOL finished) {
            [self updateRangeBarGradientLayerFrame];
        }];
    } else {
        [self.rangeBarTrackView layoutIfNeeded];
        [self updateRangeBarGradientLayerFrame];
    }
}

- (void)updateRangeBarGradientLayerFrame
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.rangeBarGradientLayer.frame = self.rangeBarSelectionView.bounds;
    [CATransaction commit];
}

- (NSArray<NSNumber *> *)fullRecordsStartEndRange
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (records.count == 0) {
        return @[];
    }

    long startTime = LONG_MAX;
    long endTime = 0;
    for (MirrorRecordModel *record in records) {
        startTime = MIN(startTime, record.startTime);
        endTime = MAX(endTime, record.endTime);
    }
    if (startTime == LONG_MAX || endTime <= startTime) {
        return @[];
    }
    return @[@(startTime), @(endTime)];
}

#pragma mark - Getters

- (SpanType)currentSpanType
{
    return [self spanTypeFromSelectedSegmentIndex:self.typeSwitch.selectedSegmentIndex];
}

- (SpanType)spanTypeFromSelectedSegmentIndex:(NSInteger)selectedSegmentIndex
{
    if (selectedSegmentIndex == 0) return SpanTypeWeek;
    if (selectedSegmentIndex == 1) return SpanTypeMonth;
    return SpanTypeYear;
}

- (NSInteger)selectedSegmentIndexFromSpanType:(SpanType)spanType
{
    if (spanType == SpanTypeWeek) return 0;
    if (spanType == SpanTypeMonth) return 1;
    return 2;
}

- (NSMutableArray<MirrorReadModel *> *)data
{
    if (!_data) {
        _data = [NSMutableArray new];
    }
    return _data;
}

- (NSMutableArray<MirrorReadModel *> *)legendData
{
    if (!_legendData) {
        _legendData = [NSMutableArray new];
    }
    return _legendData;
}

- (UISegmentedControl *)typeSwitch
{
    if (!_typeSwitch) {
        _typeSwitch = [[UISegmentedControl alloc] initWithItems:@[[MirrorLanguage mirror_stringWithKey:@"segment_week"], [MirrorLanguage mirror_stringWithKey:@"segment_month"], [MirrorLanguage mirror_stringWithKey:@"segment_year"]]];
        _typeSwitch.selectedSegmentIndex = [self selectedSegmentIndexFromSpanType:[MirrorSettings spanType]];
        [_typeSwitch addTarget:self action:@selector(spanTypeChanged) forControlEvents:UIControlEventValueChanged];
    }
    return _typeSwitch;
}

- (UIView *)interactionView
{
    if (!_interactionView) {
        _interactionView = [UIView new];
    }
    return _interactionView;
}

- (UIView *)rangeBarTrackView
{
    if (!_rangeBarTrackView) {
        _rangeBarTrackView = [UIView new];
        _rangeBarTrackView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
        _rangeBarTrackView.layer.cornerRadius = 4*kHeightRatio;
        _rangeBarTrackView.clipsToBounds = YES;
    }
    return _rangeBarTrackView;
}

- (UIView *)rangeBarSelectionView
{
    if (!_rangeBarSelectionView) {
        _rangeBarSelectionView = [UIView new];
        _rangeBarSelectionView.layer.cornerRadius = 4*kHeightRatio;
        _rangeBarSelectionView.clipsToBounds = YES;
        [_rangeBarSelectionView.layer addSublayer:self.rangeBarGradientLayer];
    }
    return _rangeBarSelectionView;
}

- (CAGradientLayer *)rangeBarGradientLayer
{
    if (!_rangeBarGradientLayer) {
        _rangeBarGradientLayer = [CAGradientLayer layer];
        _rangeBarGradientLayer.startPoint = CGPointMake(0, 0.5);
        _rangeBarGradientLayer.endPoint = CGPointMake(1, 0.5);
        _rangeBarGradientLayer.colors = @[
            (__bridge id)[UIColor mirrorColorNamed:MirrorColorTypeCellPink].CGColor,
            (__bridge id)[UIColor mirrorColorNamed:MirrorColorTypeCellOrange].CGColor,
            (__bridge id)[UIColor mirrorColorNamed:MirrorColorTypeCellYellow].CGColor,
            (__bridge id)[UIColor mirrorColorNamed:MirrorColorTypeCellGreen].CGColor,
            (__bridge id)[UIColor mirrorColorNamed:MirrorColorTypeCellTeal].CGColor,
            (__bridge id)[UIColor mirrorColorNamed:MirrorColorTypeCellBlue].CGColor,
            (__bridge id)[UIColor mirrorColorNamed:MirrorColorTypeCellPurple].CGColor,
            (__bridge id)[UIColor mirrorColorNamed:MirrorColorTypeCellGray].CGColor,
        ];
    }
    return _rangeBarGradientLayer;
}

- (UILabel *)dateLabel
{
    if (!_dateLabel) {
        _dateLabel = [UILabel new];
        _dateLabel.textAlignment = NSTextAlignmentCenter;
        _dateLabel.text = @"";
        _dateLabel.font = [UIFont mirrorLabelFont];
        [_dateLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [_dateLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
        _dateLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText]; // 和nickname的文字颜色保持一致
    }
    return _dateLabel;
}

- (UIImageView *)leftArrow
{
    if (!_leftArrow) {
        UIImage *image = [[UIImage systemImageNamed:@"chevron.left"] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeText]];
        UIImage *imageWithRightColor = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        _leftArrow = [[UIImageView alloc] initWithImage:imageWithRightColor];
    }
    return _leftArrow;
}

- (UIView *)rightArrow
{
    if (!_rightArrow) {
        UIImage *image = [[UIImage systemImageNamed:@"chevron.right"] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeText]];
        UIImage *imageWithRightColor = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        _rightArrow = [[UIImageView alloc] initWithImage:imageWithRightColor];
    }
    return _rightArrow;
}

- (LegendView *)legendView
{
    if (!_legendView) {
        _legendView = [[LegendView alloc] initWithData:self.legendData];
    }
    return _legendView;
}

- (TaskProgressListView *)taskProgressListView
{
    if (!_taskProgressListView) {
        _taskProgressListView = [[TaskProgressListView alloc] initWithData:self.data];
        _taskProgressListView.delegate = self;
    }
    return _taskProgressListView;
}

- (PiechartView *)piechartView
{
    if (!_piechartView) {
        _piechartView = [[PiechartView alloc] initWithData:self.data width:MIN([[self leftWidthLeftHeight][0] floatValue], [[self leftWidthLeftHeight][1] floatValue]) enableInteractive:YES];
        _piechartView.delegate = self.legendView;
    }
    return _piechartView;
}

- (UIButton *)chartTypeButton
{
    if (!_chartTypeButton) {
        _chartTypeButton = [UIButton new];
        [_chartTypeButton addTarget:self action:@selector(switchChartType) forControlEvents:UIControlEventTouchUpInside];
        [self updateChartTypeButton];
    }
    return _chartTypeButton;
}

- (UILabel *)emptyHintLabel
{
    if (!_emptyHintLabel) {
        _emptyHintLabel = [UILabel new];
        _emptyHintLabel.textAlignment = NSTextAlignmentCenter;
        _emptyHintLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:16];
        _emptyHintLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse]; // 和nickname的文字颜色保持一致
        _emptyHintLabel.text = [MirrorLanguage mirror_stringWithKey:@"no_data"];
        _emptyHintLabel.hidden = self.legendData.count > 0;
    }
    return _emptyHintLabel;
}

- (void)updateHint
{
    self.emptyHintLabel.text = [MirrorLanguage mirror_stringWithKey:@"no_data"];
    self.emptyHintLabel.hidden = self.legendData.count > 0;
}

#pragma mark - Privates

- (NSArray *)leftWidthLeftHeight
{
    CGFloat navi = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    CGFloat typeSwitch_plusGapBelow = 32*kHeightRatio + kGapInLine;
    CGFloat interaction_plusGapBelow = 60*kHeightRatio;
    CGFloat rangeBar_plusGapBelow = 8*kHeightRatio + kGapInLine;
    CGFloat legend_plusGapBelow = [self.legendView legendViewHeight] + kGapInLine;
    CGFloat tabbar_plusGapAbove = self.tabBarController.tabBar.frame.size.height + kGapInLine;
    CGFloat leftHeight = kScreenHeight - navi - typeSwitch_plusGapBelow - interaction_plusGapBelow - rangeBar_plusGapBelow - legend_plusGapBelow - tabbar_plusGapAbove;
    CGFloat leftWidth = kScreenWidth - 2*kLeftRightSpacing;

    return @[@(leftWidth), @(leftHeight)];
}


@end
