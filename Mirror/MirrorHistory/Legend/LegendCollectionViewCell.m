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
#import "UIColor+MirrorColor.h"
static CGFloat const kPadding = 10;
static NSTimeInterval const kLegendHighlightAnimationDuration = 0.3;

@interface LegendCollectionViewCell ()

@property (nonatomic, strong) UIView *coloredView;
@property (nonatomic, strong) UIImageView *checkMark;
@property (nonatomic, strong) UILabel *label;

@end

@implementation LegendCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCellWithTaskname:(NSString *)taskName
{
    [self configCellWithTaskname:taskName highlighted:NO];
}

- (void)configCellWithTaskname:(NSString *)taskName highlighted:(BOOL)highlighted
{
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:taskName];
    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = 6;
    self.layer.masksToBounds = YES;
    self.contentView.backgroundColor = [UIColor clearColor];
    [self setLegendHighlighted:highlighted taskName:taskName animated:NO];
    self.contentView.layer.cornerRadius = 6;
    self.contentView.layer.masksToBounds = YES;
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    [self.contentView addSubview:self.coloredView];
    self.coloredView.backgroundColor = task.isHidden ? [UIColor mirrorColorNamed:MirrorColorTypeBackground] : [UIColor mirrorColorNamed:task.color];
    self.coloredView.layer.borderColor = [UIColor mirrorColorPulsed:task.color].CGColor;
    self.coloredView.layer.borderWidth = 2;
    [self.coloredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@20);
        make.centerY.offset(0);
        make.left.offset(kPadding);
    }];
    
    [self.coloredView addSubview:self.checkMark];
    self.checkMark.hidden = task.isHidden;
    self.checkMark.tintColor = [UIColor mirrorColorPulsed:task.color];
    [self.checkMark mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.offset(0);
        make.width.height.equalTo(@20);
    }];
    
    [self.contentView addSubview:self.label];
    self.label.textColor = [UIColor mirrorColorPulsed:task.color];
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
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

- (void)setLegendHighlighted:(BOOL)highlighted taskName:(NSString *)taskName animated:(BOOL)animated
{
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:taskName];
    UIColor *highlightColor = highlighted && task ? [[UIColor mirrorColorNamed:task.color] colorWithAlphaComponent:1.0] : [UIColor clearColor];
    if (!animated) {
        self.backgroundColor = highlightColor;
        return;
    }

    [UIView animateWithDuration:kLegendHighlightAnimationDuration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.backgroundColor = highlightColor;
    } completion:nil];
}

- (UIView *)coloredView
{
    if (!_coloredView) {
        _coloredView = [UIView new];
    }
    return _coloredView;
}

- (UIImageView *)checkMark
{
    if (!_checkMark) {
        UIImage *image = [[UIImage systemImageNamed:@"checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _checkMark = [[UIImageView alloc] initWithImage:image];
        _checkMark.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _checkMark;
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
