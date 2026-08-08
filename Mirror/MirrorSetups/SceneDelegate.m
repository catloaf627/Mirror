//
//  SceneDelegate.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/24.
//

#import "SceneDelegate.h"
#import "MirrorTabsManager.h"
#import "MirrorNaviManager.h"
#import "MirrorSettings.h"
#import "MirrorStorage.h"
#import <UIKit/UIKit.h>


@interface SceneDelegate ()<UITabBarControllerDelegate>

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // 由于删除了storyboard，所以需要自己手动创建UIWindow
    // 类似于iPad可以分屏，所以有多个scene
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    _window = [[UIWindow alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Init tabbarController (使用mirrorTabController避免重复init)
    UITabBarController *tabbarController = [[MirrorTabsManager sharedInstance] mirrorTabController];
    tabbarController.delegate = self;
    
    // Init navibarController (使用mirrorNaviControllerWithRootViewController:避免重复init)
    UINavigationController *navigationController = [[MirrorNaviManager sharedInstance] mirrorNaviControllerWithRootViewController:tabbarController];
    
    // Setup Window
    _window.rootViewController = navigationController;
    [_window makeKeyAndVisible];
    _window.windowScene = windowScene;
    NSLog(@"SceneDelegate %@, %@", tabbarController, navigationController); // 监控：只有一个tabbarController，只有一个navibarController
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    [MirrorStorage resumeGoingOnLiveActivityIfNeeded];
    BOOL appIsDark = [MirrorSettings appliedDarkMode];
    BOOL systemIsDark = [UIScreen mainScreen].traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    if (appIsDark == systemIsDark) {
        return;
    } else {
        [MirrorSettings switchTheme];
    }
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}


@end
