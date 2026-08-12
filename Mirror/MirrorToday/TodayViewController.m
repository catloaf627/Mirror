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
#import "LeftAnimation.h"
#import "SettingsViewController.h"
#import "TodayTotalHeader.h"
#import "OneDayTimelineViewController.h"

#define kLeftRightSpacing (20*kWidthRatio)

@interface TodayViewController () <UIViewControllerTransitioningDelegate>

@property (nonatomic, assign) BOOL isLoaded;

// Navibar
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactiveTransition;

// UI
@property (nonatomic, strong) OneDayTimelineViewController *timelineViewController;

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskMergeNotification object:nil];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self p_setupUI];
    _isLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:nil];
}

- (void)restartVC
{
    // 更新tabbar
    [[MirrorTabsManager sharedInstance] updateTodayTabItemWithTabController:self.tabBarController];
    if (!_isLoaded) return;

    [self.timelineViewController willMoveToParentViewController:nil];
    [self.timelineViewController.view removeFromSuperview];
    [self.timelineViewController removeFromParentViewController];
    self.timelineViewController = nil;
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
     */
    if (!_isLoaded) return;
    [self.timelineViewController updateDate:[NSDate now]];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];

    TodayTotalHeader *header = [TodayTotalHeader new];
    header.backgroundColor = self.view.backgroundColor;
    OneDayTimelineViewController *timelineViewController = [[OneDayTimelineViewController alloc] initWithDate:[NSDate now]
                                                                                                  headerView:header
                                                                                                headerHeight:kTodayHeaderHeight
                                                                                                headerInsets:UIEdgeInsetsMake(0, kLeftRightSpacing, 0, kLeftRightSpacing)
                                                                                         headerConfiguration:^(UIView *headerView, NSMutableArray<MirrorRecordModel *> *records) {
        [(TodayTotalHeader *)headerView configWithRecords:records];
    }];
    self.timelineViewController = timelineViewController;
    [self addChildViewController:timelineViewController];
    [self.view addSubview:timelineViewController.view];
    [timelineViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.left.right.offset(0);
        make.bottom.offset(-self.tabBarController.tabBar.frame.size.height);
    }];
    [timelineViewController didMoveToParentViewController:self];

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

#pragma mark - Getters

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

#pragma mark - Animations

// 从左边缘滑动唤起settings
- (void)edgeGestureRecognizerAction:(UIScreenEdgePanGestureRecognizer *)pan
{
    //产生百分比
    CGFloat sheetWidth = self.view.frame.size.width * kLeftSheetRatio;
    CGFloat process = [pan translationInView:self.view].x / sheetWidth;
    
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
