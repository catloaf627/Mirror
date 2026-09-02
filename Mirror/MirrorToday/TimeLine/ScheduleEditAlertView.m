//
//  ScheduleEditAlertView.m
//  Mirror
//

#import "ScheduleEditAlertView.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "MirrorMacro.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"

@interface ScheduleEditAlertView () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) MirrorScheduleModel *schedule;
@property (nonatomic, assign) long dayStart;
@property (nonatomic, assign) long dayEnd;
@property (nonatomic, assign) BOOL isNew;
@property (nonatomic, copy) ScheduleEditCompletion completion;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *startLabel;
@property (nonatomic, strong) UILabel *endLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIButton *startTimeButton;
@property (nonatomic, strong) UIButton *endTimeButton;
@property (nonatomic, strong) UITextField *infoTextField;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIView *datePickerDismissView;
@property (nonatomic, strong) UIView *datePickerPanelView;
@property (nonatomic, strong) UIVisualEffectView *datePickerBlurView;
@property (nonatomic, strong) MASConstraint *cardCenterYConstraint;
@property (nonatomic, assign) BOOL editingStartTime;
@property (nonatomic, assign) long startTimestamp;
@property (nonatomic, assign) long endTimestamp;
@property (nonatomic, assign) CGFloat keyboardOverlap;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;

@end

@implementation ScheduleEditAlertView

- (instancetype)initWithSchedule:(MirrorScheduleModel *)schedule
                        dayStart:(long)dayStart
                          dayEnd:(long)dayEnd
                           isNew:(BOOL)isNew
                      completion:(ScheduleEditCompletion)completion
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _schedule = schedule;
        _dayStart = dayStart;
        _dayEnd = dayEnd;
        _isNew = isNew;
        _completion = [completion copy];
        _startTimestamp = schedule.startTime;
        _endTimestamp = schedule.endTime;
        [self setupFormatter];
        [self setupUI];
        [self updateTimeButtonTitles];
        [self updateAppearance];
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
    [self closeSavingChanges:YES];
}

- (void)removeFromSuperview
{
    [self dismissDatePickerPanelAnimated:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super removeFromSuperview];
}

- (void)setupFormatter
{
    self.timeFormatter = [NSDateFormatter new];
    self.timeFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
    self.timeFormatter.dateStyle = NSDateFormatterNoStyle;
    self.timeFormatter.timeStyle = NSDateFormatterNoStyle;
    self.timeFormatter.dateFormat = @"HH:mm";
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

- (void)setupUI
{
    self.backgroundColor = UIColor.clearColor;
    self.alpha = 1;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    tapRecognizer.cancelsTouchesInView = NO;
    tapRecognizer.delegate = self;
    [self addGestureRecognizer:tapRecognizer];
    
    [self addSubview:self.cardView];
    [self.cardView mas_makeConstraints:^(MASConstraintMaker *make) {
        self.cardCenterYConstraint = make.centerY.mas_equalTo(self);
        make.centerX.mas_equalTo(self);
        make.left.greaterThanOrEqualTo(self).offset(24*kWidthRatio);
        make.right.lessThanOrEqualTo(self).offset(-24*kWidthRatio);
        make.width.mas_equalTo(self).multipliedBy(0.86).priorityHigh();
        make.width.mas_lessThanOrEqualTo(360*kWidthRatio);
    }];
    
    [self.cardView addSubview:self.blurView];
    [self.blurView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    [self.blurView.contentView addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.startLabel];
    [self.contentView addSubview:self.startTimeButton];
    [self.contentView addSubview:self.endLabel];
    [self.contentView addSubview:self.endTimeButton];
    [self.contentView addSubview:self.infoLabel];
    [self.contentView addSubview:self.infoTextField];
    
    CGFloat leftInset = 20*kWidthRatio;
    CGFloat rightInset = -20*kWidthRatio;
    CGFloat labelWidth = 88*kWidthRatio;
    CGFloat rowHeight = 36*kHeightRatio;
    
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(22*kHeightRatio);
        make.left.offset(leftInset);
        make.right.offset(rightInset);
        make.height.mas_equalTo(34*kHeightRatio);
    }];
    [self.startLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(leftInset);
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(14*kHeightRatio);
        make.width.mas_equalTo(labelWidth);
        make.height.mas_equalTo(rowHeight);
    }];
    [self.startTimeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.startLabel.mas_right).offset(8*kWidthRatio);
        make.right.offset(rightInset);
        make.centerY.mas_equalTo(self.startLabel);
        make.height.mas_equalTo(rowHeight);
    }];
    [self.endLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.height.mas_equalTo(self.startLabel);
        make.top.mas_equalTo(self.startLabel.mas_bottom).offset(8*kHeightRatio);
    }];
    [self.endTimeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.mas_equalTo(self.startTimeButton);
        make.centerY.mas_equalTo(self.endLabel);
    }];
    [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.height.mas_equalTo(self.startLabel);
        make.top.mas_equalTo(self.endLabel.mas_bottom).offset(8*kHeightRatio);
    }];
    [self.infoTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.mas_equalTo(self.startTimeButton);
        make.centerY.mas_equalTo(self.infoLabel);
        make.bottom.offset(-22*kHeightRatio);
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    UIView *touchedView = touch.view;
    while (touchedView && touchedView != gestureRecognizer.view) {
        if ([touchedView isKindOfClass:UIControl.class]) {
            return NO;
        }
        touchedView = touchedView.superview;
    }
    return YES;
}

- (void)backgroundTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    CGPoint point = [recognizer locationInView:self.cardView];
    if (CGRectContainsPoint(self.cardView.bounds, point)) {
        [self dismissDatePickerPanelAnimated:YES];
        [self endEditing:YES];
        return;
    }
    if (self.datePickerPanelView.superview) {
        [self dismissDatePickerPanelAnimated:YES];
        return;
    }
    [self closeSavingChanges:YES];
}

- (void)startTimeTapped
{
    [self presentDatePickerForStartTime:YES anchor:self.startTimeButton];
}

- (void)endTimeTapped
{
    [self presentDatePickerForStartTime:NO anchor:self.endTimeButton];
}

- (void)presentDatePickerForStartTime:(BOOL)isStartTime anchor:(UIView *)anchor
{
    [self.infoTextField resignFirstResponder];
    self.editingStartTime = isStartTime;
    [self configureDatePickerForStartTime:isStartTime];
    [self showDatePickerPanelWithAnchor:anchor];
}

- (void)configureDatePickerForStartTime:(BOOL)isStartTime
{
    self.datePicker.datePickerMode = UIDatePickerModeTime;
    self.datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
    self.datePicker.date = [NSDate dateWithTimeIntervalSince1970:(isStartTime ? self.startTimestamp : self.endTimestamp)];
    self.datePicker.minimumDate = nil;
    self.datePicker.maximumDate = nil;
    if (isStartTime) {
        self.datePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:[self minimumStartTimestamp]];
        self.datePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    } else {
        self.datePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
        self.datePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.dayEnd];
    }
}

- (void)showDatePickerPanelWithAnchor:(UIView *)anchor
{
    UIWindow *window = self.window;
    if (!window || !anchor) {
        return;
    }
    if (self.datePickerDismissView.superview != window) {
        self.datePickerDismissView.frame = window.bounds;
        [window addSubview:self.datePickerDismissView];
    } else {
        self.datePickerDismissView.frame = window.bounds;
    }
    [window bringSubviewToFront:self.datePickerDismissView];
    
    if (!self.datePickerPanelView.superview) {
        [window addSubview:self.datePickerPanelView];
        [self.datePickerBlurView.contentView addSubview:self.datePicker];
        [self.datePicker mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.offset(0);
        }];
    }
    
    CGRect anchorFrame = [anchor convertRect:anchor.bounds toView:window];
    CGFloat horizontalInset = 24*kWidthRatio;
    CGFloat panelWidth = MIN(CGRectGetWidth(window.bounds) - horizontalInset * 2, 300*kWidthRatio);
    CGFloat panelHeight = 216*kHeightRatio;
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

- (void)datePickerDismissTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self dismissDatePickerPanelAnimated:YES];
    }
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
    };
    if (animated) {
        [UIView animateWithDuration:0.14 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:changes completion:completion];
    } else {
        changes();
        completion(YES);
    }
}

- (void)datePickerValueChanged:(UIDatePicker *)datePicker
{
    long timestamp = [self timestampOnSelectedDayFromDate:datePicker.date];
    if (self.editingStartTime) {
        timestamp = MAX(timestamp, [self minimumStartTimestamp]);
        timestamp = MIN(timestamp, self.endTimestamp - kMinSeconds);
        self.startTimestamp = timestamp;
    } else {
        timestamp = MAX(timestamp, self.startTimestamp + kMinSeconds);
        timestamp = MIN(timestamp, self.dayEnd);
        self.endTimestamp = timestamp;
    }
    self.datePicker.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    [self updateTimeButtonTitles];
}

- (void)infoTextFieldDidBeginEditing:(UITextField *)textField
{
    [self dismissDatePickerPanelAnimated:YES];
}

- (void)closeSavingChanges:(BOOL)shouldSaveChanges
{
    if (!self.superview) {
        return;
    }
    [self dismissDatePickerPanelAnimated:NO];
    [self endEditing:YES];
    if (!shouldSaveChanges) {
        [self removeFromSuperview];
        return;
    }
    if (self.endTimestamp - self.startTimestamp < kMinSeconds) {
        [self showMessage:@"End time must be after start time."];
        return;
    }
    MirrorScheduleModel *schedule = [[MirrorScheduleModel alloc] initWithInfo:self.infoTextField.text ?: @"" startTime:self.startTimestamp endTime:self.endTimestamp];
    schedule.originalIndex = self.schedule.originalIndex;
    ScheduleEditCompletion completion = self.completion;
    UIView *cardView = self.cardView;
    self.presentingViewController = nil;
    self.cardCenterYConstraint = nil;
    self.keyboardOverlap = 0;
    [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.alpha = 0;
        cardView.transform = CGAffineTransformMakeScale(0.94, 0.94);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (completion) {
            completion(schedule);
        }
    }];
}

- (void)updateTimeButtonTitles
{
    [self.startTimeButton setTitle:[self timeStringFromTimestamp:self.startTimestamp] forState:UIControlStateNormal];
    [self.endTimeButton setTitle:[self timeStringFromTimestamp:self.endTimestamp] forState:UIControlStateNormal];
}

- (void)updateAppearance
{
    UIColor *accentColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    UIColor *labelColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    UIColor *borderColor = [[UIColor mirrorColorNamed:MirrorColorTypeText] colorWithAlphaComponent:0.12];
    self.tintColor = accentColor;
    self.titleLabel.textColor = accentColor;
    self.startLabel.textColor = labelColor;
    self.endLabel.textColor = labelColor;
    self.infoLabel.textColor = labelColor;
    self.startTimeButton.tintColor = accentColor;
    self.endTimeButton.tintColor = accentColor;
    self.startTimeButton.layer.borderColor = borderColor.CGColor;
    self.endTimeButton.layer.borderColor = borderColor.CGColor;
    self.infoTextField.layer.borderColor = borderColor.CGColor;
    self.datePicker.tintColor = accentColor;
}

- (NSString *)timeStringFromTimestamp:(long)timestamp
{
    return [self.timeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

- (long)timestampOnSelectedDayFromDate:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDateComponents *dayComponents = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate dateWithTimeIntervalSince1970:self.dayStart]];
    NSDateComponents *timeComponents = [gregorian components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
    dayComponents.hour = timeComponents.hour;
    dayComponents.minute = timeComponents.minute;
    dayComponents.second = 0;
    long timestamp = lround([[gregorian dateFromComponents:dayComponents] timeIntervalSince1970]);
    return MIN(MAX(timestamp, self.dayStart), self.dayEnd);
}

- (long)minimumStartTimestamp
{
    return self.dayStart;
}

- (void)showMessage:(NSString *)message
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
    [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
}

- (UILabel *)pickerLabelWithText:(NSString *)text
{
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.adjustsFontSizeToFitWidth = YES;
    return label;
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

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.text = [MirrorLanguage mirror_stringWithKey:@"schedule"];
        _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.minimumScaleFactor = 0.6;
    }
    return _titleLabel;
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

- (UILabel *)infoLabel
{
    if (!_infoLabel) {
        _infoLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"schedule_info"]];
    }
    return _infoLabel;
}

- (UIButton *)startTimeButton
{
    if (!_startTimeButton) {
        _startTimeButton = [self timeButtonWithAction:@selector(startTimeTapped)];
    }
    return _startTimeButton;
}

- (UIButton *)endTimeButton
{
    if (!_endTimeButton) {
        _endTimeButton = [self timeButtonWithAction:@selector(endTimeTapped)];
    }
    return _endTimeButton;
}

- (UITextField *)infoTextField
{
    if (!_infoTextField) {
        _infoTextField = [UITextField new];
        _infoTextField.text = self.schedule.scheduleInfo ?: @"";
        _infoTextField.placeholder = [MirrorLanguage mirror_stringWithKey:@"schedule"];
        _infoTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        _infoTextField.borderStyle = UITextBorderStyleRoundedRect;
        _infoTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        [_infoTextField addTarget:self action:@selector(infoTextFieldDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
        [_infoTextField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    }
    return _infoTextField;
}

- (UIDatePicker *)datePicker
{
    if (!_datePicker) {
        _datePicker = [UIDatePicker new];
        _datePicker.datePickerMode = UIDatePickerModeTime;
        _datePicker.minuteInterval = 5;
        _datePicker.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 216*kHeightRatio);
        _datePicker.locale = [NSLocale localeWithLocaleIdentifier:@"en_GB"];
        [_datePicker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
        if (@available(iOS 13.4, *)) {
            _datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
        }
    }
    return _datePicker;
}

- (UIView *)datePickerDismissView
{
    if (!_datePickerDismissView) {
        _datePickerDismissView = [UIView new];
        _datePickerDismissView.backgroundColor = UIColor.clearColor;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(datePickerDismissTapped:)];
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

@end
