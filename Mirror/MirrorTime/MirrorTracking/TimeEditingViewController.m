//
//  TimeEditingViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/24.
//

#import "TimeEditingViewController.h"
#import <Masonry/Masonry.h>
#import "MirrorStorage.h"
#import "MirrorSettings.h"
#import "MirrorMacro.h"
#import "CellAnimation.h"
#import "MirrorLanguage.h"
#import "MirrorTimeText.h"
#import "SplitLineView.h"
#import "UIFont+MirrorFont.h"

@interface TimeEditingViewController () <UIViewControllerTransitioningDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

// UI
@property (nonatomic, strong) UIButton *dismissButton;
@property (nonatomic, strong) UILabel *tasknameLabel;
@property (nonatomic, strong) UILabel *startLabel;
@property (nonatomic, strong) UIDatePicker *startPicker;
@property (nonatomic, strong) UIPickerView *lastedPicker;
@property (nonatomic, strong) UIButton *saveButton;
@property (nonatomic, strong) SplitLineView *splitView;
@property (nonatomic, strong) UIButton *startButton;

// Data
@property (nonatomic, strong) NSString *taskName;

@end

@implementation TimeEditingViewController

- (instancetype)initWithTaskName:(NSString *)taskName
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        self.taskName = taskName;
    }
    return self;
}

- (void)restartVC
{
    // 将vc.view里的所有subviews全部置为nil
    self.dismissButton = nil;
    self.tasknameLabel = nil;
    self.startLabel = nil;
    self.startPicker = nil;
    self.lastedPicker = nil;
    self.saveButton = nil;
    self.splitView = nil;
    self.startButton = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self  p_setupUI];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.lastedPicker selectRow:1 inComponent:0 animated:YES]; // 默认一小时，在页面出现以后滚一下，让用户知道这个picker可以滚动
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    for (UIView *subview in self.view.subviews) {
        subview.alpha = 0; // 为了避免退场动画出现时subview的布局出现问题。
    }
}

- (void)p_setupUI
{
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = [UIColor mirrorColorNamed:[MirrorStorage getTaskModelFromDB:self.taskName].color];
    [self.view addSubview:self.tasknameLabel];
    self.tasknameLabel.text = self.taskName;
    [self.tasknameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.offset(100*kHeightRatio);
        make.height.mas_equalTo(50*kHeightRatio);
        make.width.mas_equalTo(kScreenWidth);
    }];
    [self.view addSubview:self.startLabel];
    [self.startLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(20);
        make.top.mas_equalTo(self.tasknameLabel.mas_bottom).offset(20*kHeightRatio);
        make.height.mas_equalTo(50*kHeightRatio);
        make.width.mas_equalTo((kScreenWidth - 2*20)/3);
    }];
    [self.view addSubview:self.startPicker];
    [self.startPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-20);
        make.top.mas_equalTo(self.tasknameLabel.mas_bottom).offset(20*kHeightRatio);
        make.height.mas_equalTo(50*kHeightRatio);
        make.width.mas_equalTo(2*(kScreenWidth - 2*20)/3);
    }];
    [self.view addSubview:self.lastedPicker];
    [self.lastedPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(20);
        make.top.mas_equalTo(self.startPicker.mas_bottom).offset(20*kHeightRatio);
        make.height.mas_equalTo(50*kHeightRatio);
        make.width.mas_equalTo((kScreenWidth - 3*20)/2);
    }];
    [self.view addSubview:self.saveButton];
    [self.saveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.lastedPicker.mas_right).offset(20);
        make.centerY.mas_equalTo(self.lastedPicker);
        make.height.mas_equalTo(40*kHeightRatio);
        make.width.mas_equalTo((kScreenWidth - 3*20)/2);
    }];
    [self.view addSubview:self.splitView];
    [self.splitView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.offset(0);
        make.height.mas_equalTo(10*kHeightRatio);
        make.width.mas_equalTo(kScreenWidth);
    }];
    [self.view addSubview:self.startButton];
    [self.startButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.centerY.offset(kScreenHeight/6);
        make.height.mas_equalTo(50*kHeightRatio);
        make.width.mas_equalTo(3*(kScreenWidth - 2*20)/4);
    }];
    
    [self.view addSubview:self.dismissButton];
    [self.dismissButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-20);
        make.bottom.mas_equalTo(self.tasknameLabel.mas_top);
        make.width.height.mas_equalTo(40);
    }];
    
    // 动画
    self.transitioningDelegate = self;
}

#pragma mark - Actions
    

- (void)startCounting
{
    [MirrorStorage startTask:self.taskName at:[NSDate now]];
    [self dismissViewControllerAnimated:NO completion:nil]; // present time tracking vc，此时 time editing vc的退场不需要动画
}

- (void)saveRecord
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *starts = [gregorian components:NSCalendarUnitYear | NSCalendarUnitMonth| NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute| NSCalendarUnitSecond fromDate:self.startPicker.date];
    starts.timeZone = [NSTimeZone systemTimeZone];
    starts.second = 0;
    NSDate *startDate = [gregorian dateFromComponents:starts]; // 去掉秒数
    NSDate *endDate = [NSDate dateWithTimeIntervalSince1970:([startDate timeIntervalSince1970] + [self.lastedPicker selectedRowInComponent:0] * 3600 + [self.lastedPicker selectedRowInComponent:1] * 60)];
    [MirrorStorage savePeriodWithTaskname:self.taskName startAt:startDate endAt:endDate];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIPickerViewDataSource, UIPickerViewDelegate

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
}
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (component == 0) {
        return 24;
    } else {
        return 60;
    }
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
    return (kScreenWidth - 3*20)/4;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 40;
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [UILabel new];
    label.textAlignment = component == 0 ? NSTextAlignmentRight : NSTextAlignmentLeft;
    label.adjustsFontSizeToFitWidth = YES;
    label.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    label.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:17];
    label.text = component == 0 ? [[@(row)stringValue] stringByAppendingString:row==1 ? [MirrorLanguage mirror_stringWithKey:@"picker_hour"] :[MirrorLanguage mirror_stringWithKey:@"picker_hours"]] : [[@(row)stringValue] stringByAppendingString:row==1 ? [MirrorLanguage mirror_stringWithKey:@"picker_min"] :[MirrorLanguage mirror_stringWithKey:@"picker_mins"]];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    if ([pickerView selectedRowInComponent:1] == 0 && component == 0 && row == 0) { //在分钟为0的情况下选择了0小时
        [pickerView selectRow:1 inComponent:1 animated:YES]; // 把分钟设置为1
    }
    if ([pickerView selectedRowInComponent:0] == 0 && component == 1 && row == 0) { //在小时为0的情况下选择了0分钟
        [pickerView selectRow:1 inComponent:0 animated:YES]; // 把小时设置为1
    }
}


#pragma mark - Getters
    
- (UIButton *)dismissButton
{
    if (!_dismissButton) {
        _dismissButton = [UIButton new];
        UIImage *iconImage = [[UIImage systemImageNamed:@"xmark"]  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [_dismissButton setImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _dismissButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dismissButton;
}

- (UILabel *)tasknameLabel
{
    if (!_tasknameLabel) {
        _tasknameLabel = [UILabel new];
        _tasknameLabel.textAlignment = NSTextAlignmentCenter;
        _tasknameLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _tasknameLabel.font = [UIFont mirrorTitleFont];
    }
    return _tasknameLabel;
}

- (UILabel *)startLabel
{
    if (!_startLabel) {
        _startLabel = [UILabel new];
        _startLabel.textAlignment = NSTextAlignmentCenter;
        _startLabel.text = [MirrorLanguage mirror_stringWithKey:@"starts_at"];
        _startLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _startLabel.font = [UIFont mirrorHintFont];
    }
    return _startLabel;
}

- (UIDatePicker *)startPicker
{
    if (!_startPicker) {
        _startPicker = [UIDatePicker new];
        _startPicker.datePickerMode = UIDatePickerModeDateAndTime;
        _startPicker.timeZone = [NSTimeZone systemTimeZone];
        _startPicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
        _startPicker.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        // 如果上一个任务的结束时间在未来，设置start picker和未来那个数字对齐，否则，使用现在的时间
        NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
        if (records.count > 0) {
            long formmerEndTime = records[records.count-1].endTime;
            BOOL canStartAtNow = formmerEndTime <= [[NSDate now] timeIntervalSince1970];
            if (canStartAtNow) {
                _startPicker.date = [NSDate now];
            } else {
                _startPicker.date = [NSDate dateWithTimeIntervalSince1970:formmerEndTime];
                [self.startButton setEnabled:NO];;
                [self.splitView updateText:[MirrorLanguage mirror_stringWithKey:@"now_is_occupied"]];
            }
            _startPicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:formmerEndTime];
        } else {
            _startPicker.date = [NSDate now];
            _startPicker.minimumDate =  0;
        }
    }
    return _startPicker;
}

- (UIPickerView *)lastedPicker
{
    if (!_lastedPicker) {
        _lastedPicker = [UIPickerView new];
        _lastedPicker.delegate = self;
    }
    return _lastedPicker;
}

- (UIButton *)saveButton
{
    if (!_saveButton) {
        _saveButton = [UIButton new];
        [_saveButton setTitle:[MirrorLanguage mirror_stringWithKey:@"save"] forState:UIControlStateNormal];
        [_saveButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeText] forState:UIControlStateNormal];
        _saveButton.titleLabel.font = [UIFont mirrorButtonFont];
        _saveButton.layer.borderColor = [UIColor mirrorColorNamed:MirrorColorTypeText].CGColor;
        _saveButton.layer.borderWidth = 1;
        _saveButton.layer.cornerRadius = 12;
        [_saveButton addTarget:self action:@selector(saveRecord) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveButton;
}

- (SplitLineView *)splitView
{
    if (!_splitView) {
        _splitView = [[SplitLineView alloc] initWithText:[MirrorLanguage mirror_stringWithKey:@"or"] color:[UIColor mirrorColorNamed:[UIColor mirror_getPulseColorType:[MirrorStorage getTaskModelFromDB:self.taskName].color]]];
    }
    return _splitView;
}


- (UIButton *)startButton
{
    if (!_startButton) {
        _startButton = [UIButton new];
        [_startButton setTitle:[MirrorLanguage mirror_stringWithKey:@"start_now"] forState:UIControlStateNormal];
        [_startButton setTitle:[MirrorLanguage mirror_stringWithKey:@"start_now"] forState:UIControlStateDisabled];
        _startButton.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_startButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeBackground] forState:UIControlStateNormal];
        [_startButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeTextHint] forState:UIControlStateDisabled];
        _startButton.titleLabel.font = [UIFont mirrorButtonFont];
        _startButton.layer.borderColor = [UIColor mirrorColorNamed:MirrorColorTypeText].CGColor;
        _startButton.layer.borderWidth = 1;
        _startButton.layer.cornerRadius = 12;
        [_startButton addTarget:self action:@selector(startCounting) forControlEvents:UIControlEventTouchUpInside];
    }
    return _startButton;
}
    
#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    CellAnimation *animation = [CellAnimation new];
    animation.isPresent = NO;
    animation.cellFrame = self.cellFrame;
    return animation;
}


@end
