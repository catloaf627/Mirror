//
//  MirrorNaviManager.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/29.
//

#import "MirrorNaviManager.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"

static CGFloat const kCollectionViewPadding = 20; // 左右留白
static CGFloat const kNaviIconPointSize = 23;

@interface MirrorNaviManager ()

@property (nonatomic, strong) UINavigationController *controller;

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIView *rightButton;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation MirrorNaviManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static MirrorNaviManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[MirrorNaviManager alloc]init];
    });
    return instance;
}

- (UINavigationController *)mirrorNaviControllerWithRootViewController:tabbarController
{
    if (!_controller) {
        _controller = [[UINavigationController alloc] initWithRootViewController:tabbarController];
        [_controller.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
        _controller.navigationBar.shadowImage = [UIImage new];
    }
    return _controller;
}

- (void)updateNaviItemWithTitle:(NSString *)title leftButton:(nullable UIButton *)leftButton rightButton:(nullable UIView *)rightButton
{
    // 抹干净画布 重新开始
    [self.titleLabel removeFromSuperview];
    [self.leftButton removeFromSuperview];
    [self.rightButton removeFromSuperview];

    _controller.navigationBar.topItem.title = @""; // 不要在二级页上出现"Back"
    _controller.navigationBar.titleTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor clearColor], NSForegroundColorAttributeName, nil]; // 系统title 颜色
    _controller.navigationBar.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText]; // baritem 颜色
    _titleLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText]; // title label 颜色
    
    self.titleLabel.text = title;
    self.leftButton = leftButton;
    self.rightButton = rightButton;
    [self applyIconConfigurationToView:self.leftButton];
    [self applyIconConfigurationToView:self.rightButton];
    
    // 固定写死的布局
    [_controller.navigationBar addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.offset(0);
        make.width.mas_equalTo(_controller.navigationBar.frame.size.width/2);
        make.height.mas_equalTo(_controller.navigationBar.frame.size.height);
    }];
    if (leftButton) {
        [_controller.navigationBar addSubview:self.leftButton];
        [self.leftButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(kCollectionViewPadding);
            make.centerY.offset(0);
            make.width.height.mas_equalTo(_controller.navigationBar.frame.size.height);
        }];
    }
    if (rightButton) {
        [_controller.navigationBar addSubview:self.rightButton];
        [self.rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.offset(-kCollectionViewPadding);
            make.centerY.offset(0);
            make.height.mas_equalTo(_controller.navigationBar.frame.size.height);
            make.width.mas_equalTo(MAX(_controller.navigationBar.frame.size.height, self.rightButton.frame.size.width));
        }];
    }
}

- (void)applyIconConfigurationToView:(UIView *)view
{
    if (!view) {
        return;
    }

    if ([view isKindOfClass:UIButton.class]) {
        UIButton *button = (UIButton *)view;
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:kNaviIconPointSize weight:UIImageSymbolWeightRegular];
            [button setPreferredSymbolConfiguration:configuration forImageInState:UIControlStateNormal];
            [button setPreferredSymbolConfiguration:configuration forImageInState:UIControlStateHighlighted];
            [button setPreferredSymbolConfiguration:configuration forImageInState:UIControlStateSelected];
        }
        button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }

    for (UIView *subview in view.subviews) {
        [self applyIconConfigurationToView:subview];
    }
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.numberOfLines = 1;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont mirrorTitleFont];
    }
    return _titleLabel;
}

- (UIButton *)leftButton
{
    if (!_leftButton) {
        _leftButton = [UIButton new];
        _leftButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    }
    return _leftButton;
}

- (UIView *)rightButton
{
    if (!_rightButton) {
        _rightButton = [UIView new];
    }
    return _rightButton;
}

@end
