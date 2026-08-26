//
//  UIImage+MirrorSymbol.h
//  Mirror
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (MirrorSymbol)

+ (nullable UIImage *)mirror_systemImageNamed:(NSString * _Nullable)imageName fallbackName:(NSString *)fallbackName;
+ (nullable UIImage *)mirror_systemImageNamed:(NSString * _Nullable)imageName fallbackName:(NSString *)fallbackName configuration:(UIImageConfiguration * _Nullable)configuration;

// Uses fallbackName when imageName is unavailable or debug fallback mode is enabled.
// Pass fallbackConfiguration when the fallback symbol needs a different size or weight.
+ (nullable UIImage *)mirror_systemImageNamed:(NSString * _Nullable)imageName fallbackName:(NSString *)fallbackName configuration:(UIImageConfiguration * _Nullable)configuration fallbackConfiguration:(UIImageConfiguration * _Nullable)fallbackConfiguration;

@end

NS_ASSUME_NONNULL_END
