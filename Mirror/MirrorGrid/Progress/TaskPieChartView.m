//
//  TaskPieChartView.m
//  Mirror
//

#import "TaskPieChartView.h"
#import "MirrorMacro.h"
#import "MirrorSettings.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import <Masonry/Masonry.h>

static CGFloat const kTaskPieChartRangeControlHeight = 30;
static CGFloat const kTaskPieChartRangeControlSpacing = 6;

@interface TaskPieChartView ()

@property (nonatomic, strong) UISegmentedControl *rangeSegmentedControl;
@property (nonatomic, strong) PiechartView *piechartView;
@property (nonatomic, strong) MASConstraint *pieWidthConstraint;
@property (nonatomic, strong) MASConstraint *pieHeightConstraint;
@property (nonatomic, assign) CGFloat pieWidth;
@property (nonatomic, assign) BOOL rangeSelectionActive;

@end

@implementation TaskPieChartView

+ (CGFloat)maximumPieWidthForAvailableWidth:(CGFloat)availableWidth
{
    return availableWidth;
}

+ (CGFloat)totalHeightForPieWidth:(CGFloat)pieWidth
{
    return kTaskPieChartRangeControlHeight*kHeightRatio + kTaskPieChartRangeControlSpacing*kHeightRatio + pieWidth;
}

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data width:(CGFloat)width enableInteractive:(BOOL)enableInteractive
{
    self = [super init];
    if (self) {
        self.pieWidth = width;
        self.textFontScale = 1.0;
        _rangeSelectionActive = YES;
        [self addSubview:self.rangeSegmentedControl];
        [self.rangeSegmentedControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.mas_equalTo(self);
            make.height.mas_equalTo(kTaskPieChartRangeControlHeight*kHeightRatio);
        }];

        _piechartView = [[PiechartView alloc] initWithData:data width:width enableInteractive:enableInteractive];
        _piechartView.textFontScale = self.textFontScale;
        [self addSubview:_piechartView];
        [_piechartView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.rangeSegmentedControl.mas_bottom).offset(kTaskPieChartRangeControlSpacing*kHeightRatio);
            make.centerX.mas_equalTo(self);
            self.pieWidthConstraint = make.width.mas_equalTo(width);
            self.pieHeightConstraint = make.height.mas_equalTo(width);
        }];
    }
    return self;
}

- (void)setDelegate:(UIView<PiechartDelegate> *)delegate
{
    _delegate = delegate;
    self.piechartView.delegate = delegate;
}

- (void)setTextFontScale:(CGFloat)textFontScale
{
    _textFontScale = textFontScale;
    self.piechartView.textFontScale = textFontScale;
}

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data width:(CGFloat)width enableInteractive:(BOOL)enableInteractive
{
    self.pieWidth = width;
    [self updateRangeSegmentSelection];
    [self.pieWidthConstraint setOffset:width];
    [self.pieHeightConstraint setOffset:width];
    [self.piechartView updateWithData:data width:width enableInteractive:enableInteractive];
}

- (void)setRangeSelectionActive:(BOOL)active
{
    _rangeSelectionActive = active;
    [self updateRangeSegmentSelection];
}

- (void)chartRangeChanged:(UISegmentedControl *)sender
{
    _rangeSelectionActive = YES;
    [MirrorSettings saveChartRange:(MirrorChartRange)sender.selectedSegmentIndex];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (void)updateRangeSegmentSelection
{
    self.rangeSegmentedControl.selectedSegmentIndex = self.rangeSelectionActive ? [MirrorSettings appliedChartRange] : UISegmentedControlNoSegment;
}

#pragma mark - Getters

- (UISegmentedControl *)rangeSegmentedControl
{
    if (!_rangeSegmentedControl) {
        _rangeSegmentedControl = [[UISegmentedControl alloc] initWithItems:[MirrorSettings chartRangeTitles]];
        _rangeSegmentedControl.selectedSegmentIndex = [MirrorSettings appliedChartRange];
        if (@available(iOS 13.0, *)) {
            _rangeSegmentedControl.selectedSegmentTintColor = [[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight] colorWithAlphaComponent:0.14];
        }
        [_rangeSegmentedControl setTitleTextAttributes:@{
            NSFontAttributeName: [UIFont mirrorHintFont],
            NSForegroundColorAttributeName: [UIColor mirrorColorNamed:MirrorColorTypeTextHint]
        } forState:UIControlStateNormal];
        [_rangeSegmentedControl setTitleTextAttributes:@{
            NSFontAttributeName: [UIFont mirrorHintFont],
            NSForegroundColorAttributeName: [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight]
        } forState:UIControlStateSelected];
        [_rangeSegmentedControl addTarget:self action:@selector(chartRangeChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _rangeSegmentedControl;
}

@end
