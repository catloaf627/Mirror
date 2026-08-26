//
//  TimeTrackerAddTaskCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/28.
//

#import "TimeTrackerAddTaskCollectionViewCell.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "UIImage+MirrorSymbol.h"

static CGFloat const kShadowWidth = 5;

@interface TimeTrackerAddTaskCollectionViewCell ()

@property (nonatomic, strong) UIImageView *addIconView;

@end

@implementation TimeTrackerAddTaskCollectionViewCell

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)setupAddTaskCell
{
    [self p_setupUI];
}

- (void)p_setupUI
{
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(kShadowWidth);
        make.right.offset(-kShadowWidth);
        make.top.offset(kShadowWidth);
        make.bottom.offset(-kShadowWidth);
    }];
    self.contentView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    self.contentView.layer.cornerRadius = 14;
    [self.contentView addSubview:self.addIconView];
    [self.addIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.offset(0);
        make.width.mas_equalTo(50);
        make.height.mas_equalTo(50);
    }];
}

#pragma mark - Getters

- (UIImageView *)addIconView
{
    if (!_addIconView) {
        UIImage *image = [[UIImage mirror_systemImageNamed:@"plus" fallbackName:@"plus"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _addIconView = [[UIImageView alloc]initWithImage:image];
        [_addIconView setTintColor:[UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellPlus]];
    }
    return _addIconView;
}


@end
