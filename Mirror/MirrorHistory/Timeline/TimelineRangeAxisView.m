//
//  TimelineRangeAxisView.m
//  Mirror
//

#import "TimelineRangeAxisView.h"
#import "MirrorMacro.h"

@interface TimelineRangeAxisView ()

@property (nonatomic, strong) UIView *trackView;
@property (nonatomic, strong) UIView *selectedTrackView;
@property (nonatomic, strong) UIView *startHandleView;
@property (nonatomic, strong) UIView *endHandleView;
@property (nonatomic, strong) UIDatePicker *startDatePicker;
@property (nonatomic, strong) UIDatePicker *endDatePicker;
@property (nonatomic, assign) BOOL isUpdatingDatePickers;

@end

@implementation TimelineRangeAxisView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.backgroundColor = [UIColor clearColor];
    self.axisColor = [UIColor systemBlueColor];
    
    self.trackView = [UIView new];
    self.trackView.backgroundColor = [[UIColor systemGrayColor] colorWithAlphaComponent:0.25];
    self.trackView.layer.cornerRadius = 2;
    [self addSubview:self.trackView];
    
    self.selectedTrackView = [UIView new];
    self.selectedTrackView.backgroundColor = self.axisColor;
    self.selectedTrackView.layer.cornerRadius = 2;
    [self addSubview:self.selectedTrackView];
    
    self.startHandleView = [self handleView];
    self.endHandleView = [self handleView];
    [self addSubview:self.startHandleView];
    [self addSubview:self.endHandleView];
    
    self.startDatePicker = [self datePickerWithAction:@selector(startDatePickerValueChanged:)];
    self.endDatePicker = [self datePickerWithAction:@selector(endDatePickerValueChanged:)];
    [self addSubview:self.startDatePicker];
    [self addSubview:self.endDatePicker];
    
    UIPanGestureRecognizer *startPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    UIPanGestureRecognizer *endPanRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.startHandleView addGestureRecognizer:startPanRecognizer];
    [self.endHandleView addGestureRecognizer:endPanRecognizer];
}

- (UIView *)handleView
{
    UIView *view = [UIView new];
    view.backgroundColor = self.axisColor;
    view.layer.cornerRadius = 11;
    view.layer.borderWidth = 3;
    view.layer.borderColor = UIColor.whiteColor.CGColor;
    view.layer.shadowColor = UIColor.blackColor.CGColor;
    view.layer.shadowOpacity = 0.18;
    view.layer.shadowRadius = 3;
    view.layer.shadowOffset = CGSizeMake(0, 1);
    view.userInteractionEnabled = YES;
    return view;
}

- (UIDatePicker *)datePickerWithAction:(SEL)action
{
    UIDatePicker *picker = [UIDatePicker new];
    picker.datePickerMode = UIDatePickerModeDateAndTime;
    picker.timeZone = [NSTimeZone systemTimeZone];
    picker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    picker.transform = CGAffineTransformMakeScale(0.82, 0.82);
    [picker addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    return picker;
}

- (void)setAxisColor:(UIColor *)axisColor
{
    _axisColor = axisColor ?: [UIColor systemBlueColor];
    self.selectedTrackView.backgroundColor = _axisColor;
    self.startHandleView.backgroundColor = _axisColor;
    self.endHandleView.backgroundColor = _axisColor;
}

- (void)configureWithMinimumTimestamp:(long)minimumTimestamp
                     maximumTimestamp:(long)maximumTimestamp
                        startTimestamp:(long)startTimestamp
                          endTimestamp:(long)endTimestamp
                          canDragStart:(BOOL)canDragStart
                            canDragEnd:(BOOL)canDragEnd
{
    self.minimumTimestamp = minimumTimestamp;
    self.maximumTimestamp = MAX(maximumTimestamp, minimumTimestamp + kMinSeconds);
    self.startTimestamp = canDragStart ? MIN(MAX(startTimestamp, self.minimumTimestamp), self.maximumTimestamp - kMinSeconds) : MIN(startTimestamp, endTimestamp - kMinSeconds);
    self.endTimestamp = canDragEnd ? MAX(MIN(endTimestamp, self.maximumTimestamp), self.startTimestamp + kMinSeconds) : MAX(endTimestamp, self.startTimestamp + kMinSeconds);
    self.canDragStart = canDragStart;
    self.canDragEnd = canDragEnd;
    self.startHandleView.hidden = !canDragStart;
    self.endHandleView.hidden = !canDragEnd;
    [self updateDatePickers];
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat pickerWidth = MIN(CGRectGetWidth(self.bounds) / 2 + 18, 136);
    self.startDatePicker.frame = CGRectMake(-12, -2, pickerWidth, 34);
    self.endDatePicker.frame = CGRectMake(CGRectGetWidth(self.bounds) - pickerWidth + 12, -2, pickerWidth, 34);
    
    CGFloat trackLeft = 16;
    CGFloat trackRight = CGRectGetWidth(self.bounds) - 16;
    CGFloat trackWidth = MAX(trackRight - trackLeft, 1);
    CGFloat trackY = 46;
    CGFloat startX = trackLeft + trackWidth * [self ratioForTimestamp:self.startTimestamp];
    CGFloat endX = trackLeft + trackWidth * [self ratioForTimestamp:self.endTimestamp];
    
    self.trackView.frame = CGRectMake(trackLeft, trackY, trackWidth, 4);
    self.selectedTrackView.frame = CGRectMake(MIN(startX, endX), trackY, MAX(fabs(endX - startX), 4), 4);
    self.startHandleView.frame = CGRectMake(startX - 11, trackY - 9, 22, 22);
    self.endHandleView.frame = CGRectMake(endX - 11, trackY - 9, 22, 22);
}

- (CGFloat)ratioForTimestamp:(long)timestamp
{
    long range = self.maximumTimestamp - self.minimumTimestamp;
    if (range <= 0) {
        return 0;
    }
    return MIN(MAX((CGFloat)(timestamp - self.minimumTimestamp) / (CGFloat)range, 0), 1);
}

- (long)timestampForLocationX:(CGFloat)x
{
    CGFloat trackLeft = 16;
    CGFloat trackRight = CGRectGetWidth(self.bounds) - 16;
    CGFloat ratio = MIN(MAX((x - trackLeft) / MAX(trackRight - trackLeft, 1), 0), 1);
    long timestamp = self.minimumTimestamp + lround((self.maximumTimestamp - self.minimumTimestamp) * ratio);
    return [self roundedTimestamp:timestamp];
}

- (long)roundedTimestamp:(long)timestamp
{
    return (long)round(timestamp / (double)kMinSeconds) * kMinSeconds;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    BOOL isStartHandle = recognizer.view == self.startHandleView;
    if ((isStartHandle && !self.canDragStart) || (!isStartHandle && !self.canDragEnd)) {
        return;
    }
    
    CGPoint location = [recognizer locationInView:self];
    long timestamp = [self timestampForLocationX:location.x];
    if (isStartHandle) {
        timestamp = MIN(MAX(timestamp, self.minimumTimestamp), self.endTimestamp - kMinSeconds);
        [self setStartTimestampFromUserInput:timestamp];
    } else {
        timestamp = MAX(MIN(timestamp, self.maximumTimestamp), self.startTimestamp + kMinSeconds);
        [self setEndTimestampFromUserInput:timestamp];
    }
}

- (void)startDatePickerValueChanged:(UIDatePicker *)picker
{
    if (self.isUpdatingDatePickers) {
        return;
    }
    long timestamp = [self roundedTimestamp:round([picker.date timeIntervalSince1970])];
    if (self.canDragStart) {
        timestamp = MAX(timestamp, self.minimumTimestamp);
    }
    timestamp = MIN(timestamp, self.endTimestamp - kMinSeconds);
    [self setStartTimestampFromUserInput:timestamp];
}

- (void)endDatePickerValueChanged:(UIDatePicker *)picker
{
    if (self.isUpdatingDatePickers) {
        return;
    }
    long timestamp = [self roundedTimestamp:round([picker.date timeIntervalSince1970])];
    timestamp = MAX(timestamp, self.startTimestamp + kMinSeconds);
    if (self.canDragEnd) {
        timestamp = MIN(timestamp, self.maximumTimestamp);
    }
    [self setEndTimestampFromUserInput:timestamp];
}

- (void)setStartTimestampFromUserInput:(long)timestamp
{
    if (timestamp == self.startTimestamp) {
        [self updateDatePickers];
        return;
    }
    self.startTimestamp = timestamp;
    [self updateDatePickers];
    [self setNeedsLayout];
    if (self.valueChanged) {
        self.valueChanged(YES, timestamp);
    }
}

- (void)setEndTimestampFromUserInput:(long)timestamp
{
    if (timestamp == self.endTimestamp) {
        [self updateDatePickers];
        return;
    }
    self.endTimestamp = timestamp;
    [self updateDatePickers];
    [self setNeedsLayout];
    if (self.valueChanged) {
        self.valueChanged(NO, timestamp);
    }
}

- (void)updateDatePickers
{
    self.isUpdatingDatePickers = YES;
    self.startDatePicker.minimumDate = self.canDragStart ? [NSDate dateWithTimeIntervalSince1970:self.minimumTimestamp] : nil;
    self.startDatePicker.maximumDate = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp - kMinSeconds];
    self.startDatePicker.date = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp];
    self.endDatePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:self.startTimestamp + kMinSeconds];
    self.endDatePicker.maximumDate = self.canDragEnd ? [NSDate dateWithTimeIntervalSince1970:self.maximumTimestamp] : nil;
    self.endDatePicker.date = [NSDate dateWithTimeIntervalSince1970:self.endTimestamp];
    self.isUpdatingDatePickers = NO;
}

@end
