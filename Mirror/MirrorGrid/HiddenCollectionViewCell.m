//
//  HiddenCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/27.
//

#import "HiddenCollectionViewCell.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorStorage.h"
#import "MirrorTaskModel.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"

#define kPadding (10*kWidthRatio)

@interface HiddenCollectionViewCell ()

@property (nonatomic, strong) UIImageView *checkMark;
@property (nonatomic, strong) UIView *coloredView;
@property (nonatomic, strong) UILabel *label;

@end

@implementation HiddenCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCellWithTaskname:(NSString *)taskName
{
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:taskName];
    [self addSubview:self.coloredView];
    self.coloredView.backgroundColor = [UIColor mirrorColorNamed:task.color];
    self.coloredView.layer.borderColor = [UIColor mirrorColorNamed: [UIColor mirror_getPulseColorType:task.color]].CGColor;
    self.coloredView.layer.borderWidth = 2;
    [self.coloredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@20);
        make.centerY.offset(0);
        make.left.offset(kPadding);
    }];
    
    [self.coloredView addSubview:self.checkMark];
    self.checkMark.tintColor = [UIColor mirrorColorNamed: [UIColor mirror_getPulseColorType:task.color]];
    [self.checkMark mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.offset(0);
    }];
    self.checkMark.hidden = task.isHidden;
    
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

- (UIImageView *)checkMark
{
    if (!_checkMark) {
        UIImage *image = [[UIImage systemImageNamed:@"checkmark"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _checkMark = [[UIImageView alloc] initWithImage:image];
    }
    return _checkMark;
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
        _label.adjustsFontSizeToFitWidth = YES;
        _label.font = [UIFont mirrorLabelFont];
    }
    return _label;
}

@end
