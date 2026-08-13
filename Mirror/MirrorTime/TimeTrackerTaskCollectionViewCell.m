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
static CGFloat const kCornerRadius = 14;
static NSString * const kEditingShakeAnimationKey = @"MirrorEditingShakeAnimation";

@interface TimeTrackerTaskCollectionViewCell ()

@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *mergeButton;
@property (nonatomic, assign) BOOL didSetupUI;
@property (nonatomic, assign) BOOL isEditingModeEnabled;
@property (nonatomic, assign) BOOL isShowingActionButtons;

@end

@implementation TimeTrackerTaskCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configWithTaskname:(NSString *)taskName
{
    [self p_setupUI];
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:taskName];
    UIColor *taskColor = [UIColor mirrorColorNamed:task.color];
    self.taskNameLabel.text = taskName;
    self.hintLabel.text = [MirrorTimeText Xh:[MirrorTool getTotalTimeOfPeriods:[MirrorStorage getAllTaskRecords:taskName]]];
    self.taskNameLabel.textColor = [UIColor mirrorColorPulsed:task.color];
    self.contentView.backgroundColor = taskColor;
    self.backView.backgroundColor = taskColor;
    self.backView.layer.borderColor = [UIColor mirrorColorPulsed:task.color].CGColor;
}

- (void)p_setupUI
{
    if (self.didSetupUI) {
        return;
    }
    self.didSetupUI = YES;

    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = NO;

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(kShadowWidth);
        make.right.offset(-kShadowWidth);
        make.top.offset(kShadowWidth);
        make.bottom.offset(-kShadowWidth);
    }];
    self.contentView.layer.cornerRadius = kCornerRadius;
    self.contentView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
    self.contentView.layer.shadowRadius = kShadowWidth / 2;
    self.contentView.layer.shadowOpacity = 0.2;

    [self addSubview:self.backView];
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.contentView);
    }];
    self.backView.hidden = YES;

    [self.contentView addSubview:self.taskNameLabel];
    [self.contentView addSubview:self.hintLabel];
    [self.taskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.contentView);
        make.centerY.mas_equalTo(self.contentView).offset(-8);
        make.left.offset(8);
        make.right.offset(-8);
    }];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.taskNameLabel.mas_bottom).offset(8);
        make.centerX.mas_equalTo(self.contentView);
        make.left.offset(8);
        make.right.offset(-8);
    }];

    [self.backView addSubview:self.deleteButton];
    [self.backView addSubview:self.mergeButton];
    [self.backView addSubview:self.editButton];
    [self.mergeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.backView);
        make.width.height.mas_equalTo(32);
    }];
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mergeButton);
        make.right.mas_equalTo(self.mergeButton.mas_left).offset(-18);
        make.width.height.mas_equalTo(32);
    }];
    [self.editButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.mergeButton);
        make.left.mas_equalTo(self.mergeButton.mas_right).offset(18);
        make.width.height.mas_equalTo(32);
    }];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setEditingModeEnabled:NO animated:NO];
    [self setActionButtonsVisible:NO animated:NO];
}

#pragma mark - Actions

- (void)tapEditButton
{
    [self.delegate timeTrackerTaskCollectionViewCellDidTapEdit:self];
}

- (void)tapDeleteButton
{
    [self.delegate timeTrackerTaskCollectionViewCellDidTapDelete:self];
}

- (void)tapMergeButton
{
    [self.delegate timeTrackerTaskCollectionViewCellDidTapMerge:self];
}

- (void)setEditingModeEnabled:(BOOL)editingModeEnabled
{
    [self setEditingModeEnabled:editingModeEnabled animated:NO];
}

- (void)setEditingModeEnabled:(BOOL)editingModeEnabled animated:(BOOL)animated
{
    self.isEditingModeEnabled = editingModeEnabled;
    if (editingModeEnabled) {
        [self startEditingShakeAnimation];
    } else {
        [self stopEditingShakeAnimation];
        [self setActionButtonsVisible:NO animated:animated];
    }
}

- (void)setActionButtonsVisible:(BOOL)visible animated:(BOOL)animated
{
    BOOL currentlyVisible = !self.backView.hidden;
    if (currentlyVisible == visible && self.isShowingActionButtons == visible) {
        return;
    }

    self.isShowingActionButtons = visible;
    UIViewAnimationOptions direction = visible ? UIViewAnimationOptionTransitionFlipFromRight : UIViewAnimationOptionTransitionFlipFromLeft;
    void (^stateChange)(void) = ^{
        self.contentView.hidden = visible;
        self.backView.hidden = !visible;
    };

    if (!animated || currentlyVisible == visible) {
        stateChange();
        return;
    }

    [UIView transitionWithView:self
                      duration:0.28
                       options:direction | UIViewAnimationOptionAllowUserInteraction
                    animations:stateChange
                    completion:nil];
}

- (BOOL)dismissActionButtonsIfNeeded
{
    if (!self.isShowingActionButtons) {
        return NO;
    }
    [self setActionButtonsVisible:NO animated:YES];
    return YES;
}

- (void)startEditingShakeAnimation
{
    if ([self.layer animationForKey:kEditingShakeAnimationKey]) {
        return;
    }

    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.values = @[@(-0.035), @(0.035), @(-0.028)];
    animation.duration = 0.14;
    animation.repeatCount = HUGE_VALF;
    animation.autoreverses = YES;
    animation.timeOffset = (arc4random_uniform(100) / 100.0) * animation.duration;
    [self.layer addAnimation:animation forKey:kEditingShakeAnimationKey];
}

- (void)stopEditingShakeAnimation
{
    [self.layer removeAnimationForKey:kEditingShakeAnimationKey];
    self.transform = CGAffineTransformIdentity;
}

#pragma mark - Getters

- (UILabel *)taskNameLabel
{
    if (!_taskNameLabel) {
        _taskNameLabel = [[UILabel alloc] init];
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

- (UIView *)backView
{
    if (!_backView) {
        _backView = [UIView new];
        _backView.layer.cornerRadius = kCornerRadius;
        _backView.layer.borderWidth = 1.5;
        _backView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
        _backView.layer.shadowRadius = kShadowWidth / 2;
        _backView.layer.shadowOpacity = 0.2;
    }
    return _backView;
}

- (UIButton *)editButton
{
    if (!_editButton) {
        _editButton = [UIButton new];
        _editButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _editButton.accessibilityLabel = [MirrorLanguage mirror_stringWithKey:@"edit"];
        [_editButton setImage:[UIImage systemImageNamed:@"pencil"] forState:UIControlStateNormal];
        [_editButton addTarget:self action:@selector(tapEditButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _editButton;
}

- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [UIButton new];
        _deleteButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _deleteButton.accessibilityLabel = [MirrorLanguage mirror_stringWithKey:@"delete"];
        [_deleteButton setImage:[UIImage systemImageNamed:@"trash"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(tapDeleteButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (UIButton *)mergeButton
{
    if (!_mergeButton) {
        _mergeButton = [UIButton new];
        _mergeButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _mergeButton.accessibilityLabel = [MirrorLanguage mirror_stringWithKey:@"merge"];
        [_mergeButton setImage:[UIImage systemImageNamed:@"inset.filled.righthalf.arrow.right.rectangle"] forState:UIControlStateNormal];
        [_mergeButton addTarget:self action:@selector(tapMergeButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mergeButton;
}

@end
