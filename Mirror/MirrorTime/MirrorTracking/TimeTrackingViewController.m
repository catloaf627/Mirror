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
#import <QuartzCore/QuartzCore.h>

static CGFloat const kPadding = 20;

static CGFloat const kTaskNameSize = 35;
static CGFloat const kIntervalSize = 70;

static NSString *const kHintFont = @"TrebuchetMS-Italic";
static CGFloat const kCircleLineWidth = 18;

static UIColor *MirrorTrackingBackgroundColor(void)
{
    return [UIColor colorWithWhite:0 alpha:0.8];
}

static UIColor *MirrorTrackingCircleTrackColor(void)
{
    return [UIColor colorWithWhite:0.08 alpha:0.65];
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

@interface MirrorTrackingCircleView : UIView

@property (nonatomic, assign) BOOL isCountingDown;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat startAngle;
@property (nonatomic, strong) UIColor *taskColor;
@property (nonatomic, strong) UIColor *pulseColor;
@property (nonatomic, strong) CAShapeLayer *trackLayer;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, strong) CAShapeLayer *progressMaskLayer;
@property (nonatomic, strong) CAShapeLayer *startCapLayer;
@property (nonatomic, strong) CAShapeLayer *endCapLayer;

@end

@implementation MirrorTrackingCircleView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayers];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupLayers];
    }
    return self;
}

- (void)setupLayers
{
    self.backgroundColor = UIColor.clearColor;
    self.trackLayer = [CAShapeLayer layer];
    self.trackLayer.fillColor = UIColor.clearColor.CGColor;
    self.trackLayer.lineCap = kCALineCapRound;
    self.trackLayer.lineWidth = kCircleLineWidth;
    [self.layer addSublayer:self.trackLayer];

    self.startCapLayer = [CAShapeLayer layer];
    [self.layer addSublayer:self.startCapLayer];

    self.gradientLayer = [CAGradientLayer layer];
    if (@available(iOS 12.0, *)) {
        self.gradientLayer.type = kCAGradientLayerConic;
    }
    self.gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    self.gradientLayer.endPoint = CGPointMake(1, 0.5);
    [self.layer addSublayer:self.gradientLayer];

    self.progressMaskLayer = [CAShapeLayer layer];
    self.progressMaskLayer.fillColor = UIColor.clearColor.CGColor;
    self.progressMaskLayer.strokeColor = UIColor.blackColor.CGColor;
    self.progressMaskLayer.lineCap = kCALineCapButt;
    self.progressMaskLayer.lineWidth = kCircleLineWidth;
    self.gradientLayer.mask = self.progressMaskLayer;

    self.endCapLayer = [CAShapeLayer layer];
    [self.layer addSublayer:self.endCapLayer];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateCircleLayers];
}

- (void)setIsCountingDown:(BOOL)isCountingDown
{
    _isCountingDown = isCountingDown;
    [self updateCircleLayers];
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self updateCircleLayers];
}

- (void)setStartAngle:(CGFloat)startAngle
{
    _startAngle = startAngle;
    [self updateCircleLayers];
}

- (void)setTaskColor:(UIColor *)taskColor
{
    _taskColor = taskColor;
    [self updateCircleLayers];
}

- (void)setPulseColor:(UIColor *)pulseColor
{
    _pulseColor = pulseColor;
    [self updateCircleLayers];
}

- (UIBezierPath *)semiCapPathWithCenter:(CGPoint)center angle:(CGFloat)angle radius:(CGFloat)radius forward:(BOOL)forward
{
    CGPoint outerPoint = CGPointMake(center.x + radius*cos(angle), center.y + radius*sin(angle));

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:outerPoint];
    [path addArcWithCenter:center radius:radius startAngle:angle endAngle:angle + M_PI clockwise:forward];
    [path closePath];
    return path;
}

- (void)updateCircleLayers
{
    if (CGRectIsEmpty(self.bounds) || !self.taskColor || !self.pulseColor) {
        return;
    }

    CGRect circleRect = CGRectInset(self.bounds, kCircleLineWidth/2 + 4, kCircleLineWidth/2 + 4);
    CGPoint center = CGPointMake(CGRectGetMidX(circleRect), CGRectGetMidY(circleRect));
    CGFloat radius = MIN(CGRectGetWidth(circleRect), CGRectGetHeight(circleRect))/2;
    CGFloat progress = MAX(0, MIN(1, self.progress));
    CGFloat startAngle = self.startAngle;
    CGFloat endAngle = startAngle + 2*M_PI*progress;
    BOOL drawsFullRing = !self.isCountingDown && progress >= 1;
    CGFloat drawStartAngle = startAngle;
    CGFloat drawEndAngle = endAngle;
    CGFloat capRadius = kCircleLineWidth/2;
    CGFloat gradientProgress = drawsFullRing ? 1 : MIN(1, MAX(0.01, (drawEndAngle - drawStartAngle) / (2*M_PI)));
    CGFloat pulseStartProgress = drawsFullRing ? 1 : MAX(0.001, gradientProgress - 0.01);
    CGFloat pulseHoldProgress = drawsFullRing ? 1 : MIN(0.999, gradientProgress + 0.01);
    CGPoint gradientEndPoint = CGPointMake(0.5 + cos(drawStartAngle)/2, 0.5 + sin(drawStartAngle)/2);
    UIBezierPath *trackPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:startAngle + 2*M_PI clockwise:YES];
    UIBezierPath *progressPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:drawStartAngle endAngle:drawEndAngle clockwise:YES];
    CGFloat startCapX = center.x + radius * cos(drawStartAngle);
    CGFloat startCapY = center.y + radius * sin(drawStartAngle);
    CGFloat capAngle = drawsFullRing ? drawStartAngle : drawEndAngle;
    CGFloat endCapX = center.x + radius * cos(capAngle);
    CGFloat endCapY = center.y + radius * sin(capAngle);

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    self.trackLayer.frame = self.bounds;
    self.trackLayer.path = trackPath.CGPath;
    self.trackLayer.strokeColor = MirrorTrackingCircleTrackColor().CGColor;

    self.gradientLayer.frame = self.bounds;
    self.gradientLayer.startPoint = CGPointMake(0.5, 0.5);
    self.gradientLayer.endPoint = gradientEndPoint;
    self.gradientLayer.transform = CATransform3DIdentity;
    self.gradientLayer.colors = @[(id)self.taskColor.CGColor, (id)self.pulseColor.CGColor, (id)self.pulseColor.CGColor, (id)self.taskColor.CGColor];
    self.gradientLayer.locations = @[@0, @(pulseStartProgress), @(pulseHoldProgress), @1];
    self.gradientLayer.hidden = progress <= 0;

    self.progressMaskLayer.frame = self.bounds;
    self.progressMaskLayer.path = progressPath.CGPath;
    self.progressMaskLayer.hidden = progress <= 0;

    self.startCapLayer.path = [self semiCapPathWithCenter:CGPointMake(startCapX, startCapY) angle:drawStartAngle radius:capRadius forward:NO].CGPath;
    self.startCapLayer.fillColor = self.taskColor.CGColor;
    self.startCapLayer.hidden = progress <= 0;

    self.endCapLayer.path = [self semiCapPathWithCenter:CGPointMake(endCapX, endCapY) angle:capAngle radius:capRadius forward:YES].CGPath;
    self.endCapLayer.fillColor = self.pulseColor.CGColor;
    self.endCapLayer.hidden = progress <= 0;

    [CATransaction commit];
}

@end

@interface TimeTrackingViewController () <UIViewControllerTransitioningDelegate>

// UI
@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) UIButton *noteButton;
@property (nonatomic, strong) MirrorTrackingCircleView *circleView;
@property (nonatomic, strong) UILabel *timeIntervalLabel;
@property (nonatomic, strong) UIButton *stopButton;

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
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
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
        make.width.equalTo(self.circleView).offset(-2*kCircleLineWidth - 16);
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

    BOOL canStop = [self canStopAndKeepRecord];

    if (canStop) {
        self.timeIntervalLabel.text = [[NSDateComponentsFormatter new] stringFromTimeInterval:self.timeInterval];
        self.circleView.isCountingDown = NO;
        self.circleView.startAngle = [self hourCircleStartAngle];
        self.circleView.progress = [self hourCircleProgress];
        [self.stopButton setTitle:[MirrorLanguage mirror_stringWithKey:@"stop"] forState:UIControlStateNormal];
    } else {
        NSTimeInterval countdown = MAX(0, kMinSeconds - self.accurateTimeInterval);
        self.timeIntervalLabel.text = [[NSDateComponentsFormatter new] stringFromTimeInterval:ceil(countdown)];
        self.circleView.isCountingDown = YES;
        self.circleView.startAngle = -M_PI_2;
        self.circleView.progress = countdown / kMinSeconds;
        [self.stopButton setTitle:[MirrorLanguage mirror_stringWithKey:@"give_up"] forState:UIControlStateNormal];
    }

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
    NSInteger elapsedMinutes = MAX(0, floor(self.timeInterval / 60.0));
    if (elapsedMinutes >= 60) {
        return 1;
    }
    return elapsedMinutes / 60.0;
}

- (CGFloat)hourCircleStartAngle
{
    NSInteger elapsedMinutes = MAX(0, floor(self.timeInterval / 60.0));
    if (elapsedMinutes < 60) {
        return -M_PI_2;
    }
    NSInteger minuteInHour = elapsedMinutes % 60;
    return -M_PI_2 + 2*M_PI*(minuteInHour / 60.0);
}

- (void)stopButtonClicked
{
    [self dismissViewControllerAnimated:YES completion:nil];
    if ([self canStopAndKeepRecord]) {
        [MirrorStorage stopTask:self.taskName at:[NSDate now]];
    } else {
        [MirrorStorage cancelGoingOnTask];
    }
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

- (NSDate *)startTime
{
    return [MirrorStorage goingOnTaskStartDate] ?: [NSDate now];
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
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:21 weight:UIImageSymbolWeightRegular];
            UIImage *image = [[UIImage systemImageNamed:@"pencil.and.list.clipboard"] imageWithConfiguration:configuration];
            [_noteButton setImage:image forState:UIControlStateNormal];
        }
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

- (UIButton *)stopButton
{
    if (!_stopButton) {
        _stopButton = [UIButton new];
        [_stopButton setTitle:[MirrorLanguage mirror_stringWithKey:@"give_up"] forState:UIControlStateNormal];
        _stopButton.backgroundColor = MirrorTrackingButtonBackgroundColor();
        [_stopButton setTitleColor:MirrorTrackingPrimaryTextColor() forState:UIControlStateNormal];
        _stopButton.titleLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:20];
        _stopButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
        _stopButton.layer.borderWidth = 1;
        _stopButton.layer.cornerRadius = 12;
        _stopButton.clipsToBounds = YES;
        [_stopButton setBackgroundImage:MirrorTrackingImageWithColor(MirrorTrackingButtonBackgroundColor()) forState:UIControlStateNormal];
        [_stopButton setBackgroundImage:MirrorTrackingImageWithColor(MirrorTrackingButtonHighlightedColor()) forState:UIControlStateHighlighted];
        [_stopButton addTarget:self action:@selector(stopButtonClicked) forControlEvents:UIControlEventTouchUpInside];
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
