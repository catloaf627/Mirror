//
//  MirrorManualGuidePointer.m
//  Mirror
//

#import "MirrorManualGuidePointer.h"
#import "UIColor+MirrorColor.h"
#import "UIImage+MirrorSymbol.h"

static NSString * const kManualGuidePointerShownKey = @"MirrorManualGuidePointerShown";
static UIView *sManualGuidePointerView = nil;

@implementation MirrorManualGuidePointer

+ (void)showOnceFromViewController:(UIViewController *)viewController targetView:(UIView *)targetView
{
    [self remove];

    UIWindow *window = viewController.view.window;
    BOOL hasShownManualGuidePointer = [[NSUserDefaults standardUserDefaults] boolForKey:kManualGuidePointerShownKey];
    hasShownManualGuidePointer = NO;
    if (hasShownManualGuidePointer ||
        !window ||
        !targetView.superview ||
        viewController.presentedViewController) {
        NSLog(@"Manual guide pointer skipped - shown: %@, window: %@, targetSuperview: %@, presentedViewController: %@",
              hasShownManualGuidePointer ? @"YES" : @"NO",
              window ? @"YES" : @"NO",
              targetView.superview ? @"YES" : @"NO",
              viewController.presentedViewController ? NSStringFromClass(viewController.presentedViewController.class) : @"nil");
        return;
    }

    CGRect targetFrame = [targetView convertRect:targetView.bounds toView:window];
    if (CGRectIsEmpty(targetFrame)) {
        return;
    }

    CGFloat pointerSize = 58;
    CGPoint clickCenter = CGPointMake(CGRectGetMidX(targetFrame) - pointerSize / 2 + 8,
                                      CGRectGetMidY(targetFrame) + 20);
    CGPoint startCenter = CGPointMake(clickCenter.x - 36, clickCenter.y + 16);
    UIView *pointerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, pointerSize, pointerSize)];
    pointerView.userInteractionEnabled = NO;
    pointerView.alpha = 0.0;
    pointerView.transform = CGAffineTransformMakeScale(0.92, 0.92);
    pointerView.center = startCenter;
    pointerView.layer.shadowColor = UIColor.blackColor.CGColor;
    pointerView.layer.shadowOpacity = 0.25;
    pointerView.layer.shadowRadius = 7;
    pointerView.layer.shadowOffset = CGSizeMake(0, 4);

    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:40 weight:UIImageSymbolWeightRegular];
    UIImage *handImage = [UIImage mirror_systemImageNamed:@"hand.point.up.right.fill" fallbackName:@"hand.point.up.fill" configuration:configuration fallbackConfiguration:configuration];
    if (handImage) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[handImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        imageView.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.frame = pointerView.bounds;
        imageView.transform = CGAffineTransformMakeRotation(M_PI_4);
        [pointerView addSubview:imageView];
    } else {
        UILabel *fallbackLabel = [[UILabel alloc] initWithFrame:pointerView.bounds];
        fallbackLabel.text = @"☝︎";
        fallbackLabel.font = [UIFont systemFontOfSize:42 weight:UIFontWeightRegular];
        fallbackLabel.textAlignment = NSTextAlignmentCenter;
        fallbackLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        fallbackLabel.transform = CGAffineTransformMakeRotation(M_PI_4);
        [pointerView addSubview:fallbackLabel];
    }

    [window addSubview:pointerView];
    sManualGuidePointerView = pointerView;

    [self animatePointer:pointerView clickCenter:clickCenter startCenter:startCenter];
}

+ (void)remove
{
    [sManualGuidePointerView.layer removeAllAnimations];
    [sManualGuidePointerView removeFromSuperview];
    sManualGuidePointerView = nil;
}

+ (void)animatePointer:(UIView *)pointerView clickCenter:(CGPoint)clickCenter startCenter:(CGPoint)startCenter
{
    [self animatePointerPass:pointerView clickCenter:clickCenter startCenter:startCenter delay:0 completion:^{
        if (sManualGuidePointerView != pointerView) {
            return;
        }

        [self animatePointerPass:pointerView clickCenter:clickCenter startCenter:startCenter delay:0.25 completion:^{
            if (sManualGuidePointerView != pointerView) {
                return;
            }

            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kManualGuidePointerShownKey];
            [self fadeOutPointer:pointerView];
        }];
    }];
}

+ (void)fadeOutPointer:(UIView *)pointerView
{
    [UIView animateWithDuration:0.25 animations:^{
        pointerView.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (sManualGuidePointerView == pointerView) {
            [self remove];
        }
    }];
}

+ (void)animatePointerPass:(UIView *)pointerView clickCenter:(CGPoint)clickCenter startCenter:(CGPoint)startCenter delay:(NSTimeInterval)delay completion:(void (^)(void))completion
{
    if (sManualGuidePointerView != pointerView) {
        if (completion) {
            completion();
        }
        return;
    }

    [UIView animateKeyframesWithDuration:2.0
                                   delay:delay
                                 options:UIViewKeyframeAnimationOptionAllowUserInteraction
                              animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.12 animations:^{
            pointerView.alpha = 1.0;
            pointerView.center = startCenter;
            pointerView.transform = CGAffineTransformMakeScale(0.92, 0.92);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.12 relativeDuration:0.42 animations:^{
            pointerView.center = clickCenter;
            pointerView.transform = CGAffineTransformIdentity;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.54 relativeDuration:0.10 animations:^{
            pointerView.center = CGPointMake(clickCenter.x + 8, clickCenter.y);
            pointerView.transform = CGAffineTransformMakeScale(0.82, 0.82);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.64 relativeDuration:0.14 animations:^{
            pointerView.center = clickCenter;
            pointerView.transform = CGAffineTransformIdentity;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.82 relativeDuration:0.18 animations:^{
            pointerView.center = startCenter;
            pointerView.transform = CGAffineTransformMakeScale(0.92, 0.92);
        }];
    } completion:^(BOOL finished) {
        if (finished && completion) {
            completion();
        }
    }];
}

@end
