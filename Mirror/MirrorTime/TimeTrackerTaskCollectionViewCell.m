//
//  TimeTrackerTaskCollectionViewCell.m
//  Mirror
//
//  Created by wangyuqing on 2022/9/26.
//

#import "TimeTrackerTaskCollectionViewCell.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "MirrorLanguage.h"
#import "MirrorStorage.h"
#import "MirrorSettings.h"
#import "MirrorTimeText.h"
#import "MirrorTool.h"
#import "UIFont+MirrorFont.h"

static CGFloat const kShadowWidth = 5;

@interface TimeTrackerTaskCollectionViewCell ()

@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) UILabel *hintLabel;

@end

@implementation TimeTrackerTaskCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configWithTaskname:(NSString *)taskName
{
    self.taskNameLabel.text = taskName;
    self.hintLabel.text = [MirrorTimeText Xh: [MirrorTool getTotalTimeOfPeriods:[MirrorStorage getAllTaskRecords:taskName]]];
    self.contentView.backgroundColor = [UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:taskName].color];

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
    self.contentView.layer.cornerRadius = 14;
    self.contentView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
    self.contentView.layer.shadowRadius = kShadowWidth/2;
    self.contentView.layer.shadowOpacity = 0.2;
    
    [self.contentView addSubview:self.taskNameLabel];
    [self.contentView addSubview:self.hintLabel];
    [self.taskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self);
        make.centerY.mas_equalTo(self).offset(-8);
        make.left.offset(8);
        make.right.offset(-8);
    }];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.taskNameLabel.mas_bottom).offset(8);
        make.centerX.mas_equalTo(self);
        make.left.offset(8);
        make.right.offset(-8);
    }];
}

#pragma mark - Getters

- (UILabel *)taskNameLabel
{
    if (!_taskNameLabel) {
        _taskNameLabel = [[UILabel alloc] init];
        _taskNameLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _taskNameLabel.numberOfLines = 1;
        _taskNameLabel.textAlignment = NSTextAlignmentCenter;
        _taskNameLabel.font = [UIFont mirrorTitleFont_Card];
    }
    return _taskNameLabel;
}

- (UILabel *)hintLabel
{
    if (!_hintLabel) {
        _hintLabel = [[UILabel alloc] init];
        _hintLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _hintLabel.numberOfLines = 1;
        _hintLabel.textAlignment = NSTextAlignmentCenter;
        _hintLabel.font = [UIFont mirrorHintFont_Card];
    }
    return _hintLabel;
}

@end
