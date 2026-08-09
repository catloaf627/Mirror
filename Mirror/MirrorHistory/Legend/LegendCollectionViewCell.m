//
//  LegendCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/15.
//

#import "LegendCollectionViewCell.h"
#import <Masonry/Masonry.h>
#import "MirrorStorage.h"
#import "MirrorTaskModel.h"
#import "UIFont+MirrorFont.h"
static CGFloat const kPadding = 10;

@interface LegendCollectionViewCell ()

@property (nonatomic, strong) UIView *coloredView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation LegendCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCellWithTaskname:(NSString *)taskName
{
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:taskName];
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 4; // 背景色twinkle的时候有点弧度好看
    [self addSubview:self.coloredView];
    self.coloredView.backgroundColor = [UIColor mirrorColorNamed:task.color];
    self.coloredView.layer.borderColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground].CGColor;
    self.coloredView.layer.borderWidth = 2;
    [self.coloredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@20);
        make.centerY.offset(0);
        make.left.offset(kPadding);
    }];
    
    [self addSubview:self.label];
    self.label.textColor = [UIColor mirrorColorNamed: [UIColor mirror_getPulseColorType:task.color]];
    self.label.text = task.taskName;
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@20);
        make.centerY.offset(0);
        make.left.mas_equalTo(self.coloredView.mas_right).offset(kPadding);
        make.right.offset(-kPadding);
    }];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.coloredView.transform = CGAffineTransformIdentity;
}

- (void)animateColorSquareSelection
{
    self.coloredView.transform = CGAffineTransformIdentity;
    [UIView animateKeyframesWithDuration:1.0 delay:0 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.2 animations:^{
            self.coloredView.transform = CGAffineTransformMakeScale(1.8, 1.8);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.2 relativeDuration:0.2 animations:^{
            self.coloredView.transform = CGAffineTransformMakeScale(1.15, 1.15);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.4 relativeDuration:0.2 animations:^{
            self.coloredView.transform = CGAffineTransformMakeScale(1.6, 1.6);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.6 relativeDuration:0.4 animations:^{
            self.coloredView.transform = CGAffineTransformIdentity;
        }];
    } completion:nil];
}

- (UIView *)coloredView
{
    if (!_coloredView) {
        _coloredView = [UIView new];
    }
    return _coloredView;
}

- (UILabel *)label
{
    if (!_label) {
        _label = [UILabel new];
        _label.font = [UIFont mirrorLabelFont];
    }
    return _label;
}

@end
