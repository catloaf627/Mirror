//
//  TodayViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/4.
//

#import "TodayViewController.h"
#import "MirrorTabsManager.h"
#import "MirrorNaviManager.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorMacro.h"
#import "MirrorSettings.h"
#import "LeftAnimation.h"
#import "SettingsViewController.h"
#import "MirrorLanguage.h"
#import "TodayPeriodCollectionViewCell.h"
#import "TodayTotalHeader.h"
#import "MirrorStorage.h"
#import "UIFont+MirrorFont.h"

#define kLeftRightSpacing (20*kWidthRatio)
#define kCellSpacing (20*kHeightRatio) // cell之间的上下间距

@interface TodayViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, EditPeriodForTodayProtocol, UIViewControllerTransitioningDelegate>

@property (nonatomic, assign) BOOL isLoaded;
// Navibar
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactiveTransition;
// Data source
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *todayData;
// UI
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *emptyHintLabel;

@end

@implementation TodayViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 系统通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSignificantTimeChangeNotification object:nil];
        // 设置通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorSwitchShowIndexNotification object:nil];// 比其他vc多监听一个index通知
        // 数据通知 (直接数据驱动UI，本地数据变动必然导致这里的UI变动)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
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
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:nil];
}

- (void)restartVC
{
    // 更新tabbar
    [[MirrorTabsManager sharedInstance] updateTodayTabItemWithTabController:self.tabBarController];
    if (!_isLoaded) return;
    // 将vc.view里的所有subviews全部置为nil
    self.collectionView = nil;
    self.emptyHintLabel = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 更新navibar
    if (self.tabBarController.selectedIndex == 1) {
        [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:nil];
    }
    [self p_setupUI];
}

- (void)reloadData
{
    /*
     调用reloadData后UI不刷新的bug折磨了我很久，一开始以为是其他页面遮挡了collection view导致的不刷新，多次改动collection view reload data的调用方式都没成功
     最后发现根本原因是：在整个页面还没有setupUI的时候就被通知reloadData
     例子1：冷启后还没有进入TodayVC就切换了index settings，导致TodayVC还没有setup UI就被reload了，这以后再进入TodayVC，修改今日数据或是修改index settings，UI不会更新。
        现象：新添的数据看不到、修改了的数据不生效、更新数据后today header上的饼状图也不生效...
     例子2:冷启后还没有进入GirdVC就切换了heatmap settings，导致GirdVC还没有setup UI就被reload了，这以后再进入GirdVC，修改hidden数据或是修改heatmap settings，UI不会更新。
        现象：选择隐藏/显示某些tasks以后，grid不更新...
     例子2:冷启后还没有进入HistoryVC就切换了piechart settings on data，导致HistoryVC还没有setup UI就被reload了，这以后再进入HistoryVC，修改hidden数据或是修改piechart settings on data，UI不会更新。
        现象：切换日/周/月/年的时候，legend不跟着更新...
     具体technical原因不明。最后的解决办法是给每个VC都添加isLoaded属性，根本没被load过的VC被通知reload的时候直接返回不进行任何操作。
    */
    if (!_isLoaded) return;
    self.todayData = [MirrorStorage getTodayData];
    [self updateHint]; // reloaddata要顺便reload一下emptyhint的状态
    [self.collectionView reloadData];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];

    [self.view addSubview:self.collectionView];
    [self.collectionView reloadData];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.left.offset(kLeftRightSpacing);
        make.right.offset(-kLeftRightSpacing);
        make.bottom.offset(-kTabBarHeight);
    }];
    [self.view addSubview:self.emptyHintLabel];
    [self.emptyHintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.left.right.offset(0);
    }];

    UIScreenEdgePanGestureRecognizer *edgeRecognizer = [UIScreenEdgePanGestureRecognizer new];
    edgeRecognizer.edges = UIRectEdgeLeft;
    [edgeRecognizer addTarget:self action:@selector(edgeGestureRecognizerAction:)];
    [self.view addGestureRecognizer:edgeRecognizer];
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
#pragma mark - Collection view delegate


- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.todayData.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TodayPeriodCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[TodayPeriodCollectionViewCell identifier] forIndexPath:indexPath];
    [cell configWithTaskname:self.todayData[indexPath.item].taskName periodIndex:self.todayData[indexPath.item].originalIndex];
    cell.delegate = self;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kScreenWidth - 2*kCellSpacing, 80*kHeightRatio);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *header;
    if (kind == UICollectionElementKindSectionHeader) {
        header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
        TodayTotalHeader* todayHeader = (TodayTotalHeader *)header;
        [todayHeader configWithRecords:self.todayData];
    }
    return header;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(kScreenWidth, kTodayHeaderHeight);
}

#pragma mark - Getters

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumLineSpacing = 10;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.view.backgroundColor;
        
        [_collectionView registerClass:[TodayPeriodCollectionViewCell class] forCellWithReuseIdentifier:[TodayPeriodCollectionViewCell identifier]];
        [_collectionView registerClass:[TodayTotalHeader class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
    }
    return _collectionView;
}

- (UILabel *)emptyHintLabel
{
    if (!_emptyHintLabel) {
        _emptyHintLabel = [UILabel new];
        _emptyHintLabel.textAlignment = NSTextAlignmentCenter;
        _emptyHintLabel.font = [UIFont mirrorHintFont];
        _emptyHintLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse]; // 和nickname的文字颜色保持一致
        _emptyHintLabel.text = [MirrorLanguage mirror_stringWithKey:@"no_data_today"];
        _emptyHintLabel.hidden = self.todayData.count > 0;
    }
    return _emptyHintLabel;
}

- (void)updateHint
{
    self.emptyHintLabel.text = [MirrorLanguage mirror_stringWithKey:@"no_data_today"];
    self.emptyHintLabel.hidden = self.todayData.count > 0;
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

- (NSMutableArray<MirrorRecordModel *> *)todayData
{
    if (!_todayData) {
        _todayData = [MirrorStorage getTodayData];
    }
    return _todayData;
}

#pragma mark - Animations

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
    LeftAnimation *animation = [LeftAnimation new];
    animation.isPresent = YES;
    return animation;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactiveTransition;
}

@end
