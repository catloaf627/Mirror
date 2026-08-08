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

@interface MirrorNaviManager ()

@property (nonatomic, strong) UINavigationController *controller;

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;
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

- (void)updateNaviItemWithTitle:(NSString *)title leftButton:(nullable UIButton *)leftButton rightButton:(nullable UIButton *)rightButton
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
            make.width.height.mas_equalTo(_controller.navigationBar.frame.size.height);
        }];
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

- (UIButton *)rightButton
{
    if (!_rightButton) {
        _rightButton = [UIButton new];
        _rightButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    }
    return _rightButton;
}

@end
