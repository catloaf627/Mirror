//
//  MirrorNaviManager.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/29.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorNaviManager : NSObject

+ (instancetype)sharedInstance;
- (UINavigationController *)mirrorNaviControllerWithRootViewController:tabbarController;

- (void)updateNaviItemWithTitle:(NSString *)title leftButton:(nullable UIView *)leftButton rightButton:(nullable UIView *)rightButton;


@end

NS_ASSUME_NONNULL_END
