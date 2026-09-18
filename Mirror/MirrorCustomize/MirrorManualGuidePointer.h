//
//  MirrorManualGuidePointer.h
//  Mirror
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorManualGuidePointer : NSObject

+ (void)showOnceFromViewController:(UIViewController *)viewController targetView:(UIView *)targetView;
+ (void)remove;

@end

NS_ASSUME_NONNULL_END
