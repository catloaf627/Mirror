//
//  UIFont+MirrorFont.h
//  Mirror
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (MirrorFont)

+ (UIFont *)mirrorTodayFont;
+ (UIFont *)mirrorTitleFont;
+ (UIFont *)mirrorSubtitleFont;
+ (UIFont *)mirrorLabelFont;
+ (UIFont *)mirrorHintFont;

@end

NS_ASSUME_NONNULL_END
