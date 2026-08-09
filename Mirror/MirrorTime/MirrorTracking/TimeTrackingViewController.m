//
//  TimeTrackingViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/24.
//

#import "TimeTrackingViewController.h"
#import "MirrorTaskModel.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorMacro.h"
#import "MirrorLanguage.h"
#import "MirrorStorage.h"
#import "MirrorTool.h"
#import "CellAnimation.h"

static CGFloat const kPadding = 20;

static CGFloat const kTaskNameSize = 35;
static CGFloat const kIntervalSize = 70;

static NSString *const kHintFont = @"TrebuchetMS-Italic";
static CGFloat const kCircleLineWidth = 18;

@interface MirrorTrackingCircleView : UIView

@property (nonatomic, assign) BOOL isCountingDown;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, strong) UIColor *taskColor;
@property (nonatomic, strong) UIColor *pulseColor;

@end

@implementation MirrorTrackingCircleView

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }

    CGRect circleRect = CGRectInset(self.bounds, kCircleLineWidth/2 + 4, kCircleLineWidth/2 + 4);
    CGPoint center = CGPointMake(CGRectGetMidX(circleRect), CGRectGetMidY(circleRect));
    CGFloat radius = MIN(CGRectGetWidth(circleRect), CGRectGetHeight(circleRect))/2;
    CGFloat startAngle = -M_PI_2;
    CGFloat endAngle = startAngle + 2*M_PI*MAX(0, MIN(1, self.progress));

    CGContextSetLineWidth(context, kCircleLineWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    [[UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG] setStroke];
    CGContextAddArc(context, center.x, center.y, radius, startAngle, startAngle + 2*M_PI, 0);
    CGContextStrokePath(context);

    if (self.progress <= 0) {
        return;
    }

    NSInteger segmentCount = MAX(1, ceil(self.progress * 120));
    for (NSInteger index = 0; index < segmentCount; index++) {
        CGFloat segmentStart = startAngle + (endAngle - startAngle) * index / segmentCount;
        CGFloat segmentEnd = startAngle + (endAngle - startAngle) * (index + 1) / segmentCount;
        CGFloat ratio = segmentCount == 1 ? 1 : (CGFloat)index / (segmentCount - 1);
        UIColor *color = [self colorBetween:self.taskColor and:self.pulseColor ratio:ratio];
        [color setStroke];
        CGContextAddArc(context, center.x, center.y, radius, segmentStart, segmentEnd, 0);
        CGContextStrokePath(context);
    }
}

- (UIColor *)colorBetween:(UIColor *)startColor and:(UIColor *)endColor ratio:(CGFloat)ratio
{
    CGFloat startRed = 0;
    CGFloat startGreen = 0;
    CGFloat startBlue = 0;
    CGFloat startAlpha = 0;
    CGFloat endRed = 0;
    CGFloat endGreen = 0;
    CGFloat endBlue = 0;
    CGFloat endAlpha = 0;
    [startColor getRed:&startRed green:&startGreen blue:&startBlue alpha:&startAlpha];
    [endColor getRed:&endRed green:&endGreen blue:&endBlue alpha:&endAlpha];
    return [UIColor colorWithRed:startRed + (endRed - startRed)*ratio
                           green:startGreen + (endGreen - startGreen)*ratio
                            blue:startBlue + (endBlue - startBlue)*ratio
                           alpha:startAlpha + (endAlpha - startAlpha)*ratio];
}

@end

@interface TimeTrackingViewController () <UIViewControllerTransitioningDelegate>

// UI
@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) MirrorTrackingCircleView *circleView;
@property (nonatomic, strong) UILabel *timeIntervalLabel;
@property (nonatomic, strong) UIButton *stopButton;

// Data

@property (nonatomic, strong) NSString *taskName;
@property (nonatomic, strong) NSDate *nowTime;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *accurateStartDate;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, assign) NSTimeInterval accurateTimeInterval;


// Timer
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation TimeTrackingViewController

- (instancetype)initWithTaskName:(NSString *)taskName
{
    return [self initWithTaskName:taskName accurateStartDate:nil];
}

- (instancetype)initWithTaskName:(NSString *)taskName accurateStartDate:(NSDate *)accurateStartDate
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        self.taskName = taskName;
        self.accurateStartDate = accurateStartDate;
    }
    return self;
}

- (void)restartVC
{
    // 将vc.view里的所有subviews全部置为nil
    self.taskNameLabel = nil;
    self.circleView = nil;
    self.timeIntervalLabel = nil;
    self.stopButton = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self  p_setupUI];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)dealloc // 页面被销毁，销毁timer
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
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
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.circleView];
    [self.circleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.centerY.offset(-20);
        make.width.height.mas_equalTo(MIN(kScreenWidth - 2*kPadding, 280));
    }];

    [self.view addSubview:self.timeIntervalLabel];
    [self.timeIntervalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.circleView);
        make.width.equalTo(self.circleView).offset(-2*kCircleLineWidth - 16);
    }];
    
    [self.view addSubview:self.taskNameLabel];
    [self.taskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.bottom.equalTo(self.circleView.mas_top).offset(-36);
        make.width.equalTo(@(kScreenWidth - 2*kPadding));
    }];
    
    [self.view addSubview:self.stopButton];
    [self.stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.top.equalTo(self.circleView.mas_bottom).offset(36);
        make.height.mas_equalTo(50);
        make.width.mas_equalTo(3*(kScreenWidth - 2*20)/4);
    }];
    
    [self updateLabels];
    __weak typeof(self) weakSelf = self;
    self.timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)1.0f repeats:YES block:^(NSTimer * _Nonnull timer) {
        // 在iOS 10以后系统，苹果针对NSTimer进行了优化，使用Block回调方式，解决了循环引用问题。
        [weakSelf updateLabels];
    }];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    // 动画
    self.transitioningDelegate = self;
}

#pragma mark - Actions

- (void)updateLabels
{
    BOOL canStop = [self canStopAndKeepRecord];
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];

    if (canStop) {
        self.timeIntervalLabel.text = [[NSDateComponentsFormatter new] stringFromTimeInterval:self.timeInterval];
        self.circleView.isCountingDown = NO;
        self.circleView.progress = [self hourCircleProgress];
        [self.stopButton setTitle:[MirrorLanguage mirror_stringWithKey:@"stop"] forState:UIControlStateNormal];
    } else {
        NSTimeInterval countdown = MAX(0, kMinSeconds - self.accurateTimeInterval);
        self.timeIntervalLabel.text = [[NSDateComponentsFormatter new] stringFromTimeInterval:ceil(countdown)];
        self.circleView.isCountingDown = YES;
        self.circleView.progress = countdown / kMinSeconds;
        [self.stopButton setTitle:[MirrorLanguage mirror_stringWithKey:@"give_up"] forState:UIControlStateNormal];
    }

    [self.circleView setNeedsDisplay];
}

- (CGFloat)hourCircleProgress
{
    NSInteger elapsedMinutes = MAX(0, floor(self.timeInterval / 60.0));
    NSInteger minuteInHour = elapsedMinutes % 60;
    if (elapsedMinutes > 0 && minuteInHour == 0) {
        return 1;
    }
    return minuteInHour / 60.0;
}

- (void)stopButtonClicked
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if ([self canStopAndKeepRecord]) {
        [MirrorStorage stopTask:self.taskName at:[NSDate now]];
    } else {
        [MirrorStorage deletePeriodAtIndex:[MirrorStorage retriveMirrorRecords].count-1];
    }
}

- (BOOL)canStopAndKeepRecord
{
    return self.accurateTimeInterval >= kMinSeconds;
}

#pragma mark - Data

- (NSDate *)nowTime
{
    return [NSDate now]; // 当前时间
}

- (NSDate *)startTime
{
    NSMutableArray<MirrorRecordModel *> * records = [MirrorStorage retriveMirrorRecords];
    long startTimestamp = records[records.count -1].startTime;
    NSDate *startTime = [NSDate dateWithTimeIntervalSince1970:startTimestamp];
    return startTime;
}

- (NSDate *)accurateStartDate
{
    if (!_accurateStartDate) {
        _accurateStartDate = self.startTime;
    }
    return _accurateStartDate;
}

- (NSTimeInterval)timeInterval
{
    return [self.nowTime timeIntervalSinceDate:self.startTime];
}

- (NSTimeInterval)accurateTimeInterval
{
    return [self.nowTime timeIntervalSinceDate:self.accurateStartDate];
}

#pragma mark - Getters

- (UILabel *)taskNameLabel
{
    if (!_taskNameLabel) {
        _taskNameLabel = [UILabel new];
        _taskNameLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _taskNameLabel.font = [UIFont fontWithName:kHintFont size:kTaskNameSize];
        _taskNameLabel.text = self.taskName;
        _taskNameLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _taskNameLabel;
}

- (MirrorTrackingCircleView *)circleView
{
    if (!_circleView) {
        _circleView = [MirrorTrackingCircleView new];
        _circleView.backgroundColor = UIColor.clearColor;
        MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:self.taskName];
        _circleView.taskColor = [UIColor mirrorColorNamed:task.color];
        _circleView.pulseColor = [UIColor mirrorColorNamed:[UIColor mirror_getPulseColorType:task.color]];
    }
    return _circleView;
}

- (UILabel *)timeIntervalLabel
{
    if (!_timeIntervalLabel) {
        _timeIntervalLabel = [UILabel new];
        _timeIntervalLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _timeIntervalLabel.font = [UIFont fontWithName:kHintFont size:kIntervalSize];
        _timeIntervalLabel.text = [MirrorLanguage mirror_stringWithKey:@"go"];
        _timeIntervalLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _timeIntervalLabel;
}

- (UIButton *)stopButton
{
    if (!_stopButton) {
        _stopButton = [UIButton new];
        [_stopButton setTitle:[MirrorLanguage mirror_stringWithKey:@"give_up"] forState:UIControlStateNormal];
        _stopButton.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_stopButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeBackground] forState:UIControlStateNormal];
        _stopButton.titleLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:20];
        _stopButton.layer.borderColor = [UIColor mirrorColorNamed:MirrorColorTypeText].CGColor;
        _stopButton.layer.borderWidth = 1;
        _stopButton.layer.cornerRadius = 12;
        [_stopButton addTarget:self action:@selector(stopButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _stopButton;
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
