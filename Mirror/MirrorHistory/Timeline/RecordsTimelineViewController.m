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
#import "MirrorMacro.h"

static CGFloat const kHorizontalPadding = 20;
static CGFloat const kTimelineX = 28;
static CGFloat const kDotSize = 10;
static CGFloat const kRowMinHeight = 72;
static CGFloat const kTextLeftPadding = 18;

@interface RecordsTimelineViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) MirrorDataModel *data;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *highlightedRecords;
@property (nonatomic, weak) UIView *firstHighlightedRow;

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:self.data.taskModel.taskName leftButton:nil rightButton:nil];
}

- (void)restartVC
{
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:self.data.taskModel.taskName leftButton:nil rightButton:nil];
    self.scrollView = nil;
    self.contentView = nil;
    self.firstHighlightedRow = nil;
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self p_setupUI];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
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
    UIView *previousRow = nil;
    self.firstHighlightedRow = nil;
    NSMutableArray<MirrorRecordModel *> *records = [[self.data.records sortedArrayUsingComparator:^NSComparisonResult(MirrorRecordModel *record0, MirrorRecordModel *record1) {
        if (record0.startTime < record1.startTime) return NSOrderedAscending;
        if (record0.startTime > record1.startTime) return NSOrderedDescending;
        return NSOrderedSame;
    }] mutableCopy];
    
    for (NSInteger index = 0; index < records.count; index++) {
        BOOL isHighlighted = [self shouldHighlightRecord:records[index]];
        UIView *row = [self timelineRowWithRecord:records[index] isFirst:index == 0 isLast:index == records.count - 1 isHighlighted:isHighlighted];
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
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (previousRow) {
            make.bottom.mas_equalTo(previousRow.mas_bottom).offset(20 * kHeightRatio);
        } else {
            make.bottom.mas_equalTo(self.contentView.mas_top);
        }
    }];
    
    if (self.firstHighlightedRow) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self scrollToFirstHighlightedRow];
        });
    }
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
    [self.view layoutIfNeeded];
    CGRect rowRect = [self.firstHighlightedRow.superview convertRect:self.firstHighlightedRow.frame toView:self.scrollView];
    CGFloat targetY = MAX(rowRect.origin.y - 16 * kHeightRatio, 0);
    CGFloat maxY = MAX(self.scrollView.contentSize.height - CGRectGetHeight(self.scrollView.bounds), 0);
    [self.scrollView setContentOffset:CGPointMake(0, MIN(targetY, maxY)) animated:NO];
}

- (UIView *)timelineRowWithRecord:(MirrorRecordModel *)record isFirst:(BOOL)isFirst isLast:(BOOL)isLast isHighlighted:(BOOL)isHighlighted
{
    UIView *row = [UIView new];
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:record.taskName];
    UIColor *pulseColor = [UIColor mirrorColorNamed:[UIColor mirror_getPulseColorType:task.color]];
    UIColor *taskColor = [UIColor mirrorColorNamed:task.color];
    row.backgroundColor = isHighlighted ? [pulseColor colorWithAlphaComponent:0.12] : [UIColor clearColor];
    row.layer.cornerRadius = 8;
    
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
    timeLabel.text = [NSString stringWithFormat:@"%@ - %@", [MirrorTool timeFromTimestamp:record.startTime printTimeStamp:NO], [MirrorTool timeFromTimestamp:record.endTime printTimeStamp:NO]];
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

#pragma mark - Getters

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
        _scrollView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _scrollView.alwaysBounceVertical = YES;
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
