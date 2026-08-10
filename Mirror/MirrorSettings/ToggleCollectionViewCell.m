//
//  ToggleCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/10/24.
//

#import "ToggleCollectionViewCell.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "MirrorMacro.h"
#import "UIFont+MirrorFont.h"

@interface ToggleCollectionViewCell ()

@property (nonatomic, strong) UILabel *label;

@end

@implementation ToggleCollectionViewCell

- (void)configCellWithTitle:(NSString *)title color:(MirrorColorType)color
{
    self.contentView.backgroundColor = [UIColor mirrorColorNamed:color];
    self.contentView.layer.cornerRadius = 14;
    self.toggle.onTintColor = [UIColor mirrorColorPulsed:color]; // toggle颜色使用pulse
    self.label.text = [MirrorLanguage mirror_stringWithKey:title];
    
    [self.contentView addSubview:self.toggle];
    [self.toggle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.offset(0);
        make.right.offset(0); // toggle 有re-scale，右边会自动空出间距
    }];
    [self.contentView addSubview:self.label];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.offset(0);
        make.left.offset(12);
        float toggleWidth = 51;
        make.width.mas_lessThanOrEqualTo(kScreenWidth*kLeftSheetRatio - 15*2  - 12  - 5 - toggleWidth);
    }];
}

- (UILabel *)label
{
    if (!_label) {
        _label = [UILabel new];
        _label.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _label.font = [UIFont mirrorLabelFont];
        _label.adjustsFontSizeToFitWidth = YES;
    }
    return _label;
}

- (UISwitch *)toggle
{
    if (!_toggle) {
        _toggle = [UISwitch new];
        _toggle.transform = CGAffineTransformMakeScale(kLeftSheetRatio, kLeftSheetRatio);
    }
    return _toggle;
}


@end
