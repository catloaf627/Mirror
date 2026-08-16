//
//  MirrorToast.h
//  Mirror
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorToast : NSObject

+ (void)showWithText:(NSString *)text;
+ (void)showWithText:(NSString *)text inView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
