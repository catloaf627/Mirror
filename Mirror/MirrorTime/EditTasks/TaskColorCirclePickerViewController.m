//
//  TaskColorCirclePickerViewController.m
//  Mirror
//

#import "TaskColorCirclePickerViewController.h"
#import <Masonry/Masonry.h>
#import "UIFont+MirrorFont.h"
#import "MirrorLanguage.h"

static NSInteger const kTaskColorPickerColumnCount = 4;
static CGFloat const kTaskColorPickerSpacing = 4;
static CGFloat const kTaskColorPickerWidth = 180;
static CGFloat const kTaskColorPickerButtonSize = 30;
static CGFloat const kTaskColorPickerSelectedBorderWidth = 2;
static CGFloat const kTaskColorPickerBackdropAlpha = 0.5;
static CGFloat const kTaskColorPickerShadowOpacity = 0.25;
static CGFloat const kTaskColorPickerShadowRadius = 10;
static CGFloat const kTaskColorPickerShadowYOffset = 4;
static CGFloat const kTaskColorPickerTitleSpacing = 12;

@interface TaskColorCirclePickerViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray<NSNumber *> *colors;
@property (nonatomic, assign) MirrorColorType selectedColor;
@property (nonatomic, copy) NSString *taskName;
@property (nonatomic, copy) TaskColorCirclePickerCompletion completion;
@property (nonatomic, assign) CGRect anchorFrame;
@property (nonatomic, strong) UIView *pickerView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *colorButtons;

@end

@implementation TaskColorCirclePickerViewController

- (instancetype)initWithColors:(NSArray<NSNumber *> *)colors
                 selectedColor:(MirrorColorType)selectedColor
                       taskName:(NSString *)taskName
                   anchorFrame:(CGRect)anchorFrame
                     completion:(TaskColorCirclePickerCompletion)completion
{
    self = [super init];
    if (self) {
        _colors = colors;
        _selectedColor = selectedColor;
        _taskName = [taskName copy];
        _anchorFrame = anchorFrame;
        _completion = completion;
        _colorButtons = [NSMutableArray new];
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:kTaskColorPickerBackdropAlpha];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPicker)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
    CGFloat buttonSize = kTaskColorPickerButtonSize;
    
    [self.view addSubview:self.pickerView];
    [self.pickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
        make.width.mas_equalTo(kTaskColorPickerWidth);
    }];
    
    UILabel *titleLabel = [self pickerTitleLabelWithText:[MirrorLanguage mirror_stringWithKey:@"pick_color_for_task" with1Placeholder:self.taskName]];
    [self.pickerView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.pickerView);
    }];
    
    UIView *colorGridView = [UIView new];
    [self.pickerView addSubview:colorGridView];
    [colorGridView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.pickerView);
        make.top.mas_equalTo(titleLabel.mas_bottom).offset(kTaskColorPickerTitleSpacing);
    }];
    
    for (NSInteger index = 0; index < self.colors.count; index++) {
        NSNumber *colorNumber = self.colors[index];
        UIButton *button = [UIButton new];
        MirrorColorType color = colorNumber.integerValue;
        NSInteger row = index / kTaskColorPickerColumnCount;
        NSInteger column = index % kTaskColorPickerColumnCount;
        button.tag = color;
        button.backgroundColor = [UIColor mirrorColorNamed:color];
        button.layer.borderWidth = color == self.selectedColor ? kTaskColorPickerSelectedBorderWidth : 0;
        button.layer.borderColor = [UIColor mirrorColorNamed:[UIColor mirror_getPulseColorType:color]].CGColor;
        [button addTarget:self action:@selector(selectColor:) forControlEvents:UIControlEventTouchUpInside];
        [colorGridView addSubview:button];
        [self.colorButtons addObject:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(colorGridView).offset(column * (buttonSize + kTaskColorPickerSpacing));
            make.top.mas_equalTo(colorGridView).offset(row * (buttonSize + kTaskColorPickerSpacing));
            make.width.height.mas_equalTo(buttonSize);
            if (index == self.colors.count - 1) {
                make.right.bottom.mas_equalTo(colorGridView);
                make.bottom.mas_equalTo(self.pickerView);
            }
        }];
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

- (void)selectColor:(UIButton *)button
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    if (self.completion) {
        self.completion(button.tag);
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
        _pickerView.layer.shadowOpacity = kTaskColorPickerShadowOpacity;
        _pickerView.layer.shadowRadius = kTaskColorPickerShadowRadius;
        _pickerView.layer.shadowOffset = CGSizeMake(0, kTaskColorPickerShadowYOffset);
    }
    return _pickerView;
}

@end
