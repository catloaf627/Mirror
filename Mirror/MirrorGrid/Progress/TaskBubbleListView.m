//
//  TaskBubbleListView.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import "TaskBubbleListView.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorSettings.h"
#import <Masonry/Masonry.h>

static CGFloat const kBubbleHorizontalInset = 12;
static CGFloat const kBubbleVerticalInset = 7;
static CGFloat const kBubbleHorizontalSpacing = 8;
static CGFloat const kBubbleVerticalSpacing = 8;
static CGFloat const kBubbleCornerRadius = 10;

@interface TaskBubbleListView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *data;
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *bubbleData;
@property (nonatomic, strong) NSMutableArray<UIButton *> *bubbleButtons;
@property (nonatomic, strong) MASConstraint *contentHeightConstraint;

@end

@implementation TaskBubbleListView

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data
{
    self = [super init];
    if (self) {
        self.data = data;
        self.bubbleData = [NSMutableArray new];
        self.bubbleButtons = [NSMutableArray new];
        self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        [self addSubview:self.scrollView];
        [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self);
        }];
        
        [self.scrollView addSubview:self.contentView];
        [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(self.scrollView);
            make.width.mas_equalTo(self.scrollView);
            self.contentHeightConstraint = make.height.mas_equalTo(0);
        }];
        
        [self rebuildBubbles];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutBubbleButtons];
}

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data
{
    self.data = data;
    [self rebuildBubbles];
    [self setNeedsLayout];
}

#pragma mark - Bubbles

- (void)rebuildBubbles
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.bubbleData removeAllObjects];
    [self.bubbleButtons removeAllObjects];
    
    for (MirrorReadModel *data in self.data) {
        for (MirrorRecordModel *record in data.records) {
            UIButton *bubbleButton = [self bubbleButtonWithRecord:record data:data];
            MirrorReadModel *bubbleData = [[MirrorReadModel alloc] initWithTask:data.taskModel records:[@[record] mutableCopy]];
            bubbleButton.tag = self.bubbleData.count;
            [self.bubbleData addObject:bubbleData];
            [self.bubbleButtons addObject:bubbleButton];
            [self.contentView addSubview:bubbleButton];
        }
    }
}

- (UIButton *)bubbleButtonWithRecord:(MirrorRecordModel *)record data:(MirrorReadModel *)data
{
    UIButton *bubbleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *text = [self bubbleTextWithRecord:record fallback:data.taskModel.taskName];
    [bubbleButton setTitle:text forState:UIControlStateNormal];
    [bubbleButton setTitleColor:[UIColor mirrorColorPulsed:data.taskModel.color] forState:UIControlStateNormal];
    bubbleButton.titleLabel.font = [UIFont mirrorTitleFont_Card];
    bubbleButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    bubbleButton.contentEdgeInsets = UIEdgeInsetsMake(kBubbleVerticalInset * kHeightRatio,
                                                      kBubbleHorizontalInset * kWidthRatio,
                                                      kBubbleVerticalInset * kHeightRatio,
                                                      kBubbleHorizontalInset * kWidthRatio);
    UIColor *taskColor = [UIColor mirrorColorNamed:data.taskModel.color];
    bubbleButton.backgroundColor = [taskColor colorWithAlphaComponent:[self bubbleAlphaWithRecord:record]];
    bubbleButton.layer.cornerRadius = kBubbleCornerRadius * kWidthRatio;
    bubbleButton.layer.masksToBounds = YES;
    [bubbleButton addTarget:self action:@selector(selectBubble:) forControlEvents:UIControlEventTouchUpInside];
    return bubbleButton;
}

- (NSString *)bubbleTextWithRecord:(MirrorRecordModel *)record fallback:(NSString *)fallback
{
    NSString *note = [record.note stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return note.length > 0 ? note : fallback;
}

- (CGFloat)bubbleAlphaWithRecord:(MirrorRecordModel *)record
{
    if (![MirrorSettings appliedHeatmap]) {
        return 1;
    }
    long duration = MAX(0, record.endTime - record.startTime);
    return MIN(1.0, 0.2 + floor(duration / 3600) * 0.1);
}

- (void)layoutBubbleButtons
{
    CGFloat availableWidth = CGRectGetWidth(self.scrollView.bounds);
    if (availableWidth <= 0) {
        return;
    }
    
    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat rowHeight = 0;
    CGFloat horizontalSpacing = kBubbleHorizontalSpacing * kWidthRatio;
    CGFloat verticalSpacing = kBubbleVerticalSpacing * kHeightRatio;
    CGFloat maxBubbleWidth = availableWidth;
    
    for (UIButton *bubbleButton in self.bubbleButtons) {
        CGSize fittingSize = [bubbleButton sizeThatFits:CGSizeMake(maxBubbleWidth, CGFLOAT_MAX)];
        CGFloat width = MIN(ceil(fittingSize.width), maxBubbleWidth);
        CGFloat height = ceil(fittingSize.height);
        
        if (x > 0 && x + width > availableWidth) {
            x = 0;
            y += rowHeight + verticalSpacing;
            rowHeight = 0;
        }
        
        bubbleButton.frame = CGRectMake(x, y, width, height);
        x += width + horizontalSpacing;
        rowHeight = MAX(rowHeight, height);
    }
    
    CGFloat contentHeight = self.bubbleButtons.count > 0 ? y + rowHeight : 0;
    self.scrollView.contentSize = CGSizeMake(availableWidth, contentHeight);
    [self.contentHeightConstraint setOffset:MAX(contentHeight, CGRectGetHeight(self.scrollView.bounds))];
}

- (void)selectBubble:(UIButton *)bubbleButton
{
    NSInteger index = bubbleButton.tag;
    if (index < 0 || index >= self.bubbleData.count) {
        return;
    }
    [self.delegate taskBubbleListView:self didSelectData:self.bubbleData[index]];
}

#pragma mark - Getters

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.alwaysBounceVertical = NO;
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
