//
//  TaskPickerViewController.m
//  Mirror
//

#import "TaskPickerViewController.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorLanguage.h"

static CGFloat const kTaskPickerBackdropAlpha = 0.5;
static CGFloat const kTaskPickerShadowOpacity = 0.25;
static CGFloat const kTaskPickerShadowRadius = 10;
static CGFloat const kTaskPickerShadowYOffset = 4;
static CGFloat const kTaskPickerRowHeight = 40;
static CGFloat const kTaskPickerRowWidth = 180;
static CGFloat const kTaskPickerDotSize = 16;
static CGFloat const kTaskPickerHorizontalPadding = 12;
static CGFloat const kTaskPickerRowSpacing = 8;
static CGFloat const kTaskPickerCornerRadius = 12;
static CGFloat const kTaskPickerTitleSpacing = 12;

@interface TaskPickerViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray<MirrorTaskModel *> *tasks;
@property (nonatomic, copy) NSString *sourceTaskName;
@property (nonatomic, copy) TaskPickerCompletion completion;
@property (nonatomic, strong) UIView *pickerView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *taskButtons;

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
                make.top.mas_equalTo(titleLabel.mas_bottom).offset(kTaskPickerTitleSpacing);
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
    UIButton *button = [UIButton new];
    button.tag = index;
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
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (self.completion) {
        self.completion(self.tasks[button.tag]);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
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

@end
