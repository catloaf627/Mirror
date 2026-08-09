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
#import "MirrorStorage.h"
#import "MirrorSettings.h"
#import "LegendView.h"
#import "HistogramView.h"
#import "PiechartView.h"
#import "LinechartView.h"
#import "MirrorTimeText.h"
#import "MirrorTool.h"
#import "MirrorTabsManager.h"
#import "SettingsViewController.h"
#import "LeftAnimation.h"
#import "HiddenViewController.h"
#import "HiddenAnimation.h"
#import "UIFont+MirrorFont.h"

#define kLeftRightSpacing (20*kWidthRatio)
#define kCellWidth (25*kWidthRatio)
#define kCellSpacing (2.5*kWidthRatio)
#define kGapInLine (10*kHeightRatio)
@interface GridViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate, PushAllRecordsDelegate>

@property (nonatomic, assign) BOOL isLoaded;
// Navibar
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactiveTransition;
@property (nonatomic, strong) UIButton *typeButton;
// Data source
@property (nonatomic, strong) NSMutableArray<NSString *> *keys;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSMutableArray<MirrorDataModel *> *> *gridData;
@property (nonatomic, assign) NSInteger startTimestamp;

@property (nonatomic, assign) NSInteger selectedCellIndex;
@property (nonatomic, assign) NSInteger selectedCellIndexesStart;
@property (nonatomic, assign) NSInteger selectedCellIndexesEnd;
// UI
///grid
@property (nonatomic, strong) UILabel *leftHint;
@property (nonatomic, strong) UILabel *rightHint;
@property (nonatomic, strong) UIView *weekdayView;
@property (nonatomic, strong) UICollectionView *collectionView;
///one day (single selection)
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) LegendView *legendView;
@property (nonatomic, strong) HistogramView *histogramView;
@property (nonatomic, strong) PiechartView *piechartView;
///several days (multiple selection)
@property (nonatomic, strong) LinechartView *linechartView;

@end

@implementation GridViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 系统通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSignificantTimeChangeNotification object:nil];
        // 设置通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchWeekStartsOnNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchChartTypeRecordNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchShowShadeNotification object:nil];
        // 数据通知 (直接数据驱动UI，本地数据变动必然导致这里的UI变动)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskHiddenNotification object:nil];// 比其他vc多监听一个hidden通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStopNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskChangeOrderNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:self.typeButton];
    // scroll to today
    if (_selectedCellIndex < [self.collectionView numberOfItemsInSection:0]) { // safty
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_selectedCellIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    }
    [self updateHints];
}

- (void)restartVC
{
    // 更新tabbar
    [[MirrorTabsManager sharedInstance] updateGridTabItemWithTabController:self.tabBarController];
    if (!_isLoaded) return;
    // 将vc.view里的所有subviews全部置为nil
    self.typeButton = nil;
    self.leftHint = nil;
    self.rightHint = nil;
    self.collectionView = nil;
    self.dateLabel = nil;
    self.weekdayView = nil;
    self.legendView = nil;
    self.histogramView = nil;
    self.piechartView = nil;
    self.linechartView = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 更新navibar
    if (self.tabBarController.selectedIndex == 2) {
        [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:self.typeButton];
    }
    [self p_setupUI];
}

- (void)reloadData
{
    if (!_isLoaded) return;
    if ([MirrorSettings appliedPieChartRecord]) {
        self.piechartView.hidden = NO;
        self.histogramView.hidden = YES;
    } else {
        self.histogramView.hidden = NO;
        self.piechartView.hidden = YES;
    }
    [self updateWeekdayView];
    [self updateKeys];
    [self updateGridData];
    [self updateCharts];
    [self.collectionView reloadData];
    [self updateLinechart];
}


- (void)p_setupUI
{
    // collection view
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.leftHint];
    [self.leftHint mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing+kCellWidth+2);
        make.width.mas_equalTo((kScreenWidth-2*kLeftRightSpacing-kCellWidth-2)/2);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.height.mas_equalTo(kCellWidth);
    }];
    [self.view addSubview:self.rightHint];
    [self.rightHint mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.width.mas_equalTo((kScreenWidth-2*kLeftRightSpacing-kCellWidth-2)/2);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.height.mas_equalTo(kCellWidth);
    }];
    [self.view addSubview:self.weekdayView];
    [self.weekdayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.top.mas_equalTo(self.rightHint.mas_bottom);
        make.height.mas_equalTo(kCellWidth*7 + kCellSpacing*6);
        make.width.mas_equalTo([self weekdayViewWidth]);
    }];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.weekdayView.mas_right).offset(kCellSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.rightHint.mas_bottom);
        make.height.mas_equalTo(kCellWidth*7 + kCellSpacing*6);
    }];
    [self.view addSubview:self.dateLabel];
    [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.collectionView.mas_bottom).offset(kGapInLine);
        make.height.mas_equalTo(20*kHeightRatio);
    }];
    [self.view addSubview:self.legendView];
    [self.legendView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.dateLabel.mas_bottom).offset(kGapInLine);
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];
    [self.view addSubview:self.histogramView];
    [self.histogramView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine);
        make.bottom.mas_equalTo(self.view).offset(-self.tabBarController.tabBar.frame.size.height - kGapInLine);
    }];
    self.histogramView.hidden = [MirrorSettings appliedPieChartRecord];
    [self.view addSubview:self.piechartView];
    CGFloat width = MIN([[self leftWidthLeftHeight][0] floatValue], [[self leftWidthLeftHeight][1] floatValue]);
    [self.piechartView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (width == [[self leftWidthLeftHeight][0] floatValue]) { // 宽度小于高度
            make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine + ([[self leftWidthLeftHeight][1] floatValue]-[[self leftWidthLeftHeight][0] floatValue])/2);
            make.centerX.offset(0);
            make.width.height.mas_equalTo(width);
        } else {
            make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine);
            make.centerX.offset(0);
            make.width.height.mas_equalTo(width);
        }
    }];
    self.piechartView.hidden = ![MirrorSettings appliedPieChartRecord];
    [self.view addSubview:self.linechartView];
    [self.linechartView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kLeftRightSpacing);
        make.right.mas_equalTo(self.view).offset(-kLeftRightSpacing);
        make.top.mas_equalTo(self.dateLabel.mas_bottom).offset(kGapInLine);
        make.bottom.mas_equalTo(self.view).offset(-self.tabBarController.tabBar.frame.size.height - kGapInLine);
    }];
    self.linechartView.hidden = YES;
    _selectedCellIndexesStart = -1;
    _selectedCellIndexesEnd = -1;
    UIScreenEdgePanGestureRecognizer *edgeRecognizer = [UIScreenEdgePanGestureRecognizer new];
    edgeRecognizer.edges = UIRectEdgeLeft;
    [edgeRecognizer addTarget:self action:@selector(edgeGestureRecognizerAction:)];
    [self.view addGestureRecognizer:edgeRecognizer];
    
    [self updateCharts];
}

#pragma mark - Actions

- (void)goToSettings
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    SettingsViewController * settingsVC = [[SettingsViewController alloc] init];
    settingsVC.transitioningDelegate = self;
    settingsVC.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:settingsVC animated:YES completion:nil];
}

- (void)goToHiddenVC
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    HiddenViewController *hiddenVC = [HiddenViewController new];
    hiddenVC.showShadeButton = YES;
    hiddenVC.transitioningDelegate = self;
    hiddenVC.modalPresentationStyle = UIModalPresentationCustom;
    hiddenVC.buttonFrame = [self.typeButton convertRect:self.typeButton.bounds toView:[[[UIApplication sharedApplication] delegate] window]];
    [self presentViewController:hiddenVC animated:YES completion:nil];
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
    if (leftSide0) leftText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[leftSide0.item] integerValue]]];
    NSIndexPath *leftSide1 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 1*(kCellWidth+kCellSpacing))];
    if (leftSide1) leftText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[leftSide1.item] integerValue]]];
    NSIndexPath *leftSide2 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 2*(kCellWidth+kCellSpacing))];
    if (leftSide2) leftText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[leftSide2.item] integerValue]]];
    NSIndexPath *leftSide3 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 3*(kCellWidth+kCellSpacing))];
    if (leftSide3) leftText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[leftSide3.item] integerValue]]];
    NSIndexPath *leftSide4 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 4*(kCellWidth+kCellSpacing))];
    if (leftSide4) leftText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[leftSide4.item] integerValue]]];
    NSIndexPath *leftSide5 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 5*(kCellWidth+kCellSpacing))];
    if (leftSide5) leftText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[leftSide5.item] integerValue]]];
    NSIndexPath *leftSide6 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.contentOffset.x + kCellWidth/2, kCellWidth/2 + 6*(kCellWidth+kCellSpacing))]; // 左下角的cell indexpath
    if (leftSide6) leftText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[leftSide6.item] integerValue]]];
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
    if (rightSide0) rightText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[rightSide0.item] integerValue]]];
    NSIndexPath *rightSide1 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 1*(kCellWidth+kCellSpacing))];
    if (rightSide1) rightText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[rightSide1.item] integerValue]]];
    NSIndexPath *rightSide2 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 2*(kCellWidth+kCellSpacing))];
    if (rightSide2) rightText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[rightSide2.item] integerValue]]];
    NSIndexPath *rightSide3 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 3*(kCellWidth+kCellSpacing))];
    if (rightSide3) rightText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[rightSide3.item] integerValue]]];
    NSIndexPath *rightSide4 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 4*(kCellWidth+kCellSpacing))];
    if (rightSide4) rightText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[rightSide4.item] integerValue]]];
    NSIndexPath *rightSide5 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 5*(kCellWidth+kCellSpacing))];
    if (rightSide5) rightText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[rightSide5.item] integerValue]]];
    NSIndexPath *rightSide6 = [self.collectionView indexPathForItemAtPoint:CGPointMake(self.collectionView.frame.size.width + self.collectionView.contentOffset.x - kCellWidth/2, kCellWidth/2 + 6*(kCellWidth+kCellSpacing))]; // 右下角的cell indexpath
    if (rightSide6) rightText = [MirrorTimeText YYYYmm:[NSDate dateWithTimeIntervalSince1970:[self.keys[rightSide6.item] integerValue]]];
    if (![rightText isEqualToString:self.rightHint.text]) {
        self.rightHint.text = rightText;
    }
}

- (void)updateKeys
{
    _keys = [NSMutableArray<NSString *> new];
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage retriveMirrorRecords];
    NSInteger minTimestamp = NSIntegerMax;
    NSInteger maxTimestamp = NSIntegerMin;
    for (int i=0; i<allRecords.count; i++) {
        MirrorRecordModel *record = allRecords[i];
            NSInteger timestamp = record.startTime;
            if (record.endTime != 0 && timestamp < minTimestamp) {
                minTimestamp = timestamp;
            }
            if (record.endTime != 0 && timestamp > maxTimestamp) {
                maxTimestamp = timestamp;
            }
    }
    // 2023.5.1 3:00 到 2023.5.3 19:00 算三天
    if (maxTimestamp != NSIntegerMin && minTimestamp != NSIntegerMax) { // 有 有效数据
        if (maxTimestamp < [[NSDate now] timeIntervalSince1970]) {
            maxTimestamp = [[NSDate now] timeIntervalSince1970]; // 如果现存最晚任务也在今天之前，设置最大时间为今天。
        }
        NSDate *minDate = [NSDate dateWithTimeIntervalSince1970:minTimestamp];
        NSDate *maxDate = [NSDate dateWithTimeIntervalSince1970:maxTimestamp];
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        gregorian.timeZone = [NSTimeZone systemTimeZone];
        NSDateComponents *minComponents = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:minDate];
        minComponents.timeZone = [NSTimeZone systemTimeZone];
        NSDateComponents *maxComponents = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:maxDate];
        maxComponents.timeZone = [NSTimeZone systemTimeZone];
        
        minComponents.hour = 0;
        minComponents.minute = 0;
        minComponents.second = 0;
        maxComponents.hour = 0;
        maxComponents.minute = 0;
        maxComponents.second = 0;
        
        minDate = [gregorian dateFromComponents:minComponents];// 2023.5.1 00:00
        maxDate = [gregorian dateFromComponents:maxComponents]; // 2023.5.3 00:00
        NSInteger dateNum = [gregorian components:NSCalendarUnitDay fromDate:minDate toDate:maxDate options:0].day + 1;
        
        
        NSInteger numOfInvalidCell = 0;
        if ([MirrorSettings appliedWeekStarsOnMonday]) {
            if (minComponents.weekday > 1) {
                numOfInvalidCell = minComponents.weekday - 2;
            } else {
                numOfInvalidCell = 6;
            }
        } else {
            numOfInvalidCell = minComponents.weekday - 1;
        }
        NSDate *startDate = [gregorian dateByAddingUnit:NSCalendarUnitDay value:-numOfInvalidCell toDate:minDate options:0];
        _startTimestamp = [startDate timeIntervalSince1970]; // 第一个cell(可能是invalid的)
        // 今天的0点
        NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
        components.timeZone = [NSTimeZone systemTimeZone];
        components.hour = 0;
        components.minute = 0;
        components.second = 0;
        long timestamp = [[gregorian dateFromComponents:components] timeIntervalSince1970]; // 今天的timestamp
        _selectedCellIndex = 0;
        
        // 添加前面的补位的日期
        for (int i=0; i<numOfInvalidCell; i++) {
            NSDate *invalidDate = [gregorian dateByAddingUnit:NSCalendarUnitDay value:-(numOfInvalidCell-i) toDate:minDate options:0];
            NSInteger invalidDateTimestamp = [invalidDate timeIntervalSince1970];
            [_keys addObject:[@(invalidDateTimestamp) stringValue]];
        }
        // 添加第一个record和最后一个record之间的日期
        for (int i=0; i<dateNum; i++) {
            NSDate *validDate = [gregorian dateByAddingUnit:NSCalendarUnitDay value:i toDate:minDate options:0];
            NSInteger validDateTimestamp = [validDate timeIntervalSince1970];
            [_keys addObject:[@(validDateTimestamp) stringValue]];
        }
        NSString *todayKey = [@(timestamp) stringValue];
        NSInteger todayIndex = [_keys indexOfObject:todayKey];
        if (todayIndex != NSNotFound) {
            _selectedCellIndex = todayIndex;
        }
    }
}

- (void)updateGridData
{
    _gridData = [MirrorStorage getGridData];
}

- (void)updateCharts // legend & histogram & piechart
{
    if (self.keys.count <= _selectedCellIndex) { // 空数据保护
        return;
    }
    // data source
    NSMutableArray<MirrorDataModel *> *data = self.gridData[self.keys[_selectedCellIndex]];
    // date label
    GridCollectionViewCell *cell = (GridCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:_selectedCellIndex inSection:0]];
    if (cell) { // 从did selected调用
        self.dateLabel.text = [[[MirrorTimeText YYYYmmddWeekday:[NSDate dateWithTimeIntervalSince1970:[self.keys[_selectedCellIndex] integerValue]]] stringByAppendingString:@". "] stringByAppendingString:[MirrorTimeText XdXhXmXsFull:cell.totalTime]];
    } else { // 从setup ui调用
        long totalTime = 0;
        for (int i=0; i<data.count; i++) {
            totalTime = totalTime + [MirrorTool getTotalTimeOfPeriods:data[i].records];
        }
        self.dateLabel.text = [[[MirrorTimeText YYYYmmddWeekday:[NSDate dateWithTimeIntervalSince1970:[self.keys[_selectedCellIndex] integerValue]]] stringByAppendingString:@". "] stringByAppendingString:[MirrorTimeText XdXhXmXsFull:totalTime]];
    }

    // legend
    [self.legendView updateWithData:data];
    [self.legendView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo([self.legendView legendViewHeight]);
    }];
    // histogram
    [self.histogramView updateWithData:data];
    CGFloat width = MIN([[self leftWidthLeftHeight][0] floatValue], [[self leftWidthLeftHeight][1] floatValue]);
    [self.piechartView updateWithData:data width:width enableInteractive:YES];
    // piechart
    if (self.piechartView.superview) { //security
        [self.piechartView mas_updateConstraints:^(MASConstraintMaker *make) {
            if (width == [[self leftWidthLeftHeight][0] floatValue]) { // 宽度小于高度
                make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine + ([[self leftWidthLeftHeight][1] floatValue]-[[self leftWidthLeftHeight][0] floatValue])/2);
                make.width.height.mas_equalTo(width);
            } else {
                make.top.mas_equalTo(self.legendView.mas_bottom).offset(kGapInLine);
                make.width.height.mas_equalTo(width);
            }
        }];
    }
}

- (void)updateMultiSelectStart:(NSInteger)newstart
{
    _selectedCellIndexesStart = newstart;
}

- (void)updateMultiSelectEnd:(NSInteger)newend
{
    _selectedCellIndexesEnd = newend;
    [self updateLinechart];
    [self.collectionView reloadData];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (void)updateLinechart // linechart
{
    if (_selectedCellIndexesStart==-1 || _selectedCellIndexesEnd==-1) { // 空数据保护
        return;
    }
    NSInteger start = _selectedCellIndexesStart < _selectedCellIndexesEnd ? _selectedCellIndexesStart : _selectedCellIndexesEnd;
    NSInteger end = _selectedCellIndexesStart > _selectedCellIndexesEnd ? _selectedCellIndexesStart : _selectedCellIndexesEnd;
    NSString *startDate = [MirrorTimeText YYYYmmdd:[NSDate dateWithTimeIntervalSince1970:[[[[NSNumberFormatter alloc] init] numberFromString:self.keys[start]] doubleValue]]];
    NSString *endDate = [MirrorTimeText YYYYmmdd:[NSDate dateWithTimeIntervalSince1970:[[[[NSNumberFormatter alloc] init] numberFromString:self.keys[end]] doubleValue]]];
    self.dateLabel.text = [[startDate stringByAppendingString:@" - "] stringByAppendingString:endDate];
    // data source
    NSMutableArray<NSMutableArray<MirrorDataModel *> *> *dataArr = [NSMutableArray new];
    for (NSInteger i=start; i<=end; i++) {
        NSMutableArray<MirrorDataModel *> *data = self.gridData[self.keys[i]];
        if (data == nil) {
            data = [NSMutableArray new];
        }
        [dataArr addObject:data];
    }
    self.linechartView.hidden = NO;
    [self.linechartView refactorData:dataArr];
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

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self updateHints];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedCellIndexesStart = -1;
    _selectedCellIndexesEnd = -1;
    self.linechartView.hidden = YES;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    _selectedCellIndex = indexPath.item; // 选择
    [self updateCharts];
    [collectionView reloadData];
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
        [cell configWithData:self.gridData[self.keys[indexPath.item]] isSelected:indexPath.item==_selectedCellIndex];
    } else { // multi select
        NSInteger start = _selectedCellIndexesStart < _selectedCellIndexesEnd ? _selectedCellIndexesStart : _selectedCellIndexesEnd;
        NSInteger end = _selectedCellIndexesStart > _selectedCellIndexesEnd ? _selectedCellIndexesStart : _selectedCellIndexesEnd;
        [cell configWithData:self.gridData[self.keys[indexPath.item]] isSelected:(indexPath.item<=end && indexPath.item>=start)];
    }
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kCellWidth, kCellWidth);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
//    NSLog(@"gizmo scrollViewWillBeginDragging");
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
//    NSLog(@"gizmo scrollViewDidEndDragging");
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
        _legendView.delegate = self;
    }
    return _legendView;
}

- (HistogramView *)histogramView
{
    if (!_histogramView) {
        _histogramView = [[HistogramView alloc] initWithData:[NSMutableArray new]];
        _histogramView.delegate = self.legendView;
    }
    return _histogramView;
}

- (PiechartView *)piechartView
{
    if (!_piechartView) {
        _piechartView = [[PiechartView alloc] initWithData:[NSMutableArray new] width:0 enableInteractive:NO];
        _piechartView.delegate = self.legendView;
    }
    return _piechartView;
}

- (LinechartView *)linechartView
{
    if (!_linechartView) {
        _linechartView = [LinechartView new];
    }
    return _linechartView;
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
        _dateLabel.font = [UIFont mirrorLabelFont];
        _dateLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
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
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumLineSpacing = kCellSpacing;
        layout.minimumInteritemSpacing = kCellSpacing;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.view.backgroundColor;
//        _collectionView.allowsMultipleSelection = YES;
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [_collectionView addGestureRecognizer:longPress];
        [_collectionView registerClass:[GridCollectionViewCell class] forCellWithReuseIdentifier:[GridCollectionViewCell identifier]];
    }
    return _collectionView;
}

- (UIButton *)settingsButton
{
    if (!_settingsButton) {
        _settingsButton = [UIButton new];
        UIImage *iconImage = [[UIImage systemImageNamed:@"line.horizontal.3"]  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [_settingsButton setImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [_settingsButton addTarget:self action:@selector(goToSettings) forControlEvents:UIControlEventTouchUpInside];
    }
    return _settingsButton;
}

- (UIButton *)typeButton
{
    if (!_typeButton) {
        _typeButton = [UIButton new];
        UIImage *iconImage = [[UIImage systemImageNamed:@"checkmark.square"]  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [_typeButton setImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [_typeButton addTarget:self action:@selector(goToHiddenVC) forControlEvents:UIControlEventTouchUpInside];
    }
    return _typeButton;
}


- (NSMutableArray<NSString *> *)keys
{
    if (!_keys) {
        _keys = [NSMutableArray<NSString *> new];
        [self updateKeys];
    }
    return _keys;
}

- (NSMutableDictionary<NSString *, NSMutableArray<MirrorDataModel *> *> *)gridData
{
    if (!_gridData) {
        _gridData = [NSMutableDictionary<NSString *, NSMutableArray<MirrorDataModel *> *> new];
        [self updateGridData];
    }
    return _gridData;
}

#pragma mark - Animation

// 从左边缘滑动唤起settings
- (void)edgeGestureRecognizerAction:(UIScreenEdgePanGestureRecognizer *)pan
{
    //产生百分比
    CGFloat process = [pan translationInView:self.view].x / (self.view.frame.size.width);
    
    process = MIN(1.0,(MAX(0.0, process)));
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.interactiveTransition = [UIPercentDrivenInteractiveTransition new];
        // 触发present转场动画
        [self goToSettings];
    }else if (pan.state == UIGestureRecognizerStateChanged){
        [self.interactiveTransition updateInteractiveTransition:process];
    }else if (pan.state == UIGestureRecognizerStateEnded
              || pan.state == UIGestureRecognizerStateCancelled){
        if (process > 0.3) {
            [ self.interactiveTransition finishInteractiveTransition];
        }else{
            [ self.interactiveTransition cancelInteractiveTransition];
        }
        self.interactiveTransition = nil;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    if ([presented isKindOfClass:SettingsViewController.class]) { // Settings
        LeftAnimation *animation = [LeftAnimation new];
        animation.isPresent = YES;
        return animation;
    } else { // Hidden VC
        HiddenAnimation *animation = [HiddenAnimation new];
        animation.isPresent = YES;
        animation.buttonFrame = [self.typeButton convertRect:self.typeButton.bounds toView:[[[UIApplication sharedApplication] delegate] window]];
        return animation;
    }
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactiveTransition;
}


#pragma mark - Privates

- (NSArray *)leftWidthLeftHeight
{
    CGFloat navi = self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height;
    CGFloat leftRightTimeHint_noGapBelow = kCellWidth;
    CGFloat grid_plusGapBelow = (kCellWidth*7 + kCellSpacing*6) + kGapInLine;
    CGFloat dataLabel_plusGapBelow = 20*kHeightRatio + kGapInLine;
    CGFloat legend_plusGapBelow = [self.legendView legendViewHeight] + kGapInLine;
    CGFloat tabbar_plusGapAbove = self.tabBarController.tabBar.frame.size.height + kGapInLine;
    
    CGFloat leftHeight = kScreenHeight - navi - leftRightTimeHint_noGapBelow - grid_plusGapBelow - dataLabel_plusGapBelow - legend_plusGapBelow - tabbar_plusGapAbove;
    CGFloat leftWidth = kScreenWidth - 2*kLeftRightSpacing;
    return @[@(leftWidth), @(leftHeight)];
}



@end
