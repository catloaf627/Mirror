//
//  PeriodEditView.m
//  Mirror
//

#import "PeriodEditView.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "MirrorMacro.h"
#import "MirrorStorage.h"
#import "UIColor+MirrorColor.h"

@interface PeriodEditView ()

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
@property (nonatomic, strong) UITextField *startDateInputField;
@property (nonatomic, strong) UITextField *endDateInputField;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UIView *buttonSeparatorView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, assign) NSInteger selectedTaskIndex;
@property (nonatomic, strong) MirrorRecordModel *editingRecord;
@property (nonatomic, strong) NSArray<MirrorTaskModel *> *tasks;
@property (nonatomic, assign) MirrorColorType taskColorType;
@property (nonatomic, strong) UIColor *accentColor;
@property (nonatomic, strong, nullable) NSNumber *minimumTimestamp;
@property (nonatomic, strong, nullable) NSNumber *maximumTimestamp;
@property (nonatomic, assign) long startTimestamp;
@property (nonatomic, assign) long endTimestamp;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;

@end

@implementation PeriodEditView

- (instancetype)initWithRecord:(MirrorRecordModel *)record
                         tasks:(NSArray<MirrorTaskModel *> *)tasks
              minimumTimestamp:(NSNumber * _Nullable)minimumTimestamp
              maximumTimestamp:(NSNumber * _Nullable)maximumTimestamp
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        MirrorTaskModel *taskModel = [MirrorStorage getTaskModelFromDB:record.taskName];
        MirrorColorType colorType = taskModel ? taskModel.color : MirrorColorTypeCellGray;
        MirrorRecordModel *editingRecord = [[MirrorRecordModel alloc] initWithTitle:record.taskName ?: @"" startTime:record.startTime endTime:record.endTime];
        editingRecord.originalIndex = record.originalIndex;
        editingRecord.note = record.note ?: @"";
        _editingRecord = editingRecord;
        _tasks = [tasks copy] ?: @[];
        _taskColorType = colorType;
        _accentColor = [UIColor mirrorColorPulsed:colorType];
        _minimumTimestamp = minimumTimestamp;
        _maximumTimestamp = maximumTimestamp;
        _startTimestamp = record.startTime;
        _endTimestamp = record.endTime;
        [self setupFormatters];
        [self setupViews];
        [self updateAccentColorAppearance];
        [self updateTimeButtonTitles];
    }
    return self;
}

- (MirrorRecordModel *)editedRecord
{
    self.editingRecord.note = self.noteTextField.text ?: @"";
    return self.editingRecord;
}

- (void)refreshAppearanceForCurrentTheme
{
    self.accentColor = [UIColor mirrorColorPulsed:self.taskColorType];
    [self updateAccentColorAppearance];
}

- (void)setupFormatters
{
    self.timeFormatter = [NSDateFormatter new];
    self.timeFormatter.locale = [NSLocale localeWithLocaleIdentifier:[MirrorLanguage mirror_stringWithKey:@"locale_Identifier"]];
    self.timeFormatter.timeStyle = NSDateFormatterShortStyle;
    self.timeFormatter.dateStyle = NSDateFormatterNoStyle;
}

- (void)setupViews
{
    self.backgroundColor = UIColor.clearColor;
    self.clipsToBounds = YES;
    self.layer.cornerRadius = 16;

    [self addSubview:self.taskNamePickerView];
    [self addSubview:self.startLabel];
    [self addSubview:self.startTimeButton];
    [self addSubview:self.startCalendarButton];
    [self addSubview:self.endLabel];
    [self addSubview:self.endTimeButton];
    [self addSubview:self.endCalendarButton];
    [self addSubview:self.noteLabel];
    [self addSubview:self.noteTextField];
    [self addSubview:self.startDateInputField];
    [self addSubview:self.endDateInputField];
    [self addSubview:self.separatorView];
    [self addSubview:self.buttonSeparatorView];
    [self addSubview:self.cancelButton];
    [self addSubview:self.doneButton];

    CGFloat leftInset = 20;
    CGFloat rightInset = -20;
    CGFloat labelWidth = 88;
    CGFloat rowHeight = 36;
    CGFloat buttonHeight = 48;

    [self.taskNamePickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(22);
        make.left.offset(leftInset);
        make.right.offset(rightInset);
        make.height.mas_equalTo(34);
    }];
    [self.startLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(leftInset);
        make.top.mas_equalTo(self.taskNamePickerView.mas_bottom).offset(14);
        make.width.mas_equalTo(labelWidth);
        make.height.mas_equalTo(rowHeight);
    }];
    [self.startTimeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.startLabel.mas_right).offset(8);
        make.centerY.mas_equalTo(self.startLabel);
        make.right.mas_equalTo(self.startCalendarButton.mas_left).offset(-8);
        make.height.mas_equalTo(rowHeight);
    }];
    [self.startCalendarButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(rightInset);
        make.centerY.mas_equalTo(self.startLabel);
        make.width.height.mas_equalTo(rowHeight);
    }];
    [self.endLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.width.height.mas_equalTo(self.startLabel);
        make.top.mas_equalTo(self.startLabel.mas_bottom).offset(8);
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
        make.left.width.height.mas_equalTo(self.startLabel);
        make.top.mas_equalTo(self.endLabel.mas_bottom).offset(8);
    }];
    [self.noteTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.startTimeButton);
        make.right.offset(rightInset);
        make.height.mas_equalTo(self.startTimeButton);
        make.centerY.mas_equalTo(self.noteLabel);
    }];
    [self.startDateInputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.offset(0);
        make.width.height.mas_equalTo(1);
    }];
    [self.endDateInputField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.offset(0);
        make.width.height.mas_equalTo(1);
    }];
    [self.separatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.noteTextField.mas_bottom).offset(18);
        make.left.right.offset(0);
        make.height.mas_equalTo(1.0 / UIScreen.mainScreen.scale);
    }];
    [self.buttonSeparatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.separatorView.mas_bottom);
        make.bottom.offset(0);
        make.centerX.mas_equalTo(self);
        make.width.mas_equalTo(1.0 / UIScreen.mainScreen.scale);
    }];
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.separatorView.mas_bottom);
        make.left.bottom.offset(0);
        make.right.mas_equalTo(self.buttonSeparatorView.mas_left);
        make.height.mas_equalTo(buttonHeight);
    }];
    [self.doneButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.width.mas_equalTo(self.cancelButton);
        make.left.mas_equalTo(self.buttonSeparatorView.mas_right);
        make.right.offset(0);
    }];

    self.startDatePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    self.endDatePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
    self.startDatePicker.minimumDate = self.minimumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.minimumTimestamp.longValue] : nil;
    self.endDatePicker.maximumDate = self.maximumTimestamp ? [NSDate dateWithTimeIntervalSince1970:self.maximumTimestamp.longValue] : nil;
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
            make.width.mas_equalTo(30);
        }];
        [self.nextTaskButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.top.bottom.offset(0);
            make.width.mas_equalTo(30);
        }];
        [self.taskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.previousTaskButton.mas_right).offset(8);
            make.right.mas_equalTo(self.nextTaskButton.mas_left).offset(-8);
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

- (UITextField *)startDateInputField
{
    if (!_startDateInputField) {
        _startDateInputField = [UITextField new];
        _startDateInputField.alpha = 0;
        _startDateInputField.inputView = self.startDatePicker;
    }
    return _startDateInputField;
}

- (UITextField *)endDateInputField
{
    if (!_endDateInputField) {
        _endDateInputField = [UITextField new];
        _endDateInputField.alpha = 0;
        _endDateInputField.inputView = self.endDatePicker;
    }
    return _endDateInputField;
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
    }
    return _noteTextField;
}

- (UIView *)separatorView
{
    if (!_separatorView) {
        _separatorView = [UIView new];
    }
    return _separatorView;
}

- (UIView *)buttonSeparatorView
{
    if (!_buttonSeparatorView) {
        _buttonSeparatorView = [UIView new];
    }
    return _buttonSeparatorView;
}

- (UIButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [self actionButtonWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] action:@selector(cancelButtonTapped:)];
    }
    return _cancelButton;
}

- (UIButton *)doneButton
{
    if (!_doneButton) {
        _doneButton = [self actionButtonWithTitle:[MirrorLanguage mirror_stringWithKey:@"done"] action:@selector(doneButtonTapped:)];
    }
    return _doneButton;
}

- (UIDatePicker *)datePickerWithTimestamp:(long)timestamp
{
    UIDatePicker *datePicker = [UIDatePicker new];
    datePicker.datePickerMode = UIDatePickerModeTime;
    datePicker.minuteInterval = 5;
    datePicker.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, 216);
    datePicker.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:[MirrorLanguage mirror_stringWithKey:@"locale_Identifier"]];
    datePicker.tintColor = self.accentColor;
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }
    return datePicker;
}

- (UIButton *)calendarButtonWithAction:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setImage:[UIImage systemImageNamed:@"calendar"] forState:UIControlStateNormal];
    button.layer.cornerRadius = 8;
    button.layer.borderWidth = 1;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)timeButtonWithAction:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    button.layer.cornerRadius = 8;
    button.layer.borderWidth = 1;
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)taskArrowButtonWithSystemImageName:(NSString *)systemImageName action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setImage:[UIImage systemImageNamed:systemImageName] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)actionButtonWithTitle:(NSString *)title action:(SEL)action
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
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
                 inputField:self.startDateInputField
                      mode:UIDatePickerModeTime
       dismissingInputField:self.endDateInputField];
}

- (void)endTimeButtonTapped:(UIButton *)button
{
    [self presentDatePicker:self.endDatePicker
                 inputField:self.endDateInputField
                      mode:UIDatePickerModeTime
       dismissingInputField:self.startDateInputField];
}

- (void)startCalendarButtonTapped:(UIButton *)button
{
    [self presentDatePicker:self.startDatePicker
                 inputField:self.startDateInputField
                      mode:UIDatePickerModeDateAndTime
       dismissingInputField:self.endDateInputField];
}

- (void)endCalendarButtonTapped:(UIButton *)button
{
    [self presentDatePicker:self.endDatePicker
                 inputField:self.endDateInputField
                      mode:UIDatePickerModeDateAndTime
       dismissingInputField:self.startDateInputField];
}

- (void)presentDatePicker:(UIDatePicker *)datePicker
               inputField:(UITextField *)inputField
                     mode:(UIDatePickerMode)mode
      dismissingInputField:(UITextField *)dismissingInputField
{
    [dismissingInputField resignFirstResponder];
    if (datePicker.datePickerMode != mode) {
        datePicker.datePickerMode = mode;
        [inputField reloadInputViews];
    }
    [inputField becomeFirstResponder];
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
    self.startDatePicker.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    self.endDatePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
    [self updateTimeButtonTitles];
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
    self.endDatePicker.date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    self.startDatePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    [self updateTimeButtonTitles];
}

- (void)updateTimeButtonTitles
{
    NSString *startTitle = [self.timeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.startTimestamp]] ?: @"";
    NSString *endTitle = [self.timeFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:self.endTimestamp]] ?: @"";
    [self.startTimeButton setTitle:startTitle forState:UIControlStateNormal];
    [self.endTimeButton setTitle:endTitle forState:UIControlStateNormal];
}

- (void)cancelButtonTapped:(UIButton *)button
{
    if (self.cancelHandler) {
        self.cancelHandler();
    }
}

- (void)doneButtonTapped:(UIButton *)button
{
    if (self.doneHandler) {
        self.doneHandler();
    }
}

- (void)noteTextFieldEditingChanged:(UITextField *)textField
{
    if (textField.text.length > 200) {
        textField.text = [textField.text substringToIndex:200];
    }
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
    self.noteTextField.textColor = self.accentColor;
    self.noteTextField.tintColor = self.accentColor;
    self.separatorView.backgroundColor = separatorColor;
    self.buttonSeparatorView.backgroundColor = separatorColor;
    self.startTimeButton.tintColor = self.accentColor;
    self.endTimeButton.tintColor = self.accentColor;
    self.startCalendarButton.tintColor = self.accentColor;
    self.endCalendarButton.tintColor = self.accentColor;
    self.startTimeButton.layer.borderColor = borderColor.CGColor;
    self.endTimeButton.layer.borderColor = borderColor.CGColor;
    self.startCalendarButton.layer.borderColor = borderColor.CGColor;
    self.endCalendarButton.layer.borderColor = borderColor.CGColor;
    [self.cancelButton setTitleColor:self.accentColor forState:UIControlStateNormal];
    [self.doneButton setTitleColor:self.accentColor forState:UIControlStateNormal];
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
