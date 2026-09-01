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
#import "UIImage+MirrorSymbol.h"
#import "MirrorMacro.h"

static CGFloat const kShadowWidth = 5;
static CGFloat const kCornerRadius = 14;
static CGFloat const kActionButtonSpacing = 4;

#define kActionButtonSize (32*kWidthRatio)
#define kActionButtonLeadingInset (5*kWidthRatio)

@interface TimeTrackerTaskCollectionViewCell ()

@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) MASConstraint *taskNameCenterXConstraint;
@property (nonatomic, strong) MASConstraint *hintCenterXConstraint;
@property (nonatomic, strong) UIColor *selectedBorderColor;
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
    self.selectedBorderColor = [UIColor mirrorColorPulsed:task.color];
    self.contentView.backgroundColor = taskColor;
    self.contentView.layer.borderColor = self.selectedBorderColor.CGColor;
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
    self.contentView.layer.borderWidth = 0;
    self.contentView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
    self.contentView.layer.shadowRadius = kShadowWidth / 2;
    self.contentView.layer.shadowOpacity = 0.2;

    [self.contentView addSubview:self.deleteButton];
    [self.contentView addSubview:self.editButton];
    [self.contentView addSubview:self.taskNameLabel];
    [self.contentView addSubview:self.hintLabel];
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.contentView).offset(kActionButtonLeadingInset);
        make.bottom.mas_equalTo(self.contentView.mas_centerY).offset(-kActionButtonSpacing / 2);
        make.width.height.mas_equalTo(kActionButtonSize);
    }];
    [self.editButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.deleteButton);
        make.top.mas_equalTo(self.contentView.mas_centerY).offset(kActionButtonSpacing / 2);
        make.width.height.mas_equalTo(kActionButtonSize);
    }];
    [self.taskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        self.taskNameCenterXConstraint = make.centerX.mas_equalTo(self.contentView);
        make.centerY.mas_equalTo(self.contentView).offset(-8);
        make.width.lessThanOrEqualTo(self.contentView).offset(-62);
    }];
    [self.hintLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.taskNameLabel.mas_bottom).offset(8);
        self.hintCenterXConstraint = make.centerX.mas_equalTo(self.contentView);
        make.width.lessThanOrEqualTo(self.contentView).offset(-62);
    }];

    [self setActionButtonsVisible:NO animated:NO];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.isShowingActionButtons) {
        CGFloat textShift = [self textShiftWhenActionsVisible];
        [self.taskNameCenterXConstraint setOffset:textShift];
        [self.hintCenterXConstraint setOffset:textShift];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self setEditingModeEnabled:NO animated:NO];
    [self setActionButtonsVisible:NO animated:NO];
    [self setReorderSelected:NO animated:NO];
}

- (CGFloat)textShiftWhenActionsVisible
{
    return MAX((kActionButtonLeadingInset + kActionButtonSize) / 2.0, 0);
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

- (void)setEditingModeEnabled:(BOOL)editingModeEnabled
{
    [self setEditingModeEnabled:editingModeEnabled animated:NO];
}

- (void)setEditingModeEnabled:(BOOL)editingModeEnabled animated:(BOOL)animated
{
    self.isEditingModeEnabled = editingModeEnabled;
    if (editingModeEnabled) {
        [self setActionButtonsVisible:YES animated:animated];
    } else {
        [self setActionButtonsVisible:NO animated:animated];
    }
}

- (void)setActionButtonsVisible:(BOOL)visible animated:(BOOL)animated
{
    CGFloat expectedAlpha = visible ? 1 : 0;
    if (self.isShowingActionButtons == visible && self.deleteButton.alpha == expectedAlpha && self.editButton.alpha == expectedAlpha) {
        return;
    }

    self.isShowingActionButtons = visible;
    void (^stateChange)(void) = ^{
        self.deleteButton.alpha = visible ? 1 : 0;
        self.editButton.alpha = visible ? 1 : 0;
        self.deleteButton.userInteractionEnabled = visible;
        self.editButton.userInteractionEnabled = visible;
        self.deleteButton.transform = visible ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.72, 0.72);
        self.editButton.transform = visible ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.72, 0.72);
        CGFloat textShift = visible ? [self textShiftWhenActionsVisible] : 0;
        [self.taskNameCenterXConstraint setOffset:textShift];
        [self.hintCenterXConstraint setOffset:textShift];
        [self.contentView layoutIfNeeded];
    };

    if (!animated) {
        stateChange();
        return;
    }

    [self.contentView layoutIfNeeded];
    [UIView animateWithDuration:0.24
                          delay:0
         usingSpringWithDamping:0.82
          initialSpringVelocity:0.35
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
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

- (void)setReorderSelected:(BOOL)selected animated:(BOOL)animated
{
    void (^stateChange)(void) = ^{
        self.contentView.layer.borderWidth = selected ? 2.5 : 0;
        self.contentView.layer.borderColor = (self.selectedBorderColor ?: [UIColor mirrorColorNamed:MirrorColorTypeText]).CGColor;
    };

    if (!animated) {
        stateChange();
        return;
    }

    [UIView animateWithDuration:0.16
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:stateChange
                     completion:nil];
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

- (UIButton *)editButton
{
    if (!_editButton) {
        _editButton = [UIButton new];
        _editButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _editButton.accessibilityLabel = [MirrorLanguage mirror_stringWithKey:@"edit"];
        [_editButton setImage:[UIImage mirror_systemImageNamed:@"pencil" fallbackName:@"pencil"] forState:UIControlStateNormal];
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
        [_deleteButton setImage:[UIImage mirror_systemImageNamed:@"xmark" fallbackName:@"trash"] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(tapDeleteButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

@end
