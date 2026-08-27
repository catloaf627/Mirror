//
//  PeriodEditAlertView.m
//  Mirror
//

#import "PeriodEditAlertView.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "MirrorMacro.h"
#import "MirrorStorage.h"
#import "UIColor+MirrorColor.h"
#import "UIImage+MirrorSymbol.h"

@interface PeriodEditAlertView () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *taskNamePickerView;
@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) UILabel *startLabel;
@property (nonatomic, strong) UILabel *endLabel;
@property (nonatomic, strong) UILabel *noteLabel;
@property (nonatomic, strong) UIButton *previousTaskButton;
@property (nonatomic, strong) UIButton *nextTaskButton;
@property (nonatomic, strong) UIButton *startTimeButton;
@property (nonatomic, strong) UIButton *endTimeButton;
@property (nonatomic, strong) UIButton *startCalendarButton;
@property (nonatomic, strong) UIButton *endCalendarButton;
@property (nonatomic, strong) UIDatePicker *startDatePicker;
@property (nonatomic, strong) UIDatePicker *endDatePicker;
@property (nonatomic, strong) UITextField *noteTextField;
@property (nonatomic, strong) UIView *datePickerDismissView;
@property (nonatomic, strong) UIView *datePickerPanelView;
@property (nonatomic, strong) UIVisualEffectView *datePickerBlurView;
@property (nonatomic, strong) UIDatePicker *activeDatePicker;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) MASConstraint *cardCenterYConstraint;
@property (nonatomic, copy) PeriodEditAlertRecordChanged recordChanged;
@property (nonatomic, assign) NSInteger selectedTaskIndex;
@property (nonatomic, strong) MirrorRecordModel *editingRecord;
@property (nonatomic, strong) NSArray<MirrorTaskModel *> *tasks;
@property (nonatomic, assign) MirrorColorType taskColorType;
@property (nonatomic, strong) UIColor *accentColor;
@property (nonatomic, strong, nullable) NSNumber *minimumTimestamp;
@property (nonatomic, strong, nullable) NSNumber *maximumTimestamp;
@property (nonatomic, assign) NSInteger periodIndex;
@property (nonatomic, assign) long startTimestamp;
@property (nonatomic, assign) long endTimestamp;
@property (nonatomic, assign) CGFloat keyboardOverlap;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;

@end

@implementation PeriodEditAlertView

- (instancetype)initWithRecord:(MirrorRecordModel *)record
                    periodIndex:(NSInteger)periodIndex
               minimumTimestamp:(NSNumber * _Nullable)minimumTimestamp
               maximumTimestamp:(NSNumber * _Nullable)maximumTimestamp
                  recordChanged:(PeriodEditAlertRecordChanged)recordChanged
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        MirrorTaskModel *taskModel = [MirrorStorage getTaskModelFromDB:record.taskName];
        MirrorColorType colorType = taskModel ? taskModel.color : MirrorColorTypeCellGray;
        MirrorRecordModel *editingRecord = [[MirrorRecordModel alloc] initWithTitle:record.taskName ?: @"" startTime:record.startTime endTime:record.endTime];
        editingRecord.originalIndex = record.originalIndex;
        editingRecord.note = record.note ?: @"";
        _editingRecord = editingRecord;
        _tasks = [[MirrorStorage retriveMirrorTasks] copy] ?: @[];
        _taskColorType = colorType;
        _accentColor = [UIColor mirrorColorPulsed:colorType];
        _minimumTimestamp = minimumTimestamp;
        _maximumTimestamp = maximumTimestamp;
        _periodIndex = periodIndex;
        _recordChanged = [recordChanged copy];
        _startTimestamp = record.startTime;
        _endTimestamp = record.endTime;
        [self setupFormatters];
        [self setupViews];
        [self updateAccentColorAppearance];
        [self updateTimeButtonTitles];
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
    return self.superview != nil;
}

- (void)presentFromViewController:(UIViewController *)viewController
{
    if (self.superview) {
        return;
    }

    self.presentingViewController = viewController;
    UIView *containerView = viewController.view.window ?: viewController.view;
    self.alpha = 1;
    self.cardView.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [containerView addSubview:self];
    [self mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(containerView);
    }];
    [self layoutIfNeeded];

    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.cardView.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)dismiss
{
    [self closeAlertSavingChanges:YES];
}

- (MirrorRecordModel *)editedRecord
{
    [self dismissDatePickerPanelAnimated:NO];
    self.editingRecord.note = self.noteTextField.text ?: @"";
    [MirrorStorage editPeriodNote:self.editingRecord.note periodIndex:self.periodIndex];
    return self.editingRecord;
}

- (void)removeFromSuperview
{
    [self dismissDatePickerPanelAnimated:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super removeFromSuperview];
}

- (BOOL)dismissTransientControlsAnimated:(BOOL)animated
{
    if (!self.datePickerPanelView.superview) {
        return NO;
    }
    [self dismissDatePickerPanelAnimated:animated];
    return YES;
}

- (void)refreshAppearanceForCurrentTheme
{
    self.accentColor = [UIColor mirrorColorPulsed:self.taskColorType];
    [self updateAccentColorAppearance];
}

- (void)themeChanged:(NSNotification *)notification
{
    self.cardView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
    [self refreshAppearanceForCurrentTheme];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    if (!self.superview) {
        return;
    }

    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertedFrame = [self convertRect:keyboardFrame fromView:nil];
    CGFloat overlap = MAX(0, CGRectGetMaxY(self.bounds) - CGRectGetMinY(convertedFrame));
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
    if (!self.superview || !self.cardView) {
        return;
    }

    [self layoutIfNeeded];
    CGSize fittingSize = [self.cardView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGFloat availableHeight = CGRectGetHeight(self.bounds) - self.keyboardOverlap;
    CGFloat bottomPadding = self.keyboardOverlap > 0 ? 12*kHeightRatio : 0;
    CGFloat centeredOffset = self.keyboardOverlap > 0 ? -(self.keyboardOverlap / 2.0) : 0;
    CGFloat cardBottomAtCenter = (availableHeight / 2.0) + (fittingSize.height / 2.0) + centeredOffset;
    CGFloat overflow = MAX(0, cardBottomAtCenter - availableHeight + bottomPadding);
    CGFloat yOffset = centeredOffset - overflow;
    [self.cardCenterYConstraint setOffset:yOffset];

    void (^changes)(void) = ^{
        [self layoutIfNeeded];
    };
    if (animated) {
        [UIView animateWithDuration:MAX(duration, 0.01) delay:0 options:curve animations:changes completion:nil];
    } else {
        changes();
    }
}

- (void)overlayTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }

    CGPoint location = [gestureRecognizer locationInView:self.cardView];
    if (!CGRectContainsPoint(self.cardView.bounds, location)) {
        if ([self dismissTransientControlsAnimated:YES]) {
            return;
        }
        [self dismiss];
    }
}

- (void)closeAlertSavingChanges:(BOOL)shouldSaveChanges
{
    if (!self.superview) {
        return;
    }

    MirrorRecordModel *editedRecord = shouldSaveChanges ? [self editedRecord] : nil;
    PeriodEditAlertRecordChanged recordChanged = shouldSaveChanges ? self.recordChanged : nil;
    UIView *cardView = self.cardView;
    [self dismissTransientControlsAnimated:NO];
    [self.presentingViewController.view endEditing:YES];
    [self endEditing:YES];
    self.presentingViewController = nil;
    self.cardCenterYConstraint = nil;
    self.keyboardOverlap = 0;

    [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.alpha = 0;
        cardView.transform = CGAffineTransformMakeScale(0.94, 0.94);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (recordChanged) {
            recordChanged(editedRecord);
        }
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    UIView *touchedView = touch.view;
    UIView *gestureView = gestureRecognizer.view;
    while (touchedView && touchedView != gestureView) {
        if ([touchedView isKindOfClass:UIControl.class]) {
            return NO;
        }
        touchedView = touchedView.superview;
    }
    return YES;
}

- (void)contentTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    [self dismissTransientControlsAnimated:YES];
}

- (void)setupFormatters
{
    self.timeFormatter = [NSDateFormatter new];
    self.timeFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
    self.timeFormatter.dateStyle = NSDateFormatterNoStyle;
    self.timeFormatter.timeStyle = NSDateFormatterNoStyle;
    self.timeFormatter.dateFormat = @"HH:mm";
}

- (void)setupViews
{
    self.backgroundColor = UIColor.clearColor;
    self.alpha = 1;

    UITapGestureRecognizer *overlayTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(overlayTapped:)];
    overlayTapGesture.cancelsTouchesInView = NO;
    [self addGestureRecognizer:overlayTapGesture];

    [self addSubview:self.cardView];
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_greaterThanOrEqualTo(self).offset(24*kWidthRatio);
        make.right.mas_lessThanOrEqualTo(self).offset(-24*kWidthRatio);
        self.cardCenterYConstraint = make.centerY.mas_equalTo(self);
        make.width.mas_lessThanOrEqualTo(360*kWidthRatio);
        make.width.mas_equalTo(self).multipliedBy(0.86).priorityHigh();
    }];

    [self.cardView addSubview:self.blurView];
    [self.blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];

    [self.blurView.contentView addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];

    UITapGestureRecognizer *contentTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentTapped:)];
    contentTapGesture.cancelsTouchesInView = NO;
    contentTapGesture.delegate = self;
    [self.contentView addGestureRecognizer:contentTapGesture];

    [self.contentView addSubview:self.taskNamePickerView];
    [self.contentView addSubview:self.startLabel];
    [self.contentView addSubview:self.startTimeButton];
    [self.contentView addSubview:self.startCalendarButton];
    [self.contentView addSubview:self.endLabel];
    [self.contentView addSubview:self.endTimeButton];
    [self.contentView addSubview:self.endCalendarButton];
    [self.contentView addSubview:self.noteLabel];
    [self.contentView addSubview:self.noteTextField];
    [self.contentView addSubview:self.separatorView];

    CGFloat leftInset = 20*kWidthRatio;
    CGFloat rightInset = -20*kWidthRatio;
    CGFloat labelWidth = 88*kWidthRatio;
    CGFloat rowHeight = 36*kHeightRatio;

    [self.taskNamePickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(22*kHeightRatio);
        make.left.offset(leftInset);
        make.right.offset(rightInset);
        make.height.mas_equalTo(34*kHeightRatio);
    }];
    [self.startLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(leftInset);
        make.top.mas_equalTo(self.taskNamePickerView.mas_bottom).offset(14*kHeightRatio);
        make.width.mas_equalTo(labelWidth);
        make.height.mas_equalTo(rowHeight);
    }];
    [self.startTimeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.startCalendarButton.mas_right).offset(8*kWidthRatio);
        make.centerY.mas_equalTo(self.startLabel);
        make.right.offset(rightInset);
        make.height.mas_equalTo(rowHeight);
    }];
    [self.startCalendarButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.startLabel.mas_right).offset(8*kWidthRatio);
        make.centerY.mas_equalTo(self.startLabel);
        make.width.height.mas_equalTo(rowHeight);
    }];
    [self.endLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.height.mas_equalTo(self.startLabel);
        make.top.mas_equalTo(self.startLabel.mas_bottom).offset(8*kHeightRatio);
    }];
    [self.endTimeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.mas_equalTo(self.startTimeButton);
        make.centerY.mas_equalTo(self.endLabel);
    }];
    [self.endCalendarButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.width.height.mas_equalTo(self.startCalendarButton);
        make.centerY.mas_equalTo(self.endLabel);
    }];
    [self.noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(leftInset);
        make.width.mas_equalTo(44*kWidthRatio);
        make.height.mas_equalTo(rowHeight);
        make.top.mas_equalTo(self.endLabel.mas_bottom).offset(8*kHeightRatio);
    }];
    [self.noteTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.noteLabel.mas_right).offset(8*kWidthRatio);
        make.right.offset(rightInset);
        make.height.mas_equalTo(self.startTimeButton);
        make.centerY.mas_equalTo(self.noteLabel);
    }];
    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.noteTextField.mas_bottom).offset(18*kHeightRatio);
        make.left.right.bottom.offset(0);
        make.height.mas_equalTo(1.0 / UIScreen.mainScreen.scale);
    }];

    self.startDatePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    self.endDatePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
    self.startDatePicker.minimumDate = self.minimumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.minimumTimestamp.longValue] : nil;
    self.endDatePicker.maximumDate = self.maximumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.maximumTimestamp.longValue] : nil;
}

- (UIView *)cardView
{
    if (!_cardView) {
        _cardView = [UIView new];
        _cardView.backgroundColor = UIColor.clearColor;
        _cardView.layer.cornerRadius = 16*kWidthRatio;
        _cardView.layer.masksToBounds = NO;
        _cardView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
        _cardView.layer.shadowOpacity = 0.18;
        _cardView.layer.shadowRadius = 24*kWidthRatio;
        _cardView.layer.shadowOffset = CGSizeMake(0, 10*kHeightRatio);
    }
    return _cardView;
}

- (UIVisualEffectView *)blurView
{
    if (!_blurView) {
        _blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
        _blurView.alpha = 0.9;
        _blurView.clipsToBounds = YES;
        _blurView.layer.cornerRadius = 16*kWidthRatio;
    }
    return _blurView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = UIColor.clearColor;
        _contentView.clipsToBounds = YES;
        _contentView.layer.cornerRadius = 16*kWidthRatio;
    }
    return _contentView;
}

- (UIView *)taskNamePickerView
{
    if (!_taskNamePickerView) {
        _taskNamePickerView = [UIView new];
        [_taskNamePickerView addSubview:self.previousTaskButton];
        [_taskNamePickerView addSubview:self.taskNameLabel];
        [_taskNamePickerView addSubview:self.nextTaskButton];
        [self.previousTaskButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.offset(0);
            make.width.mas_equalTo(30*kWidthRatio);
        }];
        [self.nextTaskButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.top.bottom.offset(0);
            make.width.mas_equalTo(30*kWidthRatio);
        }];
        [self.taskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.previousTaskButton.mas_right).offset(8*kWidthRatio);
            make.right.mas_equalTo(self.nextTaskButton.mas_left).offset(-8*kWidthRatio);
            make.top.bottom.offset(0);
        }];
        self.selectedTaskIndex = [self indexOfTaskName:self.editingRecord.taskName];
        [self updateTaskArrowButtonsEnabled];
    }
    return _taskNamePickerView;
}

- (UILabel *)taskNameLabel
{
    if (!_taskNameLabel) {
        _taskNameLabel = [UILabel new];
        _taskNameLabel.text = self.editingRecord.taskName;
        _taskNameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _taskNameLabel.textAlignment = NSTextAlignmentCenter;
        _taskNameLabel.adjustsFontSizeToFitWidth = YES;
        _taskNameLabel.minimumScaleFactor = 0.6;
    }
    return _taskNameLabel;
}

- (UILabel *)startLabel
{
    if (!_startLabel) {
        _startLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"starts_at"]];
    }
    return _startLabel;
}

- (UILabel *)endLabel
{
    if (!_endLabel) {
        _endLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"ends_at"]];
    }
    return _endLabel;
}

- (UILabel *)noteLabel
{
    if (!_noteLabel) {
        _noteLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"note"]];
    }
    return _noteLabel;
}

- (UIButton *)previousTaskButton
{
    if (!_previousTaskButton) {
        _previousTaskButton = [self taskArrowButtonWithSystemImageName:@"chevron.left" action:@selector(previousTaskButtonTapped:)];
    }
    return _previousTaskButton;
}

- (UIButton *)nextTaskButton
{
    if (!_nextTaskButton) {
        _nextTaskButton = [self taskArrowButtonWithSystemImageName:@"chevron.right" action:@selector(nextTaskButtonTapped:)];
    }
    return _nextTaskButton;
}

- (UIButton *)startTimeButton
{
    if (!_startTimeButton) {
        _startTimeButton = [self timeButtonWithAction:@selector(startTimeButtonTapped:)];
    }
    return _startTimeButton;
}

- (UIButton *)endTimeButton
{
    if (!_endTimeButton) {
        _endTimeButton = [self timeButtonWithAction:@selector(endTimeButtonTapped:)];
    }
    return _endTimeButton;
}

- (UIButton *)startCalendarButton
{
    if (!_startCalendarButton) {
        _startCalendarButton = [self calendarButtonWithAction:@selector(startCalendarButtonTapped:)];
    }
    return _startCalendarButton;
}

- (UIButton *)endCalendarButton
{
    if (!_endCalendarButton) {
        _endCalendarButton = [self calendarButtonWithAction:@selector(endCalendarButtonTapped:)];
    }
    return _endCalendarButton;
}

- (UIDatePicker *)startDatePicker
{
    if (!_startDatePicker) {
        _startDatePicker = [self datePickerWithTimestamp:self.startTimestamp];
        [_startDatePicker addTarget:self action:@selector(startDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _startDatePicker;
}

- (UIDatePicker *)endDatePicker
{
    if (!_endDatePicker) {
        _endDatePicker = [self datePickerWithTimestamp:self.endTimestamp];
        [_endDatePicker addTarget:self action:@selector(endDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _endDatePicker;
}

- (UITextField *)noteTextField
{
    if (!_noteTextField) {
        _noteTextField = [UITextField new];
        _noteTextField.text = self.editingRecord.note ?: @"";
        _noteTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _noteTextField.borderStyle = UITextBorderStyleRoundedRect;
        _noteTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [_noteTextField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [_noteTextField addTarget:self action:@selector(noteTextFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
        [_noteTextField addTarget:self action:@selector(noteTextFieldDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
    }
    return _noteTextField;
}

- (UIView *)datePickerDismissView
{
    if (!_datePickerDismissView) {
        _datePickerDismissView = [UIView new];
        _datePickerDismissView.backgroundColor = UIColor.clearColor;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(datePickerDismissViewTapped:)];
        [_datePickerDismissView addGestureRecognizer:tapGesture];
    }
    return _datePickerDismissView;
}

- (UIView *)datePickerPanelView
{
    if (!_datePickerPanelView) {
        _datePickerPanelView = [UIView new];
        _datePickerPanelView.backgroundColor = UIColor.clearColor;
        _datePickerPanelView.layer.cornerRadius = 14*kWidthRatio;
        _datePickerPanelView.layer.shadowColor = [UIColor blackColor].CGColor;
        _datePickerPanelView.layer.shadowOpacity = 0.16;
        _datePickerPanelView.layer.shadowRadius = 16*kWidthRatio;
        _datePickerPanelView.layer.shadowOffset = CGSizeMake(0, 6*kHeightRatio);
        [_datePickerPanelView addSubview:self.datePickerBlurView];
        [self.datePickerBlurView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.offset(0);
        }];
    }
    return _datePickerPanelView;
}

- (UIVisualEffectView *)datePickerBlurView
{
    if (!_datePickerBlurView) {
        _datePickerBlurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterial]];
        _datePickerBlurView.alpha = 0.96;
        _datePickerBlurView.clipsToBounds = YES;
        _datePickerBlurView.layer.cornerRadius = 14*kWidthRatio;
    }
    return _datePickerBlurView;
}

- (UIView *)separatorView
{
    if (!_separatorView) {
        _separatorView = [UIView new];
    }
    return _separatorView;
}

- (UIDatePicker *)datePickerWithTimestamp:(long)timestamp
{
    UIDatePicker *datePicker = [UIDatePicker new];
    datePicker.datePickerMode = UIDatePickerModeTime;
    datePicker.minuteInterval = 5;
    datePicker.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 216*kHeightRatio);
    datePicker.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
    datePicker.tintColor = self.accentColor;
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    return datePicker;
}

- (UIButton *)calendarButtonWithAction:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setImage:[UIImage mirror_systemImageNamed:@"calendar" fallbackName:@"calendar"] forState:UIControlStateNormal];
    button.layer.cornerRadius = 8*kWidthRatio;
    button.layer.borderWidth = 1;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)timeButtonWithAction:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    button.layer.cornerRadius = 8*kWidthRatio;
    button.layer.borderWidth = 1;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 10*kWidthRatio, 0, 10*kWidthRatio);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)taskArrowButtonWithSystemImageName:(NSString *)systemImageName action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setImage:[UIImage mirror_systemImageNamed:systemImageName fallbackName:systemImageName] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UILabel *)pickerLabelWithText:(NSString *)text
{
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

- (void)startTimeButtonTapped:(UIButton *)button
{
    [self presentDatePicker:self.startDatePicker
                    anchor:self.startTimeButton
                      mode:UIDatePickerModeTime];
}

- (void)endTimeButtonTapped:(UIButton *)button
{
    [self presentDatePicker:self.endDatePicker
                    anchor:self.endTimeButton
                      mode:UIDatePickerModeTime];
}

- (void)startCalendarButtonTapped:(UIButton *)button
{
    [self presentDatePicker:self.startDatePicker
                    anchor:self.startCalendarButton
                      mode:UIDatePickerModeDate];
}

- (void)endCalendarButtonTapped:(UIButton *)button
{
    [self presentDatePicker:self.endDatePicker
                    anchor:self.endCalendarButton
                      mode:UIDatePickerModeDate];
}

- (void)presentDatePicker:(UIDatePicker *)datePicker anchor:(UIView *)anchor mode:(UIDatePickerMode)mode
{
    [self.noteTextField resignFirstResponder];
    [self configureDatePicker:datePicker mode:mode];
    [self showDatePickerPanelWithDatePicker:datePicker anchor:anchor];
}

- (void)configureDatePicker:(UIDatePicker *)datePicker mode:(UIDatePickerMode)mode
{
    BOOL isStartDate = datePicker == self.startDatePicker;
    datePicker.datePickerMode = mode;
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:mode == UIDatePickerModeTime ? @"en_GB" : [MirrorLanguage mirror_stringWithKey:@"locale_Identifier"]];
    datePicker.date = [NSDate dateWithTimeIntervalSince1970:isStartDate ? self.startTimestamp : self.endTimestamp];
    datePicker.minimumDate = nil;
    datePicker.maximumDate = nil;
    if (isStartDate) {
        datePicker.minimumDate = self.minimumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.minimumTimestamp.longValue] : nil;
        datePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    } else {
        datePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
        datePicker.maximumDate = self.maximumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.maximumTimestamp.longValue] : nil;
    }
    if (@available(iOS 14.0, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    } else if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
}

- (void)showDatePickerPanelWithDatePicker:(UIDatePicker *)datePicker anchor:(UIView *)anchor
{
    UIWindow *window = self.window;
    if (!window || !anchor) {
        return;
    }

    [self installDatePickerDismissViewInWindow:window];
    if (!self.datePickerPanelView.superview) {
        [window addSubview:self.datePickerPanelView];
    }
    if (self.activeDatePicker != datePicker) {
        [self.activeDatePicker removeFromSuperview];
        self.activeDatePicker = datePicker;
        [self.datePickerBlurView.contentView addSubview:datePicker];
        [datePicker mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.offset(0);
        }];
    }

    CGRect anchorFrame = [anchor convertRect:anchor.bounds toView:window];
    CGFloat horizontalInset = 24*kWidthRatio;
    CGFloat panelWidth = MIN(CGRectGetWidth(window.bounds) - horizontalInset * 2, 300*kWidthRatio);
    CGFloat panelHeight = 216*kHeightRatio;
    [self showPanelWithAnchorFrame:anchorFrame width:panelWidth height:panelHeight];
}

- (void)showPanelWithAnchorFrame:(CGRect)anchorFrame width:(CGFloat)panelWidth height:(CGFloat)panelHeight
{
    UIWindow *window = self.window;
    if (!window) {
        return;
    }

    CGFloat horizontalInset = 24*kWidthRatio;
    CGFloat panelX = MIN(MAX(horizontalInset, CGRectGetMidX(anchorFrame) - panelWidth / 2.0), CGRectGetWidth(window.bounds) - horizontalInset - panelWidth);
    CGFloat preferredY = CGRectGetMaxY(anchorFrame) + 8*kHeightRatio;
    CGFloat maxY = CGRectGetHeight(window.bounds) - window.safeAreaInsets.bottom - 12*kHeightRatio;
    CGFloat panelY = preferredY + panelHeight <= maxY ? preferredY : CGRectGetMinY(anchorFrame) - panelHeight - 8*kHeightRatio;
    panelY = MAX(window.safeAreaInsets.top + 12*kHeightRatio, panelY);

    self.datePickerPanelView.frame = CGRectMake(panelX, panelY, panelWidth, panelHeight);
    [window bringSubviewToFront:self.datePickerPanelView];

    if (self.datePickerPanelView.alpha < 1) {
        self.datePickerPanelView.transform = CGAffineTransformMakeScale(0.96, 0.96);
        self.datePickerPanelView.alpha = 0;
        [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.datePickerPanelView.alpha = 1;
            self.datePickerPanelView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)installDatePickerDismissViewInWindow:(UIWindow *)window
{
    if (!window) {
        return;
    }
    if (self.datePickerDismissView.superview != window) {
        [self.datePickerDismissView removeFromSuperview];
        self.datePickerDismissView.frame = window.bounds;
        [window addSubview:self.datePickerDismissView];
    } else {
        self.datePickerDismissView.frame = window.bounds;
    }
    [window bringSubviewToFront:self.datePickerDismissView];
}

- (void)datePickerDismissViewTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    [self dismissDatePickerPanelAnimated:YES];
}

- (void)dismissDatePickerPanelAnimated:(BOOL)animated
{
    UIView *panelView = self.datePickerPanelView;
    if (!panelView.superview) {
        [self.datePickerDismissView removeFromSuperview];
        return;
    }

    void (^changes)(void) = ^{
        panelView.alpha = 0;
        panelView.transform = CGAffineTransformMakeScale(0.96, 0.96);
    };
    void (^completion)(BOOL) = ^(BOOL finished) {
        [panelView removeFromSuperview];
        [self.datePickerDismissView removeFromSuperview];
        panelView.transform = CGAffineTransformIdentity;
        [self.activeDatePicker removeFromSuperview];
        self.activeDatePicker = nil;
    };

    if (animated) {
        [UIView animateWithDuration:0.14 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:changes completion:completion];
    } else {
        changes();
        completion(YES);
    }
}

- (long)timestampByApplyingDate:(NSDate *)date toTimestamp:(long)timestamp
{
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    calendar.timeZone = [NSTimeZone systemTimeZone];
    NSDate *timeDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
    NSDateComponents *timeComponents = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:timeDate];
    dateComponents.hour = timeComponents.hour;
    dateComponents.minute = timeComponents.minute;
    dateComponents.second = 0;
    dateComponents.calendar = calendar;
    dateComponents.timeZone = calendar.timeZone;
    return round([dateComponents.date timeIntervalSince1970]);
}

- (void)previousTaskButtonTapped:(UIButton *)button
{
    [self selectTaskAtIndex:self.selectedTaskIndex - 1];
}

- (void)nextTaskButtonTapped:(UIButton *)button
{
    [self selectTaskAtIndex:self.selectedTaskIndex + 1];
}

- (void)selectTaskAtIndex:(NSInteger)index
{
    NSInteger taskCount = (NSInteger)self.tasks.count;
    if (taskCount == 0) {
        return;
    }
    NSInteger wrappedIndex = index % taskCount;
    if (wrappedIndex < 0) {
        wrappedIndex += taskCount;
    }
    NSString *taskName = self.tasks[wrappedIndex].taskName ?: @"";
    if (taskName.length == 0) {
        return;
    }
    self.selectedTaskIndex = wrappedIndex;
    if ([taskName isEqualToString:self.editingRecord.taskName]) {
        return;
    }
    self.editingRecord.taskName = taskName;
    MirrorTaskModel *taskModel = [MirrorStorage getTaskModelFromDB:taskName];
    self.taskColorType = taskModel ? taskModel.color : MirrorColorTypeCellGray;
    self.accentColor = [UIColor mirrorColorPulsed:self.taskColorType];
    self.taskNameLabel.text = taskName;
    [self updateAccentColorAppearance];
    [MirrorStorage editPeriodTaskName:taskName periodIndex:self.periodIndex];
}

- (NSInteger)indexOfTaskName:(NSString *)taskName
{
    for (NSInteger index = 0; index < self.tasks.count; index++) {
        if ([self.tasks[index].taskName isEqualToString:taskName]) {
            return index;
        }
    }
    return self.tasks.count > 0 ? 0 : NSNotFound;
}

- (void)updateTaskArrowButtonsEnabled
{
    BOOL canSwitchTask = self.tasks.count > 1;
    self.previousTaskButton.enabled = canSwitchTask;
    self.nextTaskButton.enabled = canSwitchTask;
    self.previousTaskButton.alpha = canSwitchTask ? 1.0 : 0.35;
    self.nextTaskButton.alpha = canSwitchTask ? 1.0 : 0.35;
}

- (void)startDatePickerValueChanged:(UIDatePicker *)datePicker
{
    long timestamp = datePicker.datePickerMode == UIDatePickerModeDate ? [self timestampByApplyingDate:datePicker.date toTimestamp:self.startTimestamp] : round([datePicker.date timeIntervalSince1970]);
    if (self.minimumTimestamp) {
        timestamp = MAX(timestamp, self.minimumTimestamp.longValue);
    }
    timestamp = MIN(timestamp, self.endTimestamp - kMinSeconds);
    self.startTimestamp = timestamp;
    self.editingRecord.startTime = timestamp;
    self.startDatePicker.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    self.endDatePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
    [self updateTimeButtonTitles];
    [MirrorStorage editPeriodStartTime:self.startTimestamp endTime:self.endTimestamp periodIndex:self.periodIndex];
}

- (void)endDatePickerValueChanged:(UIDatePicker *)datePicker
{
    long timestamp = datePicker.datePickerMode == UIDatePickerModeDate ? [self timestampByApplyingDate:datePicker.date toTimestamp:self.endTimestamp] : round([datePicker.date timeIntervalSince1970]);
    timestamp = MAX(timestamp, self.startTimestamp + kMinSeconds);
    if (self.maximumTimestamp) {
        timestamp = MIN(timestamp, self.maximumTimestamp.longValue);
    }
    self.endTimestamp = timestamp;
    self.editingRecord.endTime = timestamp;
    self.endDatePicker.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    self.startDatePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    [self updateTimeButtonTitles];
    [MirrorStorage editPeriodStartTime:self.startTimestamp endTime:self.endTimestamp periodIndex:self.periodIndex];
}

- (void)updateTimeButtonTitles
{
    NSString *startTitle = [self.timeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.startTimestamp]] ?: @"";
    NSString *endTitle = [self.timeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.endTimestamp]] ?: @"";
    [self.startTimeButton setAttributedTitle:nil forState:UIControlStateNormal];
    [self.endTimeButton setAttributedTitle:nil forState:UIControlStateNormal];
    [self.startTimeButton setTitle:startTitle forState:UIControlStateNormal];
    [self.endTimeButton setTitle:endTitle forState:UIControlStateNormal];
}

- (void)noteTextFieldEditingChanged:(UITextField *)textField
{
    if (textField.text.length > 200) {
        textField.text = [textField.text substringToIndex:200];
    }
}

- (void)noteTextFieldDidBeginEditing:(UITextField *)textField
{
    [self dismissDatePickerPanelAnimated:YES];
}

- (void)updateAccentColorAppearance
{
    UIColor *separatorColor = [[UIColor mirrorColorNamed:MirrorColorTypeTextHint] colorWithAlphaComponent:0.22];
    UIColor *borderColor = [[UIColor mirrorColorNamed:MirrorColorTypeText] colorWithAlphaComponent:0.12];
    self.tintColor = self.accentColor;
    self.taskNameLabel.textColor = self.accentColor;
    self.startLabel.textColor = self.accentColor;
    self.endLabel.textColor = self.accentColor;
    self.noteLabel.textColor = self.accentColor;
    self.previousTaskButton.tintColor = self.accentColor;
    self.nextTaskButton.tintColor = self.accentColor;
    self.startDatePicker.tintColor = self.accentColor;
    self.endDatePicker.tintColor = self.accentColor;
    self.datePickerPanelView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
    self.noteTextField.textColor = self.accentColor;
    self.noteTextField.tintColor = self.accentColor;
    self.separatorView.backgroundColor = separatorColor;
    self.startTimeButton.tintColor = self.accentColor;
    self.endTimeButton.tintColor = self.accentColor;
    self.startCalendarButton.tintColor = self.accentColor;
    self.endCalendarButton.tintColor = self.accentColor;
    self.startTimeButton.layer.borderColor = borderColor.CGColor;
    self.endTimeButton.layer.borderColor = borderColor.CGColor;
    self.startCalendarButton.layer.borderColor = borderColor.CGColor;
    self.endCalendarButton.layer.borderColor = borderColor.CGColor;
    [self updateNotePlaceholderAppearance];
}

- (void)updateNotePlaceholderAppearance
{
    UIColor *taskColor = [UIColor mirrorColorNamed:self.taskColorType];
    self.noteTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[MirrorLanguage mirror_stringWithKey:@"note"] attributes:@{
        NSForegroundColorAttributeName: taskColor,
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
    }];
}

@end
