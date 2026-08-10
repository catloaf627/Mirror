//
//  CellAnimation.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/24.
//

#import "CellAnimation.h"
#import "UIColor+MirrorColor.h"

static CGFloat const kShadowWidth = 5;

@implementation CellAnimation

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
    
    if (_isPresent) { // present
        UIColor *originalBackgroundColor = transView.backgroundColor;
        transView.backgroundColor = self.cellColor ?: originalBackgroundColor;
        transView.frame = CGRectMake(self.cellFrame.origin.x + kShadowWidth, self.cellFrame.origin.y + kShadowWidth, self.cellFrame.size.width - 2*kShadowWidth, self.cellFrame.size.height - 2*kShadowWidth);
        transView.layer.cornerRadius = 14;
        transView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
        transView.layer.shadowRadius = kShadowWidth/2;
        transView.layer.shadowOpacity = 1;
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            transView.frame = CGRectMake(0, 0, width, height);
            transView.backgroundColor = originalBackgroundColor;
            transView.layer.cornerRadius = 0;
            transView.layer.shadowColor = 0;
            transView.layer.shadowRadius = 0;
            transView.layer.shadowOpacity = 0;
        } completion:^(BOOL finished) {
             transView.backgroundColor = originalBackgroundColor;
             [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    } else { // dismiss
        UIColor *originalBackgroundColor = transView.backgroundColor;
        UIView *animationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        animationView.backgroundColor = originalBackgroundColor;
        animationView.clipsToBounds = YES;
        animationView.layer.cornerRadius = 0;
        animationView.layer.shadowColor = 0;
        animationView.layer.shadowRadius = 0;
        animationView.layer.shadowOpacity = 0;
        [[transitionContext containerView] addSubview:animationView];
        
        [transView layoutIfNeeded];
        for (UIView *subview in transView.subviews) {
            UIView *snapshotView = [subview snapshotViewAfterScreenUpdates:NO];
            snapshotView.frame = [subview convertRect:subview.bounds toView:transView];
            [animationView addSubview:snapshotView];
        }
        
        transView.frame = CGRectMake(0, 0, width, height);
        transView.transform = CGAffineTransformIdentity;
        transView.hidden = YES;
        [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
            animationView.frame = CGRectMake(self.cellFrame.origin.x + kShadowWidth, self.cellFrame.origin.y + kShadowWidth, self.cellFrame.size.width - 2*kShadowWidth, self.cellFrame.size.height - 2*kShadowWidth);
            animationView.backgroundColor = self.cellColor ?: originalBackgroundColor;
            animationView.layer.cornerRadius = 14;
            animationView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
            animationView.layer.shadowRadius = kShadowWidth/2;
            animationView.layer.shadowOpacity = 1;
        } completion:^(BOOL finished) {
             transView.hidden = NO;
             [animationView removeFromSuperview];
             [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        }];
    }
}


@end
