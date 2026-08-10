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

@interface TimeTrackerTaskCollectionViewCell ()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) UILabel *hintLabel;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIButton *colorButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *mergeButton;
@property (nonatomic, assign) BOOL didSetupUI;

@end

@implementation TimeTrackerTaskCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configWithTaskname:(NSString *)taskName
{
    [self p_setupUI];
    self.taskNameLabel.text = taskName;
    self.hintLabel.text = [MirrorTimeText Xh: [MirrorTool getTotalTimeOfPeriods:[MirrorStorage getAllTaskRecords:taskName]]];
    self.contentView.backgroundColor = [UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:taskName].color];
}

- (void)p_setupUI
{
    if (self.didSetupUI) {
        return;
    }
    self.didSetupUI = YES;
    
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
    [self addSubview:self.deleteButton];
    [self addSubview:self.mergeButton];
    [self addSubview:self.editButton];
    [self addSubview:self.colorButton];
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.offset(kShadowWidth);
        make.width.mas_equalTo(self.mas_width).multipliedBy(0.5);
        make.height.mas_equalTo(self.mas_height).multipliedBy(0.5).offset(-kShadowWidth);
    }];
    [self.mergeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(kShadowWidth);
        make.top.mas_equalTo(self.deleteButton.mas_bottom);
        make.bottom.offset(-kShadowWidth);
        make.width.mas_equalTo(self.mas_width).multipliedBy(0.5);
    }];
    [self.editButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-kShadowWidth);
        make.top.offset(kShadowWidth);
        make.width.mas_equalTo(self.mas_width).multipliedBy(0.5);
        make.height.mas_equalTo(self.mas_height).multipliedBy(0.5).offset(-kShadowWidth);
    }];
    [self.colorButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-kShadowWidth);
        make.top.mas_equalTo(self.editButton.mas_bottom);
        make.bottom.offset(-kShadowWidth);
        make.width.mas_equalTo(self.mas_width).multipliedBy(0.5);
    }];
    self.deleteButton.alpha = 0;
    self.mergeButton.alpha = 0;
    self.editButton.alpha = 0;
    self.colorButton.alpha = 0;
    [self bringSubviewToFront:self.contentView];
    
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(kShadowWidth);
        make.right.offset(-kShadowWidth);
        make.top.offset(kShadowWidth);
        make.bottom.offset(-kShadowWidth);
    }];
    self.contentView.layer.cornerRadius = kCornerRadius;
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
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [self.contentView addGestureRecognizer:panGesture];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.contentView.transform = CGAffineTransformIdentity;
    self.deleteButton.alpha = 0;
    self.mergeButton.alpha = 0;
    self.editButton.alpha = 0;
    self.colorButton.alpha = 0;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat iconOffset = CGRectGetWidth(self.deleteButton.bounds) / 6.0;
    self.deleteButton.imageEdgeInsets = UIEdgeInsetsMake(0, -iconOffset, 0, iconOffset);
    self.mergeButton.imageEdgeInsets = UIEdgeInsetsMake(0, -iconOffset, 0, iconOffset);
    self.editButton.imageEdgeInsets = UIEdgeInsetsMake(0, iconOffset, 0, -iconOffset);
    self.colorButton.imageEdgeInsets = UIEdgeInsetsMake(0, iconOffset, 0, -iconOffset);
}

#pragma mark - Actions

- (void)handlePan:(UIPanGestureRecognizer *)panGesture
{
    CGPoint translation = [panGesture translationInView:self];
    CGFloat currentOffset = self.contentView.transform.tx;
    CGFloat actionWidth = [self actionWidth];
    
    switch (panGesture.state) {
        case UIGestureRecognizerStateChanged:
        {
            CGFloat targetOffset = MAX(-actionWidth, MIN(actionWidth, currentOffset + translation.x));
            self.contentView.transform = CGAffineTransformMakeTranslation(targetOffset, 0);
            [self updateActionButtonVisibilityWithOffset:targetOffset];
            [panGesture setTranslation:CGPointZero inView:self];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGFloat velocityX = [panGesture velocityInView:self].x;
            CGFloat targetOffset = 0;
            if (currentOffset < -actionWidth / 2 || velocityX < -300) {
                targetOffset = -actionWidth;
            } else if (currentOffset > actionWidth / 2 || velocityX > 300) {
                targetOffset = actionWidth;
            }
            [self setContentOffset:targetOffset animated:YES];
            break;
        }
        default:
            break;
    }
}

- (void)tapEditButton
{
    [self setContentOffset:0 animated:YES];
    [self.delegate timeTrackerTaskCollectionViewCellDidTapEdit:self];
}

- (void)tapColorButton
{
    [self setContentOffset:0 animated:YES];
    [self.delegate timeTrackerTaskCollectionViewCellDidTapColor:self];
}

- (void)tapDeleteButton
{
    [self setContentOffset:0 animated:YES];
    [self.delegate timeTrackerTaskCollectionViewCellDidTapDelete:self];
}

- (void)tapMergeButton
{
    [self setContentOffset:0 animated:YES];
    [self.delegate timeTrackerTaskCollectionViewCellDidTapMerge:self];
}

- (BOOL)dismissActionButtonsIfNeeded
{
    if (CGAffineTransformIsIdentity(self.contentView.transform)) {
        return NO;
    }
    [self setContentOffset:0 animated:YES];
    return YES;
}

- (void)setContentOffset:(CGFloat)offset animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        self.contentView.transform = CGAffineTransformMakeTranslation(offset, 0);
        [self updateActionButtonVisibilityWithOffset:offset];
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    } else {
        animations();
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return YES;
    }
    CGPoint velocity = [(UIPanGestureRecognizer *)gestureRecognizer velocityInView:self];
    return fabs(velocity.x) > fabs(velocity.y);
}

- (CGFloat)actionWidth
{
    return CGRectGetWidth(self.bounds) / 3.0;
}

- (void)updateActionButtonVisibilityWithOffset:(CGFloat)offset
{
    self.deleteButton.alpha = offset > 0 ? 1 : 0;
    self.mergeButton.alpha = offset > 0 ? 1 : 0;
    self.editButton.alpha = offset < 0 ? 1 : 0;
    self.colorButton.alpha = offset < 0 ? 1 : 0;
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

- (UIButton *)editButton
{
    if (!_editButton) {
        _editButton = [UIButton new];
        _editButton.backgroundColor = [UIColor systemBlueColor];
        _editButton.layer.cornerRadius = kCornerRadius;
        _editButton.layer.masksToBounds = YES;
        if (@available(iOS 11.0, *)) {
            _editButton.layer.maskedCorners = kCALayerMaxXMinYCorner;
        }
        _editButton.tintColor = [UIColor whiteColor];
        _editButton.accessibilityLabel = [MirrorLanguage mirror_stringWithKey:@"edit"];
        [_editButton setImage:[UIImage systemImageNamed:@"pencil"] forState:UIControlStateNormal];
        [_editButton addTarget:self action:@selector(tapEditButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _editButton;
}

- (UIButton *)colorButton
{
    if (!_colorButton) {
        _colorButton = [UIButton new];
        _colorButton.backgroundColor = [UIColor systemYellowColor];
        _colorButton.layer.cornerRadius = kCornerRadius;
        _colorButton.layer.masksToBounds = YES;
        if (@available(iOS 11.0, *)) {
            _colorButton.layer.maskedCorners = kCALayerMaxXMaxYCorner;
        }
        _colorButton.tintColor = [UIColor whiteColor];
        _colorButton.accessibilityLabel = [MirrorLanguage mirror_stringWithKey:@"edit"];
        [_colorButton setImage:[UIImage systemImageNamed:@"paintpalette"] forState:UIControlStateNormal];
        [_colorButton addTarget:self action:@selector(tapColorButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _colorButton;
}

- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [UIButton new];
        _deleteButton.backgroundColor = [UIColor systemRedColor];
        _deleteButton.layer.cornerRadius = kCornerRadius;
        _deleteButton.layer.masksToBounds = YES;
        if (@available(iOS 11.0, *)) {
            _deleteButton.layer.maskedCorners = kCALayerMinXMinYCorner;
        }
        _deleteButton.tintColor = [UIColor whiteColor];
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
        _mergeButton.backgroundColor = [UIColor systemOrangeColor];
        _mergeButton.layer.cornerRadius = kCornerRadius;
        _mergeButton.layer.masksToBounds = YES;
        if (@available(iOS 11.0, *)) {
            _mergeButton.layer.maskedCorners = kCALayerMinXMaxYCorner;
        }
        _mergeButton.tintColor = [UIColor whiteColor];
        _mergeButton.accessibilityLabel = [MirrorLanguage mirror_stringWithKey:@"merge"];
        [_mergeButton setImage:[UIImage systemImageNamed:@"inset.filled.righthalf.arrow.right.rectangle"] forState:UIControlStateNormal];
        [_mergeButton addTarget:self action:@selector(tapMergeButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mergeButton;
}

@end
