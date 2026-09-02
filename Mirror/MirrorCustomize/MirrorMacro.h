//
//  MirrorMacro.h
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kTodayHeaderHeight [UIScreen mainScreen].bounds.size.height/5
#define kWidthRatio (kScreenWidth / 320.0) // 基准是 iPhone 14 Pro，它的屏幕宽度是 320 points
#define kHeightRatio (kScreenHeight / 693.0) // 基准是 iPhone 14 Pro，它的屏幕高度是 693 points

static inline UIWindow * _Nullable MirrorKeyWindow(void) {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive || ![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }

        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
    }
    return nil;
}

static inline CGFloat MirrorBottomSafeAreaHeight(void) {
    UIWindow *window = MirrorKeyWindow();
    return window ? window.safeAreaInsets.bottom : 0;
}

#define kIs_iphone ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
#define kIs_iPhoneX kScreenWidth >=375.0f && kScreenHeight >=812.0f&& kIs_iphone
    
// Font
// https://stackoverflow.com/questions/8090916/fonts-on-ios-device

// 侧边半屏ratio
#define kLeftSheetRatio (0.8)
// Max number of colors
#define kMaxColorNum (8)
// 最小记录时间为一分钟（只要时长超过一分钟，分钟数必然有变化）全app忽略秒数（秒数全部记为0）
#define kMinSeconds (60)

// System Notifications
#define MirrorSignificantTimeChangeNotification @"MirrorSignificantTimeChangeNotification"

// Import data Notification
#define MirrorImportDataNotificaiton @"MirrorImportDataNotificaiton"

// Settings Notifications
#define MirrorSwitchThemeNotification @"MirrorSwitchThemeNotification"
#define MirrorSwitchLanguageNotification @"MirrorSwitchLanguageNotification"
#define MirrorSwitchWeekStartsOnNotification @"MirrorSwitchWeekStartsOnNotification"
#define MirrorSwitchChartTypeRecordNotification @"MirrorSwitchChartTypeRecordNotification"
#define MirrorSwitchShowIndexNotification @"MirrorSwitchShowIndexNotification"
#define MirrorSwitchShowShadeNotification @"MirrorSwitchShowShadeNotification"
// Data Notifications (MirrorStorage统一来发)
#define MirrorTaskCreateNotification @"MirrorTaskCreateNotification"
#define MirrorTaskDeleteNotification @"MirrorTaskDeleteNotification"
#define MirrorTaskMergeNotification @"MirrorTaskMergeNotification"
#define MirrorTaskHiddenNotification @"MirrorTaskHiddenNotification"
#define MirrorTaskChangeOrderNotification @"MirrorTaskChangeOrderNotification"
#define MirrorTaskEditNotification @"MirrorTaskEditNotification"
#define MirrorTaskStartNotification @"MirrorTaskStartNotification"
#define MirrorTaskStopNotification @"MirrorTaskStopNotification"
#define MirrorPeriodDeleteNotification @"MirrorPeriodDeleteNotification"
#define MirrorPeriodEditNotification @"MirrorPeriodEditNotification"
#define MirrorDayCreateNotification @"MirrorDayCreateNotification"
#define MirrorDayDeleteNotification @"MirrorDayDeleteNotification"
#define MirrorDayEditNotification @"MirrorDayEditNotification"
#define MirrorScheduleChangeNotification @"MirrorScheduleChangeNotification"

// 数据
#define TASKS @"tasks"
#define RECORDS @"records"
#define DAYS @"days"
#define SCHEDULES @"schedules"
#define SECONDS @"seconds"

// Debug
#define is_record [[NSUserDefaults standardUserDefaults] boolForKey:@"is_record"]
#define is_debug [[NSUserDefaults standardUserDefaults] boolForKey:@"is_debug"]

@interface MirrorMacro : NSObject

@end

NS_ASSUME_NONNULL_END
