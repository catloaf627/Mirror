//
//  MirrorToast.m
//  Mirror
//

#import "MirrorToast.h"
#import "MirrorMacro.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"

static NSTimeInterval const kMirrorToastFadeDuration = 0.22;
static NSTimeInterval const kMirrorToastVisibleDuration = 1.6;
static CGFloat const kMirrorToastHorizontalInset = 24;
static CGFloat const kMirrorToastTopSpacing = 10;
static CGFloat const kMirrorToastVerticalPadding = 10;
static CGFloat const kMirrorToastHorizontalPadding = 16;
static CGFloat const kMirrorToastMaxWidthRatio = 0.86;
static NSInteger const kMirrorToastViewTag = 240926;

@implementation MirrorToast

+ (void)showWithText:(NSString *)text
{
    UIWindow *window = MirrorKeyWindow();
    if (!window) {
        return;
    }
    [self showWithText:text inView:window];
}

+ (void)showWithText:(NSString *)text inView:(UIView *)view
{
    NSString *message = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (message.length == 0 || view == nil) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self removeExistingToastInView:view];
        UIView *toastView = [self toastViewWithText:message constrainedToView:view];
        [view addSubview:toastView];
        [self layoutToastView:toastView inView:view];
        [self animateToastView:toastView];
    });
}

+ (UIView *)toastViewWithText:(NSString *)text constrainedToView:(UIView *)view
{
    UIView *container = [UIView new];
    container.tag = kMirrorToastViewTag;
    container.userInteractionEnabled = NO;
    container.alpha = 0;
    container.transform = CGAffineTransformMakeTranslation(0, -12);
    container.layer.cornerRadius = 16;
    container.layer.masksToBounds = YES;
    container.backgroundColor = [[UIColor mirrorColorNamed:MirrorColorTypeText] colorWithAlphaComponent:0.82];

    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont mirrorHintFont];
    label.textColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    label.tag = 1;
    [container addSubview:label];

    CGFloat maxWidth = CGRectGetWidth(view.bounds) * kMirrorToastMaxWidthRatio - 2*kMirrorToastHorizontalPadding;
    CGSize labelSize = [label sizeThatFits:CGSizeMake(maxWidth, CGFLOAT_MAX)];
    CGFloat width = MIN(MAX(labelSize.width + 2*kMirrorToastHorizontalPadding, 96), CGRectGetWidth(view.bounds) - 2*kMirrorToastHorizontalInset);
    CGFloat height = MAX(labelSize.height + 2*kMirrorToastVerticalPadding, 38);
    container.bounds = CGRectMake(0, 0, width, height);
    label.frame = CGRectInset(container.bounds, kMirrorToastHorizontalPadding, kMirrorToastVerticalPadding);
    return container;
}

+ (void)layoutToastView:(UIView *)toastView inView:(UIView *)view
{
    UIEdgeInsets safeAreaInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        safeAreaInsets = view.safeAreaInsets;
    }
    CGFloat top = safeAreaInsets.top + kMirrorToastTopSpacing;
    toastView.center = CGPointMake(CGRectGetMidX(view.bounds), top + CGRectGetHeight(toastView.bounds) / 2.0);
}

+ (void)animateToastView:(UIView *)toastView
{
    [UIView animateWithDuration:kMirrorToastFadeDuration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toastView.alpha = 1;
        toastView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:kMirrorToastFadeDuration delay:kMirrorToastVisibleDuration options:UIViewAnimationOptionCurveEaseIn animations:^{
            toastView.alpha = 0;
            toastView.transform = CGAffineTransformMakeTranslation(0, -10);
        } completion:^(BOOL finished) {
            [toastView removeFromSuperview];
        }];
    }];
}

+ (void)removeExistingToastInView:(UIView *)view
{
    UIView *existingToast = [view viewWithTag:kMirrorToastViewTag];
    if (!existingToast) {
        return;
    }
    [existingToast.layer removeAllAnimations];
    [existingToast removeFromSuperview];
}

@end
