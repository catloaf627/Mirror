//
//  TaskRecordsViewController.m
//  Mirror
//

#import "TaskRecordsViewController.h"
#import <Masonry/Masonry.h>
#import "MirrorNaviManager.h"
#import "MirrorStorage.h"
#import "MirrorTimeText.h"
#import "MirrorTool.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorLanguage.h"
#import "MirrorMacro.h"
#import "PeriodEditAlertView.h"
#import <math.h>

static CGFloat const kHorizontalPadding = 20;
static CGFloat const kDotMinSize = 8;
static CGFloat const kDotMaxSize = 16;
static NSTimeInterval const kDotMaxDuration = 8 * 60 * 60;
static CGFloat const kRowMinHeight = 72;
static NSInteger const kTimelineBatchSize = 50;
static CGFloat const kTimelineLoadThreshold = 48;

#define kTimelineX (kScreenWidth/4)

typedef NS_ENUM(NSInteger, TimelineBatchScrollPosition) {
    TimelineBatchScrollPositionTop,
    TimelineBatchScrollPositionNearTop,
    TimelineBatchScrollPositionNearBottom,
};

@interface TaskRecordsViewController () <UIEditMenuInteractionDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) MirrorReadModel *data;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *highlightedRecords;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *sortedTimelineRecords;
@property (nonatomic, weak) UIView *firstHighlightedRow;
@property (nonatomic, assign) NSInteger selectedPeriodIndex;
@property (nonatomic, assign) NSInteger editingPeriodIndex;
@property (nonatomic, assign) NSInteger timelineBatchStartIndex;
@property (nonatomic, assign) NSInteger timelineBatchEndIndex;
@property (nonatomic, assign) NSInteger savedTimelineBatchStartIndex;
@property (nonatomic, assign) CGPoint savedTimelineContentOffset;
@property (nonatomic, assign) BOOL isRenderingTimelineBatch;
@property (nonatomic, assign) BOOL shouldReloadAfterEditingPeriodAlert;
@property (nonatomic, assign) BOOL shouldRestoreTimelineScrollPosition;
@property (nonatomic, assign) BOOL didScrollToInitialHighlightedRow;
@property (nonatomic, assign) BOOL isRecordEditMenuVisible;
@property (nonatomic, assign) BOOL shouldSuppressNextRecordEditMenu;
@property (nonatomic, strong) PeriodEditAlertView *editingPeriodAlert;
@property (nonatomic, weak) UIView *firstTimelineRow;
@property (nonatomic, weak) UIView *lastTimelineRow;
@property (nonatomic, weak) UIView *borderedRecordRow;
@property (nonatomic, weak) UIEditMenuInteraction *visibleRecordEditMenuInteraction API_AVAILABLE(ios(16.0));

@end

@implementation TaskRecordsViewController

- (instancetype)initWithData:(MirrorReadModel *)data
{
    return [self initWithData:data highlightedRecords:nil];
}

- (instancetype)initWithData:(MirrorReadModel *)data highlightedRecords:(NSMutableArray<MirrorRecordModel *> *)highlightedRecords
{
    self = [super init];
    if (self) {
        self.data = data;
        self.highlightedRecords = highlightedRecords;
        [self addObservers];
    }
    return self;
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:[self navigationTitle] leftButton:nil rightButton:nil];
}

- (void)restartVC
{
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:[self navigationTitle] leftButton:nil rightButton:nil];
    self.scrollView = nil;
    self.contentView = nil;
    self.sortedTimelineRecords = nil;
    self.timelineBatchStartIndex = 0;
    self.timelineBatchEndIndex = 0;
    self.firstHighlightedRow = nil;
    self.firstTimelineRow = nil;
    self.lastTimelineRow = nil;
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self p_setupUI];
}

- (void)reloadData
{
    if (self.editingPeriodAlert.isPresented) {
        self.shouldReloadAfterEditingPeriodAlert = YES;
        return;
    }
    
    self.data.records = [MirrorStorage getAllTaskRecords:self.data.taskModel.taskName];
    if (self.scrollView != nil) {
        self.savedTimelineContentOffset = self.scrollView.contentOffset;
        self.savedTimelineBatchStartIndex = self.timelineBatchStartIndex;
        self.shouldRestoreTimelineScrollPosition = YES;
    }
    self.scrollView = nil;
    self.contentView = nil;
    self.sortedTimelineRecords = nil;
    self.timelineBatchStartIndex = 0;
    self.timelineBatchEndIndex = 0;
    self.firstHighlightedRow = nil;
    self.firstTimelineRow = nil;
    self.lastTimelineRow = nil;
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self p_setupUI];
}

- (NSString *)navigationTitle
{
    return self.data.taskModel.taskName;
}

- (NSMutableArray<MirrorRecordModel *> *)timelineRecords
{
    return self.data.records;
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.bottom.mas_equalTo(self.view);
    }];
    
    [self.scrollView addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.scrollView);
        make.width.mas_equalTo(self.scrollView);
    }];
    
    [self buildTimelineRows];
}

- (void)buildTimelineRows
{
    self.sortedTimelineRecords = [[[self timelineRecords] sortedArrayUsingComparator:^NSComparisonResult(MirrorRecordModel *record0, MirrorRecordModel *record1) {
        if (record0.startTime < record1.startTime) return NSOrderedAscending;
        if (record0.startTime > record1.startTime) return NSOrderedDescending;
        return NSOrderedSame;
    }] mutableCopy];
    self.timelineBatchStartIndex = self.shouldRestoreTimelineScrollPosition ? self.savedTimelineBatchStartIndex : [self initialTimelineBatchStartIndex];
    [self renderTimelineBatchAtStartIndex:self.timelineBatchStartIndex scrollPosition:TimelineBatchScrollPositionTop];
    
    if (self.firstHighlightedRow && !self.shouldRestoreTimelineScrollPosition && !self.didScrollToInitialHighlightedRow) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToFirstHighlightedRow];
        });
    }
}

- (NSInteger)initialTimelineBatchStartIndex
{
    if (self.highlightedRecords.count == 0 || self.sortedTimelineRecords.count <= kTimelineBatchSize) {
        return 0;
    }
    
    for (NSInteger index = 0; index < self.sortedTimelineRecords.count; index++) {
        if ([self shouldHighlightRecord:self.sortedTimelineRecords[index]]) {
            NSInteger maxStartIndex = MAX((NSInteger)self.sortedTimelineRecords.count - kTimelineBatchSize, 0);
            NSInteger leadingRecordCount = kTimelineBatchSize / 2;
            return MIN(MAX(index - leadingRecordCount, 0), maxStartIndex);
        }
    }
    return 0;
}

- (void)renderTimelineBatchAtStartIndex:(NSInteger)startIndex scrollPosition:(TimelineBatchScrollPosition)scrollPosition
{
    if (self.isRenderingTimelineBatch) {
        return;
    }
    
    self.isRenderingTimelineBatch = YES;
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.firstHighlightedRow = nil;
    self.firstTimelineRow = nil;
    self.lastTimelineRow = nil;
    
    NSInteger totalCount = self.sortedTimelineRecords.count;
    NSInteger maxStartIndex = MAX(totalCount - kTimelineBatchSize, 0);
    NSInteger safeStartIndex = MIN(MAX(startIndex, 0), maxStartIndex);
    NSInteger endIndex = MIN(safeStartIndex + kTimelineBatchSize, totalCount);
    self.timelineBatchStartIndex = safeStartIndex;
    self.timelineBatchEndIndex = endIndex;
    
    [self addTimelineRowsFromIndex:safeStartIndex toIndex:endIndex afterRow:nil beforeRow:nil];
    [self updateTimelineContentBottomConstraint];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view layoutIfNeeded];
        CGFloat maxOffsetY = MAX(self.scrollView.contentSize.height - CGRectGetHeight(self.scrollView.bounds), 0);
        if (scrollPosition == TimelineBatchScrollPositionTop) {
            self.scrollView.contentOffset = CGPointZero;
        }
        if (self.shouldRestoreTimelineScrollPosition) {
            self.scrollView.contentOffset = CGPointMake(
                0,
                MIN(MAX(self.savedTimelineContentOffset.y, 0), maxOffsetY)
            );
            self.shouldRestoreTimelineScrollPosition = NO;
        }
        self.isRenderingTimelineBatch = NO;
    });
}

- (void)addTimelineRowsFromIndex:(NSInteger)startIndex toIndex:(NSInteger)endIndex afterRow:(UIView *)afterRow beforeRow:(UIView *)beforeRow
{
    if (startIndex >= endIndex) {
        return;
    }
    
    NSInteger totalCount = self.sortedTimelineRecords.count;
    UIView *previousRow = afterRow;
    UIView *firstAddedRow = nil;
    UIView *lastAddedRow = nil;
    
    for (NSInteger index = startIndex; index < endIndex; index++) {
        MirrorRecordModel *record = self.sortedTimelineRecords[index];
        BOOL isHighlighted = [self shouldHighlightRecord:record];
        UIView *row = [self timelineRowWithRecord:record isFirst:index == 0 isLast:index == totalCount - 1 isHighlighted:isHighlighted];
        if (isHighlighted && self.firstHighlightedRow == nil) {
            self.firstHighlightedRow = row;
        }
        [self.contentView addSubview:row];
        [row mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(self.contentView);
            make.height.mas_greaterThanOrEqualTo(kRowMinHeight * kHeightRatio);
            if (previousRow) {
                make.top.mas_equalTo(previousRow.mas_bottom);
            } else {
                make.top.mas_equalTo(self.contentView).offset(12 * kHeightRatio);
            }
        }];
        if (firstAddedRow == nil) {
            firstAddedRow = row;
        }
        lastAddedRow = row;
        previousRow = row;
    }
    
    if (beforeRow != nil && lastAddedRow != nil) {
        [beforeRow mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(self.contentView);
            make.height.mas_greaterThanOrEqualTo(kRowMinHeight * kHeightRatio);
            make.top.mas_equalTo(lastAddedRow.mas_bottom);
        }];
    }
    
    if (self.firstTimelineRow == nil || beforeRow == self.firstTimelineRow) {
        self.firstTimelineRow = firstAddedRow;
    }
    if (self.lastTimelineRow == nil || afterRow == self.lastTimelineRow) {
        self.lastTimelineRow = lastAddedRow;
    }
}

- (void)updateTimelineContentBottomConstraint
{
    UIView *lastRow = self.lastTimelineRow;
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.scrollView);
        make.width.mas_equalTo(self.scrollView);
        if (lastRow) {
            make.bottom.mas_equalTo(lastRow.mas_bottom).offset(20 * kHeightRatio);
        } else {
            make.bottom.mas_equalTo(self.contentView.mas_top);
        }
    }];
}

- (void)appendNextTimelineBatchIfNeeded
{
    if (self.timelineBatchEndIndex >= self.sortedTimelineRecords.count) {
        return;
    }
    
    self.isRenderingTimelineBatch = YES;
    NSInteger nextEndIndex = MIN(self.timelineBatchEndIndex + kTimelineBatchSize, self.sortedTimelineRecords.count);
    [self addTimelineRowsFromIndex:self.timelineBatchEndIndex toIndex:nextEndIndex afterRow:self.lastTimelineRow beforeRow:nil];
    self.timelineBatchEndIndex = nextEndIndex;
    [self updateTimelineContentBottomConstraint];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view layoutIfNeeded];
        self.isRenderingTimelineBatch = NO;
    });
}

- (void)prependPreviousTimelineBatchIfNeeded
{
    if (self.timelineBatchStartIndex <= 0) {
        return;
    }
    
    self.isRenderingTimelineBatch = YES;
    [self.view layoutIfNeeded];
    CGFloat oldContentHeight = self.scrollView.contentSize.height;
    CGFloat oldOffsetY = self.scrollView.contentOffset.y;
    
    NSInteger previousStartIndex = MAX(self.timelineBatchStartIndex - kTimelineBatchSize, 0);
    [self addTimelineRowsFromIndex:previousStartIndex toIndex:self.timelineBatchStartIndex afterRow:nil beforeRow:self.firstTimelineRow];
    self.timelineBatchStartIndex = previousStartIndex;
    [self updateTimelineContentBottomConstraint];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view layoutIfNeeded];
        CGFloat heightDelta = self.scrollView.contentSize.height - oldContentHeight;
        CGFloat maxOffsetY = MAX(self.scrollView.contentSize.height - CGRectGetHeight(self.scrollView.bounds), 0);
        self.scrollView.contentOffset = CGPointMake(0, MIN(MAX(oldOffsetY + heightDelta, 0), maxOffsetY));
        self.isRenderingTimelineBatch = NO;
    });
}

- (BOOL)shouldHighlightRecord:(MirrorRecordModel *)record
{
    for (MirrorRecordModel *highlightedRecord in self.highlightedRecords) {
        if (highlightedRecord.originalIndex == record.originalIndex) {
            return YES;
        }
    }
    return NO;
}

- (void)scrollToFirstHighlightedRow
{
    self.isRenderingTimelineBatch = YES;
    [self.view layoutIfNeeded];
    CGRect rowRect = [self.firstHighlightedRow.superview convertRect:self.firstHighlightedRow.frame toView:self.scrollView];
    CGFloat targetY = MAX(rowRect.origin.y - 16 * kHeightRatio, 0);
    CGFloat maxY = MAX(self.scrollView.contentSize.height - CGRectGetHeight(self.scrollView.bounds), 0);
    [self.scrollView setContentOffset:CGPointMake(0, MIN(targetY, maxY)) animated:NO];
    self.didScrollToInitialHighlightedRow = YES;
    self.isRenderingTimelineBatch = NO;
}

- (UIView *)visibleTimelineRowWithOriginalIndex:(NSInteger)originalIndex
{
    for (UIView *row in self.contentView.subviews) {
        if (row.tag == originalIndex) {
            return row;
        }
    }
    return nil;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.isRenderingTimelineBatch || self.sortedTimelineRecords.count <= kTimelineBatchSize) {
        return;
    }
    
    CGFloat maxOffsetY = scrollView.contentSize.height - CGRectGetHeight(scrollView.bounds);
    if (maxOffsetY <= 0) {
        return;
    }
    
    if (scrollView.contentOffset.y >= maxOffsetY - kTimelineLoadThreshold) {
        [self appendNextTimelineBatchIfNeeded];
    } else if (scrollView.contentOffset.y <= kTimelineLoadThreshold) {
        if (self.timelineBatchStartIndex > 0) {
            [self prependPreviousTimelineBatchIfNeeded];
        }
    }
}

// Scale the timeline dot by duration, using a capped logarithmic curve to keep long records understated.
- (CGFloat)dotSizeForRecord:(MirrorRecordModel *)record
{
    NSTimeInterval duration = MAX((NSTimeInterval)(record.endTime - record.startTime), 0);
    NSTimeInterval cappedDuration = MIN(duration, kDotMaxDuration);
    CGFloat durationRatio = log1p(cappedDuration / 3600.0) / log1p(kDotMaxDuration / 3600.0);
    return kDotMinSize + (kDotMaxSize - kDotMinSize) * durationRatio;
}

- (UIView *)timelineRowWithRecord:(MirrorRecordModel *)record isFirst:(BOOL)isFirst isLast:(BOOL)isLast isHighlighted:(BOOL)isHighlighted
{
    UIView *row = [UIView new];
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:record.taskName];
    UIColor *pulseColor = [UIColor mirrorColorPulsed:task.color];
    UIColor *taskColor = [UIColor mirrorColorNamed:task.color];
    CGFloat dotSize = [self dotSizeForRecord:record];
    row.backgroundColor = isHighlighted ? [pulseColor colorWithAlphaComponent:0.12] : [UIColor clearColor];
    row.tag = record.originalIndex;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(recordRowTapped:)];
    [row addGestureRecognizer:tapRecognizer];
    if (@available(iOS 16.0, *)) {
        UIEditMenuInteraction *editMenuInteraction = [[UIEditMenuInteraction alloc] initWithDelegate:self];
        [row addInteraction:editMenuInteraction];
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showEditMenu:)];
        [tapRecognizer requireGestureRecognizerToFail:longPressRecognizer];
        [row addGestureRecognizer:longPressRecognizer];
    }
    
    UIView *topLine = [UIView new];
    topLine.backgroundColor = pulseColor;
    topLine.alpha = isFirst ? 0 : 0.35;
    [row addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(row.mas_left).offset(kHorizontalPadding + kTimelineX);
        make.top.mas_equalTo(row);
        make.width.mas_equalTo(2);
        make.bottom.mas_equalTo(row.mas_centerY).offset(-dotSize / 2);
    }];
    
    UIView *bottomLine = [UIView new];
    bottomLine.backgroundColor = pulseColor;
    bottomLine.alpha = isLast ? 0 : 0.35;
    [row addSubview:bottomLine];
    [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(topLine);
        make.top.mas_equalTo(row.mas_centerY).offset(dotSize / 2);
        make.width.mas_equalTo(2);
        make.bottom.mas_equalTo(row);
    }];
    
    UIView *dot = [UIView new];
    dot.backgroundColor = taskColor;
    dot.layer.borderColor = pulseColor.CGColor;
    dot.layer.borderWidth = 2;
    dot.layer.cornerRadius = dotSize / 2;
    [row addSubview:dot];
    [dot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(topLine);
        make.centerY.mas_equalTo(row);
        make.width.height.mas_equalTo(dotSize);
    }];
    
    UILabel *leftDateLabel = [UILabel new];
    leftDateLabel.font = [UIFont mirrorHighlightFont];
    leftDateLabel.textColor = pulseColor;
    leftDateLabel.alpha = 0.7;
    leftDateLabel.textAlignment = NSTextAlignmentRight;
    leftDateLabel.adjustsFontSizeToFitWidth = YES;
    leftDateLabel.minimumScaleFactor = 0.7;
    leftDateLabel.text = [MirrorTool timelineMonthDayTextForTimestamp:record.startTime];
    [row addSubview:leftDateLabel];
    [leftDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(row).offset(4 * kWidthRatio);
        make.right.mas_equalTo(dot.mas_left).offset(-8 * kWidthRatio);
        make.centerY.mas_equalTo(dot.mas_centerY).offset(-6 * kHeightRatio);
    }];
    
    UILabel *leftYearLabel = [UILabel new];
    leftYearLabel.font = [UIFont mirrorHintFont];
    leftYearLabel.textColor = pulseColor;
    leftYearLabel.alpha = 0.7;
    leftYearLabel.textAlignment = NSTextAlignmentRight;
    leftYearLabel.adjustsFontSizeToFitWidth = YES;
    leftYearLabel.minimumScaleFactor = 0.7;
    leftYearLabel.text = [MirrorTool timelineYearTextForTimestamp:record.startTime];
    [row addSubview:leftYearLabel];
    [leftYearLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(leftDateLabel);
        make.top.mas_equalTo(leftDateLabel.mas_bottom).offset(4 * kHeightRatio);
        make.bottom.mas_lessThanOrEqualTo(row).offset(-10 * kHeightRatio);
    }];
    
    UILabel *durationLabel = [UILabel new];
    durationLabel.font = [UIFont mirrorLabelFont];
    durationLabel.textColor = pulseColor;
    durationLabel.adjustsFontSizeToFitWidth = YES;
    durationLabel.minimumScaleFactor = 0.7;
    durationLabel.text = [MirrorTimeText XdXhXmXsShortWithstart:record.startTime end:record.endTime];
    [durationLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [durationLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [row addSubview:durationLabel];
    [durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(dot.mas_right).offset(8 * kWidthRatio);
        make.centerY.mas_equalTo(dot.mas_centerY);
    }];
    
    UILabel *noteLabel = [UILabel new];
    noteLabel.font = [UIFont mirrorHintFont];
    noteLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    noteLabel.adjustsFontSizeToFitWidth = YES;
    noteLabel.minimumScaleFactor = 0.7;
    noteLabel.text = record.note;
    if (is_debug) {
        noteLabel.text = [NSString stringWithFormat:@"%@ #%ld", record.note ?: @"", (long)record.originalIndex];
    }
    [noteLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [row addSubview:noteLabel];
    [noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(durationLabel.mas_right).offset(10);
        make.right.mas_equalTo(row).offset(-kHorizontalPadding);
        make.centerY.mas_equalTo(durationLabel.mas_centerY);
        make.bottom.mas_lessThanOrEqualTo(row).offset(-10 * kHeightRatio);
    }];
    
    return row;
}

- (void)recordRowTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    UIColor *borderColor = [UIColor mirrorColorPulsed:self.data.taskModel.color];
    [self flashBorderForRecordRow:recognizer.view color:borderColor];
}

- (void)showBorderForRecordRow:(UIView *)row color:(UIColor *)color
{
    if (self.borderedRecordRow && self.borderedRecordRow != row) {
        [self clearBorderForRecordRow:self.borderedRecordRow];
    }
    
    self.borderedRecordRow = row;
    row.layer.cornerRadius = 8;
    row.layer.masksToBounds = YES;
    row.layer.borderColor = color.CGColor;
    row.layer.borderWidth = 1.5;
}

- (void)clearBorderForRecordRow:(UIView *)row
{
    if (!row) {
        return;
    }
    
    row.layer.borderWidth = 0;
    row.layer.borderColor = nil;
    if (self.borderedRecordRow == row) {
        self.borderedRecordRow = nil;
    }
}

- (void)flashBorderForRecordRow:(UIView *)row color:(UIColor *)color
{
    [self showBorderForRecordRow:row color:color];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.65 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!self.isRecordEditMenuVisible && self.borderedRecordRow == row) {
            [self clearBorderForRecordRow:row];
        }
    });
}

#pragma mark - Edit Menu

- (void)showEditMenu:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    if ([self dismissVisibleRecordEditMenuIfNeeded]) {
        return;
    }
    if (self.shouldSuppressNextRecordEditMenu) {
        self.shouldSuppressNextRecordEditMenu = NO;
        return;
    }
    
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];
    
    UIView *view = recognizer.view;
    self.selectedPeriodIndex = view.tag;
    UIColor *borderColor = [UIColor mirrorColorPulsed:self.data.taskModel.color];
    [self showBorderForRecordRow:view color:borderColor];
    [self shakeSelectedRow:view];
    
    if (@available(iOS 16.0, *)) {
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
}

- (void)shakeSelectedRow:(UIView *)row
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.values = @[@0, @(-4 * kWidthRatio), @(4 * kWidthRatio), @(-2 * kWidthRatio), @(2 * kWidthRatio), @0];
    animation.duration = 0.18;
    [row.layer addAnimation:animation forKey:@"selectedRowShake"];
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
        UIButton *button = [UIButton new];
        button.tag = periodIndex;
        [self deletePeriod:button];
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
        [self clearBorderForRecordRow:self.borderedRecordRow];
        self.shouldSuppressNextRecordEditMenu = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.isRecordEditMenuVisible) {
                self.shouldSuppressNextRecordEditMenu = NO;
            }
        });
    }
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
    [self clearBorderForRecordRow:self.borderedRecordRow];
    self.shouldSuppressNextRecordEditMenu = NO;
    return YES;
}

- (void)deletePeriod:(UIButton *)sender
{
    NSInteger periodIndex = sender.tag;
    UIAlertController *deleteButtonAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete_period_?"] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MirrorStorage deletePeriodAtIndex:periodIndex];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];
    
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
        BOOL shouldReload = weakSelf.shouldReloadAfterEditingPeriodAlert;
        weakSelf.shouldReloadAfterEditingPeriodAlert = NO;
        weakSelf.editingPeriodAlert = nil;
        if (shouldReload) {
            [weakSelf reloadData];
        }
    }];
    self.editingPeriodAlert = alert;
    [alert presentFromViewController:self];
}

- (void)saveEditingRecord:(MirrorRecordModel *)record periodIndex:(NSInteger)periodIndex
{
    [MirrorStorage editPeriodWithRecord:record periodIndex:periodIndex];
}

#pragma mark - Getters

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
        _scrollView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.delegate = self;
    }
    return _scrollView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    }
    return _contentView;
}

@end
