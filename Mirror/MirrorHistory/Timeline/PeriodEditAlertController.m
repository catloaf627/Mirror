//
//  PeriodEditAlertController.m
//  Mirror
//

#import "PeriodEditAlertController.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"
#import "MirrorStorage.h"

@interface PeriodEditAlertController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) UIAlertController *alertController;
@property (nonatomic, strong) UIDatePicker *startDatePicker;
@property (nonatomic, strong) UIDatePicker *endDatePicker;
@property (nonatomic, strong) UITextField *noteTextField;
@property (nonatomic, strong) UITapGestureRecognizer *dismissTapRecognizer;
@property (nonatomic, copy) PeriodEditAlertTimeValueChanged valueChanged;
@property (nonatomic, copy) PeriodEditAlertDismissed dismissed;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIColor *accentColor;
@property (nonatomic, strong, nullable) NSNumber *minimumTimestamp;
@property (nonatomic, strong, nullable) NSNumber *maximumTimestamp;
@property (nonatomic, assign) long startTimestamp;
@property (nonatomic, assign) long endTimestamp;
@property (nonatomic, copy) NSString *note;

@end

@implementation PeriodEditAlertController

- (instancetype)initWithRecord:(MirrorRecordModel *)record
               minimumTimestamp:(NSNumber * _Nullable)minimumTimestamp
               maximumTimestamp:(NSNumber * _Nullable)maximumTimestamp
                   valueChanged:(PeriodEditAlertTimeValueChanged)valueChanged
                      dismissed:(PeriodEditAlertDismissed)dismissed
{
    self = [super init];
    if (self) {
        MirrorTaskModel *taskModel = [MirrorStorage getTaskModelFromDB:record.taskName];
        MirrorColorType colorType = taskModel ? taskModel.color : MirrorColorTypeCellGray;
        _title = [record.taskName copy];
        _accentColor = [UIColor mirrorColorPulsed:colorType];
        _minimumTimestamp = minimumTimestamp;
        _maximumTimestamp = maximumTimestamp;
        _startTimestamp = record.startTime;
        _endTimestamp = record.endTime;
        _note = [record.note copy] ?: @"";
        _valueChanged = [valueChanged copy];
        _dismissed = [dismissed copy];
    }
    return self;
}

- (BOOL)isPresented
{
    return self.dismissTapRecognizer != nil;
}

- (void)presentFromViewController:(UIViewController *)viewController
{
    self.presentingViewController = viewController;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"\n\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    self.alertController = alertController;
    [self configureContentInAlertController:alertController];
    
    __weak typeof(self) weakSelf = self;
    [viewController presentViewController:alertController animated:YES completion:^{
        [weakSelf addDismissTapRecognizer];
    }];
}

- (void)configureContentInAlertController:(UIAlertController *)alertController
{
    UILabel *titleLabel = [self titleLabelWithText:self.title];
    UILabel *startLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"starts_at"]];
    UIDatePicker *startDatePicker = [self timePickerWithTimestamp:self.startTimestamp];
    startDatePicker.minimumDate = self.minimumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.minimumTimestamp.longValue] : nil;
    startDatePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    [startDatePicker addTarget:self action:@selector(startDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.startDatePicker = startDatePicker;

    UILabel *endLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"ends_at"]];
    UIDatePicker *endDatePicker = [self timePickerWithTimestamp:self.endTimestamp];
    endDatePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
    endDatePicker.maximumDate = self.maximumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.maximumTimestamp.longValue] : nil;
    [endDatePicker addTarget:self action:@selector(endDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.endDatePicker = endDatePicker;

    UILabel *noteLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"note"]];
    UITextField *noteTextField = [UITextField new];
    noteTextField.text = self.note;
    noteTextField.placeholder = [MirrorLanguage mirror_stringWithKey:@"note"];
    noteTextField.font = [UIFont mirrorHintFont];
    noteTextField.textColor = self.accentColor;
    noteTextField.tintColor = self.accentColor;
    noteTextField.borderStyle = UITextBorderStyleRoundedRect;
    noteTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [noteTextField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [noteTextField addTarget:self action:@selector(noteTextFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    self.noteTextField = noteTextField;
    
    UIView *contentView = alertController.view;
    [contentView addSubview:titleLabel];
    [contentView addSubview:startLabel];
    [contentView addSubview:startDatePicker];
    [contentView addSubview:endLabel];
    [contentView addSubview:endDatePicker];
    [contentView addSubview:noteLabel];
    [contentView addSubview:noteTextField];
    
    CGFloat leftInset = 24;
    CGFloat rightInset = -24;
    CGFloat labelWidth = 88;
    CGFloat rowHeight = 34;
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(20);
        make.left.offset(leftInset);
        make.right.offset(rightInset);
        make.height.mas_equalTo(26);
    }];
    [startLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(leftInset);
        make.top.mas_equalTo(titleLabel.mas_bottom).offset(8);
        make.width.mas_equalTo(labelWidth);
        make.height.mas_equalTo(rowHeight);
    }];
    [startDatePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(startLabel.mas_right).offset(8);
        make.centerY.mas_equalTo(startLabel);
        make.right.offset(rightInset);
        make.height.mas_equalTo(rowHeight);
    }];
    [endLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.height.mas_equalTo(startLabel);
        make.top.mas_equalTo(startLabel.mas_bottom).offset(8);
    }];
    [endDatePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.mas_equalTo(startDatePicker);
        make.centerY.mas_equalTo(endLabel);
    }];
    [noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.height.mas_equalTo(startLabel);
        make.top.mas_equalTo(endLabel.mas_bottom).offset(8);
    }];
    [noteTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.mas_equalTo(startDatePicker);
        make.centerY.mas_equalTo(noteLabel);
    }];
}

- (UIDatePicker *)timePickerWithTimestamp:(long)timestamp
{
    UIDatePicker *datePicker = [UIDatePicker new];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    datePicker.minuteInterval = 5;
    datePicker.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    datePicker.tintColor = self.accentColor;
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    }
    return datePicker;
}

- (UILabel *)titleLabelWithText:(NSString *)text
{
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont mirrorTitleFont];
    label.textColor = self.accentColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

- (UILabel *)pickerLabelWithText:(NSString *)text
{
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont mirrorHintFont];
    label.textColor = self.accentColor;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

- (void)startDatePickerValueChanged:(UIDatePicker *)datePicker
{
    long timestamp = round([datePicker.date timeIntervalSince1970]);
    if (self.minimumTimestamp) {
        timestamp = MAX(timestamp, self.minimumTimestamp.longValue);
    }
    timestamp = MIN(timestamp, self.endTimestamp - kMinSeconds);
    self.startTimestamp = timestamp;
    self.endDatePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
    if (self.valueChanged) {
        self.valueChanged(YES, timestamp);
    }
}

- (void)endDatePickerValueChanged:(UIDatePicker *)datePicker
{
    long timestamp = round([datePicker.date timeIntervalSince1970]);
    timestamp = MAX(timestamp, self.startTimestamp + kMinSeconds);
    if (self.maximumTimestamp) {
        timestamp = MIN(timestamp, self.maximumTimestamp.longValue);
    }
    self.endTimestamp = timestamp;
    self.startDatePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    if (self.valueChanged) {
        self.valueChanged(NO, timestamp);
    }
}

- (void)addDismissTapRecognizer
{
    if (self.dismissTapRecognizer != nil) {
        return;
    }
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTapRecognized:)];
    tapRecognizer.cancelsTouchesInView = NO;
    tapRecognizer.delegate = self;
    self.dismissTapRecognizer = tapRecognizer;
    [self.presentingViewController.view.window addGestureRecognizer:tapRecognizer];
}

- (void)dismissTapRecognized:(UITapGestureRecognizer *)tapRecognizer
{
    if (tapRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    [self dismiss];
}

- (void)dismiss
{
    UIAlertController *alertController = self.alertController;
    if (alertController == nil) {
        [self removeDismissTapRecognizer];
        return;
    }
    
    NSString *note = self.noteTextField.text ?: @"";
    PeriodEditAlertDismissed dismissed = self.dismissed;
    [self removeDismissTapRecognizer];
    self.startDatePicker = nil;
    self.endDatePicker = nil;
    self.noteTextField = nil;
    self.alertController = nil;
    [alertController dismissViewControllerAnimated:YES completion:^{
        if (dismissed) {
            dismissed(note);
        }
    }];
}

- (void)noteTextFieldEditingChanged:(UITextField *)textField
{
    if (textField.text.length > 200) {
        textField.text = [textField.text substringToIndex:200];
    }
}

- (void)removeDismissTapRecognizer
{
    [self.presentingViewController.view.window removeGestureRecognizer:self.dismissTapRecognizer];
    self.dismissTapRecognizer = nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer != self.dismissTapRecognizer) {
        return YES;
    }
    return [self shouldDismissForTouch:touch];
}

- (BOOL)shouldDismissForTouch:(UITouch *)touch
{
    UIView *alertView = self.alertController.view;
    UIWindow *window = touch.window ?: self.presentingViewController.view.window;
    if (alertView == nil || window == nil) {
        return NO;
    }
    
    CGPoint windowPoint = [touch locationInView:window];
    if ([self point:windowPoint inView:alertView window:window]) {
        return NO;
    }
    if ([self point:windowPoint isInsideInteractivePickerFromTouchedView:touch.view window:window]) {
        return NO;
    }
    return YES;
}

- (BOOL)point:(CGPoint)point isInsideInteractivePickerFromTouchedView:(UIView *)touchedView window:(UIWindow *)window
{
    UIView *currentView = touchedView;
    while (currentView != nil) {
        NSString *className = NSStringFromClass([currentView class]);
        BOOL isPickerView = [className containsString:@"DatePicker"] ||
                            [className containsString:@"Calendar"] ||
                            [className containsString:@"TimePicker"] ||
                            [self isPopoverContentView:currentView className:className window:window];
        if (isPickerView && [self point:point inView:currentView window:window]) {
            return YES;
        }
        currentView = currentView.superview;
    }
    return NO;
}

- (BOOL)isPopoverContentView:(UIView *)view className:(NSString *)className window:(UIWindow *)window
{
    if (![className containsString:@"Popover"]) {
        return NO;
    }
    CGRect rect = [view convertRect:view.bounds toView:window];
    return CGRectGetWidth(rect) < CGRectGetWidth(window.bounds) * 0.9 &&
           CGRectGetHeight(rect) < CGRectGetHeight(window.bounds) * 0.9;
}

- (BOOL)point:(CGPoint)point inView:(UIView *)view window:(UIWindow *)window
{
    CGRect rect = [view convertRect:view.bounds toView:window];
    return CGRectContainsPoint(rect, point);
}

- (void)dealloc
{
    [self removeDismissTapRecognizer];
}

@end
