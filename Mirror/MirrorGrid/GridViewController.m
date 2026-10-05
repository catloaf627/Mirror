//
//  GridViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/2.
//

#import "GridViewController.h"
#import <Masonry/Masonry.h>
#import "MirrorNaviManager.h"
#import "UIColor+MirrorColor.h"
#import "GridCollectionViewCell.h"
#import "MirrorMacro.h"
#import "MirrorLanguage.h"
#import "MirrorTaskModel.h"
#import "MirrorDayModel.h"
#import "MirrorStorage.h"
#import "MirrorSettings.h"
#import "LegendView.h"
#import "TaskProgressListView.h"
#import "TaskBubbleListView.h"
#import "TaskLineChartView.h"
#import "TaskPieChartView.h"
#import "TaskRecordsViewController.h"
#import "MirrorTimeText.h"
#import "MirrorTool.h"
#import "MirrorTabsManager.h"
#import "UIFont+MirrorFont.h"
#import "MirrorToast.h"
#import "UIImage+MirrorSymbol.h"

#define kLeftRightSpacing (20*kWidthRatio)
#define kCellWidth (25*kWidthRatio)
#define kCellSpacing (2.5*kWidthRatio)
#define kGapInLine (10*kHeightRatio)
#define kChartTopPadding (10*kHeightRatio)
#define kChartBottomPadding (10*kHeightRatio)

@interface GridFixedRowsLayout : UICollectionViewLayout

@end

@implementation GridFixedRowsLayout

- (CGSize)collectionViewContentSize
{
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    NSInteger columnCount = itemCount == 0 ? 0 : (itemCount + 6) / 7;
    CGFloat width = columnCount == 0 ? 0 : columnCount * kCellWidth + MAX(columnCount - 1, 0) * kCellSpacing;
    CGFloat height = 7 * kCellWidth + 6 * kCellSpacing;
    return CGSizeMake(width, height);
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    NSInteger column = indexPath.item / 7;
    NSInteger row = indexPath.item % 7;
    attributes.frame = CGRectMake(column * (kCellWidth + kCellSpacing),
                                  row * (kCellWidth + kCellSpacing),
                                  kCellWidth,
                                  kCellWidth);
    return attributes;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    if (itemCount == 0) {
        return @[];
    }

    NSInteger firstColumn = MAX((NSInteger)floor(CGRectGetMinX(rect) / (kCellWidth + kCellSpacing)) - 1, 0);
    NSInteger lastColumn = MIN((NSInteger)ceil(CGRectGetMaxX(rect) / (kCellWidth + kCellSpacing)) + 1, (itemCount + 6) / 7 - 1);
    NSMutableArray<UICollectionViewLayoutAttributes *> *attributes = [NSMutableArray new];
    for (NSInteger column = firstColumn; column <= lastColumn; column++) {
        for (NSInteger row = 0; row < 7; row++) {
            NSInteger item = column * 7 + row;
            if (item >= itemCount) {
                break;
            }
            [attributes addObject:[self layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0]]];
        }
    }
    return attributes;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

@end

@interface GridViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TaskProgressListDelegate, TaskBubbleListDelegate>

@property (nonatomic, assign) BOOL isLoaded;
// Navibar
@property (nonatomic, strong) UIButton *chartModeButton;
@property (nonatomic, strong) UIButton *heatmapButton;
@property (nonatomic, strong) UIButton *weekStartsOnButton;
@property (nonatomic, strong) UIView *gridOptionsView;
// Data source
@property (nonatomic, strong) NSMutableArray<NSString *> *keys;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableArray<MirrorReadModel *> *> *gridData;
@property (nonatomic, strong) NSMutableDictionary<NSString *, MirrorDayModel *> *specialDaysByDateKey;

@property (nonatomic, assign) NSInteger selectedCellIndex;
@property (nonatomic, assign) NSInteger selectedCellIndexesStart;
@property (nonatomic, assign) NSInteger selectedCellIndexesEnd;
@property (nonatomic, assign) BOOL hasInitializedSelectedCellIndex;
@property (nonatomic, assign) BOOL shouldUseChartRangeSelection;
// UI
///grid
@property (nonatomic, strong) UILabel *leftHint;
@property (nonatomic, strong) UILabel *rightHint;
@property (nonatomic, strong) UIView *weekdayView;
@property (nonatomic, strong) UICollectionView *collectionView;
///one day (single selection)
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) LegendView *legendView;
@property (nonatomic, strong) TaskProgressListView *taskProgressListView;
@property (nonatomic, strong) TaskBubbleListView *taskBubbleListView;
@property (nonatomic, strong) TaskLineChartView *taskLineChartView;
@property (nonatomic, strong) TaskPieChartView *piechartView;
@end

@implementation GridViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.shouldUseChartRangeSelection = YES;
        // 系统通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSignificantTimeChangeNotification object:nil];
        // 设置通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchWeekStartsOnNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchChartTypeRecordNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chartRangeChanged) name:MirrorSwitchChartRangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchShowShadeNotification object:nil];
        // 数据通知 (直接数据驱动UI，本地数据变动必然导致这里的UI变动)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskHiddenNotification object:nil];// 比其他vc多监听一个hidden通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStopNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskMergeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskChangeOrderNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorDayCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorDayDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorDayEditNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    _isLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.chartModeButton rightButton:self.gridOptionsView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Scroll to today.
    if (_selectedCellIndex < [self.collectionView numberOfItemsInSection:0]) { // safety
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_selectedCellIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
}

- (void)restartVC
{
    // 更新tabbar
    [[MirrorTabsManager sharedInstance] updateGridTabItemWithTabController:self.tabBarController];
    if (!_isLoaded) return;
    // 将vc.view里的所有subviews全部置为nil
    self.leftHint = nil;
    self.rightHint = nil;
    self.collectionView = nil;
    self.dateLabel = nil;
    self.weekdayView = nil;
    self.legendView = nil;
    self.taskProgressListView = nil;
    self.taskBubbleListView = nil;
    self.taskLineChartView = nil;
    self.piechartView = nil;
    self.chartModeButton = nil;
    self.heatmapButton = nil;
    self.weekStartsOnButton = nil;
    self.gridOptionsView = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 更新navibar
    if (self.tabBarController.selectedIndex == 2) {
        [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.chartModeButton rightButton:self.gridOptionsView];
    }
    [self p_setupUI];
}

- (void)reloadData
{
    if (!_isLoaded) return;
    [self updateChartModeButton];
    [self updateHeatmapButton];
    [self updateWeekStartsOnButton];
    [self updateChartVisibility];
    [self updateKeys];
    [self updateGridData];
    if (self.shouldUseChartRangeSelection) {
        [self syncSelectedCellsWithChartRangeIfNeeded];
    }
    [self updateCharts];
    [self.collectionView reloadData];
}

- (void)chartRangeChanged
{
    if (!_isLoaded) return;
    self.shouldUseChartRangeSelection = YES;
    [self syncSelectedCellsWithChartRangeIfNeeded];
    [self updateCharts];
    [self.collectionView reloadData];
}


- (void)p_setupUI
{
    // collection view
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.height.mas_equalTo(kCellWidth*7 + kCellSpacing*6);
    }];
    [self.view addSubview:self.dateLabel];
    [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.collectionView.mas_bottom).offset(kGapInLine);
        make.height.mas_equalTo(24*kHeightRatio);
    }];
    [self.view addSubview:self.legendView];
    [self.legendView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.dateLabel.mas_bottom).offset(kGapInLine);
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];
    [self.view addSubview:self.taskProgressListView];
    [self.taskProgressListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.legendView.mas_bottom).offset(kChartTopPadding);
        make.bottom.mas_equalTo(self.view).offset(-self.tabBarController.tabBar.frame.size.height - kChartBottomPadding);
    }];
    [self.view addSubview:self.taskBubbleListView];
    [self.taskBubbleListView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.legendView.mas_bottom).offset(kChartTopPadding);
        make.bottom.mas_equalTo(self.view).offset(-self.tabBarController.tabBar.frame.size.height - kChartBottomPadding);
    }];
    [self.view addSubview:self.taskLineChartView];
    [self.taskLineChartView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.legendView.mas_bottom).offset(kChartTopPadding);
        make.bottom.mas_equalTo(self.view).offset(-self.tabBarController.tabBar.frame.size.height - kChartBottomPadding);
    }];
    [self.view addSubview:self.piechartView];
    CGFloat chartAreaWidth = [[self leftWidthLeftHeight][0] floatValue];
    CGFloat chartAreaHeight = [[self leftWidthLeftHeight][1] floatValue];
    CGFloat width = MAX(0, MIN([TaskPieChartView maximumPieWidthForAvailableWidth:chartAreaWidth], chartAreaHeight - ([TaskPieChartView totalHeightForPieWidth:0])));
    CGFloat totalWidth = chartAreaWidth;
    CGFloat totalHeight = [TaskPieChartView totalHeightForPieWidth:width];
    [self.piechartView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.top.mas_equalTo(self.legendView.mas_bottom).offset(kChartTopPadding + (chartAreaHeight - totalHeight) / 2);
        make.width.mas_equalTo(totalWidth);
        make.height.mas_equalTo(totalHeight);
    }];
    [self updateChartVisibility];
    _selectedCellIndexesStart = -1;
    _selectedCellIndexesEnd = -1;
    if (self.shouldUseChartRangeSelection) {
        [self syncSelectedCellsWithChartRangeIfNeeded];
    }
    [self updateCharts];
}

#pragma mark - Actions

- (void)switchHeatmap
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [MirrorSettings switchHeatmap];
    NSString *toastKey = [MirrorSettings appliedHeatmap] ? @"grid_toast_heatmap_on" : @"grid_toast_heatmap_off";
    [self showGridOptionToastWithKey:toastKey];
}

- (void)switchWeekStartsOn
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [MirrorSettings switchWeekStartsOn];
    NSString *toastKey = [MirrorSettings appliedWeekStarsOnMonday] ? @"grid_toast_week_starts_monday" : @"grid_toast_week_starts_sunday";
    [self showGridOptionToastWithKey:toastKey];
}

- (void)switchChartMode
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [MirrorSettings switchGridChartMode];
}

- (void)showGridOptionToastWithKey:(NSString *)key
{
    [MirrorToast showWithText:[MirrorLanguage mirror_stringWithKey:key] inView:self.view];
}

- (void)updateChartModeButton
{
    MirrorGridChartMode chartMode = [MirrorSettings appliedGridChartMode];
    NSString *imageName = @"circle.grid.cross.up.filled";
    NSString *fallbackName = imageName;
    switch (chartMode) {
        case MirrorGridChartModeBubbles:
            imageName = @"capsule";
            fallbackName = @"circle.grid.cross.up.filled";
            break;
        case MirrorGridChartModeProgressList:
            imageName = @"list.bullet";
            fallbackName = @"circle.grid.cross.right.filled";
            break;
        case MirrorGridChartModePieChart:
            imageName = @"chart.pie";
            fallbackName = @"circle.grid.cross.down.filled";
            break;
        case MirrorGridChartModeLineChart:
            imageName = @"chart.xyaxis.line";
            fallbackName = @"circle.grid.cross.left.filled";
            break;
    }
    
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightRegular];
    UIImage *iconImage = [[UIImage mirror_systemImageNamed:imageName fallbackName:fallbackName configuration:configuration] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.chartModeButton setImage:iconImage forState:UIControlStateNormal];
    [self.chartModeButton setTitle:iconImage ? nil : [NSString stringWithFormat:@"%ld", (long)chartMode] forState:UIControlStateNormal];
    self.chartModeButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.chartModeButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight];
}

- (void)updateChartVisibility
{
    MirrorGridChartMode chartMode = [MirrorSettings appliedGridChartMode];
    self.taskProgressListView.hidden = chartMode != MirrorGridChartModeProgressList;
    self.taskBubbleListView.hidden = chartMode != MirrorGridChartModeBubbles;
    self.taskLineChartView.hidden = chartMode != MirrorGridChartModeLineChart;
    self.piechartView.hidden = chartMode != MirrorGridChartModePieChart;
}

- (void)updateHeatmapButton
{
    BOOL appliedHeatmap = [MirrorSettings appliedHeatmap];
    NSString *imageName = appliedHeatmap ? @"paintpalette" : @"paintpalette.fill";
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightRegular];
    UIImage *iconImage = [[UIImage mirror_systemImageNamed:imageName fallbackName:@"paintpalette" configuration:configuration] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.heatmapButton setImage:iconImage forState:UIControlStateNormal];
    [self.heatmapButton setTitle:iconImage ? nil : (appliedHeatmap ? @"ON" : @"OFF") forState:UIControlStateNormal];
    self.heatmapButton.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    self.heatmapButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight];
}

- (void)updateWeekStartsOnButton
{
    BOOL appliedWeekStarsOnMonday = [MirrorSettings appliedWeekStarsOnMonday];
    NSString *imageName = appliedWeekStarsOnMonday ? @"1.lane" : @"7.lane";
    UIImage *iconImage = [[UIImage mirror_systemImageNamed:imageName fallbackName:appliedWeekStarsOnMonday ? @"1" : @"7"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.weekStartsOnButton setImage:iconImage forState:UIControlStateNormal];
    [self.weekStartsOnButton setTitle:iconImage ? nil : (appliedWeekStarsOnMonday ? @"1" : @"7") forState:UIControlStateNormal];
    self.weekStartsOnButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    self.weekStartsOnButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight];
}

#pragma mark - update data

- (void)updateHints
{
    /*
     最左侧一列正着数，找到这一列最后一个有日子的cell，取出它的月份作为hint，例如下面七个cell：
     [4月29日]        循环到0，文案设置为"2023年4月"
     [4月30日]        循环到1，文案设置为"2023年4月"
     [5月1日]         循环到2，文案设置为"2023年5月"
     [5月2日]         循环到3，文案设置为"2023年5月"
     [5月3日]         循环到4，文案设置为"2023年5月"
     [cell不存在]           循环到5，跳过
     [cell不存在]           循环到6，跳过
     最后文案取为"2023年5月"
     */
    NSString *leftText = self.leftHint.text;
    NSIndexPath *leftSide0 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 0*(kCellWidth+kCellSpacing))]; // 左上角的cell indexpath
    if (leftSide0) leftText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[leftSide0.item]]];
    NSIndexPath *leftSide1 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 1*(kCellWidth+kCellSpacing))];
    if (leftSide1) leftText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[leftSide1.item]]];
    NSIndexPath *leftSide2 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 2*(kCellWidth+kCellSpacing))];
    if (leftSide2) leftText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[leftSide2.item]]];
    NSIndexPath *leftSide3 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 3*(kCellWidth+kCellSpacing))];
    if (leftSide3) leftText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[leftSide3.item]]];
    NSIndexPath *leftSide4 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 4*(kCellWidth+kCellSpacing))];
    if (leftSide4) leftText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[leftSide4.item]]];
    NSIndexPath *leftSide5 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 5*(kCellWidth+kCellSpacing))];
    if (leftSide5) leftText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[leftSide5.item]]];
    NSIndexPath *leftSide6 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 6*(kCellWidth+kCellSpacing))]; // 左下角的cell indexpath
    if (leftSide6) leftText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[leftSide6.item]]];
    if (![leftText isEqualToString:self.leftHint.text]) {
        self.leftHint.text = leftText;
    }
    

    
    /*
     最右侧一列正着数，找到这一列最后一个有日子的cell，取出它的月份作为hint，例如下面七个cell：
     [4月29日]        循环到0，文案设置为"2023年4月"
     [4月30日]        循环到1，文案设置为"2023年4月"
     [5月1日]         循环到2，文案设置为"2023年5月"
     [5月2日]         循环到3，文案设置为"2023年5月"
     [5月3日]         循环到4，文案设置为"2023年5月"
     [cell不存在]           循环到5，跳过
     [cell不存在]           循环到6，跳过
     最后文案取为"2023年5月"
     */
    NSString *rightText = self.rightHint.text;
    NSIndexPath *rightSide0 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 0*(kCellWidth+kCellSpacing))]; // 右上角的cell indexpath
    if (rightSide0) rightText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[rightSide0.item]]];
    NSIndexPath *rightSide1 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 1*(kCellWidth+kCellSpacing))];
    if (rightSide1) rightText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[rightSide1.item]]];
    NSIndexPath *rightSide2 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 2*(kCellWidth+kCellSpacing))];
    if (rightSide2) rightText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[rightSide2.item]]];
    NSIndexPath *rightSide3 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 3*(kCellWidth+kCellSpacing))];
    if (rightSide3) rightText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[rightSide3.item]]];
    NSIndexPath *rightSide4 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 4*(kCellWidth+kCellSpacing))];
    if (rightSide4) rightText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[rightSide4.item]]];
    NSIndexPath *rightSide5 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 5*(kCellWidth+kCellSpacing))];
    if (rightSide5) rightText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[rightSide5.item]]];
    NSIndexPath *rightSide6 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 6*(kCellWidth+kCellSpacing))]; // 右下角的cell indexpath
    if (rightSide6) rightText = [MirrorTimeText YYYYmm:[self dateFromKey:self.keys[rightSide6.item]]];
    if (![rightText isEqualToString:self.rightHint.text]) {
        self.rightHint.text = rightText;
    }
}

- (void)updateKeys
{
    NSDate *minDate = [self getMinDateForGrid];
    NSDate *maxDate = [self getMaxDateForGrid];
    _keys = [self getDateKeysFromMinDate:minDate maxDate:maxDate];
    NSInteger todayIndex = [_keys indexOfObject:[self keyFromDate:[NSDate now]]];
    if (!self.hasInitializedSelectedCellIndex && todayIndex != NSNotFound) {
        _selectedCellIndex = todayIndex;
        self.hasInitializedSelectedCellIndex = YES;
    }
}

- (void)updateGridData
{
    _gridData = [MirrorStorage getGridData];
    _specialDaysByDateKey = [NSMutableDictionary<NSString *, MirrorDayModel *> new];
    for (MirrorDayModel *day in [MirrorStorage retriveMirrorDays]) {
        if (day.dateStr.length > 0) {
            _specialDaysByDateKey[day.dateStr] = day;
        }
    }
}

- (NSMutableArray<MirrorReadModel *> *)gridDataForDateKey:(NSString *)dateKey
{
    return self.gridData[dateKey];
}

- (MirrorDayModel *)specialDayForDateKey:(NSString *)dateKey
{
    return self.specialDaysByDateKey[dateKey];
}

- (NSMutableArray<MirrorReadModel *> *)chartDataFromIndex:(NSInteger)startIndex toIndex:(NSInteger)endIndex shouldHideHidden:(BOOL)shouldHideHidden
{
    if (self.keys.count <= startIndex || self.keys.count <= endIndex) {
        return [NSMutableArray new];
    }
    
    long startTime = [[self dateFromKey:self.keys[startIndex]] timeIntervalSince1970];
    NSDate *endDate = [self dateFromKey:self.keys[endIndex]];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    long endTime = [[gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:endDate options:0] timeIntervalSince1970];
    return [MirrorStorage getAllRecordsInTaskOrderWithStart:startTime end:endTime shouldHideHidden:shouldHideHidden];
}

- (NSMutableArray<MirrorReadModel *> *)lineChartDataFromDateKeys:(NSArray<NSString *> *)dateKeys
{
    if (dateKeys.count == 0) {
        return [NSMutableArray new];
    }
    NSDate *startDate = [self dateFromKey:dateKeys.firstObject];
    NSDate *endDate = [self dateFromKey:dateKeys.lastObject];
    if (!startDate || !endDate) {
        return [NSMutableArray new];
    }
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    long startTime = [startDate timeIntervalSince1970];
    long endTime = [[gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:endDate options:0] timeIntervalSince1970];
    return [MirrorStorage getAllRecordsInTaskOrderWithStart:startTime end:endTime shouldHideHidden:YES];
}

- (NSArray<NSString *> *)lineChartDateKeysFromIndex:(NSInteger)startIndex toIndex:(NSInteger)endIndex
{
    if (self.keys.count == 0 || startIndex < 0 || endIndex < 0 || startIndex >= self.keys.count || endIndex >= self.keys.count) {
        return @[];
    }
    NSInteger start = MIN(startIndex, endIndex);
    NSInteger end = MAX(startIndex, endIndex);
    if (start == end) {
        NSDate *date = [self dateFromKey:self.keys[start]];
        if (!date) {
            return @[];
        }
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        gregorian.timeZone = [NSTimeZone systemTimeZone];
        NSDate *previousDate = [gregorian dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:date options:0];
        NSDate *nextDate = [gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:date options:0];
        return @[[self keyFromDate:previousDate], self.keys[start], [self keyFromDate:nextDate]];
    }
    return [self.keys subarrayWithRange:NSMakeRange(start, end - start + 1)];
}

- (NSArray<NSNumber *> *)chartRangeIndexes
{
    if (self.keys.count == 0) {
        return @[];
    }
    MirrorChartRange selectedChartRange = [MirrorSettings appliedChartRange];
    if (selectedChartRange == MirrorChartRangeAll) {
        return @[@0, @(self.keys.count - 1)];
    }

    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDate *endDate = [gregorian startOfDayForDate:[NSDate now]];
    NSDate *startDate = nil;
    switch (selectedChartRange) {
        case MirrorChartRangeOneWeek:
            startDate = [gregorian dateByAddingUnit:NSCalendarUnitDay value:-6 toDate:endDate options:0];
            break;
        case MirrorChartRangeOneMonth:
            startDate = [gregorian dateByAddingUnit:NSCalendarUnitMonth value:-1 toDate:endDate options:0];
            break;
        case MirrorChartRangeThreeMonths:
            startDate = [gregorian dateByAddingUnit:NSCalendarUnitMonth value:-3 toDate:endDate options:0];
            break;
        case MirrorChartRangeSixMonths:
            startDate = [gregorian dateByAddingUnit:NSCalendarUnitMonth value:-6 toDate:endDate options:0];
            break;
        case MirrorChartRangeYearToDate: {
            NSDateComponents *components = [gregorian components:NSCalendarUnitYear fromDate:endDate];
            components.month = 1;
            components.day = 1;
            startDate = [gregorian dateFromComponents:components];
            break;
        }
        case MirrorChartRangeOneYear:
            startDate = [gregorian dateByAddingUnit:NSCalendarUnitYear value:-1 toDate:endDate options:0];
            break;
        case MirrorChartRangeAll:
            startDate = [self dateFromKey:self.keys.firstObject];
            break;
    }

    NSInteger startIndex = [self firstDateKeyIndexOnOrAfterDate:startDate];
    NSInteger endIndex = [self lastDateKeyIndexOnOrBeforeDate:endDate];
    if (startIndex == NSNotFound || endIndex == NSNotFound || startIndex > endIndex) {
        NSInteger todayIndex = [self.keys indexOfObject:[self keyFromDate:endDate]];
        if (todayIndex == NSNotFound) {
            todayIndex = MIN(MAX(self.selectedCellIndex, 0), self.keys.count - 1);
        }
        return @[@(todayIndex), @(todayIndex)];
    }
    return @[@(startIndex), @(endIndex)];
}

- (NSInteger)firstDateKeyIndexOnOrAfterDate:(NSDate *)date
{
    if (!date) {
        return NSNotFound;
    }
    for (NSInteger index = 0; index < self.keys.count; index++) {
        NSDate *keyDate = [self dateFromKey:self.keys[index]];
        if (keyDate && [keyDate compare:date] != NSOrderedAscending) {
            return index;
        }
    }
    return NSNotFound;
}

- (NSInteger)lastDateKeyIndexOnOrBeforeDate:(NSDate *)date
{
    if (!date) {
        return NSNotFound;
    }
    for (NSInteger index = self.keys.count - 1; index >= 0; index--) {
        NSDate *keyDate = [self dateFromKey:self.keys[index]];
        if (keyDate && [keyDate compare:date] != NSOrderedDescending) {
            return index;
        }
    }
    return NSNotFound;
}

- (NSMutableArray<MirrorReadModel *> *)legendDataFromIndex:(NSInteger)startIndex toIndex:(NSInteger)endIndex
{
    NSMutableArray<MirrorReadModel *> *legendData = [NSMutableArray new];
    for (MirrorTaskModel *task in [MirrorStorage retriveMirrorTasks]) {
        MirrorReadModel *readModel = [[MirrorReadModel alloc] initWithTask:task records:[NSMutableArray new]];
        [legendData addObject:readModel];
    }
    return legendData;
}

- (void)updateCharts
{
    if (_selectedCellIndexesStart != -1 && _selectedCellIndexesEnd != -1) {
        [self updateChartsFromIndex:_selectedCellIndexesStart toIndex:_selectedCellIndexesEnd];
        return;
    } else {
        if (self.keys.count <= _selectedCellIndex) return; // 空数据保护
        [self updateChartsFromIndex:_selectedCellIndex toIndex:_selectedCellIndex];
    }
}

- (void)syncSelectedCellsWithChartRangeIfNeeded
{
    MirrorGridChartMode chartMode = [MirrorSettings appliedGridChartMode];
    if (chartMode != MirrorGridChartModePieChart && chartMode != MirrorGridChartModeLineChart) {
        return;
    }
    NSArray<NSNumber *> *chartIndexes = [self chartRangeIndexes];
    if (chartIndexes.count != 2) {
        return;
    }
    NSInteger start = chartIndexes.firstObject.integerValue;
    NSInteger end = chartIndexes.lastObject.integerValue;
    if (start < 0 || end < 0 || start >= self.keys.count || end >= self.keys.count) {
        return;
    }
    _selectedCellIndexesStart = start;
    _selectedCellIndexesEnd = end;
    _selectedCellIndex = end;
}

- (void)updateChartsFromIndex:(NSInteger)startIndex toIndex:(NSInteger)endIndex
{
    if (self.keys.count == 0 || startIndex < 0 || endIndex < 0) { // 空数据保护
        return;
    }
    if (startIndex >= self.keys.count) startIndex = self.keys.count - 1;
    if (endIndex >= self.keys.count) endIndex = self.keys.count - 1;
    if (_selectedCellIndexesStart != -1 && _selectedCellIndexesEnd != -1) {
        _selectedCellIndexesStart = startIndex;
        _selectedCellIndexesEnd = endIndex;
    }
    
    NSInteger start = startIndex < endIndex ? startIndex : endIndex;
    NSInteger end = startIndex > endIndex ? startIndex : endIndex;
    MirrorGridChartMode chartMode = [MirrorSettings appliedGridChartMode];
    NSMutableArray<MirrorReadModel *> *legendData = [self legendDataFromIndex:start toIndex:end];

    // legend
    [self.legendView updateWithData:legendData];
    [self.legendView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];

    if (chartMode == MirrorGridChartModeProgressList) {
        NSMutableArray<MirrorReadModel *> *data = [self chartDataFromIndex:start toIndex:end shouldHideHidden:YES];
        [self updateDateLabelWithData:data start:start end:end];
        [self.taskProgressListView updateWithData:data];
        return;
    }
    if (chartMode == MirrorGridChartModeBubbles) {
        NSMutableArray<MirrorReadModel *> *data = [self chartDataFromIndex:start toIndex:end shouldHideHidden:YES];
        [self updateDateLabelWithData:data start:start end:end];
        [self.taskBubbleListView updateWithData:data];
        return;
    }

    NSInteger chartStart = start;
    NSInteger chartEnd = end;
    if (self.shouldUseChartRangeSelection) {
        NSArray<NSNumber *> *chartIndexes = [self chartRangeIndexes];
        chartStart = chartIndexes.count == 2 ? chartIndexes.firstObject.integerValue : start;
        chartEnd = chartIndexes.count == 2 ? chartIndexes.lastObject.integerValue : end;
    }

    if (chartMode == MirrorGridChartModeLineChart) {
        NSArray<NSString *> *lineChartDateKeys = [self lineChartDateKeysFromIndex:chartStart toIndex:chartEnd];
        NSMutableArray<MirrorReadModel *> *lineChartData = [self lineChartDataFromDateKeys:lineChartDateKeys];
        [self updateDateLabelWithData:lineChartData start:chartStart end:chartEnd];
        [self.taskLineChartView setRangeSelectionActive:self.shouldUseChartRangeSelection];
        [self.taskLineChartView updateWithData:lineChartData dateKeys:lineChartDateKeys];
        return;
    }
    if (chartMode == MirrorGridChartModePieChart) {
        NSMutableArray<MirrorReadModel *> *rangedChartData = [self chartDataFromIndex:chartStart toIndex:chartEnd shouldHideHidden:YES];
        [self updateDateLabelWithData:rangedChartData start:chartStart end:chartEnd];
        CGFloat chartAreaWidth = [[self leftWidthLeftHeight][0] floatValue];
        CGFloat chartAreaHeight = [[self leftWidthLeftHeight][1] floatValue];
        CGFloat width = MAX(0, MIN([TaskPieChartView maximumPieWidthForAvailableWidth:chartAreaWidth], chartAreaHeight - ([TaskPieChartView totalHeightForPieWidth:0])));
        CGFloat totalWidth = chartAreaWidth;
        CGFloat totalHeight = [TaskPieChartView totalHeightForPieWidth:width];
        [self.piechartView setRangeSelectionActive:self.shouldUseChartRangeSelection];
        [self.piechartView updateWithData:rangedChartData width:width enableInteractive:YES];
        if (self.piechartView.superview) { //security
            [self.piechartView mas_updateConstraints:^(MASConstraintMaker *make) {
                make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
                make.top.mas_equalTo(self.legendView.mas_bottom).offset(kChartTopPadding + (chartAreaHeight - totalHeight) / 2);
                make.width.mas_equalTo(totalWidth);
                make.height.mas_equalTo(totalHeight);
            }];
        }
    }
}

- (void)updateDateLabelWithData:(NSMutableArray<MirrorReadModel *> *)data start:(NSInteger)start end:(NSInteger)end
{
    long totalTime = 0;
    for (MirrorReadModel *readModel in data) {
        totalTime += [MirrorTool getTotalTimeOfPeriods:readModel.records];
    }

    NSString *totalTimeText = totalTime > 0 ? [[@": " stringByAppendingString:[MirrorTimeText XdXhXmXsFull:totalTime]] copy] : @"";
    if (start == end) {
        self.dateLabel.text = [[MirrorTimeText YYYYmmddWeekday:[self dateFromKey:self.keys[start]]] stringByAppendingString:totalTimeText];
    } else {
        NSString *startDate = [MirrorTimeText YYYYmmdd:[self dateFromKey:self.keys[start]]];
        NSString *endDate = [MirrorTimeText YYYYmmdd:[self dateFromKey:self.keys[end]]];
        self.dateLabel.text = [[[startDate stringByAppendingString:@" - "] stringByAppendingString:endDate] stringByAppendingString:totalTimeText];
    }
}

- (void)updateMultiSelectStart:(NSInteger)newstart
{
    self.shouldUseChartRangeSelection = NO;
    _selectedCellIndexesStart = newstart;
}

- (void)updateMultiSelectEnd:(NSInteger)newend
{
    _selectedCellIndexesEnd = newend;
    [self updateCharts];
    [self.collectionView reloadData];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (CGFloat)weekdayViewWidth
{
    NSArray<NSString *> *weekdayKeys = @[
        @"monday",
        @"tuesday",
        @"wednesday",
        @"thursday",
        @"friday",
        @"saturday",
        @"sunday"
    ];
    UIFont *font = [UIFont mirrorHintFont];
    CGFloat maxWidth = 0;
    
    for (NSString *weekdayKey in weekdayKeys) {
        NSString *weekday = [MirrorLanguage mirror_stringWithKey:weekdayKey];
        CGFloat weekdayWidth = [weekday sizeWithAttributes:@{NSFontAttributeName: font}].width;
        maxWidth = MAX(maxWidth, weekdayWidth);
    }
    [self updateHints]; // if not add this line, hint will disappear due to the update of weekdayview size
    return ceil(maxWidth);
}

- (void)updateWeekdayView
{
    if (!_weekdayView) return;  //security
    [_weekdayView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    BOOL appliedWeekStarsOnMonday = [MirrorSettings appliedWeekStarsOnMonday];
    UIColor *textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    UILabel *day0 = [UILabel new];
    day0.textAlignment = NSTextAlignmentRight;
    day0.text = appliedWeekStarsOnMonday ? [MirrorLanguage mirror_stringWithKey:@"monday"] : [MirrorLanguage mirror_stringWithKey:@"sunday"];
    day0.textColor = textColor;
    day0.font = [UIFont mirrorHintFont];
    [_weekdayView addSubview:day0];
    [day0 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.offset(0);
        make.height.mas_equalTo(kCellWidth);
    }];
    UILabel *day1 = [UILabel new];
    day1.textAlignment = NSTextAlignmentRight;
    day1.text = appliedWeekStarsOnMonday ? [MirrorLanguage mirror_stringWithKey:@"tuesday"] : [MirrorLanguage mirror_stringWithKey:@"monday"];
    day1.textColor = textColor;
    day1.font = [UIFont mirrorHintFont];
    [_weekdayView addSubview:day1];
    [day1 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.mas_equalTo(day0.mas_bottom).offset(kCellSpacing);
        make.height.mas_equalTo(kCellWidth);
    }];
    UILabel *day2 = [UILabel new];
    day2.textAlignment = NSTextAlignmentRight;
    day2.text = appliedWeekStarsOnMonday ? [MirrorLanguage mirror_stringWithKey:@"wednesday"] : [MirrorLanguage mirror_stringWithKey:@"tuesday"];
    day2.textColor = textColor;
    day2.font = [UIFont mirrorHintFont];
    [_weekdayView addSubview:day2];
    [day2 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.mas_equalTo(day1.mas_bottom).offset(kCellSpacing);
        make.height.mas_equalTo(kCellWidth);
    }];
    UILabel *day3 = [UILabel new];
    day3.textAlignment = NSTextAlignmentRight;
    day3.text = appliedWeekStarsOnMonday ? [MirrorLanguage mirror_stringWithKey:@"thursday"] : [MirrorLanguage mirror_stringWithKey:@"wednesday"];
    day3.textColor = textColor;
    day3.font = [UIFont mirrorHintFont];
    [_weekdayView addSubview:day3];
    [day3 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.mas_equalTo(day2.mas_bottom).offset(kCellSpacing);
        make.height.mas_equalTo(kCellWidth);
    }];
    UILabel *day4 = [UILabel new];
    day4.textAlignment = NSTextAlignmentRight;
    day4.text = appliedWeekStarsOnMonday ? [MirrorLanguage mirror_stringWithKey:@"friday"] : [MirrorLanguage mirror_stringWithKey:@"thursday"];
    day4.textColor = textColor;
    day4.font = [UIFont mirrorHintFont];
    [_weekdayView addSubview:day4];
    [day4 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.mas_equalTo(day3.mas_bottom).offset(kCellSpacing);
        make.height.mas_equalTo(kCellWidth);
    }];
    UILabel *day5 = [UILabel new];
    day5.textAlignment = NSTextAlignmentRight;
    day5.text = appliedWeekStarsOnMonday ? [MirrorLanguage mirror_stringWithKey:@"saturday"] : [MirrorLanguage mirror_stringWithKey:@"friday"];
    day5.textColor = textColor;
    day5.font = [UIFont mirrorHintFont];
    [_weekdayView addSubview:day5];
    [day5 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.mas_equalTo(day4.mas_bottom).offset(kCellSpacing);
        make.height.mas_equalTo(kCellWidth);
    }];
    UILabel *day6 = [UILabel new];
    day6.textAlignment = NSTextAlignmentRight;
    day6.text = appliedWeekStarsOnMonday ? [MirrorLanguage mirror_stringWithKey:@"sunday"] : [MirrorLanguage mirror_stringWithKey:@"saturday"];
    day6.textColor = textColor;
    day6.font = [UIFont mirrorHintFont];
    [_weekdayView addSubview:day6];
    [day6 mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.top.mas_equalTo(day5.mas_bottom).offset(kCellSpacing);
        make.height.mas_equalTo(kCellWidth);
    }];
}


#pragma mark - Collection view delegate

- (void)taskProgressListView:(TaskProgressListView *)taskProgressListView didSelectData:(MirrorReadModel *)data
{
    [self openTaskRecordsWithData:data];
}

- (void)taskBubbleListView:(TaskBubbleListView *)taskBubbleListView didSelectData:(MirrorReadModel *)data
{
    [self openTaskRecordsWithData:data];
}

- (void)openTaskRecordsWithData:(MirrorReadModel *)data
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage getAllTaskRecords:data.taskModel.taskName];
    MirrorReadModel *allData = [[MirrorReadModel alloc] initWithTask:data.taskModel records:allRecords];
    TaskRecordsViewController *recordsVC = [[TaskRecordsViewController alloc] initWithData:allData highlightedRecords:data.records];
    [self.navigationController pushViewController:recordsVC animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    self.shouldUseChartRangeSelection = NO;
    _selectedCellIndexesStart = -1;
    _selectedCellIndexesEnd = -1;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    _selectedCellIndex = indexPath.item; // 选择
    [self updateCharts];
    [collectionView reloadData];
    [self showSpecialDayToastIfNeededAtIndex:indexPath.item];
}

- (void)showSpecialDayToastIfNeededAtIndex:(NSInteger)index
{
    if (index < 0 || index >= self.keys.count) {
        return;
    }
    MirrorDayModel *day = [self specialDayForDateKey:self.keys[index]];
    if (day.icon.length == 0 || day.info.length == 0) {
        return;
    }
    [MirrorToast showWithText:day.info inView:self.view];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return  self.keys.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    GridCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[GridCollectionViewCell identifier] forIndexPath:indexPath];
    if (_selectedCellIndexesStart == -1 || _selectedCellIndexesEnd == -1) { // single select
        NSString *dateKey = self.keys[indexPath.item];
        [cell configWithData:[self gridDataForDateKey:dateKey] day:[self specialDayForDateKey:dateKey] isSelected:indexPath.item==_selectedCellIndex];
    } else { // multi select
        NSInteger start = _selectedCellIndexesStart < _selectedCellIndexesEnd ? _selectedCellIndexesStart : _selectedCellIndexesEnd;
        NSInteger end = _selectedCellIndexesStart > _selectedCellIndexesEnd ? _selectedCellIndexesStart : _selectedCellIndexesEnd;
        NSString *dateKey = self.keys[indexPath.item];
        [cell configWithData:[self gridDataForDateKey:dateKey] day:[self specialDayForDateKey:dateKey] isSelected:(indexPath.item<=end && indexPath.item>=start)];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kCellWidth, kCellWidth);
}

#pragma mark - Actions

- (void)longPress:(UILongPressGestureRecognizer *)longPress
{
    NSIndexPath *indexPath = [_collectionView indexPathForItemAtPoint:[longPress locationInView:_collectionView]];
    if (indexPath.length == 0) return; // 触点在缝里(spacing)不算
    
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self updateMultiSelectStart:indexPath.item];
        [self updateMultiSelectEnd:indexPath.item];
    }
    if (longPress.state == UIGestureRecognizerStateChanged && _selectedCellIndexesEnd != indexPath.item && indexPath.length != 0) {
        [self updateMultiSelectEnd:indexPath.item];
    }
    if (longPress.state == UIGestureRecognizerStateEnded) {
        [self updateMultiSelectEnd:indexPath.item];
    }
}

#pragma mark - Getters

- (LegendView *)legendView
{
    if (!_legendView) {
        _legendView = [[LegendView alloc] initWithData:[NSMutableArray new]];
    }
    return _legendView;
}

- (TaskProgressListView *)taskProgressListView
{
    if (!_taskProgressListView) {
        _taskProgressListView = [[TaskProgressListView alloc] initWithData:[NSMutableArray new]];
        _taskProgressListView.delegate = self;
    }
    return _taskProgressListView;
}

- (TaskBubbleListView *)taskBubbleListView
{
    if (!_taskBubbleListView) {
        _taskBubbleListView = [[TaskBubbleListView alloc] initWithData:[NSMutableArray new]];
        _taskBubbleListView.delegate = self;
    }
    return _taskBubbleListView;
}

- (TaskLineChartView *)taskLineChartView
{
    if (!_taskLineChartView) {
        _taskLineChartView = [[TaskLineChartView alloc] initWithData:[NSMutableArray new] dateKeys:@[]];
    }
    return _taskLineChartView;
}

- (TaskPieChartView *)piechartView
{
    if (!_piechartView) {
        _piechartView = [[TaskPieChartView alloc] initWithData:[NSMutableArray new] width:0 enableInteractive:NO];
        _piechartView.textFontScale = 1.25;
        _piechartView.delegate = self.legendView;
    }
    return _piechartView;
}

- (UILabel *)leftHint
{
    if (!_leftHint) {
        _leftHint = [UILabel new];
        _leftHint.textAlignment = NSTextAlignmentLeft;
        _leftHint.font = [UIFont mirrorLabelFont];
        _leftHint.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    }
    return _leftHint;
}

- (UILabel *)rightHint
{
    if (!_rightHint) {
        _rightHint = [UILabel new];
        _rightHint.textAlignment = NSTextAlignmentRight;
        _rightHint.font = [UIFont mirrorLabelFont];
        _rightHint.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    }
    return _rightHint;
}

- (UILabel *)dateLabel
{
    if (!_dateLabel) {
        _dateLabel = [UILabel new];
        _dateLabel.textAlignment = NSTextAlignmentCenter;
        _dateLabel.font = [UIFont mirrorHighlightFont];
        _dateLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _dateLabel.adjustsFontSizeToFitWidth = YES;
        _dateLabel.minimumScaleFactor = 0.7;
    }
    return _dateLabel;
}

- (UIView *)weekdayView
{
    if (!_weekdayView) {
        _weekdayView = [UIView new];
        [self updateWeekdayView];
    }
    return _weekdayView;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        GridFixedRowsLayout *layout = [GridFixedRowsLayout new];
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.view.backgroundColor;
//        _collectionView.allowsMultipleSelection = YES;
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        longPress.minimumPressDuration = 0.25;
        longPress.allowableMovement = 12;
        [_collectionView addGestureRecognizer:longPress];
        [_collectionView registerClass:[GridCollectionViewCell class] forCellWithReuseIdentifier:[GridCollectionViewCell identifier]];
    }
    return _collectionView;
}

- (UIButton *)heatmapButton
{
    if (!_heatmapButton) {
        _heatmapButton = [UIButton new];
        [_heatmapButton addTarget:self action:@selector(switchHeatmap) forControlEvents:UIControlEventTouchUpInside];
        [self updateHeatmapButton];
    }
    return _heatmapButton;
}

- (UIButton *)chartModeButton
{
    if (!_chartModeButton) {
        _chartModeButton = [UIButton new];
        [_chartModeButton addTarget:self action:@selector(switchChartMode) forControlEvents:UIControlEventTouchUpInside];
        [self updateChartModeButton];
    }
    return _chartModeButton;
}

- (UIButton *)weekStartsOnButton
{
    if (!_weekStartsOnButton) {
        _weekStartsOnButton = [UIButton new];
        [_weekStartsOnButton addTarget:self action:@selector(switchWeekStartsOn) forControlEvents:UIControlEventTouchUpInside];
        [self updateWeekStartsOnButton];
    }
    return _weekStartsOnButton;
}

- (UIView *)gridOptionsView
{
    if (!_gridOptionsView) {
        CGFloat itemSize = self.navigationController.navigationBar.frame.size.height;
        _gridOptionsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, itemSize * 2, itemSize)];
        [_gridOptionsView addSubview:self.weekStartsOnButton];
        [self.weekStartsOnButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.mas_equalTo(_gridOptionsView);
            make.width.mas_equalTo(itemSize);
        }];
        [_gridOptionsView addSubview:self.heatmapButton];
        [self.heatmapButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.top.bottom.mas_equalTo(_gridOptionsView);
            make.width.mas_equalTo(itemSize);
        }];
    }
    return _gridOptionsView;
}

- (NSMutableArray<NSString *> *)keys
{
    if (!_keys) {
        _keys = [NSMutableArray<NSString *> new];
        [self updateKeys];
    }
    return _keys;
}

- (NSMutableDictionary<NSString *, NSMutableArray<MirrorReadModel *> *> *)gridData
{
    if (!_gridData) {
        _gridData = [NSMutableDictionary<NSString *, NSMutableArray<MirrorReadModel *> *> new];
        [self updateGridData];
    }
    return _gridData;
}

- (NSMutableDictionary<NSString *, MirrorDayModel *> *)specialDaysByDateKey
{
    if (!_specialDaysByDateKey) {
        [self updateGridData];
    }
    return _specialDaysByDateKey;
}

#pragma mark - Helpers

// 获取 grid 展示范围的最小日期：取第一条记录开始时间和今天中更早的日期，再返回它所在周的第一天
- (NSDate *)getMinDateForGrid
{
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage retriveMirrorRecords];
    NSDate *today = [NSDate now];
    NSDate *realFirstDate = today;
    for (MirrorRecordModel *record in allRecords) {
        if (record.endTime > record.startTime) {
            NSDate *firstRecordDate = [NSDate dateWithTimeIntervalSince1970:record.startTime];
            realFirstDate = [firstRecordDate compare:today] == NSOrderedAscending ? firstRecordDate : today;
            break;
        }
    }
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDateComponents *components = [gregorian components:NSCalendarUnitWeekday fromDate:realFirstDate];
    
    NSInteger numOfInvalidCell = 0;
    if ([MirrorSettings appliedWeekStarsOnMonday]) {
        if (components.weekday > 1) {
            numOfInvalidCell = components.weekday - 2;
        } else {
            numOfInvalidCell = 6;
        }
    } else {
        numOfInvalidCell = components.weekday - 1;
    }
    
    return [gregorian dateByAddingUnit:NSCalendarUnitDay value:-numOfInvalidCell toDate:realFirstDate options:0];
}

// 获取 grid 展示范围的最大日期：取最后一条记录实际覆盖到的日期和今天中更晚的日期
- (NSDate *)getMaxDateForGrid
{
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage retriveMirrorRecords];
    MirrorRecordModel *lastValidRecord = nil;
    for (MirrorRecordModel *record in allRecords.reverseObjectEnumerator) {
        if (record.endTime > record.startTime) {
            lastValidRecord = record;
            break;
        }
    }
    
    if (!lastValidRecord) {
        return [NSDate now];
    }
    
    NSDate *lastRecordEndDate = [NSDate dateWithTimeIntervalSince1970:lastValidRecord.endTime];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDateComponents *endComponents = [gregorian components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:lastRecordEndDate];
    BOOL isEndAtZeroClock = endComponents.hour == 0 && endComponents.minute == 0 && endComponents.second == 0;
    NSDate *lastRecordDate = isEndAtZeroClock ? [gregorian dateByAddingUnit:NSCalendarUnitDay value:-1 toDate:lastRecordEndDate options:0] : lastRecordEndDate; // 最后一条record结束与11月8日0点的话，那么最后一天其实是11月7日。
    NSDate *today = [NSDate now];
    return [lastRecordDate compare:today] == NSOrderedDescending ? lastRecordDate : today;
}

// 根据最小日期和最大日期生成 grid 使用的日期字符串数组，格式如 2026-08-12，包含起止日期
- (NSMutableArray<NSString *> *)getDateKeysFromMinDate:(NSDate *)minDate maxDate:(NSDate *)maxDate
{
    NSMutableArray<NSString *> *dateKeys = [NSMutableArray<NSString *> new];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDate *currentDate = [gregorian startOfDayForDate:minDate]; // 00:00:00
    NSDate *endDate = [gregorian startOfDayForDate:maxDate]; // 00:00:00
    while ([currentDate compare:endDate] != NSOrderedDescending) {
        NSString *dateKey = [self keyFromDate:currentDate];
//        NSLog(@"grid date: %@", dateKey);
        [dateKeys addObject:dateKey];
        currentDate = [gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:currentDate options:0];
    }
    return dateKeys;
}

- (NSString *)keyFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:date];
}

- (NSDate *)dateFromKey:(NSString *)dateKey
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter dateFromString:dateKey];
}

- (NSArray *)leftWidthLeftHeight
{
    CGFloat navi = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    CGFloat grid_plusGapBelow = (kCellWidth*7 + kCellSpacing*6) + kGapInLine;
    CGFloat dataLabel_plusGapBelow = 24*kHeightRatio + kGapInLine;
    CGFloat legend_plusGapBelow = [self.legendView legendViewHeight] + kChartTopPadding;
    CGFloat tabbar_plusGapAbove = self.tabBarController.tabBar.frame.size.height + kChartBottomPadding;
    
    CGFloat leftHeight = kScreenHeight - navi - grid_plusGapBelow - dataLabel_plusGapBelow - legend_plusGapBelow - tabbar_plusGapAbove;
    CGFloat leftWidth = kScreenWidth - 2*kLeftRightSpacing;
    return @[@(leftWidth), @(leftHeight)];
}



@end
