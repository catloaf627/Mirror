//
//  MirrorTabsManager.h
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorTabsManager : NSObject

+ (instancetype)sharedInstance;
- (UITabBarController *)mirrorTabController;
- (void)updateTimeTabItemWithTabController:(UITabBarController *)tabbarController;
- (void)updateTodayTabItemWithTabController:(UITabBarController *)tabbarController;
- (void)updateGridTabItemWithTabController:(UITabBarController *)tabbarController;
- (void)updateHistoryTabItemWithTabController:(UITabBarController *)tabbarController;
- (void)updateSpecialDaysTabItemWithTabController:(UITabBarController *)tabbarController;

@end

NS_ASSUME_NONNULL_END
