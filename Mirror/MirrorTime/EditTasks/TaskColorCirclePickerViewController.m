//
//  TaskColorCirclePickerViewController.m
//  Mirror
//

#import "TaskColorCirclePickerViewController.h"
#import <Masonry/Masonry.h>

static NSInteger const kTaskColorPickerColumnCount = 4;
static CGFloat const kTaskColorPickerSpacing = 4;
static CGFloat const kTaskColorPickerButtonSize = 20;
static CGFloat const kTaskColorPickerSelectedBorderWidth = 2;
static CGFloat const kTaskColorPickerBackdropAlpha = 0.2;
static CGFloat const kTaskColorPickerShadowOpacity = 0.25;
static CGFloat const kTaskColorPickerShadowRadius = 10;
static CGFloat const kTaskColorPickerShadowYOffset = 4;

@interface TaskColorCirclePickerViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray<NSNumber *> *colors;
@property (nonatomic, assign) MirrorColorType selectedColor;
@property (nonatomic, copy) TaskColorCirclePickerCompletion completion;
@property (nonatomic, assign) CGRect anchorFrame;
@property (nonatomic, strong) UIView *pickerView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *colorButtons;

@end

@implementation TaskColorCirclePickerViewController

- (instancetype)initWithColors:(NSArray<NSNumber *> *)colors
                 selectedColor:(MirrorColorType)selectedColor
                   anchorFrame:(CGRect)anchorFrame
                     completion:(TaskColorCirclePickerCompletion)completion
{
    self = [super init];
    if (self) {
        _colors = colors;
        _selectedColor = selectedColor;
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
        [self.pickerView addSubview:button];
        [self.colorButtons addObject:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.pickerView).offset(column * (buttonSize + kTaskColorPickerSpacing));
            make.top.mas_equalTo(self.pickerView).offset(row * (buttonSize + kTaskColorPickerSpacing));
            make.width.height.mas_equalTo(buttonSize);
            if (index == self.colors.count - 1) {
                make.right.bottom.mas_equalTo(self.pickerView);
            }
        }];
    }
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
