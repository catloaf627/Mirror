//
//  RecordsTimelineViewController.m
//  Mirror
//

#import "RecordsTimelineViewController.h"
#import <Masonry/Masonry.h>
#import "MirrorNaviManager.h"
#import "MirrorStorage.h"
#import "MirrorTimeText.h"
#import "MirrorTool.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorLanguage.h"
#import "MirrorMacro.h"

static CGFloat const kHorizontalPadding = 20;
static CGFloat const kTimelineX = 28;
static CGFloat const kDotSize = 10;
static CGFloat const kRowMinHeight = 72;
static CGFloat const kTextLeftPadding = 18;
static NSInteger const kTimelineBatchSize = 50;
static CGFloat const kTimelineLoadThreshold = 48;

typedef NS_ENUM(NSInteger, TimelineBatchScrollPosition) {
    TimelineBatchScrollPositionTop,
    TimelineBatchScrollPositionNearTop,
    TimelineBatchScrollPositionNearBottom,
};

@interface RecordsTimelineViewController () <UIEditMenuInteractionDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIButton *deleteFutureRecordsButton;
@property (nonatomic, strong) MirrorDataModel *data;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *records;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *highlightedRecords;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *sortedTimelineRecords;
@property (nonatomic, copy) NSString *titleKey;
@property (nonatomic, weak) UIView *firstHighlightedRow;
@property (nonatomic, assign) NSInteger selectedPeriodIndex;
@property (nonatomic, assign) NSInteger editingPeriodIndex;
@property (nonatomic, assign) NSInteger timelineBatchStartIndex;
@property (nonatomic, assign) BOOL isRenderingTimelineBatch;
@property (nonatomic, strong) UIDatePicker *editingStartPicker;
@property (nonatomic, strong) UIDatePicker *editingEndPicker;
@property (nonatomic, strong) UITapGestureRecognizer *editingDismissTapRecognizer;
@property (nonatomic, weak) UIEditMenuInteraction *visibleRecordEditMenuInteraction API_AVAILABLE(ios(16.0));

@end

@implementation RecordsTimelineViewController

- (instancetype)initWithData:(MirrorDataModel *)data
{
    return [self initWithData:data highlightedRecords:nil];
}

- (instancetype)initWithData:(MirrorDataModel *)data highlightedRecords:(NSMutableArray<MirrorRecordModel *> *)highlightedRecords
{
    self = [super init];
    if (self) {
        self.data = data;
        self.highlightedRecords = highlightedRecords;
        [self addObservers];
    }
    return self;
}

- (instancetype)initWithRecords:(NSMutableArray<MirrorRecordModel *> *)records titleKey:(NSString *)titleKey
{
    self = [super init];
    if (self) {
        self.records = records;
        self.titleKey = titleKey;
        [self addObservers];
    }
    return self;
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
    if (self.titleKey.length == 0) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
    }
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
    self.deleteFutureRecordsButton = nil;
    self.sortedTimelineRecords = nil;
    self.timelineBatchStartIndex = 0;
    self.firstHighlightedRow = nil;
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self p_setupUI];
}

- (void)reloadData
{
    if (self.titleKey.length > 0) {
        [self reloadCustomRecords];
    } else {
        self.data.records = [MirrorStorage getAllTaskRecords:self.data.taskModel.taskName];
    }
    self.scrollView = nil;
    self.contentView = nil;
    self.deleteFutureRecordsButton = nil;
    self.sortedTimelineRecords = nil;
    self.timelineBatchStartIndex = 0;
    self.firstHighlightedRow = nil;
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self p_setupUI];
}

- (NSString *)navigationTitle
{
    if (self.titleKey.length > 0) {
        return [MirrorLanguage mirror_stringWithKey:self.titleKey];
    }
    return self.data.taskModel.taskName;
}

- (void)reloadCustomRecords
{
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage retriveMirrorRecords];
    NSMutableSet<NSNumber *> *visibleOriginalIndexes = [NSMutableSet new];
    for (MirrorRecordModel *record in self.records) {
        [visibleOriginalIndexes addObject:@(record.originalIndex)];
    }
    
    NSMutableArray<MirrorRecordModel *> *updatedRecords = [NSMutableArray new];
    for (MirrorRecordModel *record in allRecords) {
        if ([visibleOriginalIndexes containsObject:@(record.originalIndex)]) {
            [updatedRecords addObject:record];
        }
    }
    self.records = updatedRecords;
}

- (NSMutableArray<MirrorRecordModel *> *)timelineRecords
{
    if (self.titleKey.length > 0) {
        return self.records;
    }
    return self.data.records;
}

- (BOOL)isOccupiedRecordsPage
{
    return [self.titleKey isEqualToString:@"occupied_records"];
}

- (BOOL)shouldShowDeleteFutureRecordsButton
{
    return [self isOccupiedRecordsPage] && self.records.count > 0;
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    if ([self shouldShowDeleteFutureRecordsButton]) {
        [self.view addSubview:self.deleteFutureRecordsButton];
        [self.deleteFutureRecordsButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.view).offset(kHorizontalPadding * kWidthRatio);
            make.right.mas_equalTo(self.view).offset(-kHorizontalPadding * kWidthRatio);
            make.bottom.mas_equalTo(self.view).offset(-16 * kHeightRatio);
            make.height.mas_equalTo(48 * kHeightRatio);
        }];
    }
    
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        if ([self shouldShowDeleteFutureRecordsButton]) {
            make.bottom.mas_equalTo(self.deleteFutureRecordsButton.mas_top).offset(-12 * kHeightRatio);
        } else {
            make.bottom.mas_equalTo(self.view);
        }
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
    self.timelineBatchStartIndex = [self initialTimelineBatchStartIndex];
    [self renderTimelineBatchAtStartIndex:self.timelineBatchStartIndex scrollPosition:TimelineBatchScrollPositionTop];
    
    if (self.firstHighlightedRow) {
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
    
    NSInteger oldStartIndex = self.timelineBatchStartIndex;
    NSInteger totalCount = self.sortedTimelineRecords.count;
    NSInteger maxStartIndex = MAX(totalCount - kTimelineBatchSize, 0);
    NSInteger safeStartIndex = MIN(MAX(startIndex, 0), maxStartIndex);
    NSInteger endIndex = MIN(safeStartIndex + kTimelineBatchSize, totalCount);
    self.timelineBatchStartIndex = safeStartIndex;
    
    UIView *previousRow = nil;
    for (NSInteger index = safeStartIndex; index < endIndex; index++) {
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
        previousRow = row;
    }
    
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.scrollView);
        make.width.mas_equalTo(self.scrollView);
        if (previousRow) {
            make.bottom.mas_equalTo(previousRow.mas_bottom).offset(20 * kHeightRatio);
        } else {
            make.bottom.mas_equalTo(self.contentView.mas_top);
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view layoutIfNeeded];
        CGFloat maxOffsetY = MAX(self.scrollView.contentSize.height - CGRectGetHeight(self.scrollView.bounds), 0);
        if (scrollPosition == TimelineBatchScrollPositionNearTop) {
            self.scrollView.contentOffset = CGPointMake(0, MIN(kTimelineLoadThreshold + 1, maxOffsetY));
        } else if (scrollPosition == TimelineBatchScrollPositionNearBottom) {
            CGFloat targetOffsetY = MAX(maxOffsetY - kTimelineLoadThreshold - 1, 0);
            NSInteger previousRecordIndex = oldStartIndex - 1;
            if (previousRecordIndex >= 0 && previousRecordIndex < self.sortedTimelineRecords.count) {
                MirrorRecordModel *previousRecord = self.sortedTimelineRecords[previousRecordIndex];
                UIView *previousRow = [self visibleTimelineRowWithOriginalIndex:previousRecord.originalIndex];
                if (previousRow) {
                    CGRect rowRect = [previousRow.superview convertRect:previousRow.frame toView:self.scrollView];
                    targetOffsetY = MIN(MAX(rowRect.origin.y, 0), maxOffsetY);
                }
            }
            self.scrollView.contentOffset = CGPointMake(0, targetOffsetY);
        } else {
            self.scrollView.contentOffset = CGPointZero;
        }
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
        NSInteger nextStartIndex = self.timelineBatchStartIndex + kTimelineBatchSize;
        if (nextStartIndex < self.sortedTimelineRecords.count) {
            [self renderTimelineBatchAtStartIndex:nextStartIndex scrollPosition:TimelineBatchScrollPositionNearTop];
        }
    } else if (scrollView.contentOffset.y <= kTimelineLoadThreshold) {
        NSInteger previousStartIndex = self.timelineBatchStartIndex - kTimelineBatchSize + 1;
        if (self.timelineBatchStartIndex > 0) {
            [self renderTimelineBatchAtStartIndex:previousStartIndex scrollPosition:TimelineBatchScrollPositionNearBottom];
        }
    }
}

- (UIView *)timelineRowWithRecord:(MirrorRecordModel *)record isFirst:(BOOL)isFirst isLast:(BOOL)isLast isHighlighted:(BOOL)isHighlighted
{
    UIView *row = [UIView new];
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:record.taskName];
    UIColor *pulseColor = [UIColor mirrorColorPulsed:task.color];
    UIColor *taskColor = [UIColor mirrorColorNamed:task.color];
    row.backgroundColor = isHighlighted ? [pulseColor colorWithAlphaComponent:0.12] : [UIColor clearColor];
    row.tag = record.originalIndex;
    if (@available(iOS 16.0, *)) {
        UIEditMenuInteraction *editMenuInteraction = [[UIEditMenuInteraction alloc] initWithDelegate:self];
        [row addInteraction:editMenuInteraction];
        UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showEditMenu:)];
        [row addGestureRecognizer:tapRecognizer];
    }
    
    UIView *topLine = [UIView new];
    topLine.backgroundColor = pulseColor;
    topLine.alpha = isFirst ? 0 : 0.35;
    [row addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(row.mas_left).offset(kHorizontalPadding + kTimelineX);
        make.top.mas_equalTo(row);
        make.width.mas_equalTo(2);
        make.bottom.mas_equalTo(row.mas_centerY).offset(-kDotSize / 2);
    }];
    
    UIView *bottomLine = [UIView new];
    bottomLine.backgroundColor = pulseColor;
    bottomLine.alpha = isLast ? 0 : 0.35;
    [row addSubview:bottomLine];
    [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(topLine);
        make.top.mas_equalTo(row.mas_centerY).offset(kDotSize / 2);
        make.width.mas_equalTo(2);
        make.bottom.mas_equalTo(row);
    }];
    
    UIView *dot = [UIView new];
    dot.backgroundColor = taskColor;
    dot.layer.borderColor = pulseColor.CGColor;
    dot.layer.borderWidth = 2;
    dot.layer.cornerRadius = kDotSize / 2;
    [row addSubview:dot];
    [dot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(topLine);
        make.centerY.mas_equalTo(row);
        make.width.height.mas_equalTo(kDotSize);
    }];
    
    UILabel *dateLabel = [UILabel new];
    dateLabel.font = [UIFont mirrorHintFont];
    dateLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    dateLabel.text = [MirrorTimeText YYYYmmddWeekdayWithStart:record.startTime];
    [row addSubview:dateLabel];
    [dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(dot.mas_right).offset(kTextLeftPadding);
        make.right.mas_equalTo(row).offset(-kHorizontalPadding);
        make.top.mas_equalTo(row).offset(10 * kHeightRatio);
    }];
    
    UILabel *timeLabel = [UILabel new];
    timeLabel.font = [UIFont mirrorLabelFont];
    timeLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    timeLabel.adjustsFontSizeToFitWidth = YES;
    timeLabel.text = [NSString stringWithFormat:@"%@ - %@", [MirrorTool localizedTimeFromTimestamp:record.startTime], [MirrorTool localizedTimeFromTimestamp:record.endTime]];
    [row addSubview:timeLabel];
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(dateLabel);
        make.top.mas_equalTo(dateLabel.mas_bottom).offset(4 * kHeightRatio);
    }];
    
    UILabel *durationLabel = [UILabel new];
    durationLabel.font = [UIFont mirrorHintFont];
    durationLabel.textColor = pulseColor;
    durationLabel.text = [MirrorTimeText XdXhXmXsShortWithstart:record.startTime end:record.endTime];
    [row addSubview:durationLabel];
    [durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(dateLabel);
        make.top.mas_equalTo(timeLabel.mas_bottom).offset(4 * kHeightRatio);
        make.bottom.mas_lessThanOrEqualTo(row).offset(-10 * kHeightRatio);
    }];
    
    return row;
}

#pragma mark - Actions

- (void)deleteFutureRecords
{
    [self deleteAllVisibleFutureRecords];
}

- (void)deleteAllVisibleFutureRecords
{
    NSArray<MirrorRecordModel *> *recordsToDelete = [self.records sortedArrayUsingComparator:^NSComparisonResult(MirrorRecordModel *record0, MirrorRecordModel *record1) {
        if (record0.originalIndex > record1.originalIndex) return NSOrderedAscending;
        if (record0.originalIndex < record1.originalIndex) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    for (MirrorRecordModel *record in recordsToDelete) {
        [MirrorStorage deletePeriodAtIndex:record.originalIndex];
    }
    self.records = [NSMutableArray new];
    [self reloadData];
}

#pragma mark - Edit Menu

- (void)showEditMenu:(UITapGestureRecognizer *)recognizer
{
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];
    
    UIView *view = recognizer.view;
    self.selectedPeriodIndex = view.tag;
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

- (void)removeCustomRecordWithOriginalIndex:(NSInteger)originalIndex
{
    NSInteger indexToRemove = NSNotFound;
    for (NSInteger index = 0; index < self.records.count; index++) {
        if (self.records[index].originalIndex == originalIndex) {
            indexToRemove = index;
            break;
        }
    }
    if (indexToRemove == NSNotFound) {
        return;
    }
    
    [self.records removeObjectAtIndex:indexToRemove];
    for (MirrorRecordModel *record in self.records) {
        if (record.originalIndex > originalIndex) {
            record.originalIndex = record.originalIndex - 1;
        }
    }
    [self reloadData];
}

- (void)editMenuInteraction:(UIEditMenuInteraction *)interaction willPresentMenuForConfiguration:(UIEditMenuConfiguration *)configuration animator:(id<UIEditMenuInteractionAnimating>)animator API_AVAILABLE(ios(16.0))
{
    self.visibleRecordEditMenuInteraction = interaction;
}

- (void)editMenuInteraction:(UIEditMenuInteraction *)interaction willDismissMenuForConfiguration:(UIEditMenuConfiguration *)configuration animator:(id<UIEditMenuInteractionAnimating>)animator API_AVAILABLE(ios(16.0))
{
    if (interaction == self.visibleRecordEditMenuInteraction) {
        self.visibleRecordEditMenuInteraction = nil;
    }
}

- (void)deletePeriod:(UIButton *)sender
{
    NSInteger periodIndex = sender.tag;
    UIAlertController *deleteButtonAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete_period_?"] message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MirrorStorage deletePeriodAtIndex:periodIndex];
        if (self.titleKey.length > 0) {
            [self removeCustomRecordWithOriginalIndex:periodIndex];
        }
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:record.taskName message:@"\n\n\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    
    UIDatePicker *startPicker = [UIDatePicker new];
    startPicker.datePickerMode = UIDatePickerModeDateAndTime;
    startPicker.timeZone = [NSTimeZone systemTimeZone];
    startPicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    startPicker.date = [NSDate dateWithTimeIntervalSince1970:record.startTime];
    startPicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:record.endTime - kMinSeconds];
    [startPicker addTarget:self action:@selector(startPickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    if (periodIndex - 1 >= 0) {
        startPicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:records[periodIndex - 1].endTime];
    }
    
    UIDatePicker *endPicker = [UIDatePicker new];
    endPicker.datePickerMode = UIDatePickerModeDateAndTime;
    endPicker.timeZone = [NSTimeZone systemTimeZone];
    endPicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    endPicker.date = [NSDate dateWithTimeIntervalSince1970:record.endTime];
    endPicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:record.startTime + kMinSeconds];
    [endPicker addTarget:self action:@selector(endPickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    if (periodIndex + 1 <= records.count - 1) {
        endPicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:records[periodIndex + 1].startTime];
    }
    
    self.editingPeriodIndex = periodIndex;
    self.editingStartPicker = startPicker;
    self.editingEndPicker = endPicker;
    
    UILabel *startLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"starts_at"]];
    UILabel *endLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"ends_at"]];
    UILabel *noteLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"note"]];
    UITextField *noteTextField = [UITextField new];
    noteTextField.text = record.note;
    noteTextField.placeholder = [MirrorLanguage mirror_stringWithKey:@"note"];
    noteTextField.font = [UIFont mirrorHintFont];
    noteTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    noteTextField.borderStyle = UITextBorderStyleRoundedRect;
    noteTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    noteTextField.tag = periodIndex;
    [noteTextField addTarget:self action:@selector(noteTextFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    UIView *contentView = alertController.view;
    [contentView addSubview:startLabel];
    [contentView addSubview:startPicker];
    [contentView addSubview:endLabel];
    [contentView addSubview:endPicker];
    [contentView addSubview:noteLabel];
    [contentView addSubview:noteTextField];
    
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
    [noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(startLabel);
        make.top.mas_equalTo(endLabel.mas_bottom).offset(8);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(30);
    }];
    [noteTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(noteLabel.mas_right).offset(8);
        make.centerY.mas_equalTo(noteLabel);
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

- (void)noteTextFieldEditingChanged:(UITextField *)textField
{
    if (textField.text.length > 200) {
        textField.text = [textField.text substringToIndex:200];
    }
    [MirrorStorage editPeriodNote:textField.text ?: @"" periodIndex:textField.tag];
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

- (UIButton *)deleteFutureRecordsButton
{
    if (!_deleteFutureRecordsButton) {
        _deleteFutureRecordsButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _deleteFutureRecordsButton.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
        _deleteFutureRecordsButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _deleteFutureRecordsButton.titleLabel.font = [UIFont mirrorLabelFont];
        _deleteFutureRecordsButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _deleteFutureRecordsButton.layer.cornerRadius = 14;
        _deleteFutureRecordsButton.layer.borderWidth = 1;
        _deleteFutureRecordsButton.layer.borderColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint].CGColor;
        UIImage *trashImage = [[UIImage systemImageNamed:@"trash"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_deleteFutureRecordsButton setImage:trashImage forState:UIControlStateNormal];
        [_deleteFutureRecordsButton setTitle:[MirrorLanguage mirror_stringWithKey:@"delete_future_records_to_start_counting"] forState:UIControlStateNormal];
        [_deleteFutureRecordsButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeTextHint] forState:UIControlStateNormal];
        _deleteFutureRecordsButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8 * kWidthRatio);
        _deleteFutureRecordsButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8 * kWidthRatio, 0, 0);
        [_deleteFutureRecordsButton addTarget:self action:@selector(deleteFutureRecords) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteFutureRecordsButton;
}

@end
