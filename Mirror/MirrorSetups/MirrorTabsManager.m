//
//  MirrorTabsManager.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import "MirrorTabsManager.h"

#import "TimeViewController.h"
#import "TodayViewController.h"
#import "GridViewController.h"

#import "UIColor+MirrorColor.h"
#import "MirrorLanguage.h"
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
        //create a tabbar controller
        _controller  = [[UITabBarController alloc] init];
        
        //add 3 view controllers to tabbar controller
        [_controller setViewControllers:@[timeTrackerVC, todayVC, gridVC]];
        _controller.selectedIndex = 0;
        _controller.tabBar.barTintColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _controller.tabBar.backgroundImage = [UIImage new];
        _controller.tabBar.shadowImage = [UIImage new];

        [self updateTimeTabItemWithTabController:_controller];
        [self updateTodayTabItemWithTabController:_controller];
        [self updateGridTabItemWithTabController:_controller];
    }
    return _controller;
}

- (void)updateTimeTabItemWithTabController:(UITabBarController *)tabbarController
{
    [self updateTabbarController:tabbarController index:0 tabbarItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"start"] imageName:@"alarm" selectedImageName:@"alarm.fill"];
}

- (void)updateTodayTabItemWithTabController:(UITabBarController *)tabbarController
{
    [self updateTabbarController:tabbarController index:1 tabbarItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"today"] imageName:@"doc.plaintext" selectedImageName:@"doc.plaintext.fill"];
}

- (void)updateGridTabItemWithTabController:(UITabBarController *)tabbarController
{
    [self updateTabbarController:tabbarController index:2 tabbarItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"record"] imageName:@"square.grid.2x2" selectedImageName:@"square.grid.2x2.fill"];
}

- (void)updateTabbarController:(UITabBarController *)tabbarController index:(NSInteger)index tabbarItemWithTitle:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName
{
    if (index < 0 || index >= tabbarController.viewControllers.count) {
        return;
    }
    // 默认图片
    UIImage *image = [[UIImage systemImageNamed:imageName] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconText]];
    UIImage *imageWithRightColor = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]; //这一行的作用是让image使用image本身的颜色，而不是系统颜色
    // 选中图片
    UIImage *selectedImage = [[UIImage systemImageNamed:selectedImageName] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight]];
    UIImage *selectedImageWithRightColor = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];//这一行的作用是让image使用image本身的颜色，而不是系统颜色
    // 设置图片
    UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:title image:imageWithRightColor selectedImage:selectedImageWithRightColor];
    item.titlePositionAdjustment = UIOffsetZero;
    item.imageInsets = UIEdgeInsetsZero;
    // 默认文字
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconText]} forState:UIControlStateNormal];
    // 选中文字
    [item setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight]} forState:UIControlStateSelected];
    tabbarController.viewControllers[index].tabBarItem = item;
}

@end
