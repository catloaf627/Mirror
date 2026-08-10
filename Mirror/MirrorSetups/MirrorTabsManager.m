//
//  MirrorTabsManager.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import "MirrorTabsManager.h"

#import "TimeViewController.h"
#import "TodayViewController.h"
#import "HistoryViewController.h"
#import "GridViewController.h"

#import "UIColor+MirrorColor.h"
#import "MirrorLanguage.h"
#import "MirrorSettings.h"
#import "MirrorMacro.h"

@interface MirrorTabsManager ()

@property (nonatomic, strong) UITabBarController *controller;

@end

@implementation MirrorTabsManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static MirrorTabsManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[MirrorTabsManager alloc]init];
    });
    return instance;
}

- (UITabBarController *)mirrorTabController
{
    if (!_controller) {
        TimeViewController *timeTrackerVC = [[TimeViewController alloc]init];
        TodayViewController *todayVC = [[TodayViewController alloc]init];
        GridViewController *gridVC = [[GridViewController alloc] init];
        HistoryViewController *historyVC = [[HistoryViewController alloc] init];
        //create a tabbar controller
        _controller  = [[UITabBarController alloc] init];
        
        //add 4 view controllers to tabbar controller
        [_controller setViewControllers:@[timeTrackerVC, todayVC, gridVC, historyVC]];
        _controller.selectedIndex = 0;
        _controller.tabBar.barTintColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _controller.tabBar.backgroundImage = [UIImage new];
        _controller.tabBar.shadowImage = [UIImage new];

        [self updateTimeTabItemWithTabController:_controller];
        [self updateTodayTabItemWithTabController:_controller];
        [self updateGridTabItemWithTabController:_controller];
        [self updateHistoryTabItemWithTabController:_controller];
    }
    return _controller;
}

- (void)updateTimeTabItemWithTabController:(UITabBarController *)tabbarController
{
    [self updateTabbar:tabbarController.tabBar index:0 tabbarItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"start"] imageName:@"alarm" selectedImageName:@"alarm.fill"];
}

- (void)updateTodayTabItemWithTabController:(UITabBarController *)tabbarController
{
    [self updateTabbar:tabbarController.tabBar index:1 tabbarItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"today"] imageName:@"doc.plaintext" selectedImageName:@"doc.plaintext.fill"];
}

- (void)updateGridTabItemWithTabController:(UITabBarController *)tabbarController
{
    [self updateTabbar:tabbarController.tabBar index:2 tabbarItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"record"] imageName:@"square.grid.2x2" selectedImageName:@"square.grid.2x2.fill"];
}

- (void)updateHistoryTabItemWithTabController:(UITabBarController *)tabbarController
{
    BOOL usesPiechart = [MirrorSettings appliedPieChartData];
    [self updateTabbar:tabbarController.tabBar index:3 tabbarItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"data"] imageName:usesPiechart? @"chart.pie":@"list.bullet" selectedImageName:usesPiechart?@"chart.pie.fill":@"list.bullet"];
}

- (void)updateTabbar:(UITabBar *)tabbar index:(NSInteger)index tabbarItemWithTitle:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName
{
    // 取出baritem
    UITabBarItem *item = [tabbar.items objectAtIndex:index];
    // 默认图片
    UIImage *image = [[UIImage systemImageNamed:imageName] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconText]];
    UIImage *imageWithRightColor = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]; //这一行的作用是让image使用image本身的颜色，而不是系统颜色
    // 选中图片
    UIImage *selectedImage = [[UIImage systemImageNamed:selectedImageName] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight]];
    UIImage *selectedImageWithRightColor = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];//这一行的作用是让image使用image本身的颜色，而不是系统颜色
    // 设置图片
    item = [item initWithTitle:title image:imageWithRightColor selectedImage:selectedImageWithRightColor];
    // 默认文字
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconText]} forState:UIControlStateNormal];
    // 选中文字
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight]} forState:UIControlStateSelected];

    [item imageInsets];
}

@end
