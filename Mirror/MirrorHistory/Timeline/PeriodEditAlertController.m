//
//  PeriodEditAlertController.m
//  Mirror
//

#import "PeriodEditAlertController.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"

@interface PeriodEditAlertController () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) UIAlertController *alertController;
@property (nonatomic, strong) TimelineRangeAxisView *rangeAxisView;
@property (nonatomic, strong) UITextField *noteTextField;
@property (nonatomic, strong) UITapGestureRecognizer *dismissTapRecognizer;
@property (nonatomic, copy) PeriodEditAlertRangeValueChanged valueChanged;
@property (nonatomic, copy) PeriodEditAlertDismissed dismissed;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIColor *axisColor;
@property (nonatomic, assign) long minimumTimestamp;
@property (nonatomic, assign) long maximumTimestamp;
@property (nonatomic, assign) long startTimestamp;
@property (nonatomic, assign) long endTimestamp;
@property (nonatomic, assign) BOOL canDragStart;
@property (nonatomic, assign) BOOL canDragEnd;
@property (nonatomic, copy) NSString *note;

@end

@implementation PeriodEditAlertController

- (instancetype)initWithTitle:(NSString *)title
                    axisColor:(UIColor *)axisColor
              minimumTimestamp:(long)minimumTimestamp
              maximumTimestamp:(long)maximumTimestamp
                startTimestamp:(long)startTimestamp
                  endTimestamp:(long)endTimestamp
                  canDragStart:(BOOL)canDragStart
                    canDragEnd:(BOOL)canDragEnd
                          note:(nullable NSString *)note
                  valueChanged:(PeriodEditAlertRangeValueChanged)valueChanged
                     dismissed:(PeriodEditAlertDismissed)dismissed
{
    self = [super init];
    if (self) {
        _title = [title copy];
        _axisColor = axisColor;
        _minimumTimestamp = minimumTimestamp;
        _maximumTimestamp = maximumTimestamp;
        _startTimestamp = startTimestamp;
        _endTimestamp = endTimestamp;
        _canDragStart = canDragStart;
        _canDragEnd = canDragEnd;
        _note = [note copy] ?: @"";
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
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.title
                                                                             message:@"\n\n\n\n\n\n\n\n"
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    self.alertController = alertController;
    [self configureContentInAlertController:alertController];
    
    __weak typeof(self) weakSelf = self;
    [viewController presentViewController:alertController animated:YES completion:^{
        [weakSelf addDismissTapRecognizer];
    }];
}

- (void)configureContentInAlertController:(UIAlertController *)alertController
{
    TimelineRangeAxisView *rangeAxisView = [TimelineRangeAxisView new];
    rangeAxisView.axisColor = self.axisColor;
    [rangeAxisView configureWithMinimumTimestamp:self.minimumTimestamp
                                maximumTimestamp:self.maximumTimestamp
                                   startTimestamp:self.startTimestamp
                                     endTimestamp:self.endTimestamp
                                     canDragStart:self.canDragStart
                                       canDragEnd:self.canDragEnd];
    __weak typeof(self) weakSelf = self;
    rangeAxisView.valueChanged = ^(BOOL isStartTime, long timestamp) {
        if (weakSelf.valueChanged) {
            weakSelf.valueChanged(isStartTime, timestamp);
        }
    };
    self.rangeAxisView = rangeAxisView;
    
    UILabel *noteLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"note"]];
    UITextField *noteTextField = [UITextField new];
    noteTextField.text = self.note;
    noteTextField.placeholder = [MirrorLanguage mirror_stringWithKey:@"note"];
    noteTextField.font = [UIFont mirrorHintFont];
    noteTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    noteTextField.borderStyle = UITextBorderStyleRoundedRect;
    noteTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [noteTextField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [noteTextField addTarget:self action:@selector(noteTextFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    self.noteTextField = noteTextField;
    
    UIView *contentView = alertController.view;
    [contentView addSubview:rangeAxisView];
    [contentView addSubview:noteLabel];
    [contentView addSubview:noteTextField];
    
    [rangeAxisView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(24);
        make.right.offset(-24);
        make.top.offset(54);
        make.height.mas_equalTo(72);
    }];
    [noteLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(24);
        make.top.mas_equalTo(rangeAxisView.mas_bottom).offset(8);
        make.width.mas_equalTo(90);
        make.height.mas_equalTo(30);
    }];
    [noteTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(noteLabel.mas_right).offset(8);
        make.centerY.mas_equalTo(noteLabel);
        make.right.offset(-24);
        make.width.mas_equalTo(130).priorityHigh();
        make.height.mas_equalTo(34);
    }];
}

- (UILabel *)pickerLabelWithText:(NSString *)text
{
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont mirrorHintFont];
    label.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    label.adjustsFontSizeToFitWidth = YES;
    return label;
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
    self.rangeAxisView = nil;
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
