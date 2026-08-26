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
#import "CellAnimation.h"
#import "UIImage+MirrorSymbol.h"
#import "MirrorTrackingCircleView.h"
#import "StopButton.h"
#import <CoreHaptics/CoreHaptics.h>
#import <QuartzCore/QuartzCore.h>

static CGFloat const kPadding = 20;

static CGFloat const kTaskNameSize = 35;
static CGFloat const kIntervalSize = 70;

static NSString *const kHintFont = @"TrebuchetMS-Italic";
static CFTimeInterval const kStopHoldDuration = 1.2;

static UIColor *MirrorTrackingBackgroundColor(void)
{
    return [UIColor colorWithWhite:0 alpha:0.8];
}

static UIColor *MirrorTrackingPrimaryTextColor(void)
{
    return [UIColor colorWithWhite:1 alpha:0.92];
}

static UIColor *MirrorTrackingButtonBackgroundColor(void)
{
    return [UIColor colorWithWhite:1 alpha:0.14];
}

static UIColor *MirrorTrackingButtonHighlightedColor(void)
{
    return [UIColor colorWithWhite:1 alpha:0.22];
}

static UIImage *MirrorTrackingImageWithColor(UIColor *color)
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@interface TimeTrackingViewController () <UIViewControllerTransitioningDelegate>

// UI
@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) UIButton *noteButton;
@property (nonatomic, strong) MirrorTrackingCircleView *circleView;
@property (nonatomic, strong) UILabel *timeIntervalLabel;
@property (nonatomic, strong) StopButton *stopButton;

// Data

@property (nonatomic, strong) NSString *taskName;
@property (nonatomic, strong) NSDate *nowTime;
@property (nonatomic, strong) NSDate *startTime;
@property (nonatomic, strong) NSDate *accurateStartDate;
@property (nonatomic, strong) UIColor *taskColor;
@property (nonatomic, assign) MirrorColorType taskColorType;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, assign) NSTimeInterval accurateTimeInterval;
@property (nonatomic, assign) BOOL didFinishAutomatically;
@property (nonatomic, assign) BOOL didCompleteStopHold;
@property (nonatomic, assign) CFTimeInterval stopHoldStartTime;
@property (nonatomic, strong) CHHapticEngine *stopHoldHapticEngine;
@property (nonatomic, strong) id<CHHapticAdvancedPatternPlayer> stopHoldHapticPlayer;


// Timer
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) CADisplayLink *stopHoldDisplayLink;

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
        self.taskName = taskName;
        self.accurateStartDate = accurateStartDate;
        MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:taskName];
        self.taskColorType = task.color;
        self.taskColor = [UIColor mirrorColorNamed:task.color];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)dealloc // 页面被销毁，销毁timer
{
    [self.timer invalidate];
    self.timer = nil;
    [self stopStopHoldDisplayLink];
    [self stopContinuousStopHoldHaptic];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
    [self resetStopHoldProgress];
}

- (void)p_setupUI
{
    self.view.clipsToBounds = YES;
    self.view.backgroundColor = MirrorTrackingBackgroundColor();
    [self.view addSubview:self.circleView];
    [self.circleView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.centerY.offset(-20);
        make.width.height.mas_equalTo(MIN(kScreenWidth - 2*kPadding, 280));
    }];

    [self.view addSubview:self.timeIntervalLabel];
    [self.timeIntervalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.circleView);
        make.width.equalTo(self.circleView).offset(-2*MirrorTrackingCircleLineWidth - 16);
    }];
    
    [self.view addSubview:self.taskNameLabel];
    [self.taskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(0);
        make.bottom.equalTo(self.circleView.mas_top).offset(-36);
        make.width.lessThanOrEqualTo(@(kScreenWidth - 2*kPadding));
    }];
    
    [self.view addSubview:self.stopButton];
    [self.stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.offset(-29);
        make.top.equalTo(self.circleView.mas_bottom).offset(36);
        make.height.mas_equalTo(50);
        make.width.mas_equalTo(2*(kScreenWidth - 2*20)/3);
    }];

    [self.view addSubview:self.noteButton];
    [self.noteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.stopButton.mas_right).offset(8);
        make.centerY.equalTo(self.stopButton);
        make.width.height.mas_equalTo(50);
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
    if ([self finishAutomaticallyIfNeeded]) {
        return;
    }

    self.timeIntervalLabel.text = [[NSDateComponentsFormatter new] stringFromTimeInterval:self.timeInterval];
    self.circleView.startAngle = [self hourCircleStartAngle];
    self.circleView.progress = [self hourCircleProgress];
    NSString *buttonTitleKey = [self canStopAndKeepRecord] ? @"hold_to_stop" : @"cancel";
    [self.stopButton setTitle:[MirrorLanguage mirror_stringWithKey:buttonTitleKey] forState:UIControlStateNormal];

    [self.circleView setNeedsDisplay];
}

- (BOOL)finishAutomaticallyIfNeeded
{
    if (self.didFinishAutomatically) {
        return YES;
    }
    NSDictionary *autoFinishInfo = [MirrorStorage finishGoingOnTaskIfExceededMaximumEndDate];
    if (!autoFinishInfo) {
        return NO;
    }

    self.didFinishAutomatically = YES;
    UIViewController *presentingViewController = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        [self showAutoFinishedCountingAlert:autoFinishInfo fromViewController:presentingViewController];
    }];
    return YES;
}

- (void)showAutoFinishedCountingAlert:(NSDictionary *)autoFinishInfo fromViewController:(UIViewController *)viewController
{
    NSString *taskName = autoFinishInfo[@"taskName"] ?: @"";
    BOOL didSaveRecord = [autoFinishInfo[@"didSaveRecord"] boolValue];
    NSString *messageKey = didSaveRecord ? @"counting_auto_stopped_due_to_next_record" : @"counting_auto_cancelled_due_to_next_record";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:[MirrorLanguage mirror_stringWithKey:messageKey with1Placeholder:taskName]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

- (CGFloat)hourCircleProgress
{
    NSTimeInterval elapsedSeconds = MAX(0, self.timeInterval);
    if (elapsedSeconds >= 60 * 60) {
        return 1;
    }
    return elapsedSeconds / (60.0 * 60.0);
}

- (CGFloat)hourCircleStartAngle
{
    NSTimeInterval elapsedSeconds = MAX(0, self.timeInterval);
    if (elapsedSeconds < 60 * 60) {
        return -M_PI_2;
    }
    NSTimeInterval secondsInHour = fmod(elapsedSeconds, 60 * 60);
    return -M_PI_2 + 2*M_PI*(secondsInHour / (60.0 * 60.0));
}

- (void)stopButtonTouchDown
{
    if (![self canStopAndKeepRecord]) {
        return;
    }

    self.didCompleteStopHold = NO;
    self.stopHoldStartTime = CACurrentMediaTime();
    [self updateStopHoldProgress:0];
    [self startContinuousStopHoldHaptic];
    [self startStopHoldDisplayLink];
}

- (void)stopButtonTouchUpInside
{
    if (![self canStopAndKeepRecord]) {
        [self dismissViewControllerAnimated:YES completion:nil];
        [MirrorStorage cancelGoingOnTask];
        return;
    }

    if (!self.didCompleteStopHold) {
        [self resetStopHoldProgress];
    }
}

- (void)stopButtonTouchCancelled
{
    if (!self.didCompleteStopHold) {
        [self resetStopHoldProgress];
    }
}

- (void)startStopHoldDisplayLink
{
    [self stopStopHoldDisplayLink];
    self.stopHoldDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateStopHoldDisplayLink:)];
    [self.stopHoldDisplayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)stopStopHoldDisplayLink
{
    [self.stopHoldDisplayLink invalidate];
    self.stopHoldDisplayLink = nil;
}

- (void)updateStopHoldDisplayLink:(CADisplayLink *)displayLink
{
    if (![self canStopAndKeepRecord]) {
        [self resetStopHoldProgress];
        return;
    }

    CGFloat progress = MIN(1, (CACurrentMediaTime() - self.stopHoldStartTime) / kStopHoldDuration);
    [self updateStopHoldProgress:progress];

    if (progress >= 1) {
        self.didCompleteStopHold = YES;
        [self stopStopHoldDisplayLink];
        [self stopContinuousStopHoldHaptic];
        [self stopAndKeepRecord];
    }
}

- (void)updateStopHoldProgress:(CGFloat)progress
{
    CGFloat normalizedProgress = MIN(1, MAX(0, progress));
    [self.stopButton updateProgress:normalizedProgress];
}

- (void)resetStopHoldProgress
{
    [self stopStopHoldDisplayLink];
    [self stopContinuousStopHoldHaptic];
    self.didCompleteStopHold = NO;
    [UIView animateWithDuration:0.15 animations:^{
        [self updateStopHoldProgress:0];
    }];
}

- (void)startContinuousStopHoldHaptic
{
    if (!CHHapticEngine.capabilitiesForHardware.supportsHaptics) {
        return;
    }

    NSError *error = nil;
    if (!self.stopHoldHapticEngine) {
        self.stopHoldHapticEngine = [[CHHapticEngine alloc] initAndReturnError:&error];
        if (error) {
            return;
        }
    }

    [self.stopHoldHapticEngine startAndReturnError:&error];
    if (error) {
        return;
    }

    CHHapticEventParameter *intensity = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:0.22];
    CHHapticEventParameter *sharpness = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:0.08];
    CHHapticEvent *event = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous
                                                          parameters:@[intensity, sharpness]
                                                        relativeTime:0
                                                            duration:kStopHoldDuration];
    CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithEvents:@[event] parameters:@[] error:&error];
    if (error) {
        return;
    }

    self.stopHoldHapticPlayer = [self.stopHoldHapticEngine createAdvancedPlayerWithPattern:pattern error:&error];
    if (error) {
        self.stopHoldHapticPlayer = nil;
        return;
    }

    [self.stopHoldHapticPlayer startAtTime:0 error:nil];
}

- (void)stopContinuousStopHoldHaptic
{
    [self.stopHoldHapticPlayer stopAtTime:0 error:nil];
    self.stopHoldHapticPlayer = nil;
}

- (void)stopAndKeepRecord
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
    [self dismissViewControllerAnimated:YES completion:nil];
    [MirrorStorage stopTask:self.taskName at:[NSDate now]];
}

- (void)noteButtonClicked
{
    if ([MirrorStorage isGoingOnTask].length == 0) {
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"note"] message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = [MirrorStorage goingOnTaskNote];
        textField.placeholder = [MirrorLanguage mirror_stringWithKey:@"note"];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"save"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *note = alert.textFields.firstObject.text ?: @"";
        if (note.length > 200) {
            note = [note substringToIndex:200];
        }
        [MirrorStorage saveGoingOnTaskNote:note];
    }];
    [alert addAction:cancelAction];
    [alert addAction:saveAction];
    [self presentViewController:alert animated:YES completion:nil];
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

- (NSDate *)displayStartDate
{
    NSDate *startTime = self.accurateStartDate ?: [NSDate date];
    if (is_debug) {
        startTime = [startTime dateByAddingTimeInterval:-2730];
    }
    return startTime;
}

- (NSDate *)startTime
{
    return [MirrorStorage goingOnTaskStartDate] ?: [NSDate date];
}

- (NSDate *)accurateStartDate
{
    if (!_accurateStartDate) {
        _accurateStartDate = [MirrorStorage goingOnTaskAccurateStartDate] ?: self.startTime;
    }
    return _accurateStartDate;
}

- (NSTimeInterval)timeInterval
{
    return [self.nowTime timeIntervalSinceDate:self.displayStartDate];
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
        _taskNameLabel.textColor = MirrorTrackingPrimaryTextColor();
        _taskNameLabel.font = [UIFont fontWithName:kHintFont size:kTaskNameSize];
        _taskNameLabel.text = self.taskName;
        _taskNameLabel.textAlignment = NSTextAlignmentCenter;
        _taskNameLabel.adjustsFontSizeToFitWidth = YES;
        _taskNameLabel.minimumScaleFactor = 0.5;
    }
    return _taskNameLabel;
}

- (UIButton *)noteButton
{
    if (!_noteButton) {
        _noteButton = [UIButton new];
        _noteButton.backgroundColor = MirrorTrackingButtonBackgroundColor();
        _noteButton.tintColor = MirrorTrackingPrimaryTextColor();
        _noteButton.layer.cornerRadius = 12;
        _noteButton.clipsToBounds = YES;
        _noteButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
        _noteButton.layer.borderWidth = 1;
        _noteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _noteButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _noteButton.imageView.contentMode = UIViewContentModeCenter;
        _noteButton.accessibilityLabel = [MirrorLanguage mirror_stringWithKey:@"note"];
        [_noteButton setBackgroundImage:MirrorTrackingImageWithColor(MirrorTrackingButtonBackgroundColor()) forState:UIControlStateNormal];
        [_noteButton setBackgroundImage:MirrorTrackingImageWithColor(MirrorTrackingButtonHighlightedColor()) forState:UIControlStateHighlighted];
        UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:21 weight:UIImageSymbolWeightRegular];
        UIImage *image = [UIImage mirror_systemImageNamed:@"pencil.and.list.clipboard" fallbackName:@"pencil" configuration:configuration];
        [_noteButton setImage:image forState:UIControlStateNormal];
        [_noteButton addTarget:self action:@selector(noteButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _noteButton;
}

- (MirrorTrackingCircleView *)circleView
{
    if (!_circleView) {
        _circleView = [MirrorTrackingCircleView new];
        _circleView.backgroundColor = UIColor.clearColor;
        _circleView.startAngle = -M_PI_2;
        _circleView.taskColor = self.taskColor;
        _circleView.pulseColor = [UIColor mirrorColorPulsed:self.taskColorType];
    }
    return _circleView;
}

- (UILabel *)timeIntervalLabel
{
    if (!_timeIntervalLabel) {
        _timeIntervalLabel = [UILabel new];
        _timeIntervalLabel.textColor = MirrorTrackingPrimaryTextColor();
        _timeIntervalLabel.font = [UIFont fontWithName:kHintFont size:kIntervalSize];
        _timeIntervalLabel.text = [MirrorLanguage mirror_stringWithKey:@"go"];
        _timeIntervalLabel.textAlignment = NSTextAlignmentCenter;
        _timeIntervalLabel.adjustsFontSizeToFitWidth = YES;
        _timeIntervalLabel.minimumScaleFactor = 0.45;
    }
    return _timeIntervalLabel;
}

- (StopButton *)stopButton
{
    if (!_stopButton) {
        _stopButton = [[StopButton alloc] initWithTaskColor:self.taskColor];
        [_stopButton addTarget:self action:@selector(stopButtonTouchDown) forControlEvents:UIControlEventTouchDown];
        [_stopButton addTarget:self action:@selector(stopButtonTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
        [_stopButton addTarget:self action:@selector(stopButtonTouchCancelled) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    }
    return _stopButton;
}


#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    CellAnimation *animation = [CellAnimation new];
    animation.isPresent = NO;
    animation.cellColor = self.taskColor;
    animation.cellFrame = self.cellFrame;
    return animation;
}


@end
