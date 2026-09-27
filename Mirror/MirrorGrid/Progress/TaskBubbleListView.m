//
//  TaskBubbleListView.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import "TaskBubbleListView.h"
#import "HourIconView.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import <Masonry/Masonry.h>

static CGFloat const kBubbleHorizontalInset = 12;
static CGFloat const kBubbleVerticalInset = 7;
static CGFloat const kBubbleHorizontalSpacing = 8;
static CGFloat const kBubbleVerticalSpacing = 8;
static CGFloat const kBubbleCornerRadius = 10;
static CGFloat const kHourIconSize = 21;
static CGFloat const kHourIconTextSpacing = 6;
static CGFloat const kMoreTagTextSpacing = 8;
static CGFloat const kMoreTagHorizontalInset = 7;
static NSInteger const kHourIconViewTag = 1001;
static NSInteger const kMoreTagViewTag = 1002;

@interface TaskBubbleListView ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *data;
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *bubbleData;
@property (nonatomic, strong) NSMutableSet<NSString *> *expandedTaskNames;
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
        self.expandedTaskNames = [NSMutableSet new];
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
    [self.expandedTaskNames removeAllObjects];
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
        BOOL isExpanded = [self.expandedTaskNames containsObject:data.taskModel.taskName];
        NSInteger visibleRecordCount = isExpanded ? data.records.count : MIN(data.records.count, 1);
        for (NSInteger recordIndex = 0; recordIndex < visibleRecordCount; recordIndex++) {
            MirrorRecordModel *record = data.records[recordIndex];
            BOOL showsMoreTag = !isExpanded && data.records.count > 1 && recordIndex == 0;
            UIButton *bubbleButton = [self bubbleButtonWithRecord:record data:data showsMoreTag:showsMoreTag];
            MirrorReadModel *bubbleData = [[MirrorReadModel alloc] initWithTask:data.taskModel records:[@[record] mutableCopy]];
            NSInteger bubbleIndex = self.bubbleData.count;
            bubbleButton.tag = bubbleIndex;
            [self.bubbleData addObject:bubbleData];
            [self.bubbleButtons addObject:bubbleButton];
            [self.contentView addSubview:bubbleButton];
        }
    }
}

- (UIButton *)bubbleButtonWithRecord:(MirrorRecordModel *)record data:(MirrorReadModel *)data showsMoreTag:(BOOL)showsMoreTag
{
    UIButton *bubbleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *text = [self bubbleTextWithRecord:record fallback:data.taskModel.taskName];
    [bubbleButton setTitle:text forState:UIControlStateNormal];
    [bubbleButton setTitleColor:[UIColor mirrorColorPulsed:data.taskModel.color] forState:UIControlStateNormal];
    bubbleButton.titleLabel.font = [UIFont mirrorTitleFont_Card];
    bubbleButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    CGFloat iconAndSpacingWidth = (kHourIconSize + kHourIconTextSpacing) * kWidthRatio;
    NSString *moreTagText = showsMoreTag ? [self moreTagTextWithRecordCount:data.records.count] : @"";
    CGFloat moreTagWidth = [self moreTagWidthWithText:moreTagText];
    CGFloat moreTagReservedWidth = moreTagText.length > 0 ? moreTagWidth + kMoreTagTextSpacing * kWidthRatio : 0;
    bubbleButton.contentEdgeInsets = UIEdgeInsetsMake(kBubbleVerticalInset * kHeightRatio,
                                                      kBubbleHorizontalInset * kWidthRatio + iconAndSpacingWidth,
                                                      kBubbleVerticalInset * kHeightRatio,
                                                      kBubbleHorizontalInset * kWidthRatio + moreTagReservedWidth);
    HourIconView *hourIconView = [[HourIconView alloc] initWithFrame:CGRectZero];
    hourIconView.tag = kHourIconViewTag;
    [hourIconView updateWithHours:[self hoursWithRecord:record] color:data.taskModel.color];
    [bubbleButton addSubview:hourIconView];
    if (moreTagText.length > 0) {
        UIButton *moreTagButton = [self moreTagButtonWithText:moreTagText color:data.taskModel.color];
        [bubbleButton addSubview:moreTagButton];
    }
    bubbleButton.backgroundColor = [[UIColor mirrorColorNamed:data.taskModel.color] colorWithAlphaComponent:0.2];
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

- (CGFloat)hoursWithRecord:(MirrorRecordModel *)record
{
    long duration = MAX(0, record.endTime - record.startTime);
    return duration / 3600.0;
}

- (NSString *)moreTagTextWithRecordCount:(NSInteger)recordCount
{
    NSInteger hiddenRecordCount = recordCount - 1;
    return hiddenRecordCount > 0 ? [NSString stringWithFormat:@"+%ld", (long)hiddenRecordCount] : @"";
}

- (CGFloat)moreTagWidthWithText:(NSString *)text
{
    if (text.length == 0) {
        return 0;
    }
    UIFont *font = [UIFont mirrorHintFont];
    CGFloat textWidth = ceil([text sizeWithAttributes:@{NSFontAttributeName: font}].width);
    return textWidth + 2 * kMoreTagHorizontalInset * kWidthRatio;
}

- (UIButton *)moreTagButtonWithText:(NSString *)text color:(MirrorColorType)color
{
    UIButton *moreTagButton = [UIButton buttonWithType:UIButtonTypeCustom];
    moreTagButton.tag = kMoreTagViewTag;
    [moreTagButton setTitle:text forState:UIControlStateNormal];
    [moreTagButton setTitleColor:[UIColor mirrorColorPulsed:color] forState:UIControlStateNormal];
    moreTagButton.titleLabel.font = [UIFont mirrorHintFont];
    moreTagButton.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    moreTagButton.layer.cornerRadius = kBubbleCornerRadius * kWidthRatio;
    moreTagButton.layer.masksToBounds = YES;
    [moreTagButton addTarget:self action:@selector(selectMoreTag:) forControlEvents:UIControlEventTouchUpInside];
    return moreTagButton;
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
        CGFloat minHeight = kHourIconSize * kWidthRatio + 2 * kBubbleVerticalInset * kHeightRatio;
        CGFloat width = MIN(ceil(fittingSize.width), maxBubbleWidth);
        CGFloat height = MAX(ceil(fittingSize.height), ceil(minHeight));
        
        if (x > 0 && x + width > availableWidth) {
            x = 0;
            y += rowHeight + verticalSpacing;
            rowHeight = 0;
        }
        
        bubbleButton.frame = CGRectMake(x, y, width, height);
        HourIconView *hourIconView = (HourIconView *)[bubbleButton viewWithTag:kHourIconViewTag];
        CGFloat iconSize = kHourIconSize * kWidthRatio;
        hourIconView.frame = CGRectMake(kBubbleHorizontalInset * kWidthRatio,
                                        (height - iconSize) / 2,
                                        iconSize,
                                        iconSize);
        UIButton *moreTagButton = (UIButton *)[bubbleButton viewWithTag:kMoreTagViewTag];
        if (moreTagButton) {
            CGFloat moreTagWidth = [self moreTagWidthWithText:[moreTagButton titleForState:UIControlStateNormal]];
            CGFloat moreTagHeight = height - 2 * kBubbleVerticalInset * kHeightRatio;
            moreTagButton.frame = CGRectMake(width - kBubbleHorizontalInset * kWidthRatio - moreTagWidth,
                                             (height - moreTagHeight) / 2,
                                             moreTagWidth,
                                             moreTagHeight);
        }
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

- (void)selectMoreTag:(UIButton *)moreTagButton
{
    NSInteger index = moreTagButton.superview.tag;
    if (index < 0 || index >= self.bubbleData.count) {
        return;
    }
    MirrorReadModel *data = self.bubbleData[index];
    [self.expandedTaskNames addObject:data.taskModel.taskName];
    [self rebuildBubbles];
    [self setNeedsLayout];
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
