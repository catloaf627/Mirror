//
//  LeftAnimation.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/18.
//

#import "LeftAnimation.h"
#import "MirrorMacro.h"

@implementation LeftAnimation

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext{
    return .3f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext{
    
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    UIView* toView = nil;
    UIView* fromView = nil;
    UIView* transView = nil;
    
    if ([transitionContext respondsToSelector:@selector(viewForKey:)]) {
        fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
        toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    } else {
        fromView = fromViewController.view;
        toView = toViewController.view;
    }
    
    if (_isPresent) {  // present
        transView = toView;
        [[transitionContext containerView] addSubview:toView];
        
    } else {  // dismiss
        transView = fromView;
        [[transitionContext containerView] insertSubview:toView belowSubview:fromView];
    }
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    CGFloat sheetWidth = width * kLeftSheetRatio;
    
    if (_isPresent) { // present
        transView.frame = CGRectMake(-sheetWidth, 0, sheetWidth, height);
        [transitionContext containerView].backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            transView.frame = CGRectMake(0, 0, sheetWidth, height);
            [transitionContext containerView].backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        } completion:^(BOOL finished) {
             [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    } else { // dismiss
        transView.frame = CGRectMake(0, 0, sheetWidth, height);
        [transitionContext containerView].backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            transView.frame = CGRectMake(-sheetWidth, 0, sheetWidth, height);
            [transitionContext containerView].backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];
        } completion:^(BOOL finished) {
             [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    }

    
    
}


@end
