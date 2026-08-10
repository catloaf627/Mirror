//
//  TaskProgressListView.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import "TaskProgressListView.h"
#import "MirrorTool.h"
#import "MirrorTimeText.h"
#import "MirrorMacro.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import <Masonry/Masonry.h>

static CGFloat const kRowHeight = 34;
static CGFloat const kRowSpacing = 6;
static CGFloat const kBarHeight = 6;
static CGFloat const kDotSize = 8;

@interface TaskProgressListView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSMutableArray<MirrorDataModel *> *data;

@end

@implementation TaskProgressListView

- (instancetype)initWithData:(NSMutableArray<MirrorDataModel *> *)data
{
    self = [super init];
    if (self) {
        self.data = data;
        self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        [self addSubview:self.scrollView];
        [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self);
        }];
        
        [self.scrollView addSubview:self.contentView];
        [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self.scrollView);
            make.width.mas_equalTo(self.scrollView);
        }];
        
        [self rebuildRows];
    }
    return self;
}

- (void)updateWithData:(NSMutableArray<MirrorDataModel *> *)data
{
    self.data = data;
    [self rebuildRows];
}

#pragma mark - Rows

- (void)rebuildRows
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIView *previousRow = nil;
    long maxTime = [self maxTotalTime];
    for (NSInteger index = 0; index < self.data.count; index++) {
        MirrorDataModel *data = self.data[index];
        UIView *row = [self rowWithData:data index:index maxTime:maxTime];
        [self.contentView addSubview:row];
        [row mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(self.contentView);
            make.height.mas_equalTo(kRowHeight * kHeightRatio);
            if (previousRow) {
                make.top.mas_equalTo(previousRow.mas_bottom).offset(kRowSpacing * kHeightRatio);
            } else {
                make.top.mas_equalTo(self.contentView).offset(kRowSpacing * kHeightRatio);
            }
        }];
        previousRow = row;
    }
    
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.scrollView);
        make.width.mas_equalTo(self.scrollView);
        if (previousRow) {
            make.bottom.mas_equalTo(previousRow.mas_bottom).offset(kRowSpacing * kHeightRatio);
        } else {
            make.bottom.mas_equalTo(self.contentView.mas_top);
        }
    }];
}

- (UIView *)rowWithData:(MirrorDataModel *)data index:(NSInteger)index maxTime:(long)maxTime
{
    UIView *row = [UIView new];
    row.tag = index;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectRow:)];
    [row addGestureRecognizer:tapRecognizer];
    
    UIColor *taskColor = [UIColor mirrorColorNamed:data.taskModel.color];
    UIColor *pulseColor = [UIColor mirrorColorNamed:[UIColor mirror_getPulseColorType:data.taskModel.color]];
    long totalTime = [MirrorTool getTotalTimeOfPeriods:data.records];
    CGFloat percentage = maxTime > 0 ? totalTime / (CGFloat)maxTime : 0;
    
    UIView *dot = [UIView new];
    dot.backgroundColor = taskColor;
    dot.layer.cornerRadius = kDotSize / 2;
    [row addSubview:dot];
    [dot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(row);
        make.centerY.mas_equalTo(row);
        make.width.height.mas_equalTo(kDotSize);
    }];
    
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = data.taskModel.taskName;
    titleLabel.textColor = pulseColor;
    titleLabel.font = [UIFont mirrorTitleFont_Card];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    [row addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(dot.mas_right).offset(8 * kWidthRatio);
        make.centerY.mas_equalTo(row);
        make.width.mas_equalTo(60 * kWidthRatio);
        make.height.mas_equalTo(22 * kHeightRatio);
    }];
    
    UILabel *timeLabel = [UILabel new];
    timeLabel.text = [MirrorTimeText XdXhXmXsShort:totalTime];
    timeLabel.textColor = pulseColor;
    timeLabel.font = [UIFont mirrorHintFont];
    timeLabel.textAlignment = NSTextAlignmentRight;
    timeLabel.adjustsFontSizeToFitWidth = YES;
    [row addSubview:timeLabel];
    [timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(row);
        make.centerY.mas_equalTo(row);
        make.width.mas_equalTo(60 * kWidthRatio);
        make.height.mas_equalTo(22 * kHeightRatio);
    }];
    
    UIView *barTrack = [UIView new];
    barTrack.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    barTrack.layer.cornerRadius = kBarHeight / 2;
    barTrack.layer.masksToBounds = YES;
    [row addSubview:barTrack];
    [barTrack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(titleLabel.mas_right).offset(8 * kWidthRatio);
        make.right.mas_equalTo(timeLabel.mas_left).offset(-8 * kWidthRatio);
        make.centerY.mas_equalTo(row);
        make.height.mas_equalTo(kBarHeight);
    }];
    
    UIView *bar = [UIView new];
    bar.backgroundColor = taskColor;
    bar.layer.cornerRadius = kBarHeight / 2;
    bar.layer.masksToBounds = YES;
    [barTrack addSubview:bar];
    [bar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.mas_equalTo(barTrack);
        make.width.mas_equalTo(barTrack.mas_width).multipliedBy(percentage);
    }];
    
    return row;
}

- (long)maxTotalTime
{
    long maxTime = 0;
    for (MirrorDataModel *data in self.data) {
        maxTime = MAX(maxTime, [MirrorTool getTotalTimeOfPeriods:data.records]);
    }
    return maxTime;
}

- (void)selectRow:(UITapGestureRecognizer *)recognizer
{
    NSInteger index = recognizer.view.tag;
    if (index < 0 || index >= self.data.count) {
        return;
    }
    [self.delegate taskProgressListView:self didSelectData:self.data[index]];
}

#pragma mark - Getters

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
    }
    return _scrollView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

@end
