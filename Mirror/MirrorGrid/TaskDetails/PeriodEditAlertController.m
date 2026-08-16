//
//  PeriodEditAlertController.m
//  Mirror
//

#import "PeriodEditAlertController.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "UIColor+MirrorColor.h"
#import "MirrorMacro.h"
#import "MirrorStorage.h"

@interface PeriodEditAlertController ()

@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, strong) UIAlertController *alertController;
@property (nonatomic, strong) UIView *taskNamePickerView;
@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) UILabel *startLabel;
@property (nonatomic, strong) UILabel *endLabel;
@property (nonatomic, strong) UILabel *noteLabel;
@property (nonatomic, strong) UIButton *previousTaskButton;
@property (nonatomic, strong) UIButton *nextTaskButton;
@property (nonatomic, strong) UIAlertAction *cancelAction;
@property (nonatomic, strong) UIAlertAction *doneAction;
@property (nonatomic, assign) NSInteger selectedTaskIndex;
@property (nonatomic, strong) UIDatePicker *startDatePicker;
@property (nonatomic, strong) UIDatePicker *endDatePicker;
@property (nonatomic, strong) UITextField *noteTextField;
@property (nonatomic, copy) PeriodEditAlertRecordChanged recordChanged;
@property (nonatomic, strong) MirrorRecordModel *editingRecord;
@property (nonatomic, strong) NSArray<MirrorTaskModel *> *tasks;
@property (nonatomic, assign) MirrorColorType taskColorType;
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
                  recordChanged:(PeriodEditAlertRecordChanged)recordChanged
{
    self = [super init];
    if (self) {
        MirrorTaskModel *taskModel = [MirrorStorage getTaskModelFromDB:record.taskName];
        MirrorColorType colorType = taskModel ? taskModel.color : MirrorColorTypeCellGray;
        MirrorRecordModel *editingRecord = [[MirrorRecordModel alloc] initWithTitle:record.taskName ?: @"" startTime:record.startTime endTime:record.endTime];
        editingRecord.originalIndex = record.originalIndex;
        editingRecord.note = record.note ?: @"";
        _editingRecord = editingRecord;
        _tasks = [[MirrorStorage retriveMirrorTasks] copy];
        _taskColorType = colorType;
        _accentColor = [UIColor mirrorColorPulsed:colorType];
        _minimumTimestamp = minimumTimestamp;
        _maximumTimestamp = maximumTimestamp;
        _startTimestamp = record.startTime;
        _endTimestamp = record.endTime;
        _note = [record.note copy] ?: @"";
        _recordChanged = [recordChanged copy];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged:) name:MirrorSwitchThemeNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)isPresented
{
    return self.alertController != nil;
}

- (void)presentFromViewController:(UIViewController *)viewController
{
    self.presentingViewController = viewController;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:@"\n\n\n\n\n\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    self.alertController = alertController;
    [self configureContentInAlertController:alertController];
    [self configureActionsInAlertController:alertController];
    
    [viewController presentViewController:alertController animated:YES completion:nil];
}

- (void)configureContentInAlertController:(UIAlertController *)alertController
{
    UIView *taskNamePickerView = [self taskNamePickerView];
    UILabel *startLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"starts_at"]];
    self.startLabel = startLabel;
    UIDatePicker *startDatePicker = [self timePickerWithTimestamp:self.startTimestamp];
    startDatePicker.minimumDate = self.minimumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.minimumTimestamp.longValue] : nil;
    startDatePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    [startDatePicker addTarget:self action:@selector(startDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.startDatePicker = startDatePicker;

    UILabel *endLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"ends_at"]];
    self.endLabel = endLabel;
    UIDatePicker *endDatePicker = [self timePickerWithTimestamp:self.endTimestamp];
    endDatePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
    endDatePicker.maximumDate = self.maximumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.maximumTimestamp.longValue] : nil;
    [endDatePicker addTarget:self action:@selector(endDatePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.endDatePicker = endDatePicker;

    UILabel *noteLabel = [self pickerLabelWithText:[MirrorLanguage mirror_stringWithKey:@"note"]];
    self.noteLabel = noteLabel;
    UITextField *noteTextField = [UITextField new];
    noteTextField.text = self.note;
    noteTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    noteTextField.textColor = self.accentColor;
    noteTextField.tintColor = self.accentColor;
    noteTextField.borderStyle = UITextBorderStyleRoundedRect;
    noteTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [noteTextField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [noteTextField addTarget:self action:@selector(noteTextFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    self.noteTextField = noteTextField;
    
    UIView *contentView = alertController.view;
    [contentView addSubview:taskNamePickerView];
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
    [taskNamePickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(20);
        make.left.offset(leftInset);
        make.right.offset(rightInset);
        make.height.mas_equalTo(30);
    }];
    [startLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(leftInset);
        make.top.mas_equalTo(taskNamePickerView.mas_bottom).offset(8);
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
    [noteTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.lessThanOrEqualTo(contentView).offset(-56);
    }];
}

- (void)configureActionsInAlertController:(UIAlertController *)alertController
{
    __weak typeof(self) weakSelf = self;
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [weakSelf cancel];
    }];
    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"done"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf dismiss];
    }];
    self.cancelAction = cancelAction;
    self.doneAction = doneAction;
    [alertController addAction:cancelAction];
    [alertController addAction:doneAction];
    [self updateAccentColorAppearance];
}

- (UIDatePicker *)timePickerWithTimestamp:(long)timestamp
{
    UIDatePicker *datePicker = [UIDatePicker new];
    datePicker.datePickerMode = UIDatePickerModeDateAndTime;
    datePicker.minuteInterval = 5;
    datePicker.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:[MirrorLanguage mirror_stringWithKey:@"locale_Identifier"]];
    datePicker.tintColor = self.accentColor;
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    }
    return datePicker;
}

- (UIView *)taskNamePickerView
{
    UIView *pickerView = [UIView new];
    UIButton *previousButton = [self taskArrowButtonWithSystemImageName:@"chevron.left" fallbackTitle:@"<" action:@selector(previousTaskButtonTapped:)];
    UIButton *nextButton = [self taskArrowButtonWithSystemImageName:@"chevron.right" fallbackTitle:@">" action:@selector(nextTaskButtonTapped:)];
    UILabel *taskNameLabel = [UILabel new];
    taskNameLabel.text = self.editingRecord.taskName;
    taskNameLabel.textColor = self.accentColor;
    taskNameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    taskNameLabel.textAlignment = NSTextAlignmentCenter;
    taskNameLabel.adjustsFontSizeToFitWidth = YES;
    taskNameLabel.minimumScaleFactor = 0.6;
    
    [pickerView addSubview:previousButton];
    [pickerView addSubview:taskNameLabel];
    [pickerView addSubview:nextButton];
    
    CGFloat buttonSize = 30;
    [previousButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.offset(0);
        make.width.mas_equalTo(buttonSize);
    }];
    [nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.offset(0);
        make.width.mas_equalTo(buttonSize);
    }];
    [taskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(previousButton.mas_right).offset(8);
        make.right.mas_equalTo(nextButton.mas_left).offset(-8);
        make.top.bottom.offset(0);
    }];
    
    self.selectedTaskIndex = [self indexOfTaskName:self.editingRecord.taskName];
    self.taskNamePickerView = pickerView;
    self.taskNameLabel = taskNameLabel;
    self.previousTaskButton = previousButton;
    self.nextTaskButton = nextButton;
    [self updateTaskArrowButtonsEnabled];
    return pickerView;
}

- (UIButton *)taskArrowButtonWithSystemImageName:(NSString *)systemImageName fallbackTitle:(NSString *)fallbackTitle action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.tintColor = self.accentColor;
    if (@available(iOS 13.0, *)) {
        [button setImage:[UIImage systemImageNamed:systemImageName] forState:UIControlStateNormal];
    } else {
        [button setTitle:fallbackTitle forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    }
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UILabel *)pickerLabelWithText:(NSString *)text
{
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    label.textColor = self.accentColor;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
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
    MirrorColorType colorType = taskModel ? taskModel.color : MirrorColorTypeCellGray;
    self.taskColorType = colorType;
    self.accentColor = [UIColor mirrorColorPulsed:colorType];
    self.taskNameLabel.text = taskName;
    [self updateAccentColorAppearance];
}

- (void)themeChanged:(NSNotification *)notification
{
    self.accentColor = [UIColor mirrorColorPulsed:self.taskColorType];
    [self updateAccentColorAppearance];
}

- (void)updateAccentColorAppearance
{
    self.alertController.view.tintColor = self.accentColor;
    self.taskNameLabel.textColor = self.accentColor;
    self.startLabel.textColor = self.accentColor;
    self.endLabel.textColor = self.accentColor;
    self.noteLabel.textColor = self.accentColor;
    self.previousTaskButton.tintColor = self.accentColor;
    self.nextTaskButton.tintColor = self.accentColor;
    self.startDatePicker.tintColor = self.accentColor;
    self.endDatePicker.tintColor = self.accentColor;
    self.noteTextField.textColor = self.accentColor;
    self.noteTextField.tintColor = self.accentColor;
    [self updateNotePlaceholderAppearance];
    [self.cancelAction setValue:self.accentColor forKey:@"titleTextColor"];
    [self.doneAction setValue:self.accentColor forKey:@"titleTextColor"];
}

- (void)updateNotePlaceholderAppearance
{
    UIColor *taskColor = [UIColor mirrorColorNamed:self.taskColorType];
    self.noteTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:[MirrorLanguage mirror_stringWithKey:@"note"] attributes:@{
        NSForegroundColorAttributeName: taskColor,
        NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
    }];
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
    long timestamp = round([datePicker.date timeIntervalSince1970]);
    if (self.minimumTimestamp) {
        timestamp = MAX(timestamp, self.minimumTimestamp.longValue);
    }
    timestamp = MIN(timestamp, self.endTimestamp - kMinSeconds);
    self.startTimestamp = timestamp;
    self.editingRecord.startTime = timestamp;
    self.endDatePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
}

- (void)endDatePickerValueChanged:(UIDatePicker *)datePicker
{
    long timestamp = round([datePicker.date timeIntervalSince1970]);
    timestamp = MAX(timestamp, self.startTimestamp + kMinSeconds);
    if (self.maximumTimestamp) {
        timestamp = MIN(timestamp, self.maximumTimestamp.longValue);
    }
    self.endTimestamp = timestamp;
    self.editingRecord.endTime = timestamp;
    self.startDatePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
}

- (void)dismiss
{
    [self closeAlertSavingChanges:YES];
}

- (void)cancel
{
    [self closeAlertSavingChanges:NO];
}

- (void)closeAlertSavingChanges:(BOOL)shouldSaveChanges
{
    UIAlertController *alertController = self.alertController;
    if (alertController == nil) {
        return;
    }
    
    MirrorRecordModel *editedRecord = nil;
    PeriodEditAlertRecordChanged recordChanged = nil;
    if (shouldSaveChanges) {
        self.editingRecord.note = self.noteTextField.text ?: @"";
        editedRecord = self.editingRecord;
        recordChanged = self.recordChanged;
    }
    
    self.taskNamePickerView = nil;
    self.taskNameLabel = nil;
    self.startLabel = nil;
    self.endLabel = nil;
    self.noteLabel = nil;
    self.previousTaskButton = nil;
    self.nextTaskButton = nil;
    self.cancelAction = nil;
    self.doneAction = nil;
    self.startDatePicker = nil;
    self.endDatePicker = nil;
    self.noteTextField = nil;
    self.alertController = nil;
    [alertController dismissViewControllerAnimated:YES completion:^{
        if (recordChanged) {
            recordChanged(editedRecord);
        }
    }];
}

- (void)noteTextFieldEditingChanged:(UITextField *)textField
{
    if (textField.text.length > 200) {
        textField.text = [textField.text substringToIndex:200];
    }
}

@end
