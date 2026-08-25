//
//  PeriodEditAlertController.m
//  Mirror
//

#import "PeriodEditAlertController.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "MirrorMacro.h"
#import "MirrorStorage.h"
#import "PeriodEditView.h"
#import "UIColor+MirrorColor.h"

@interface PeriodEditAlertController ()

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) PeriodEditView *editView;
@property (nonatomic, strong) MASConstraint *cardCenterYConstraint;
@property (nonatomic, copy) PeriodEditAlertRecordChanged recordChanged;
@property (nonatomic, strong) MirrorRecordModel *editingRecord;
@property (nonatomic, strong) NSArray<MirrorTaskModel *> *tasks;
@property (nonatomic, strong, nullable) NSNumber *minimumTimestamp;
@property (nonatomic, strong, nullable) NSNumber *maximumTimestamp;
@property (nonatomic, assign) CGFloat keyboardOverlap;

@end

@implementation PeriodEditAlertController

- (instancetype)initWithRecord:(MirrorRecordModel *)record
               minimumTimestamp:(NSNumber * _Nullable)minimumTimestamp
               maximumTimestamp:(NSNumber * _Nullable)maximumTimestamp
                  recordChanged:(PeriodEditAlertRecordChanged)recordChanged
{
    self = [super init];
    if (self) {
        MirrorRecordModel *editingRecord = [[MirrorRecordModel alloc] initWithTitle:record.taskName ?: @"" startTime:record.startTime endTime:record.endTime];
        editingRecord.originalIndex = record.originalIndex;
        editingRecord.note = record.note ?: @"";
        _editingRecord = editingRecord;
        _tasks = [[MirrorStorage retriveMirrorTasks] copy];
        _minimumTimestamp = minimumTimestamp;
        _maximumTimestamp = maximumTimestamp;
        _recordChanged = [recordChanged copy];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isPresented
{
    return self.overlayView != nil;
}

- (void)presentFromViewController:(UIViewController *)viewController
{
    self.presentingViewController = viewController;

    UIView *containerView = viewController.view.window ?: viewController.view;
    UIView *overlayView = [UIView new];
    overlayView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.28];
    overlayView.alpha = 0;
    [containerView addSubview:overlayView];
    [overlayView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(containerView);
    }];
    self.overlayView = overlayView;

    UIView *cardView = [UIView new];
    cardView.backgroundColor = UIColor.clearColor;
    cardView.layer.cornerRadius = 16;
    cardView.layer.masksToBounds = NO;
    cardView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
    cardView.layer.shadowOpacity = 0.18;
    cardView.layer.shadowRadius = 24;
    cardView.layer.shadowOffset = CGSizeMake(0, 10);
    cardView.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [overlayView addSubview:cardView];
    self.cardView = cardView;
    [cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_greaterThanOrEqualTo(overlayView).offset(24);
        make.right.mas_lessThanOrEqualTo(overlayView).offset(-24);
        self.cardCenterYConstraint = make.centerY.mas_equalTo(overlayView);
        make.width.mas_lessThanOrEqualTo(360);
        make.width.mas_equalTo(overlayView).multipliedBy(0.86).priorityHigh();
    }];

    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial];
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurView.alpha = 0.9;
    blurView.clipsToBounds = YES;
    blurView.layer.cornerRadius = 16;
    [cardView addSubview:blurView];
    [blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    self.blurView = blurView;

    PeriodEditView *editView = [[PeriodEditView alloc] initWithRecord:self.editingRecord
                                                                tasks:self.tasks
                                                     minimumTimestamp:self.minimumTimestamp
                                                     maximumTimestamp:self.maximumTimestamp];
    __weak typeof(self) weakSelf = self;
    editView.cancelHandler = ^{
        [weakSelf cancel];
    };
    editView.doneHandler = ^{
        [weakSelf dismiss];
    };
    [blurView.contentView addSubview:editView];
    [editView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    self.editView = editView;

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTapped:)];
    tapGesture.cancelsTouchesInView = NO;
    [overlayView addGestureRecognizer:tapGesture];

    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        overlayView.alpha = 1;
        cardView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismiss
{
    [self closeAlertSavingChanges:YES];
}

- (void)cancel
{
    [self closeAlertSavingChanges:NO];
}

- (void)themeChanged:(NSNotification *)notification
{
    self.cardView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
    [self.editView refreshAppearanceForCurrentTheme];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    UIView *overlayView = self.overlayView;
    if (!overlayView) {
        return;
    }

    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertedFrame = [overlayView convertRect:keyboardFrame fromView:nil];
    CGFloat overlap = MAX(0, CGRectGetMaxY(overlayView.bounds) - CGRectGetMinY(convertedFrame));
    self.keyboardOverlap = overlap;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [self updateCardPositionAnimated:YES duration:duration curve:(curve << 16)];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.keyboardOverlap = 0;
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [self updateCardPositionAnimated:YES duration:duration curve:(curve << 16)];
}

- (void)updateCardPositionAnimated:(BOOL)animated duration:(NSTimeInterval)duration curve:(UIViewAnimationOptions)curve
{
    UIView *overlayView = self.overlayView;
    UIView *cardView = self.cardView;
    if (!overlayView || !cardView) {
        return;
    }

    [overlayView layoutIfNeeded];
    CGSize fittingSize = [cardView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat availableHeight = CGRectGetHeight(overlayView.bounds) - self.keyboardOverlap;
    CGFloat bottomPadding = self.keyboardOverlap > 0 ? 12 : 0;
    CGFloat centeredOffset = self.keyboardOverlap > 0 ? -(self.keyboardOverlap / 2.0) : 0;
    CGFloat cardBottomAtCenter = (availableHeight / 2.0) + (fittingSize.height / 2.0) + centeredOffset;
    CGFloat overflow = MAX(0, cardBottomAtCenter - availableHeight + bottomPadding);
    CGFloat yOffset = centeredOffset - overflow;
    [self.cardCenterYConstraint setOffset:yOffset];

    void (^changes)(void) = ^{
        [overlayView layoutIfNeeded];
    };
    if (animated) {
        [UIView animateWithDuration:MAX(duration, 0.01) delay:0 options:curve animations:changes completion:nil];
    } else {
        changes();
    }
}

- (void)overlayTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.cardView];
    if (!CGRectContainsPoint(self.cardView.bounds, location)) {
        [self cancel];
    }
}

- (void)closeAlertSavingChanges:(BOOL)shouldSaveChanges
{
    UIView *overlayView = self.overlayView;
    UIView *cardView = self.cardView;
    if (!overlayView) {
        return;
    }

    MirrorRecordModel *editedRecord = shouldSaveChanges ? [self.editView editedRecord] : nil;
    PeriodEditAlertRecordChanged recordChanged = shouldSaveChanges ? self.recordChanged : nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.presentingViewController.view endEditing:YES];
    [overlayView endEditing:YES];
    self.editView.cancelHandler = nil;
    self.editView.doneHandler = nil;
    self.editView = nil;
    self.blurView = nil;
    self.cardView = nil;
    self.overlayView = nil;
    self.cardCenterYConstraint = nil;
    self.keyboardOverlap = 0;

    [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        overlayView.alpha = 0;
        cardView.transform = CGAffineTransformMakeScale(0.94, 0.94);
    } completion:^(BOOL finished) {
        [overlayView removeFromSuperview];
        if (recordChanged) {
            recordChanged(editedRecord);
        }
    }];
}

@end
