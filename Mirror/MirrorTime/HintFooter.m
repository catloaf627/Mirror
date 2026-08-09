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
@interface HintFooter ()

@property (nonatomic, strong) UILabel *hintLabel;

@end

@implementation HintFooter

- (void)config
{
    [self addSubview:self.hintLabel];
    NSArray *hints = @[[MirrorLanguage mirror_stringWithKey:@"timeVC_hint0"], [MirrorLanguage mirror_stringWithKey:@"timeVC_hint1"], [MirrorLanguage mirror_stringWithKey:@"timeVC_hint3"]];
    NSString *hint = hints[arc4random() % hints.count]; // 随机选一个hint
    self.hintLabel.text = hint;
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(10);
        make.right.offset(-10);
        make.top.offset(10*kHeightRatio); // 和下面的cell的距离 与 cell之间的距离保持一致
        make.height.mas_equalTo(20*kHeightRatio);
    }];
}


- (UILabel *)hintLabel
{
    if (!_hintLabel) {
        _hintLabel = [UILabel new];
        _hintLabel.adjustsFontSizeToFitWidth = YES;
        _hintLabel.textAlignment = NSTextAlignmentLeft;
        _hintLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _hintLabel.font = [UIFont mirrorHintFont];
    }
    return _hintLabel;
}



@end
