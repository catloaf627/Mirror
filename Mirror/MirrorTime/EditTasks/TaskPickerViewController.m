//
//  TaskPickerViewController.m
//  Mirror
//

#import "TaskPickerViewController.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorLanguage.h"

static CGFloat const kTaskPickerBackdropAlpha = 0.82;
static CGFloat const kTaskPickerShadowOpacity = 0.25;
static CGFloat const kTaskPickerShadowRadius = 10;
static CGFloat const kTaskPickerShadowYOffset = 4;
static CGFloat const kTaskPickerRowHeight = 40;
static CGFloat const kTaskPickerRowWidth = 180;
static CGFloat const kTaskPickerDotSize = 16;
static CGFloat const kTaskPickerNotePrefixCheckboxSize = 18;
static CGFloat const kTaskPickerHorizontalPadding = 12;
static CGFloat const kTaskPickerRowSpacing = 8;
static CGFloat const kTaskPickerNotePrefixSpacing = 18;
static CGFloat const kTaskPickerNotePrefixLabelSpacing = 6;
static CGFloat const kTaskPickerCornerRadius = 12;
static CGFloat const kTaskPickerTitleSpacing = 12;

@interface TaskPickerViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray<MirrorTaskModel *> *tasks;
@property (nonatomic, copy) NSString *sourceTaskName;
@property (nonatomic, copy) TaskPickerCompletion completion;
@property (nonatomic, strong) UIView *pickerView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *taskButtons;
@property (nonatomic, strong) UIButton *notePrefixButton;
@property (nonatomic, strong) UILabel *notePrefixLabel;
@property (nonatomic, assign) BOOL shouldPrefixRecordNotes;

@end

@implementation TaskPickerViewController

- (instancetype)initWithTasks:(NSArray<MirrorTaskModel *> *)tasks
                sourceTaskName:(NSString *)sourceTaskName
                   completion:(TaskPickerCompletion)completion
{
    self = [super init];
    if (self) {
        _tasks = tasks;
        _sourceTaskName = [sourceTaskName copy];
        _completion = completion;
        _taskButtons = [NSMutableArray new];
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor mirrorColorNamed:MirrorColorTypeText] colorWithAlphaComponent:kTaskPickerBackdropAlpha]; // dim view
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPicker)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
    [self.view addSubview:self.pickerView];
    [self.pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
        make.width.mas_equalTo(kTaskPickerRowWidth);
    }];
    
    UILabel *titleLabel = [self pickerTitleLabelWithText:[MirrorLanguage mirror_stringWithKey:@"merge_task_to" with1Placeholder:self.sourceTaskName]];
    [self.pickerView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.pickerView);
    }];
    
    UIView *notePrefixContainer = [UIView new];
    [self.pickerView addSubview:notePrefixContainer];
    [notePrefixContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.pickerView);
        make.left.greaterThanOrEqualTo(self.pickerView);
        make.right.lessThanOrEqualTo(self.pickerView);
        make.top.mas_equalTo(titleLabel.mas_bottom).offset(kTaskPickerTitleSpacing);
        if (self.tasks.count == 0) {
            make.bottom.mas_equalTo(self.pickerView);
        }
    }];
    
    [notePrefixContainer addSubview:self.notePrefixButton];
    [self.notePrefixButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.mas_equalTo(notePrefixContainer);
        make.width.height.mas_equalTo(kTaskPickerNotePrefixCheckboxSize);
    }];
    
    [notePrefixContainer addSubview:self.notePrefixLabel];
    [self.notePrefixLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.notePrefixButton.mas_right).offset(kTaskPickerNotePrefixLabelSpacing);
        make.right.mas_equalTo(notePrefixContainer);
        make.centerY.mas_equalTo(self.notePrefixButton);
    }];
    [self updateNotePrefixButtonAppearance];
    
    UIView *previousRow = nil;
    for (NSInteger index = 0; index < self.tasks.count; index++) {
        MirrorTaskModel *task = self.tasks[index];
        UIButton *button = [self taskButtonWithTask:task index:index];
        [self.pickerView addSubview:button];
        [self.taskButtons addObject:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(self.pickerView);
            make.height.mas_equalTo(kTaskPickerRowHeight);
            if (previousRow) {
                make.top.mas_equalTo(previousRow.mas_bottom).offset(kTaskPickerRowSpacing);
            } else {
                make.top.mas_equalTo(notePrefixContainer.mas_bottom).offset(kTaskPickerNotePrefixSpacing);
            }
            if (index == self.tasks.count - 1) {
                make.bottom.mas_equalTo(self.pickerView);
            }
        }];
        previousRow = button;
    }
}

- (UILabel *)pickerTitleLabelWithText:(NSString *)text
{
    UILabel *label = [UILabel new];
    label.text = text;
    label.textColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    label.font = [UIFont mirrorLabelFont];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 1;
    label.adjustsFontSizeToFitWidth = YES;
    return label;
}

- (UIButton *)taskButtonWithTask:(MirrorTaskModel *)task index:(NSInteger)index
{
    BOOL isSourceTask = [task.taskName isEqualToString:self.sourceTaskName];
    UIButton *button = [UIButton new];
    button.tag = index;
    button.enabled = !isSourceTask;
    button.alpha = isSourceTask ? 0.2 : 1;
    button.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    button.layer.cornerRadius = kTaskPickerCornerRadius;
    button.layer.masksToBounds = YES;
    [button addTarget:self action:@selector(selectTask:) forControlEvents:UIControlEventTouchUpInside];
    
    UIView *colorView = [UIView new];
    colorView.userInteractionEnabled = NO;
    colorView.backgroundColor = [UIColor mirrorColorNamed:task.color];
    colorView.layer.cornerRadius = kTaskPickerDotSize / 2;
    colorView.layer.masksToBounds = YES;
    [button addSubview:colorView];
    [colorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(button).offset(kTaskPickerHorizontalPadding);
        make.centerY.mas_equalTo(button);
        make.width.height.mas_equalTo(kTaskPickerDotSize);
    }];
    
    UILabel *nameLabel = [UILabel new];
    nameLabel.userInteractionEnabled = NO;
    nameLabel.text = task.taskName;
    nameLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    nameLabel.font = [UIFont mirrorHintFont_Card];
    nameLabel.numberOfLines = 1;
    nameLabel.adjustsFontSizeToFitWidth = YES;
    [button addSubview:nameLabel];
    [nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(colorView.mas_right).offset(kTaskPickerHorizontalPadding);
        make.right.mas_equalTo(button).offset(-kTaskPickerHorizontalPadding);
        make.centerY.mas_equalTo(button);
    }];
    
    return button;
}

- (void)selectTask:(UIButton *)button
{
    if (button.tag < 0 || button.tag >= self.tasks.count) {
        return;
    }
    MirrorTaskModel *task = self.tasks[button.tag];
    if ([task.taskName isEqualToString:self.sourceTaskName]) {
        return;
    }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.completion) {
            self.completion(task, self.shouldPrefixRecordNotes);
        }
    }];
}

- (void)toggleNotePrefix
{
    self.shouldPrefixRecordNotes = !self.shouldPrefixRecordNotes;
    [self updateNotePrefixButtonAppearance];
}

- (void)updateNotePrefixButtonAppearance
{
    UIColor *blueColor = [UIColor systemBlueColor];
    self.notePrefixButton.backgroundColor = self.shouldPrefixRecordNotes ? blueColor : [UIColor clearColor];
    self.notePrefixButton.layer.borderColor = blueColor.CGColor;
    [self.notePrefixButton setTitle:self.shouldPrefixRecordNotes ? @"✓" : @"" forState:UIControlStateNormal];
}

- (void)dismissPicker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return ![touch.view isDescendantOfView:self.pickerView];
}

- (UIView *)pickerView
{
    if (!_pickerView) {
        _pickerView = [UIView new];
        _pickerView.backgroundColor = [UIColor clearColor];
        _pickerView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
        _pickerView.layer.shadowOpacity = kTaskPickerShadowOpacity;
        _pickerView.layer.shadowRadius = kTaskPickerShadowRadius;
        _pickerView.layer.shadowOffset = CGSizeMake(0, kTaskPickerShadowYOffset);
    }
    return _pickerView;
}

- (UIButton *)notePrefixButton
{
    if (!_notePrefixButton) {
        _notePrefixButton = [UIButton new];
        _notePrefixButton.layer.cornerRadius = 3;
        _notePrefixButton.layer.borderWidth = 1.5;
        _notePrefixButton.layer.masksToBounds = YES;
        _notePrefixButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [_notePrefixButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_notePrefixButton addTarget:self action:@selector(toggleNotePrefix) forControlEvents:UIControlEventTouchUpInside];
    }
    return _notePrefixButton;
}

- (UILabel *)notePrefixLabel
{
    if (!_notePrefixLabel) {
        _notePrefixLabel = [UILabel new];
        _notePrefixLabel.text = [NSString stringWithFormat:@"merge with prefix '%@'", self.sourceTaskName];
        _notePrefixLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _notePrefixLabel.font = [UIFont mirrorHintFont_Card];
        _notePrefixLabel.numberOfLines = 1;
        _notePrefixLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _notePrefixLabel;
}

@end
