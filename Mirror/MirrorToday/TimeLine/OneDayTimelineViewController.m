//
//  OneDayTimelineViewController.m
//  Mirror
//

#import "OneDayTimelineViewController.h"
#import "TimelineRecordView.h"
#import "TimelineBackgroundView.h"
#import "MirrorStorage.h"
#import "MirrorLanguage.h"
#import "MirrorMacro.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "PeriodEditAlertView.h"
#import <Masonry/Masonry.h>

#define kLeftRightSpacing (20*kWidthRatio)
#define kTimelineLeftWidth (52*kWidthRatio)
#define kTimelineRightPadding (12*kWidthRatio)
#define kTimelineMinimumTinyRecordHeight 10
#define kTimelineTinyRecordThresholdSeconds (10 * 60)
#define kTimelineTextHiddenThresholdSeconds (45 * 60)

@interface OneDayTimelineViewController () <TimelineRecordViewDelegate, TimelineBackgroundViewDelegate>

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong, nullable) UIView *customHeaderView;
@property (nonatomic, assign) CGFloat headerHeight;
@property (nonatomic, assign) UIEdgeInsets headerInsets;
@property (nonatomic, copy, nullable) OneDayTimelineHeaderConfiguration headerConfiguration;
@property (nonatomic, assign) BOOL didScrollToDefaultHours;
@property (nonatomic, assign) CGFloat hourHeight;
@property (nonatomic, assign) NSInteger editingPeriodIndex;
@property (nonatomic, strong) PeriodEditAlertView *editingPeriodAlert;
@property (nonatomic, weak) TimelineRecordView *activeRecordView;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *oneDayData;
@property (nonatomic, strong) UIScrollView *timelineScrollView;
@property (nonatomic, strong) TimelineBackgroundView *timelineContentView;
@property (nonatomic, strong) UIView *nowLineView;
@property (nonatomic, strong) UILabel *nowLineTimeLabel;
@property (nonatomic, strong) NSTimer *nowLineTimer;

@end

@implementation OneDayTimelineViewController

- (instancetype)initWithDate:(NSDate *)date
                  headerView:(UIView * _Nullable)headerView
                headerHeight:(CGFloat)headerHeight
                headerInsets:(UIEdgeInsets)headerInsets
         headerConfiguration:(OneDayTimelineHeaderConfiguration _Nullable)headerConfiguration
{
    self = [super init];
    if (self) {
        _date = date ?: [NSDate now];
        _customHeaderView = headerView;
        _headerHeight = headerHeight;
        _headerInsets = headerInsets;
        _headerConfiguration = [headerConfiguration copy];
        _editingPeriodIndex = NSNotFound;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupUI];
    [self reloadData];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateTimelineSizeIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startNowLineTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopNowLineTimer];
}

- (void)dealloc
{
    [self stopNowLineTimer];
}

- (void)setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];

    UIView *timelineTopAnchor = self.view;
    if (self.customHeaderView) {
        self.customHeaderView.backgroundColor = self.view.backgroundColor;
        [self.view addSubview:self.customHeaderView];
        [self.customHeaderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.view).offset(self.headerInsets.top);
            make.left.offset(self.headerInsets.left);
            make.right.offset(-self.headerInsets.right);
            make.height.mas_equalTo(self.headerHeight);
        }];
        timelineTopAnchor = self.customHeaderView;
    }

    [self.view addSubview:self.timelineScrollView];
    [self.timelineScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (self.customHeaderView) {
            make.top.mas_equalTo(timelineTopAnchor.mas_bottom).offset(self.headerInsets.bottom);
        } else {
            make.top.mas_equalTo(timelineTopAnchor);
        }
        make.left.right.bottom.offset(0);
    }];

    [self.timelineScrollView addSubview:self.timelineContentView];
    self.timelineContentView.delegate = self;
    self.timelineContentView.presentingViewController = self;
}

- (void)updateDate:(NSDate *)date
{
    self.date = date ?: [NSDate now];
    self.didScrollToDefaultHours = NO;
    [self configureTimelineContentViewForCurrentDate];
    [self updateTimelineSizeIfNeeded];
    [self reloadData];
}

- (void)reloadData
{
    self.oneDayData = [MirrorStorage getOneDayDataForDate:self.date];
    if (self.headerConfiguration && self.customHeaderView) {
        self.headerConfiguration(self.customHeaderView, self.oneDayData);
    }
    [self renderTimeline];
}

- (void)dismissTransientEditingState
{
    [self.timelineContentView dismissTaskPicker];
    [self.activeRecordView endInlineEditing];
    [self.activeRecordView endSelection];
    self.activeRecordView = nil;
    [self.editingPeriodAlert dismiss];
    self.editingPeriodAlert = nil;
}

#pragma mark - TimelineBackgroundViewDelegate

- (BOOL)timelineViewShouldBeginAddingRecord:(TimelineBackgroundView *)timelineView
{
    if (self.activeRecordView) {
        [self.activeRecordView endInlineEditing];
        [self.activeRecordView endSelection];
        self.activeRecordView = nil;
        return NO;
    }
    return YES;
}

- (void)timelineViewDidAddRecord:(TimelineBackgroundView *)timelineView
{
    [self reloadData];
}

#pragma mark - Record Menu

- (UIMenu *)recordMenuForPeriodIndex:(NSInteger)periodIndex API_AVAILABLE(ios(16.0))
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (periodIndex < 0 || periodIndex >= records.count) {
        return nil;
    }

    __weak typeof(self) weakSelf = self;
    UIAction *editAction = [UIAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"edit"] image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [weakSelf editPeriodAtIndex:periodIndex];
    }];
    UIAction *deleteAction = [UIAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [MirrorStorage deletePeriodAtIndex:periodIndex];
        [weakSelf reloadData];
    }];
    deleteAction.attributes = UIMenuElementAttributesDestructive;
    return [UIMenu menuWithTitle:@"" children:@[editAction, deleteAction]];
}

- (UIMenu *)menuForTimelineRecordView:(TimelineRecordView *)recordView API_AVAILABLE(ios(16.0))
{
    return [self recordMenuForPeriodIndex:recordView.periodIndex];
}

- (void)timelineRecordViewDidRequestMenuDismissal:(TimelineRecordView *)recordView
{
    if (self.activeRecordView != recordView) {
        [self.activeRecordView endInlineEditing];
        [self.activeRecordView endSelection];
    }
    self.activeRecordView = recordView;
}

- (void)editPeriodAtIndex:(NSInteger)periodIndex
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    if (periodIndex < 0 || periodIndex >= records.count) {
        return;
    }

    MirrorRecordModel *record = records[periodIndex];
    BOOL hasPreviousRecord = periodIndex - 1 >= 0;
    BOOL hasNextRecord = periodIndex + 1 <= records.count - 1;
    NSNumber *minimumTimestamp = hasPreviousRecord ? @(records[periodIndex - 1].endTime) : nil;
    NSNumber *maximumTimestamp = hasNextRecord ? @(records[periodIndex + 1].startTime) : nil;
    self.editingPeriodIndex = periodIndex;
    __weak typeof(self) weakSelf = self;
    PeriodEditAlertView *alert = [[PeriodEditAlertView alloc] initWithRecord:record
                                                                             periodIndex:periodIndex
                                                                         minimumTimestamp:minimumTimestamp
                                                                         maximumTimestamp:maximumTimestamp
                                                                            recordChanged:^(MirrorRecordModel *editedRecord) {
        weakSelf.editingPeriodAlert = nil;
    }];
    self.editingPeriodAlert = alert;
    [alert presentFromViewController:self];
}

- (void)saveEditingRecord:(MirrorRecordModel *)record periodIndex:(NSInteger)periodIndex
{
    [MirrorStorage editPeriodWithRecord:record periodIndex:periodIndex];
}

#pragma mark - TimelineRecordViewDelegate

- (void)timelineRecordViewDidRequestInlineEditing:(TimelineRecordView *)recordView
{
    [self beginEditingRecordView:recordView allowsMoveDrag:NO];
}

- (void)timelineRecordViewDidRequestMoveEditing:(TimelineRecordView *)recordView
{
    [self beginEditingRecordView:recordView allowsMoveDrag:YES];
}

- (void)beginEditingRecordView:(TimelineRecordView *)recordView allowsMoveDrag:(BOOL)allowsMoveDrag
{
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    NSInteger periodIndex = recordView.periodIndex;
    if (periodIndex < 0 || periodIndex >= records.count) {
        return;
    }

    if (self.activeRecordView != recordView) {
        [self.activeRecordView endInlineEditing];
    }
    MirrorRecordModel *record = records[periodIndex];
    long minimumTimestamp = periodIndex > 0 ? MAX(records[periodIndex - 1].endTime, [self dayStartTimestamp]) : [self dayStartTimestamp];
    long maximumTimestamp = periodIndex + 1 < records.count ? MIN(records[periodIndex + 1].startTime, [self dayEndTimestamp]) : [self dayEndTimestamp];
    if (maximumTimestamp <= minimumTimestamp || record.endTime <= [self dayStartTimestamp] || record.startTime >= [self dayEndTimestamp]) {
        return;
    }

    self.activeRecordView = recordView;
    [self.timelineContentView bringSubviewToFront:recordView];
    if (allowsMoveDrag) {
        [recordView beginMoveEditingWithMinimumTimestamp:minimumTimestamp
                                        maximumTimestamp:maximumTimestamp
                                              hourHeight:self.hourHeight
                                       dayStartTimestamp:[self dayStartTimestamp]
                                         dayEndTimestamp:[self dayEndTimestamp]];
    } else {
        [recordView beginInlineEditingWithMinimumTimestamp:minimumTimestamp
                                          maximumTimestamp:maximumTimestamp
                                                hourHeight:self.hourHeight
                                         dayStartTimestamp:[self dayStartTimestamp]
                                           dayEndTimestamp:[self dayEndTimestamp]];
    }
}

- (void)timelineRecordView:(TimelineRecordView *)recordView didChangeScrollEnabled:(BOOL)enabled
{
    self.timelineScrollView.scrollEnabled = enabled;
}

- (void)timelineRecordView:(TimelineRecordView *)recordView didCommitStartTimestamp:(long)timestamp
{
    NSInteger periodIndex = recordView.periodIndex;
    [MirrorStorage editPeriodIsStartTime:YES to:timestamp periodIndex:periodIndex];
    [self reloadDataKeepingInlineEditingForPeriodIndex:periodIndex];
}

- (void)timelineRecordView:(TimelineRecordView *)recordView didCommitEndTimestamp:(long)timestamp
{
    NSInteger periodIndex = recordView.periodIndex;
    [MirrorStorage editPeriodIsStartTime:NO to:timestamp periodIndex:periodIndex];
    [self reloadDataKeepingInlineEditingForPeriodIndex:periodIndex];
}

- (void)timelineRecordView:(TimelineRecordView *)recordView didCommitStartTimestamp:(long)startTimestamp endTimestamp:(long)endTimestamp
{
    NSInteger periodIndex = recordView.periodIndex;
    [MirrorStorage editPeriodStartTime:startTimestamp endTime:endTimestamp periodIndex:periodIndex];
    [self reloadDataKeepingInlineEditingForPeriodIndex:periodIndex];
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
    [self configureTimelineContentViewForCurrentDate];
    [self renderTimeline];

    if (!self.didScrollToDefaultHours) {
        [self.timelineScrollView setContentOffset:CGPointMake(0, self.hourHeight * 7.0) animated:NO];
        self.didScrollToDefaultHours = YES;
    }
}

- (void)reloadDataKeepingInlineEditingForPeriodIndex:(NSInteger)periodIndex
{
    [self reloadData];
    [self restoreEditingForPeriodIndex:periodIndex allowsMoveDrag:NO];
}

- (void)reloadDataKeepingMoveEditingForPeriodIndex:(NSInteger)periodIndex
{
    [self reloadData];
    [self restoreEditingForPeriodIndex:periodIndex allowsMoveDrag:YES];
}

- (void)restoreEditingForPeriodIndex:(NSInteger)periodIndex allowsMoveDrag:(BOOL)allowsMoveDrag
{
    for (UIView *subview in self.timelineContentView.subviews) {
        if (![subview isKindOfClass:TimelineRecordView.class]) {
            continue;
        }
        TimelineRecordView *recordView = (TimelineRecordView *)subview;
        if (recordView.periodIndex == periodIndex) {
            [self beginEditingRecordView:recordView allowsMoveDrag:allowsMoveDrag];
            return;
        }
    }
}

- (void)renderTimeline
{
    if (self.hourHeight <= 0 || CGRectGetWidth(self.timelineContentView.bounds) <= 0) {
        return;
    }

    [self.activeRecordView endInlineEditing];
    self.activeRecordView = nil;
    [self.timelineContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.nowLineView = nil;
    self.nowLineTimeLabel = nil;
    [self renderHourLines];
    [self renderRecords];
    [self updateNowLine];
}

- (void)startNowLineTimer
{
    [self stopNowLineTimer];
    self.nowLineTimer = [NSTimer timerWithTimeInterval:60.0
                                                target:self
                                              selector:@selector(updateNowLine)
                                              userInfo:nil
                                               repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.nowLineTimer forMode:NSRunLoopCommonModes];
    [self updateNowLine];
}

- (void)stopNowLineTimer
{
    [self.nowLineTimer invalidate];
    self.nowLineTimer = nil;
}

- (void)updateNowLine
{
    if (self.hourHeight <= 0 || CGRectGetWidth(self.timelineContentView.bounds) <= 0) {
        [self removeNowLine];
        return;
    }

    long now = lround([[NSDate now] timeIntervalSince1970]);
    long dayStart = [self dayStartTimestamp];
    long dayEnd = [self dayEndTimestamp];
    if (now < dayStart || now > dayEnd) {
        [self removeNowLine];
        return;
    }

    if (!self.nowLineView) {
        self.nowLineView = [UIView new];
        self.nowLineView.backgroundColor = [self nowLineColor];
        self.nowLineView.userInteractionEnabled = NO;
        [self.timelineContentView addSubview:self.nowLineView];
    }
    if (!self.nowLineTimeLabel) {
        self.nowLineTimeLabel = [UILabel new];
        self.nowLineTimeLabel.font = [UIFont mirrorMinFont];
        self.nowLineTimeLabel.textColor = [self nowLineColor];
        self.nowLineTimeLabel.textAlignment = NSTextAlignmentRight;
        self.nowLineTimeLabel.userInteractionEnabled = NO;
        [self.timelineContentView addSubview:self.nowLineTimeLabel];
    }

    CGFloat width = CGRectGetWidth(self.timelineContentView.bounds);
    CGFloat lineX = kTimelineLeftWidth;
    CGFloat lineWidth = width - lineX - kTimelineRightPadding;
    CGFloat lineY = ((CGFloat)(now - dayStart) / 3600.0) * self.hourHeight;
    CGFloat lineHeight = 1.0;
    CGFloat labelWidth = kTimelineLeftWidth - 8*kWidthRatio;
    CGFloat labelHeight = 20;
    self.nowLineTimeLabel.text = [self shortTimeFromTimestamp:now];
    self.nowLineTimeLabel.frame = CGRectMake(0, lineY - labelHeight / 2.0, labelWidth, labelHeight);
    self.nowLineView.frame = CGRectMake(lineX, lineY - lineHeight / 2.0, lineWidth, lineHeight);
    [self.timelineContentView bringSubviewToFront:self.nowLineTimeLabel];
    [self.timelineContentView bringSubviewToFront:self.nowLineView];
}

- (void)removeNowLine
{
    [self.nowLineView removeFromSuperview];
    self.nowLineView = nil;
    [self.nowLineTimeLabel removeFromSuperview];
    self.nowLineTimeLabel = nil;
}

- (UIColor *)nowLineColor
{
    return UIColor.systemRedColor;
}

- (NSString *)shortTimeFromTimestamp:(long)timestamp
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"H:mm";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

- (void)renderHourLines
{
    CGFloat width = CGRectGetWidth(self.timelineContentView.bounds);
    NSInteger hourCount = [self timelineHourCount];
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"H:mm";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    long dayStart = [self dayStartTimestamp];

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
    long dayStart = [self dayStartTimestamp];
    long dayEnd = [self dayEndTimestamp];
    CGFloat recordX = kTimelineLeftWidth;
    CGFloat recordWidth = CGRectGetWidth(self.timelineContentView.bounds) - recordX - kTimelineRightPadding;

    for (MirrorRecordModel *record in self.oneDayData) {
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
        TimelineRecordView *recordView = [self recordViewWithRecord:record frame:CGRectMake(recordX, top, recordWidth, height) showsText:showsText];
        [self.timelineContentView addSubview:recordView];
    }
}

- (TimelineRecordView *)recordViewWithRecord:(MirrorRecordModel *)record frame:(CGRect)frame showsText:(BOOL)showsText
{
    TimelineRecordView *recordView = [[TimelineRecordView alloc] initWithFrame:frame];
    recordView.delegate = self;
    [recordView configureWithRecord:record showsText:showsText];
    return recordView;
}

#pragma mark - Getters

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

- (TimelineBackgroundView *)timelineContentView
{
    if (!_timelineContentView) {
        _timelineContentView = [TimelineBackgroundView new];
        _timelineContentView.backgroundColor = self.view.backgroundColor;
    }
    return _timelineContentView;
}

- (NSMutableArray<MirrorRecordModel *> *)oneDayData
{
    if (!_oneDayData) {
        _oneDayData = [MirrorStorage getOneDayDataForDate:self.date];
    }
    return _oneDayData;
}

#pragma mark - Privates

- (void)configureTimelineContentViewForCurrentDate
{
    [self.timelineContentView configureWithHourHeight:self.hourHeight
                                    dayStartTimestamp:[self dayStartTimestamp]
                                      dayEndTimestamp:[self dayEndTimestamp]];
}

- (long)dayStartTimestamp
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDate *startOfDay = nil;
    NSTimeInterval dayDuration = 0;
    if ([gregorian rangeOfUnit:NSCalendarUnitDay startDate:&startOfDay interval:&dayDuration forDate:self.date] && startOfDay) {
        return lround([startOfDay timeIntervalSince1970]);
    }
    return lround([[gregorian startOfDayForDate:self.date] timeIntervalSince1970]);
}

- (long)dayEndTimestamp
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDate *startOfDay = nil;
    NSTimeInterval dayDuration = 0;
    if ([gregorian rangeOfUnit:NSCalendarUnitDay startDate:&startOfDay interval:&dayDuration forDate:self.date] && startOfDay) {
        return lround([startOfDay timeIntervalSince1970] + dayDuration);
    }
    NSDate *fallbackStartOfDay = [gregorian startOfDayForDate:self.date];
    NSDate *startOfNextDay = [gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:fallbackStartOfDay options:0];
    return lround([startOfNextDay timeIntervalSince1970]);
}

- (NSInteger)timelineHourCount
{
    return ([self dayEndTimestamp] - [self dayStartTimestamp]) / 3600;
}

@end
