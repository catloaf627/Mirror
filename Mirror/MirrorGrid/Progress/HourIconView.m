//
//  HourIconView.m
//  Mirror
//
//  Created by Yuqing Wang on 2026/9/27.
//

#import "HourIconView.h"

static NSInteger const kHourIconSquareCount = 9;
static NSInteger const kHourIconColumnCount = 3;
static CGFloat const kHourIconDefaultSize = 21;
static CGFloat const kHourIconSquareSpacing = 2;

@interface HourIconView ()

@property (nonatomic, strong) NSMutableArray<UIView *> *squareViews;
@property (nonatomic, assign) NSInteger filledSquareCount;
@property (nonatomic, assign) MirrorColorType color;

@end

@implementation HourIconView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.squareViews = [NSMutableArray new];
        self.color = MirrorColorTypeCellGray;
        [self setupSquares];
        [self updateSquareColors];
    }
    return self;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(kHourIconDefaultSize, kHourIconDefaultSize);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat side = MIN(CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));
    CGFloat squareSide = floor((side - (kHourIconColumnCount - 1) * kHourIconSquareSpacing) / kHourIconColumnCount);
    CGFloat contentSide = squareSide * kHourIconColumnCount + (kHourIconColumnCount - 1) * kHourIconSquareSpacing;
    CGFloat originX = (CGRectGetWidth(self.bounds) - contentSide) / 2;
    CGFloat originY = (CGRectGetHeight(self.bounds) - contentSide) / 2;
    
    for (NSInteger index = 0; index < self.squareViews.count; index++) {
        NSInteger row = index / kHourIconColumnCount;
        NSInteger column = index % kHourIconColumnCount;
        UIView *squareView = self.squareViews[index];
        squareView.frame = CGRectMake(originX + column * (squareSide + kHourIconSquareSpacing),
                                      originY + row * (squareSide + kHourIconSquareSpacing),
                                      squareSide,
                                      squareSide);
        squareView.layer.cornerRadius = MAX(1, squareSide * 0.25);
    }
}

- (void)updateWithHours:(CGFloat)hours color:(MirrorColorType)color
{
    self.color = color;
    self.filledSquareCount = MIN(kHourIconSquareCount, MAX(0, (NSInteger)ceil(hours)));
    [self updateSquareColors];
}

#pragma mark - Private

- (void)setupSquares
{
    for (NSInteger index = 0; index < kHourIconSquareCount; index++) {
        UIView *squareView = [UIView new];
        squareView.layer.masksToBounds = YES;
        [self.squareViews addObject:squareView];
        [self addSubview:squareView];
    }
}

- (void)updateSquareColors
{
    UIColor *filledColor = [[UIColor mirrorColorNamed:self.color] colorWithAlphaComponent:1.0];
    UIColor *emptyColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    for (NSInteger index = 0; index < self.squareViews.count; index++) {
        UIView *squareView = self.squareViews[index];
        squareView.backgroundColor = index < self.filledSquareCount ? filledColor : emptyColor;
    }
}

@end
