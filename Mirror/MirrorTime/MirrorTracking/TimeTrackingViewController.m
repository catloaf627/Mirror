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
    return [UIColor colorWithWhite:0.08 alpha:0.2];
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

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat startAngle;
@property (nonatomic, strong) UIColor *taskColor;
@property (nonatomic, strong) UIColor *pulseColor;

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
    self.contentMode = UIViewContentModeRedraw;
}

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    [self setNeedsDisplay];
}

- (void)setStartAngle:(CGFloat)startAngle
{
    _startAngle = startAngle;
    [self setNeedsDisplay];
}

- (void)setTaskColor:(UIColor *)taskColor
{
    _taskColor = taskColor;
    [self setNeedsDisplay];
}

- (void)setPulseColor:(UIColor *)pulseColor
{
    _pulseColor = pulseColor;
    [self setNeedsDisplay];
}

- (CGFloat)normalizedAngleDeltaFromAngle:(CGFloat)angle startAngle:(CGFloat)startAngle
{
    CGFloat delta = angle - startAngle;
    while (delta < 0) {
        delta += 2*M_PI;
    }
    while (delta >= 2*M_PI) {
        delta -= 2*M_PI;
    }
    return delta;
}

- (BOOL)colorComponentsFromColor:(UIColor *)color red:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
    if ([color getRed:red green:green blue:blue alpha:alpha]) {
        return YES;
    }
    CGFloat white = 0;
    if ([color getWhite:&white alpha:alpha]) {
        *red = white;
        *green = white;
        *blue = white;
        return YES;
    }
    return NO;
}

- (UIImage *)ringImageWithRect:(CGRect)rect center:(CGPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle sweepAngle:(CGFloat)sweepAngle
{
    CGFloat scale = UIScreen.mainScreen.scale;
    size_t width = MAX(1, (size_t)ceil(CGRectGetWidth(rect) * scale));
    size_t height = MAX(1, (size_t)ceil(CGRectGetHeight(rect) * scale));
    size_t bytesPerRow = width * 4;
    unsigned char *pixels = calloc(height * bytesPerRow, 1);
    if (!pixels) {
        return nil;
    }

    CGFloat startRed = 0, startGreen = 0, startBlue = 0, startAlpha = 0;
    CGFloat endRed = 0, endGreen = 0, endBlue = 0, endAlpha = 0;
    if (![self colorComponentsFromColor:self.taskColor red:&startRed green:&startGreen blue:&startBlue alpha:&startAlpha] ||
        ![self colorComponentsFromColor:self.pulseColor red:&endRed green:&endGreen blue:&endBlue alpha:&endAlpha]) {
        free(pixels);
        return nil;
    }

    CGFloat halfLineWidth = kCircleLineWidth / 2.0;
    CGFloat capRadius = halfLineWidth;
    CGFloat innerRadius = radius - halfLineWidth;
    CGFloat outerRadius = radius + halfLineWidth;
    CGFloat edgeWidth = 1.0 / scale;
    BOOL drawsCaps = YES;
    CGFloat capLength = drawsCaps ? capRadius : 0;
    CGFloat ringLength = radius * sweepAngle;
    CGFloat totalLength = MAX(0.001, ringLength + 2*capLength);
    CGFloat startUnitX = cos(startAngle);
    CGFloat startUnitY = sin(startAngle);
    CGFloat startCapCenterX = center.x + radius * startUnitX;
    CGFloat startCapCenterY = center.y + radius * startUnitY;
    CGFloat startTangentX = -sin(startAngle);
    CGFloat startTangentY = cos(startAngle);
    CGFloat endAngle = startAngle + sweepAngle;
    CGFloat endUnitX = cos(endAngle);
    CGFloat endUnitY = sin(endAngle);
    CGFloat endCapCenterX = center.x + radius * endUnitX;
    CGFloat endCapCenterY = center.y + radius * endUnitY;
    CGFloat endTangentX = -sin(endAngle);
    CGFloat endTangentY = cos(endAngle);

    for (size_t y = 0; y < height; y++) {
        CGFloat pointY = ((CGFloat)y + 0.5) / scale;
        for (size_t x = 0; x < width; x++) {
            CGFloat pointX = ((CGFloat)x + 0.5) / scale;
            size_t offset = y * bytesPerRow + x * 4;

            void (^blendPixel)(CGFloat, CGFloat) = ^(CGFloat coverage, CGFloat selectedProgress) {
                if (coverage <= 0) {
                    return;
                }
                CGFloat progress = MIN(1, MAX(0, selectedProgress));
                CGFloat red = startRed + (endRed - startRed) * progress;
                CGFloat green = startGreen + (endGreen - startGreen) * progress;
                CGFloat blue = startBlue + (endBlue - startBlue) * progress;
                CGFloat alpha = (startAlpha + (endAlpha - startAlpha) * progress) * MIN(1, MAX(0, coverage));
                CGFloat dstAlpha = pixels[offset + 3] / 255.0;
                CGFloat outAlpha = alpha + dstAlpha * (1 - alpha);
                CGFloat outRed = red * alpha + (pixels[offset] / 255.0) * (1 - alpha);
                CGFloat outGreen = green * alpha + (pixels[offset + 1] / 255.0) * (1 - alpha);
                CGFloat outBlue = blue * alpha + (pixels[offset + 2] / 255.0) * (1 - alpha);
                pixels[offset] = (unsigned char)lrint(MIN(1, MAX(0, outRed)) * 255);
                pixels[offset + 1] = (unsigned char)lrint(MIN(1, MAX(0, outGreen)) * 255);
                pixels[offset + 2] = (unsigned char)lrint(MIN(1, MAX(0, outBlue)) * 255);
                pixels[offset + 3] = (unsigned char)lrint(MIN(1, MAX(0, outAlpha)) * 255);
            };

            if (drawsCaps) {
                CGFloat startCapDistance = hypot(pointX - startCapCenterX, pointY - startCapCenterY);
                CGFloat startCapProjection = (pointX - startCapCenterX) * startTangentX + (pointY - startCapCenterY) * startTangentY;
                CGFloat startCapCoverage = MIN(1, MAX(0, (capRadius - startCapDistance) / edgeWidth));
                CGFloat startCapSideCoverage = MIN(1, MAX(0, (edgeWidth - startCapProjection) / edgeWidth));
                startCapCoverage *= startCapSideCoverage;
                CGFloat projection = (startCapProjection + capRadius) / capRadius;
                blendPixel(startCapCoverage, MIN(1, MAX(0, projection)) * capLength / totalLength);
            }

            CGFloat dx = pointX - center.x;
            CGFloat dy = pointY - center.y;
            CGFloat distance = hypot(dx, dy);
            CGFloat innerCoverage = MIN(1, MAX(0, (distance - innerRadius) / edgeWidth));
            CGFloat outerCoverage = MIN(1, MAX(0, (outerRadius - distance) / edgeWidth));
            CGFloat ringCoverage = innerCoverage * outerCoverage;
            CGFloat angle = atan2(dy, dx);
            CGFloat delta = [self normalizedAngleDeltaFromAngle:angle startAngle:startAngle];
            if (delta <= sweepAngle) {
                blendPixel(ringCoverage, (capLength + radius * delta) / totalLength);
            }

            if (drawsCaps) {
                CGFloat endCapDistance = hypot(pointX - endCapCenterX, pointY - endCapCenterY);
                CGFloat endCapProjection = (pointX - endCapCenterX) * endTangentX + (pointY - endCapCenterY) * endTangentY;
                CGFloat endCapCoverage = MIN(1, MAX(0, (capRadius - endCapDistance) / edgeWidth));
                CGFloat endCapSideCoverage = MIN(1, MAX(0, (endCapProjection + edgeWidth * 2) / edgeWidth));
                endCapCoverage *= endCapSideCoverage;
                CGFloat projection = endCapProjection / capRadius;
                blendPixel(endCapCoverage, (capLength + ringLength + MIN(1, MAX(0, projection)) * capLength) / totalLength);
            }
        }
    }

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext = CGBitmapContextCreate(pixels, width, height, 8, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGImageRef imageRef = bitmapContext ? CGBitmapContextCreateImage(bitmapContext) : NULL;
    UIImage *image = imageRef ? [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp] : nil;
    if (imageRef) {
        CGImageRelease(imageRef);
    }
    if (bitmapContext) {
        CGContextRelease(bitmapContext);
    }
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    return image;
}

- (void)drawRect:(CGRect)rect
{
    if (CGRectIsEmpty(self.bounds) || !self.taskColor || !self.pulseColor) {
        return;
    }

    CGRect circleRect = CGRectInset(self.bounds, kCircleLineWidth/2 + 4, kCircleLineWidth/2 + 4);
    CGPoint center = CGPointMake(CGRectGetMidX(circleRect), CGRectGetMidY(circleRect));
    CGFloat radius = MIN(CGRectGetWidth(circleRect), CGRectGetHeight(circleRect))/2;
    CGFloat progress = MAX(0, MIN(1, self.progress));
    if (progress <= 0) {
        return;
    }

    CGFloat startAngle = self.startAngle;
    CGFloat sweepAngle = progress >= 1 ? 2*M_PI : 2*M_PI*progress;

    UIBezierPath *trackPath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:startAngle endAngle:startAngle + 2*M_PI clockwise:YES];
    trackPath.lineWidth = kCircleLineWidth;
    trackPath.lineCapStyle = kCGLineCapRound;
    [MirrorTrackingCircleTrackColor() setStroke];
    [trackPath stroke];

    UIImage *ringImage = [self ringImageWithRect:self.bounds center:center radius:radius startAngle:startAngle sweepAngle:sweepAngle];
    [ringImage drawInRect:self.bounds];
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

    self.timeIntervalLabel.text = [[NSDateComponentsFormatter new] stringFromTimeInterval:self.timeInterval];
    self.circleView.startAngle = [self hourCircleStartAngle];
    self.circleView.progress = [self hourCircleProgress];
    NSString *buttonTitleKey = [self canStopAndKeepRecord] ? @"stop" : @"cancel";
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

- (void)triggerButtonHapticFeedback
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (void)stopButtonClicked
{
    if ([self canStopAndKeepRecord]) {
        [self triggerButtonHapticFeedback];
        [self dismissViewControllerAnimated:YES completion:nil];
        [MirrorStorage stopTask:self.taskName at:[NSDate now]];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
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
        if (@available(iOS 13.0, *)) {
            UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:21 weight:UIImageSymbolWeightRegular];
            UIImage *image = [[UIImage systemImageNamed:@"pencil.and.list.clipboard"] imageWithConfiguration:configuration];
            if (!image) {
                image = [[UIImage systemImageNamed:@"pencil"] imageWithConfiguration:configuration];
            }
            [_noteButton setImage:image forState:UIControlStateNormal];
        }
        if (!_noteButton.currentImage) {
            [_noteButton setTitle:[MirrorLanguage mirror_stringWithKey:@"note"] forState:UIControlStateNormal];
            _noteButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
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
        [_stopButton setTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] forState:UIControlStateNormal];
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
