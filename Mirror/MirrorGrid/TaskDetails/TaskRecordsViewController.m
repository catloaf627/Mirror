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
static CGFloat const kRowVerticalPadding = 10;
static NSString * const kTaskRecordsTimelineCellIdentifier = @"TaskRecordsTimelineCell";

static CGFloat TaskRecordsPixelCeil(CGFloat value)
{
    CGFloat scale = UIScreen.mainScreen.scale;
    if (scale <= 0) {
        return value;
    }
    return ceil(value * scale) / scale;
}

static CGFloat TaskRecordsScaledHeight(CGFloat value)
{
    return TaskRecordsPixelCeil(value * kHeightRatio);
}

#define kTimelineX (kScreenWidth/4)

@interface TaskRecordTimelineCell : UICollectionViewCell

- (void)configureWithRecord:(MirrorRecordModel *)record
                  taskColor:(UIColor *)taskColor
                 pulseColor:(UIColor *)pulseColor
                    dotSize:(CGFloat)dotSize
                    isFirst:(BOOL)isFirst
                     isLast:(BOOL)isLast
              isHighlighted:(BOOL)isHighlighted
                 isSelected:(BOOL)isSelected;
- (void)setShowsSelectionBorder:(BOOL)showsSelectionBorder color:(UIColor *)color;
- (void)shake;

@end

@interface TaskRecordTimelineCell ()

@property (nonatomic, strong) UIView *highlightBackgroundView;
@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) UIView *bottomLine;
@property (nonatomic, strong) UIView *dot;
@property (nonatomic, strong) UILabel *leftDateLabel;
@property (nonatomic, strong) UILabel *leftYearLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UILabel *noteLabel;
@property (nonatomic, assign) CGFloat dotSize;

@end

@implementation TaskRecordTimelineCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;

        self.highlightBackgroundView = [UIView new];
        self.highlightBackgroundView.hidden = YES;
        [self.contentView addSubview:self.highlightBackgroundView];

        self.topLine = [UIView new];
        [self.contentView addSubview:self.topLine];

        self.bottomLine = [UIView new];
        [self.contentView addSubview:self.bottomLine];

        self.dot = [UIView new];
        [self.contentView addSubview:self.dot];

        self.leftDateLabel = [UILabel new];
        self.leftDateLabel.font = [UIFont mirrorLabelFont];
        self.leftDateLabel.textAlignment = NSTextAlignmentRight;
        self.leftDateLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:self.leftDateLabel];

        self.leftYearLabel = [UILabel new];
        self.leftYearLabel.font = [UIFont mirrorLabelFont];
        self.leftYearLabel.textAlignment = NSTextAlignmentRight;
        self.leftYearLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:self.leftYearLabel];

        self.durationLabel = [UILabel new];
        self.durationLabel.font = [UIFont mirrorLabelFont];
        self.durationLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:self.durationLabel];

        self.noteLabel = [UILabel new];
        self.noteLabel.font = [UIFont mirrorLabelFont];
        self.noteLabel.numberOfLines = 0;
        self.noteLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.contentView addSubview:self.noteLabel];

    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setShowsSelectionBorder:NO color:nil];
    self.layer.backgroundColor = UIColor.clearColor.CGColor;
    self.contentView.layer.backgroundColor = UIColor.clearColor.CGColor;
    self.highlightBackgroundView.hidden = YES;
}

- (void)configureWithRecord:(MirrorRecordModel *)record
                  taskColor:(UIColor *)taskColor
                 pulseColor:(UIColor *)pulseColor
                    dotSize:(CGFloat)dotSize
                    isFirst:(BOOL)isFirst
                     isLast:(BOOL)isLast
              isHighlighted:(BOOL)isHighlighted
                 isSelected:(BOOL)isSelected
{
    self.dotSize = dotSize;
    self.contentView.backgroundColor = UIColor.clearColor;
    self.highlightBackgroundView.hidden = !isHighlighted;
    self.highlightBackgroundView.backgroundColor = [pulseColor colorWithAlphaComponent:0.12];
    self.topLine.backgroundColor = pulseColor;
    self.topLine.alpha = isFirst ? 0 : 0.35;
    self.bottomLine.backgroundColor = pulseColor;
    self.bottomLine.alpha = isLast ? 0 : 0.35;
    self.dot.backgroundColor = taskColor;
    self.dot.layer.borderColor = pulseColor.CGColor;
    self.dot.layer.borderWidth = 2;
    self.leftDateLabel.textColor = pulseColor;
    self.leftDateLabel.alpha = 0.7;
    self.leftDateLabel.text = [MirrorTool timelineMonthDayTextForTimestamp:record.startTime];
    self.leftYearLabel.textColor = pulseColor;
    self.leftYearLabel.alpha = 0.7;
    self.leftYearLabel.text = [MirrorTool timelineYearTextForTimestamp:record.startTime];
    self.durationLabel.textColor = pulseColor;
    self.durationLabel.text = [MirrorTimeText XdXhXmXsShortWithstart:record.startTime end:record.endTime];
    self.noteLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    self.noteLabel.text = record.note;
    if (is_debug) {
        self.noteLabel.text = [NSString stringWithFormat:@"%@ #%ld", record.note ?: @"", (long)record.originalIndex];
    }
    [self setShowsSelectionBorder:isSelected color:pulseColor];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    CGFloat height = CGRectGetHeight(self.contentView.bounds);
    CGFloat timelineX = kHorizontalPadding + kTimelineX;
    CGFloat centerY = height / 2.0;
    CGFloat dotSize = self.dotSize > 0 ? self.dotSize : kDotMinSize;

    self.highlightBackgroundView.frame = self.contentView.bounds;
    self.highlightBackgroundView.layer.cornerRadius = 0;

    self.topLine.frame = CGRectMake(timelineX - 1, 0, 2, MAX(centerY - dotSize / 2.0, 0));
    self.bottomLine.frame = CGRectMake(timelineX - 1, centerY + dotSize / 2.0, 2, MAX(height - centerY - dotSize / 2.0, 0));
    self.dot.frame = CGRectMake(timelineX - dotSize / 2.0, centerY - dotSize / 2.0, dotSize, dotSize);
    self.dot.layer.cornerRadius = dotSize / 2.0;

    CGFloat leftLabelX = 4 * kWidthRatio;
    CGFloat leftLabelRight = CGRectGetMinX(self.dot.frame) - 8 * kWidthRatio;
    CGFloat leftLabelWidth = MAX(leftLabelRight - leftLabelX, 0);
    self.leftDateLabel.frame = CGRectMake(leftLabelX, centerY - 22 * kHeightRatio, leftLabelWidth, 18 * kHeightRatio);
    self.leftYearLabel.frame = CGRectMake(leftLabelX, CGRectGetMaxY(self.leftDateLabel.frame) + 4 * kHeightRatio, leftLabelWidth, 16 * kHeightRatio);

    [self.durationLabel sizeToFit];
    CGFloat durationX = CGRectGetMaxX(self.dot.frame) + 8 * kWidthRatio;
    CGFloat durationWidth = MIN(CGRectGetWidth(self.durationLabel.bounds), MAX(width - durationX - kHorizontalPadding, 0));
    self.durationLabel.frame = CGRectMake(durationX, centerY - 10 * kHeightRatio, durationWidth, 20 * kHeightRatio);

    CGFloat noteX = CGRectGetMaxX(self.durationLabel.frame) + 10;
    CGFloat noteWidth = MAX(width - noteX - kHorizontalPadding, 0);
    CGFloat noteVerticalPadding = TaskRecordsScaledHeight(kRowVerticalPadding);
    CGFloat noteMaxHeight = MAX(height - noteVerticalPadding * 2, 0);
    CGFloat noteLineHeight = MAX(ceil(self.noteLabel.font.lineHeight), 1);
    self.noteLabel.numberOfLines = MAX((NSInteger)floor(noteMaxHeight / noteLineHeight), 1);
    CGSize noteSize = [self.noteLabel sizeThatFits:CGSizeMake(noteWidth, noteMaxHeight)];
    CGFloat noteHeight = MIN(TaskRecordsPixelCeil(noteSize.height), noteMaxHeight);
    self.noteLabel.frame = CGRectMake(noteX, centerY - noteHeight / 2.0, noteWidth, noteHeight);
}

- (void)setShowsSelectionBorder:(BOOL)showsSelectionBorder color:(UIColor *)color
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.layer.cornerRadius = 0;
    self.layer.masksToBounds = NO;
    self.layer.borderWidth = 0;
    self.layer.borderColor = nil;
    self.contentView.layer.cornerRadius = showsSelectionBorder ? 8 : 0;
    self.contentView.layer.masksToBounds = NO;
    self.contentView.layer.borderWidth = showsSelectionBorder ? 1 : 0;
    self.contentView.layer.borderColor = showsSelectionBorder ? color.CGColor : nil;
    [CATransaction commit];
}

- (void)shake
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.values = @[@0, @(-4 * kWidthRatio), @(4 * kWidthRatio), @(-2 * kWidthRatio), @(2 * kWidthRatio), @0];
    animation.duration = 0.18;
    [self.layer addAnimation:animation forKey:@"selectedRowShake"];
}

@end

@interface TaskRecordsViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIEditMenuInteractionDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) MirrorReadModel *data;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *highlightedRecords;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *sortedTimelineRecords;
@property (nonatomic, assign) NSInteger selectedPeriodIndex;
@property (nonatomic, assign) NSInteger editingPeriodIndex;
@property (nonatomic, assign) CGSize lastCollectionViewBoundsSize;
@property (nonatomic, assign) CGPoint savedTimelineContentOffset;
@property (nonatomic, assign) NSInteger pendingDeletedPeriodIndex;
@property (nonatomic, assign) BOOL shouldReloadAfterEditingPeriodAlert;
@property (nonatomic, assign) BOOL shouldRestoreTimelineScrollPosition;
@property (nonatomic, assign) BOOL didScrollToInitialHighlightedRecord;
@property (nonatomic, assign) BOOL isRecordEditMenuVisible;
@property (nonatomic, assign) BOOL shouldSuppressNextRecordEditMenu;
@property (nonatomic, strong) PeriodEditAlertView *editingPeriodAlert;
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
        self.selectedPeriodIndex = NSNotFound;
        self.pendingDeletedPeriodIndex = NSNotFound;
        [self addObservers];
    }
    return self;
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(periodDeleted) name:MirrorPeriodDeleteNotification object:nil];
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

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGSize boundsSize = self.collectionView.bounds.size;
    if (!CGSizeEqualToSize(boundsSize, self.lastCollectionViewBoundsSize)) {
        self.lastCollectionViewBoundsSize = boundsSize;
        [self.collectionView.collectionViewLayout invalidateLayout];
    }
}

- (void)restartVC
{
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:[self navigationTitle] leftButton:nil rightButton:nil];
    [UIView performWithoutAnimation:^{
        self.collectionView = nil;
        self.lastCollectionViewBoundsSize = CGSizeZero;
        self.didScrollToInitialHighlightedRecord = NO;
        [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [self p_setupUI];
        [self.view layoutIfNeeded];
    }];
}

- (void)reloadData
{
    if (self.editingPeriodAlert.isPresented) {
        self.shouldReloadAfterEditingPeriodAlert = YES;
        return;
    }

    if (self.collectionView) {
        self.savedTimelineContentOffset = self.collectionView.contentOffset;
        self.shouldRestoreTimelineScrollPosition = YES;
    }
    self.data.records = [MirrorStorage getAllTaskRecords:self.data.taskModel.taskName];
    [self sortTimelineRecords];
    [self clearSelectedPeriodIfNeeded];
    [self.collectionView reloadData];
    [self restoreTimelineScrollPositionIfNeeded];
}

- (void)periodDeleted
{
    if (self.editingPeriodAlert.isPresented) {
        self.shouldReloadAfterEditingPeriodAlert = YES;
        return;
    }
    // Deletes started from this screen skip full reload so the collection view can animate the removed cell.
    if (self.pendingDeletedPeriodIndex == NSNotFound || !self.collectionView) {
        [self reloadData];
        return;
    }

    NSIndexPath *deletedIndexPath = [self indexPathForOriginalIndex:self.pendingDeletedPeriodIndex];
    self.pendingDeletedPeriodIndex = NSNotFound;
    if (!deletedIndexPath) {
        [self reloadData];
        return;
    }

    NSInteger deletedItem = deletedIndexPath.item;
    self.selectedPeriodIndex = NSNotFound;
    [self.collectionView deselectItemAtIndexPath:deletedIndexPath animated:NO];
    self.data.records = [MirrorStorage getAllTaskRecords:self.data.taskModel.taskName];
    [self sortTimelineRecords];

    NSInteger expectedCount = [self.collectionView numberOfItemsInSection:0] - 1;
    if (expectedCount != self.sortedTimelineRecords.count) {
        [self.collectionView reloadData];
        return;
    }

    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[deletedIndexPath]];
    } completion:^(BOOL finished) {
        [UIView performWithoutAnimation:^{
            [self reloadBoundaryItemsAroundDeletedItem:deletedItem];
        }];
    }];
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
    [self sortTimelineRecords];

    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.bottom.mas_equalTo(self.view);
    }];

    if (!self.didScrollToInitialHighlightedRecord) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToFirstHighlightedRecordIfNeeded];
        });
    }
}

- (void)sortTimelineRecords
{
    self.sortedTimelineRecords = [[[self timelineRecords] sortedArrayUsingComparator:^NSComparisonResult(MirrorRecordModel *record0, MirrorRecordModel *record1) {
        if (record0.startTime < record1.startTime) return NSOrderedAscending;
        if (record0.startTime > record1.startTime) return NSOrderedDescending;
        return NSOrderedSame;
    }] mutableCopy];
}

- (void)clearSelectedPeriodIfNeeded
{
    if (self.selectedPeriodIndex == NSNotFound) {
        return;
    }
    if (![self indexPathForOriginalIndex:self.selectedPeriodIndex]) {
        self.selectedPeriodIndex = NSNotFound;
    }
}

- (void)restoreTimelineScrollPositionIfNeeded
{
    if (!self.shouldRestoreTimelineScrollPosition) {
        return;
    }
    self.shouldRestoreTimelineScrollPosition = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat maxOffsetY = MAX(self.collectionView.contentSize.height - CGRectGetHeight(self.collectionView.bounds), 0);
        self.collectionView.contentOffset = CGPointMake(0, MIN(MAX(self.savedTimelineContentOffset.y, 0), maxOffsetY));
    });
}

- (void)scrollToFirstHighlightedRecordIfNeeded
{
    NSArray<NSIndexPath *> *highlightedIndexPaths = [self highlightedRecordIndexPaths];
    if (highlightedIndexPaths.count == 0) {
        return;
    }

    [self.collectionView layoutIfNeeded];
    NSInteger maximumVisibleCellCount = [self maximumVisibleCellCount];
    if (highlightedIndexPaths.count < maximumVisibleCellCount) {
        NSIndexPath *middleIndexPath = highlightedIndexPaths[highlightedIndexPaths.count / 2];
        [self scrollToIndexPathAtVerticalCenter:middleIndexPath];
    } else {
        [self scrollToIndexPathNearTop:highlightedIndexPaths.firstObject];
    }
    self.didScrollToInitialHighlightedRecord = YES;
}

- (NSArray<NSIndexPath *> *)highlightedRecordIndexPaths
{
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray new];
    for (NSInteger index = 0; index < self.sortedTimelineRecords.count; index++) {
        if ([self shouldHighlightRecord:self.sortedTimelineRecords[index]]) {
            [indexPaths addObject:[NSIndexPath indexPathForItem:index inSection:0]];
        }
    }
    return indexPaths.copy;
}

- (NSInteger)maximumVisibleCellCount
{
    CGFloat rowHeight = TaskRecordsScaledHeight(kRowMinHeight);
    if (rowHeight <= 0) {
        return 1;
    }
    return MAX((NSInteger)floor(CGRectGetHeight(self.collectionView.bounds) / rowHeight), 1);
}

- (void)scrollToIndexPathAtVerticalCenter:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    if (!attributes) {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
        return;
    }
    [self setTimelineContentOffsetY:CGRectGetMidY(attributes.frame) - CGRectGetHeight(self.collectionView.bounds) / 2.0];
}

- (void)scrollToIndexPathNearTop:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    if (!attributes) {
        [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
        return;
    }
    [self setTimelineContentOffsetY:CGRectGetMinY(attributes.frame) - TaskRecordsScaledHeight(12)];
}

- (void)setTimelineContentOffsetY:(CGFloat)offsetY
{
    CGFloat minimumOffsetY = -self.collectionView.adjustedContentInset.top;
    CGFloat maximumOffsetY = MAX(self.collectionView.contentSize.height - CGRectGetHeight(self.collectionView.bounds) + self.collectionView.adjustedContentInset.bottom, minimumOffsetY);
    self.collectionView.contentOffset = CGPointMake(0, MIN(MAX(offsetY, minimumOffsetY), maximumOffsetY));
}

- (NSIndexPath *)indexPathForOriginalIndex:(NSInteger)originalIndex
{
    for (NSInteger index = 0; index < self.sortedTimelineRecords.count; index++) {
        if (self.sortedTimelineRecords[index].originalIndex == originalIndex) {
            return [NSIndexPath indexPathForItem:index inSection:0];
        }
    }
    return nil;
}

- (BOOL)shouldHighlightRecord:(MirrorRecordModel *)record
{
    for (MirrorRecordModel *highlightedRecord in self.highlightedRecords) {
        if (record.startTime < highlightedRecord.endTime && record.endTime > highlightedRecord.startTime) {
            return YES;
        }
    }
    return NO;
}

// Scale the timeline dot by duration, using a capped logarithmic curve to keep long records understated.
- (CGFloat)dotSizeForRecord:(MirrorRecordModel *)record
{
    NSTimeInterval duration = MAX((NSTimeInterval)(record.endTime - record.startTime), 0);
    NSTimeInterval cappedDuration = MIN(duration, kDotMaxDuration);
    CGFloat durationRatio = log1p(cappedDuration / 3600.0) / log1p(kDotMaxDuration / 3600.0);
    return kDotMinSize + (kDotMaxSize - kDotMinSize) * durationRatio;
}

#pragma mark - Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.sortedTimelineRecords.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TaskRecordTimelineCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTaskRecordsTimelineCellIdentifier forIndexPath:indexPath];
    MirrorRecordModel *record = self.sortedTimelineRecords[indexPath.item];
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:record.taskName];
    UIColor *taskColor = [UIColor mirrorColorNamed:task.color ?: self.data.taskModel.color];
    UIColor *pulseColor = [UIColor mirrorColorPulsed:task.color ?: self.data.taskModel.color];
    BOOL isHighlighted = [self shouldHighlightRecord:record];
    [cell configureWithRecord:record
                    taskColor:taskColor
                   pulseColor:pulseColor
                      dotSize:[self dotSizeForRecord:record]
                      isFirst:indexPath.item == 0
                       isLast:indexPath.item == self.sortedTimelineRecords.count - 1
                isHighlighted:isHighlighted
                   isSelected:record.originalIndex == self.selectedPeriodIndex];
    [self installEditMenuInteractionIfNeededForCell:cell];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CGRectGetWidth(collectionView.bounds), TaskRecordsScaledHeight(kRowMinHeight));
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(TaskRecordsScaledHeight(12), 0, TaskRecordsScaledHeight(20), 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger previousPeriodIndex = self.selectedPeriodIndex;
    MirrorRecordModel *record = self.sortedTimelineRecords[indexPath.item];
    self.selectedPeriodIndex = record.originalIndex;
    [self reloadSelectionFromPreviousPeriodIndex:previousPeriodIndex currentPeriodIndex:self.selectedPeriodIndex];
}

- (void)reloadSelectionFromPreviousPeriodIndex:(NSInteger)previousPeriodIndex currentPeriodIndex:(NSInteger)currentPeriodIndex
{
    UIColor *selectionColor = [UIColor mirrorColorPulsed:self.data.taskModel.color];
    NSIndexPath *previousIndexPath = [self indexPathForOriginalIndex:previousPeriodIndex];
    if (previousIndexPath) {
        TaskRecordTimelineCell *previousCell = (TaskRecordTimelineCell *)[self.collectionView cellForItemAtIndexPath:previousIndexPath];
        [previousCell setShowsSelectionBorder:NO color:nil];
    }
    NSIndexPath *currentIndexPath = [self indexPathForOriginalIndex:currentPeriodIndex];
    if (currentIndexPath) {
        TaskRecordTimelineCell *currentCell = (TaskRecordTimelineCell *)[self.collectionView cellForItemAtIndexPath:currentIndexPath];
        [currentCell setShowsSelectionBorder:YES color:selectionColor];
    }
}

- (void)reloadBoundaryItemsAroundDeletedItem:(NSInteger)deletedItem
{
    if (self.sortedTimelineRecords.count == 0) {
        return;
    }

    NSMutableOrderedSet<NSIndexPath *> *indexPaths = [NSMutableOrderedSet new];
    NSInteger previousItem = deletedItem - 1;
    if (previousItem >= 0 && previousItem < self.sortedTimelineRecords.count) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:previousItem inSection:0]];
    }
    NSInteger shiftedItem = MIN(deletedItem, self.sortedTimelineRecords.count - 1);
    if (shiftedItem >= 0) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:shiftedItem inSection:0]];
    }
    if (indexPaths.count > 0) {
        [self.collectionView reloadItemsAtIndexPaths:indexPaths.array];
    }
}

- (void)timelineBackgroundTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    NSInteger previousPeriodIndex = self.selectedPeriodIndex;
    self.selectedPeriodIndex = NSNotFound;
    [self reloadSelectionFromPreviousPeriodIndex:previousPeriodIndex currentPeriodIndex:NSNotFound];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer.view == self.collectionView) {
        CGPoint point = [touch locationInView:self.collectionView];
        return [self.collectionView indexPathForItemAtPoint:point] == nil;
    }
    return YES;
}

#pragma mark - Edit Menu

- (void)installEditMenuInteractionIfNeededForCell:(UICollectionViewCell *)cell
{
    if (@available(iOS 16.0, *)) {
        for (id<UIInteraction> interaction in cell.interactions) {
            if ([interaction isKindOfClass:UIEditMenuInteraction.class]) {
                return;
            }
        }
        UIEditMenuInteraction *editMenuInteraction = [[UIEditMenuInteraction alloc] initWithDelegate:self];
        [cell addInteraction:editMenuInteraction];
    }
}

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

    CGPoint point = [recognizer locationInView:self.collectionView];
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:point];
    if (!indexPath) {
        return;
    }

    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];

    MirrorRecordModel *record = self.sortedTimelineRecords[indexPath.item];
    TaskRecordTimelineCell *cell = (TaskRecordTimelineCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    NSInteger previousPeriodIndex = self.selectedPeriodIndex;
    self.selectedPeriodIndex = record.originalIndex;
    [self reloadSelectionFromPreviousPeriodIndex:previousPeriodIndex currentPeriodIndex:self.selectedPeriodIndex];

    [cell shake];

    if (@available(iOS 16.0, *)) {
        UIEditMenuInteraction *editMenuInteraction = nil;
        for (id<UIInteraction> interaction in cell.interactions) {
            if ([interaction isKindOfClass:UIEditMenuInteraction.class]) {
                editMenuInteraction = (UIEditMenuInteraction *)interaction;
                break;
            }
        }
        if (!editMenuInteraction) {
            return;
        }

        CGPoint cellPoint = [recognizer locationInView:cell];
        UIEditMenuConfiguration *configuration = [UIEditMenuConfiguration configurationWithIdentifier:nil sourcePoint:cellPoint];
        [editMenuInteraction presentEditMenuWithConfiguration:configuration];
    }
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
    self.shouldSuppressNextRecordEditMenu = NO;
    return YES;
}

- (void)deletePeriod:(UIButton *)sender
{
    NSInteger periodIndex = sender.tag;
    UIAlertController *deleteButtonAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete_period_?"] message:nil preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        NSIndexPath *deletedIndexPath = [self indexPathForOriginalIndex:periodIndex];
        if (deletedIndexPath) {
            TaskRecordTimelineCell *cell = (TaskRecordTimelineCell *)[self.collectionView cellForItemAtIndexPath:deletedIndexPath];
            [cell setShowsSelectionBorder:NO color:nil];
            [self.collectionView deselectItemAtIndexPath:deletedIndexPath animated:NO];
        }
        self.selectedPeriodIndex = NSNotFound;
        self.pendingDeletedPeriodIndex = periodIndex;
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
        weakSelf.selectedPeriodIndex = periodIndex;
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

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:TaskRecordTimelineCell.class forCellWithReuseIdentifier:kTaskRecordsTimelineCellIdentifier];

        UITapGestureRecognizer *backgroundTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(timelineBackgroundTapped:)];
        backgroundTapRecognizer.delegate = self;
        backgroundTapRecognizer.cancelsTouchesInView = NO;
        [_collectionView addGestureRecognizer:backgroundTapRecognizer];

        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showEditMenu:)];
        longPressRecognizer.minimumPressDuration = 0.25;
        [_collectionView addGestureRecognizer:longPressRecognizer];
    }
    return _collectionView;
}

@end
