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
#import "MirrorFakeDataSeeder.h"
#import "MirrorLanguage.h"
#import "MirrorMacro.h"
#import <UIKit/UIKit.h>


@interface SceneDelegate ()<UITabBarControllerDelegate>

@end

static NSString * const kMirrorInitialDataPromptShownKey = @"MirrorInitialDataPromptShown";

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
    [self showInitialDataPromptIfNeeded];
    NSLog(@"SceneDelegate %@, %@", tabbarController, navigationController); // 监控：只有一个tabbarController，只有一个navibarController
}


- (void)showInitialDataPromptIfNeeded
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kMirrorInitialDataPromptShownKey]) {
        return;
    }
    if ([MirrorStorage retriveMirrorTasks].count > 0 || [MirrorStorage retriveMirrorRecords].count > 0) {
        [defaults setBool:YES forKey:kMirrorInitialDataPromptShownKey];
        return;
    }

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSNumber *recordCount = [MirrorStorage iCloudRecordCount];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([defaults boolForKey:kMirrorInitialDataPromptShownKey]) {
                return;
            }
            [defaults setBool:YES forKey:kMirrorInitialDataPromptShownKey];
            if (recordCount.integerValue > 0) {
                [self showInitialICloudDownloadAlertWithRecordCount:recordCount];
            } else {
                [self showInitialExampleDataAlert];
            }
        });
    });
}

- (void)showInitialICloudDownloadAlertWithRecordCount:(NSNumber *)recordCount
{
    NSString *message = [NSString stringWithFormat:[MirrorLanguage mirror_stringWithKey:@"icloud_records_detected_message"], recordCount.stringValue];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"download_from_icloud_?"]
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"download"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([MirrorStorage importDataFromICloud]) {
            [MirrorStorage saveSecondsFromGMT:@([NSTimeZone systemTimeZone].secondsFromGMT)];
            [[NSNotificationCenter defaultCenter] postNotificationName:MirrorImportDataNotificaiton object:nil];
        } else {
            [self showWrongDataFormatAlert];
        }
    }]];
    [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)showInitialExampleDataAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"import_example_data_?"]
                                                                             message:[MirrorLanguage mirror_stringWithKey:@"import_example_data_message"]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"import"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [MirrorFakeDataSeeder seedFakeData];
        [[NSNotificationCenter defaultCenter] postNotificationName:MirrorImportDataNotificaiton object:nil];
        [self showExampleDataImportedAlert];
    }]];
    [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)showExampleDataImportedAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:[MirrorLanguage mirror_stringWithKey:@"example_data_imported_message"]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
    [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
}

- (void)showWrongDataFormatAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"wrong_data_format"]
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
    [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
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
