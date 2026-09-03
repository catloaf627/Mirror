//
//  MirrorRecordWindow.m
//  Mirror
//

#import "MirrorRecordWindow.h"

@interface MirrorRecordWindow ()

@property (nonatomic, strong) NSMapTable<UITouch *, UIView *> *tapDotViews;

@end

@implementation MirrorRecordWindow

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupTapDotViews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupTapDotViews];
    }
    return self;
}

- (void)setupTapDotViews
{
    self.tapDotViews = [NSMapTable weakToStrongObjectsMapTable];
}

- (void)sendEvent:(UIEvent *)event
{
    [super sendEvent:event];

    if (event.type != UIEventTypeTouches) {
        return;
    }

    for (UITouch *touch in event.allTouches) {
        CGPoint point = [touch locationInView:self];
        switch (touch.phase) {
            case UITouchPhaseBegan:
                [self showTapDotForTouch:touch atPoint:point];
                break;
            case UITouchPhaseMoved:
            case UITouchPhaseStationary:
                [self updateTapDotForTouch:touch atPoint:point];
                break;
            case UITouchPhaseEnded:
            case UITouchPhaseCancelled:
                [self hideTapDotForTouch:touch atPoint:point];
                break;
        }
    }
}

- (void)showTapDotForTouch:(UITouch *)touch atPoint:(CGPoint)point
{
    UIView *existingDotView = [self.tapDotViews objectForKey:touch];
    if (existingDotView) {
        existingDotView.center = point;
        return;
    }

    CGFloat dotSize = 28;
    UIView *dotView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, dotSize, dotSize)];
    dotView.center = point;
    dotView.alpha = 0;
    dotView.backgroundColor = [UIColor colorWithRed:0.38 green:0.72 blue:1 alpha:0.36];
    dotView.layer.cornerRadius = dotSize / 2;
    dotView.layer.borderWidth = 2;
    dotView.layer.borderColor = [UIColor colorWithRed:0.2 green:0.58 blue:1 alpha:0.85].CGColor;
    dotView.layer.shadowColor = [UIColor colorWithRed:0.08 green:0.28 blue:0.75 alpha:1].CGColor;
    dotView.layer.shadowOpacity = 0.35;
    dotView.layer.shadowRadius = 4;
    dotView.layer.shadowOffset = CGSizeZero;
    dotView.userInteractionEnabled = NO;
    dotView.transform = CGAffineTransformMakeScale(0.75, 0.75);
    [self addSubview:dotView];
    [self.tapDotViews setObject:dotView forKey:touch];

    [UIView animateWithDuration:0.12 animations:^{
        dotView.alpha = 1;
        dotView.transform = CGAffineTransformIdentity;
    }];
}

- (void)updateTapDotForTouch:(UITouch *)touch atPoint:(CGPoint)point
{
    UIView *dotView = [self.tapDotViews objectForKey:touch];
    dotView.center = point;
}

- (void)hideTapDotForTouch:(UITouch *)touch atPoint:(CGPoint)point
{
    UIView *dotView = [self.tapDotViews objectForKey:touch];
    if (!dotView) {
        return;
    }

    dotView.center = point;
    [self.tapDotViews removeObjectForKey:touch];

    [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        dotView.alpha = 0;
        dotView.transform = CGAffineTransformMakeScale(1.45, 1.45);
    } completion:^(BOOL finished) {
        [dotView removeFromSuperview];
    }];
}

@end
