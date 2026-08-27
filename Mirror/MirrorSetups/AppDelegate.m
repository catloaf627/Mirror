//
//  AppDelegate.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/24.
//

#import "AppDelegate.h"
#import "MirrorTabsManager.h"
#import "MirrorNaviManager.h"
#import "MirrorSettings.h"
#import "MirrorStorage.h"
#import "MirrorMacro.h"
#import "MirrorRecordWindow.h"

@interface AppDelegate () <UITabBarControllerDelegate>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 由于删除了storyboard，所以需要自己手动创建UIWindow
    Class windowClass = is_record ? MirrorRecordWindow.class : UIWindow.class;
    _window = [[windowClass alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Init tabbarController (使用mirrorTabController避免重复init)
    UITabBarController *tabbarController = [[MirrorTabsManager sharedInstance] mirrorTabController];
    tabbarController.delegate = self;
    
    // Init navibarController (使用mirrorNaviControllerWithRootViewController:避免重复init)
    UINavigationController *navigationController = [[MirrorNaviManager sharedInstance] mirrorNaviControllerWithRootViewController:tabbarController];
    
    // Setup Window
    _window.rootViewController = navigationController;
    [_window makeKeyAndVisible];
    [MirrorStorage resumeGoingOnLiveActivityIfNeeded];
    NSLog(@"AppDelegate %@, %@", tabbarController, navigationController); // 监控：只有一个tabbarController，只有一个navibarController
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

- (void)applicationSignificantTimeChange:(UIApplication *)application
{
    // 用户当前时区可能变化了；只保存新的时区偏移，不改用户原始记录时间。
    [MirrorStorage saveSecondsFromGMT:@([NSTimeZone systemTimeZone].secondsFromGMT)];
    // 发出一个重刷页面的通知（强制改时区可用、零点刷新也可用）。
    [[NSNotificationCenter defaultCenter] postNotificationName:MirrorSignificantTimeChangeNotification object:nil userInfo:nil];
}


@end
