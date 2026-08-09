//
//  MirrorMacro.h
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/27.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SpanType) {
    SpanTypeDay,
    SpanTypeWeek,
    SpanTypeMonth,
    SpanTypeYear,
};

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kTodayHeaderHeight [UIScreen mainScreen].bounds.size.height/5
#define kWidthRatio (kScreenWidth / 320.0) // 基准是 iPhone 14 Pro，它的屏幕宽度是 320 points
#define kHeightRatio (kScreenHeight / 693.0) // 基准是 iPhone 14 Pro，它的屏幕高度是 693 points

static inline UIWindow * _Nullable MirrorKeyWindow(void) {
    if (@available(iOS 13.0, *)) {
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
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [UIApplication sharedApplication].keyWindow;
#pragma clang diagnostic pop
}

static inline CGFloat MirrorBottomSafeAreaHeight(void) {
    UIWindow *window = MirrorKeyWindow();
    return window ? window.safeAreaInsets.bottom : 0;
}

#define kIs_iphone ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
#define kIs_iPhoneX kScreenWidth >=375.0f && kScreenHeight >=812.0f&& kIs_iphone
    
/*状态栏高度*/
#define kStatusBarHeight (CGFloat)(kIs_iPhoneX?(44.0):(20.0))
/*导航栏高度*/
#define kNavBarHeight (44)
/*顶部安全区域远离高度*/
#define kTopBarSafeHeight (CGFloat)(kIs_iPhoneX?(44.0):(0))
 /*底部安全区域远离高度*/
#define kBottomSafeHeight (CGFloat)(kIs_iPhoneX?(34.0):(0))
/*iPhoneX的状态栏高度差值*/
#define kTopBarDifHeight (CGFloat)(kIs_iPhoneX?(24.0):(0))

// Font
// https://stackoverflow.com/questions/8090916/fonts-on-ios-device

// 侧边半屏ratio
#define kLeftSheetRatio (0.8)
// Max number of colors
#define kMaxColorNum (8)
// 最小记录时间为一分钟（只要时长超过一分钟，分钟数必然有变化）全app忽略秒数（秒数全部记为0）
#define kMinSeconds (60)

// 系统声音 1050 - 1200 都还可以
#define kAudioClick (1123)

// System Notifications
#define MirrorSignificantTimeChangeNotification @"MirrorSignificantTimeChangeNotification"

// Import data Notification
#define MirrorImportDataNotificaiton @"MirrorImportDataNotificaiton"

// Settings Notifications
#define MirrorSwitchThemeNotification @"MirrorSwitchThemeNotification"
#define MirrorSwitchLanguageNotification @"MirrorSwitchLanguageNotification"
#define MirrorSwitchWeekStartsOnNotification @"MirrorSwitchWeekStartsOnNotification"
#define MirrorSwitchChartTypeDataNotification @"MirrorSwitchChartTypeDataNotification"
#define MirrorSwitchChartTypeRecordNotification @"MirrorSwitchChartTypeRecordNotification"
#define MirrorSwitchShowIndexNotification @"MirrorSwitchShowIndexNotification"
#define MirrorSwitchShowShadeNotification @"MirrorSwitchShowShadeNotification"
// Data Notifications (MirrorStorage统一来发)
#define MirrorTaskCreateNotification @"MirrorTaskCreateNotification"
#define MirrorTaskDeleteNotification @"MirrorTaskDeleteNotification"
#define MirrorTaskHiddenNotification @"MirrorTaskHiddenNotification"
#define MirrorTaskChangeOrderNotification @"MirrorTaskChangeOrderNotification"
#define MirrorTaskEditNotification @"MirrorTaskEditNotification"
#define MirrorTaskStartNotification @"MirrorTaskStartNotification"
#define MirrorTaskStopNotification @"MirrorTaskStopNotification"
#define MirrorPeriodDeleteNotification @"MirrorPeriodDeleteNotification"
#define MirrorPeriodEditNotification @"MirrorPeriodEditNotification"

// 数据
#define TASKS @"tasks"
#define RECORDS @"records"
#define SECONDS @"seconds"


@interface MirrorMacro : NSObject

@end

NS_ASSUME_NONNULL_END
