//
//  UIImage+MirrorSymbol.m
//  Mirror
//

#import "UIImage+MirrorSymbol.h"
#import "MirrorMacro.h"

@implementation UIImage (MirrorSymbol)

+ (UIImage *)mirror_systemImageNamed:(NSString *)imageName fallbackName:(NSString *)fallbackName
{
    return [self mirror_systemImageNamed:imageName fallbackName:fallbackName configuration:nil];
}

+ (UIImage *)mirror_systemImageNamed:(NSString *)imageName fallbackName:(NSString *)fallbackName configuration:(UIImageConfiguration *)configuration
{
    return [self mirror_systemImageNamed:imageName fallbackName:fallbackName configuration:configuration fallbackConfiguration:configuration];
}

+ (UIImage *)mirror_systemImageNamed:(NSString *)imageName fallbackName:(NSString *)fallbackName configuration:(UIImageConfiguration *)configuration fallbackConfiguration:(UIImageConfiguration *)fallbackConfiguration
{
    UIImage *image = [self mirror_imageNamed:imageName configuration:configuration];
    if (!is_debug && image) {
        return image;
    }

    // Debug fallback mode makes unsupported/new symbols visible during manual checks.
    UIImage *fallbackImage = [self mirror_imageNamed:fallbackName configuration:fallbackConfiguration];
    return fallbackImage ?: image;
}

+ (UIImage *)mirror_imageNamed:(NSString *)imageName configuration:(UIImageConfiguration *)configuration
{
    if (imageName.length == 0) {
        return nil;
    }
    if (configuration) {
        return [UIImage systemImageNamed:imageName withConfiguration:configuration];
    }
    return [UIImage systemImageNamed:imageName];
}

@end
