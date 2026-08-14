//
//  HintFooter.m
//  Mirror
//
//  Created by Yuqing Wang on 2024/3/9.
//

#import "HintFooter.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "MirrorLanguage.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"

static NSTimeInterval const kHintFooterRotationInterval = 5.0;

@interface HintFooter ()

@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) NSArray<NSString *> *hints;
@property (nonatomic, strong) NSTimer *hintTimer;
@property (nonatomic, assign) NSInteger currentHintIndex;
@property (nonatomic, assign) BOOL didSetupUI;

@end

@implementation HintFooter

- (void)config
{
    [self p_setupUIIfNeeded];
    self.hints = @[[MirrorLanguage mirror_stringWithKey:@"timeVC_hint0"],
                   [MirrorLanguage mirror_stringWithKey:@"timeVC_hint1"],
                   [MirrorLanguage mirror_stringWithKey:@"timeVC_hint2"],
                   [MirrorLanguage mirror_stringWithKey:@"timeVC_hint3"],
                   [MirrorLanguage mirror_stringWithKey:@"timeVC_hint4"]];
    self.currentHintIndex = 0;
    [self updateHintAnimated:NO];
    [self startHintTimer];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self stopHintTimer];
}

- (void)dealloc
{
    [self stopHintTimer];
}

#pragma mark - Private methods

- (void)p_setupUIIfNeeded
{
    if (self.didSetupUI) {
        return;
    }
    self.didSetupUI = YES;
    [self addSubview:self.hintLabel];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(10);
        make.right.offset(-10);
        make.top.offset(10*kHeightRatio); // 和下面的cell的距离 与 cell之间的距离保持一致
        make.height.mas_equalTo(20*kHeightRatio);
    }];
}

- (void)startHintTimer
{
    [self stopHintTimer];
    __weak typeof(self) weakSelf = self;
    self.hintTimer = [NSTimer scheduledTimerWithTimeInterval:kHintFooterRotationInterval repeats:YES block:^(NSTimer *timer) {
        [weakSelf showNextHint];
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.hintTimer forMode:NSRunLoopCommonModes];
}

- (void)stopHintTimer
{
    [self.hintTimer invalidate];
    self.hintTimer = nil;
}

- (void)showNextHint
{
    if (self.hints.count == 0) {
        return;
    }
    self.currentHintIndex = (self.currentHintIndex + 1) % self.hints.count;
    [self updateHintAnimated:YES];
}

- (void)updateHintAnimated:(BOOL)animated
{
    if (self.currentHintIndex >= self.hints.count) {
        return;
    }
    NSString *hint = self.hints[self.currentHintIndex];
    if (!animated) {
        self.hintLabel.text = hint;
        return;
    }
    [UIView transitionWithView:self.hintLabel duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.hintLabel.text = hint;
    } completion:nil];
}

- (UILabel *)hintLabel
{
    if (!_hintLabel) {
        _hintLabel = [UILabel new];
        _hintLabel.adjustsFontSizeToFitWidth = YES;
        _hintLabel.textAlignment = NSTextAlignmentLeft;
        _hintLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _hintLabel.font = [UIFont mirrorMinFont];
    }
    return _hintLabel;
}



@end
