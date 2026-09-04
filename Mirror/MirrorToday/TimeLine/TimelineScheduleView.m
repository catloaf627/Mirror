//
//  TimelineScheduleView.m
//  Mirror
//

#import "TimelineScheduleView.h"
#import "MirrorScheduleModel.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"

#define kTimelineScheduleHandleSize (10*kWidthRatio)
#define kTimelineScheduleResizeTouchOutset (14*kWidthRatio)
typedef NS_ENUM(NSInteger, TimelineScheduleDragMode) {
    TimelineScheduleDragModeNone,
    TimelineScheduleDragModeStart,
    TimelineScheduleDragModeEnd,
    TimelineScheduleDragModeMove,
};

@interface TimelineScheduleView () <UIGestureRecognizerDelegate, UIEditMenuInteractionDelegate>

@property (nonatomic, assign) NSInteger scheduleIndex;
@property (nonatomic, assign) BOOL isInlineEditing;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL allowsMoveDrag;
@property (nonatomic, assign) TimelineScheduleDragMode dragMode;
@property (nonatomic, assign) long originalStartTimestamp;
@property (nonatomic, assign) long originalEndTimestamp;
@property (nonatomic, copy) NSString *scheduleTitle;
@property (nonatomic, assign) long minimumTimestamp;
@property (nonatomic, assign) long maximumTimestamp;
@property (nonatomic, assign) long dayStartTimestamp;
@property (nonatomic, assign) long dayEndTimestamp;
@property (nonatomic, assign) CGFloat hourHeight;
@property (nonatomic, assign) CGFloat originalTop;
@property (nonatomic, assign) CGFloat originalHeight;
@property (nonatomic, strong) UIView *foregroundView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *startHandleView;
@property (nonatomic, strong) UIView *endHandleView;
@property (nonatomic, strong) CAShapeLayer *selectionPatternLayer;
@property (nonatomic, strong) CAShapeLayer *selectionPatternMaskLayer;
@property (nonatomic, strong) CAShapeLayer *dottedBorderLayer;
@property (nonatomic, assign) BOOL longSelected;
@property (nonatomic, strong) UIEditMenuInteraction *editMenuInteraction API_AVAILABLE(ios(16.0));

@end

@implementation TimelineScheduleView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    self.accessibilityIdentifier = @"TimelineScheduleView";
    self.userInteractionEnabled = YES;
    self.backgroundColor = UIColor.clearColor;
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = NO;
    
    self.selectionPatternLayer = [CAShapeLayer layer];
    self.selectionPatternLayer.fillColor = UIColor.clearColor.CGColor;
    self.selectionPatternLayer.lineWidth = 1.0;
    self.selectionPatternMaskLayer = [CAShapeLayer layer];
    self.selectionPatternLayer.mask = self.selectionPatternMaskLayer;
    [self.layer addSublayer:self.selectionPatternLayer];
    
    self.dottedBorderLayer = [CAShapeLayer layer];
    self.dottedBorderLayer.fillColor = UIColor.clearColor.CGColor;
    self.dottedBorderLayer.lineWidth = 1.2;
    self.dottedBorderLayer.lineDashPattern = @[@2, @3];
    [self.layer addSublayer:self.dottedBorderLayer];
    
    self.foregroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.foregroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.foregroundView.layer.cornerRadius = 5;
    self.foregroundView.layer.masksToBounds = YES;
    [self addSubview:self.foregroundView];
    
    self.titleLabel = [UILabel new];
    self.titleLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeSchedule];
    self.titleLabel.font = [UIFont mirrorHintFont_Card];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.foregroundView addSubview:self.titleLabel];
    
    self.startHandleView = [self handleView];
    self.endHandleView = [self handleView];
    [self addSubview:self.startHandleView];
    [self addSubview:self.endHandleView];
    [self setHandlesHidden:YES];
    
    if (@available(iOS 16.0, *)) {
        self.editMenuInteraction = [[UIEditMenuInteraction alloc] initWithDelegate:self];
        [self.foregroundView addInteraction:self.editMenuInteraction];
    }
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSchedule:)];
    tapRecognizer.delegate = self;
    [self.foregroundView addGestureRecognizer:tapRecognizer];
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressSchedule:)];
    longPressRecognizer.delegate = self;
    longPressRecognizer.minimumPressDuration = 0.25;
    [self.foregroundView addGestureRecognizer:longPressRecognizer];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panSchedule:)];
    panRecognizer.delegate = self;
    [self addGestureRecognizer:panRecognizer];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.isInlineEditing) {
        return [super pointInside:point withEvent:event];
    }
    return CGRectContainsPoint([self moveDragTouchRect], point) || CGRectContainsPoint([self startResizeTouchRect], point) || CGRectContainsPoint([self endResizeTouchRect], point);
}

- (UIView *)handleView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kTimelineScheduleHandleSize, kTimelineScheduleHandleSize)];
    view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeSchedule];
    view.layer.cornerRadius = kTimelineScheduleHandleSize / 2.0;
    view.layer.borderWidth = 2;
    view.layer.borderColor = UIColor.whiteColor.CGColor;
    view.userInteractionEnabled = NO;
    return view;
}

- (void)configureWithSchedule:(MirrorScheduleModel *)schedule
{
    self.scheduleIndex = schedule.originalIndex;
    self.tag = schedule.originalIndex;
    self.foregroundView.tag = schedule.originalIndex;
    self.originalStartTimestamp = schedule.startTime;
    self.originalEndTimestamp = schedule.endTime;
    self.scheduleTitle = schedule.scheduleInfo ?: @"";
    self.titleLabel.text = self.scheduleTitle;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateScheduleAppearance];
    CGFloat padding = 5*kWidthRatio;
    self.titleLabel.frame = CGRectMake(padding, padding, CGRectGetWidth(self.bounds) - 2*padding, 16*kWidthRatio);
    [self layoutHandles];
}

- (void)layoutHandles
{
    CGFloat handleSize = kTimelineScheduleHandleSize;
    CGFloat horizontalInset = 30*kWidthRatio;
    self.startHandleView.frame = CGRectMake(horizontalInset - handleSize / 2.0,
                                            -handleSize / 2.0,
                                            handleSize,
                                            handleSize);
    self.endHandleView.frame = CGRectMake(CGRectGetWidth(self.bounds) - horizontalInset - handleSize / 2.0,
                                          CGRectGetHeight(self.bounds) - handleSize / 2.0,
                                          handleSize,
                                          handleSize);
}

- (CGRect)startResizeTouchRect
{
    return [self resizeTouchRectCenteredAtPoint:self.startHandleView.center];
}

- (CGRect)endResizeTouchRect
{
    return [self resizeTouchRectCenteredAtPoint:self.endHandleView.center];
}

- (CGRect)resizeTouchRectCenteredAtPoint:(CGPoint)center
{
    CGFloat sideLength = MAX(64.0, kTimelineScheduleHandleSize + 2*kTimelineScheduleResizeTouchOutset);
    return CGRectMake(center.x - sideLength / 2.0,
                      center.y - sideLength / 2.0,
                      sideLength,
                      sideLength);
}

- (CGRect)moveDragTouchRect
{
    return self.bounds;
}

- (void)tapSchedule:(UITapGestureRecognizer *)recognizer
{
    if (self.isInlineEditing) {
        [self endInlineEditing];
        return;
    }
    [self.delegate timelineScheduleViewDidRequestInlineEditing:self];
}

- (void)beginLongSelection
{
    self.isInlineEditing = NO;
    self.longSelected = YES;
    self.isSelected = YES;
    self.allowsMoveDrag = NO;
    self.dragMode = TimelineScheduleDragModeNone;
    [self setHandlesHidden:YES];
    [self updateScheduleAppearance];
}

- (void)beginInlineEditingWithMinimumTimestamp:(long)minimumTimestamp
                              maximumTimestamp:(long)maximumTimestamp
                                    hourHeight:(CGFloat)hourHeight
                             dayStartTimestamp:(long)dayStartTimestamp
                               dayEndTimestamp:(long)dayEndTimestamp
{
    self.isInlineEditing = YES;
    self.longSelected = NO;
    self.isSelected = YES;
    self.allowsMoveDrag = YES;
    self.minimumTimestamp = minimumTimestamp;
    self.maximumTimestamp = maximumTimestamp;
    self.hourHeight = hourHeight;
    self.dayStartTimestamp = dayStartTimestamp;
    self.dayEndTimestamp = dayEndTimestamp;
    self.originalTop = CGRectGetMinY(self.frame);
    self.originalHeight = CGRectGetHeight(self.frame);
    [self setHandlesHidden:NO];
    [self updateScheduleAppearance];
    [self.delegate timelineScheduleView:self didChangeScrollEnabled:NO];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
}

- (void)endInlineEditing
{
    if (!self.isInlineEditing && !self.isSelected) {
        return;
    }
    self.isInlineEditing = NO;
    self.allowsMoveDrag = NO;
    self.dragMode = TimelineScheduleDragModeNone;
    [self endSelection];
    [self.delegate timelineScheduleView:self didChangeScrollEnabled:YES];
}

- (void)endSelection
{
    self.isInlineEditing = NO;
    self.isSelected = NO;
    self.longSelected = NO;
    self.allowsMoveDrag = NO;
    self.dragMode = TimelineScheduleDragModeNone;
    self.layer.borderWidth = 0;
    self.layer.borderColor = nil;
    [self setHandlesHidden:YES];
    [self updateScheduleAppearance];
}

- (void)updateScheduleAppearance
{
    UIColor *scheduleColor = [UIColor mirrorColorNamed:MirrorColorTypeSchedule];
    self.backgroundColor = UIColor.clearColor;
    self.selectionPatternLayer.frame = self.bounds;
    self.selectionPatternLayer.strokeColor = self.longSelected ? scheduleColor.CGColor : UIColor.clearColor.CGColor;
    self.selectionPatternLayer.path = [self selectionPatternPath].CGPath;
    self.selectionPatternMaskLayer.frame = self.selectionPatternLayer.bounds;
    self.selectionPatternMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.selectionPatternLayer.bounds cornerRadius:self.layer.cornerRadius].CGPath;
    self.dottedBorderLayer.frame = self.bounds;
    self.dottedBorderLayer.strokeColor = scheduleColor.CGColor;
    self.dottedBorderLayer.lineDashPattern = (self.longSelected || self.isInlineEditing) ? nil : @[@2, @3];
    self.dottedBorderLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.6, 0.6) cornerRadius:self.layer.cornerRadius].CGPath;
    self.layer.borderWidth = self.isInlineEditing ? 2 : 0;
    self.layer.borderColor = self.isInlineEditing ? scheduleColor.CGColor : nil;
    self.startHandleView.backgroundColor = scheduleColor;
    self.endHandleView.backgroundColor = scheduleColor;
}

- (UIBezierPath *)selectionPatternPath
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);
    CGFloat spacing = 8*kWidthRatio;
    for (CGFloat x = -height; x < width; x += spacing) {
        [path moveToPoint:CGPointMake(x, height)];
        [path addLineToPoint:CGPointMake(x + height, 0)];
    }
    return path;
}

- (void)longPressSchedule:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    if ([self.delegate respondsToSelector:@selector(timelineScheduleViewDidRequestLongSelection:)]) {
        [self.delegate timelineScheduleViewDidRequestLongSelection:self];
    }
    if (@available(iOS 16.0, *)) {
        CGPoint point = [recognizer locationInView:self.foregroundView];
        UIEditMenuConfiguration *configuration = [UIEditMenuConfiguration configurationWithIdentifier:nil sourcePoint:point];
        [self.editMenuInteraction presentEditMenuWithConfiguration:configuration];
    }
}

- (void)panSchedule:(UIPanGestureRecognizer *)recognizer
{
    if (!self.isInlineEditing) {
        return;
    }
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.dragMode = [self dragModeForLocation:[recognizer locationInView:self]];
        if (self.dragMode == TimelineScheduleDragModeNone) {
            return;
        }
        self.originalTop = CGRectGetMinY(self.frame);
        self.originalHeight = CGRectGetHeight(self.frame);
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (self.dragMode == TimelineScheduleDragModeNone) {
            return;
        }
        [self updateFrameWithTranslation:[recognizer translationInView:self.superview].y];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.dragMode == TimelineScheduleDragModeNone) {
            return;
        }
        [self commitDrag];
    } else if (recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed) {
        [self cancelDrag];
    }
}

- (TimelineScheduleDragMode)dragModeForLocation:(CGPoint)location
{
    if (CGRectContainsPoint([self startResizeTouchRect], location)) {
        return TimelineScheduleDragModeStart;
    }
    if (CGRectContainsPoint([self endResizeTouchRect], location)) {
        return TimelineScheduleDragModeEnd;
    }
    if (self.allowsMoveDrag && CGRectContainsPoint([self moveDragTouchRect], location)) {
        return TimelineScheduleDragModeMove;
    }
    return TimelineScheduleDragModeNone;
}

- (void)updateFrameWithTranslation:(CGFloat)translationY
{
    CGRect frame = self.frame;
    CGFloat originalBottom = self.originalTop + self.originalHeight;
    if (self.dragMode == TimelineScheduleDragModeStart) {
        long maximumStartTimestamp = self.originalEndTimestamp - kMinSeconds;
        CGFloat minimumTop = [self timelineYForTimestamp:self.minimumTimestamp];
        CGFloat maximumTop = [self timelineYForTimestamp:maximumStartTimestamp];
        CGFloat newTop = MIN(MAX(self.originalTop + translationY, minimumTop), maximumTop);
        long timestamp = [self boundaryTimestampForTimelineY:newTop];
        timestamp = MIN(MAX(timestamp, self.minimumTimestamp), maximumStartTimestamp);
        newTop = [self timelineYForTimestamp:timestamp];
        frame.origin.y = newTop;
        frame.size.height = originalBottom - newTop;
    } else if (self.dragMode == TimelineScheduleDragModeEnd) {
        long minimumEndTimestamp = self.originalStartTimestamp + kMinSeconds;
        CGFloat minimumBottom = [self timelineYForTimestamp:minimumEndTimestamp];
        CGFloat maximumBottom = [self timelineYForTimestamp:self.maximumTimestamp];
        CGFloat newBottom = MIN(MAX(originalBottom + translationY, minimumBottom), maximumBottom);
        long timestamp = [self boundaryTimestampForTimelineY:newBottom];
        timestamp = MIN(MAX(timestamp, minimumEndTimestamp), self.maximumTimestamp);
        newBottom = [self timelineYForTimestamp:timestamp];
        frame.size.height = newBottom - CGRectGetMinY(frame);
    } else if (self.dragMode == TimelineScheduleDragModeMove) {
        long duration = self.originalEndTimestamp - self.originalStartTimestamp;
        CGFloat minimumTop = [self timelineYForTimestamp:self.minimumTimestamp];
        CGFloat maximumBottom = [self timelineYForTimestamp:self.maximumTimestamp];
        CGFloat maximumTop = maximumBottom - self.originalHeight;
        CGFloat newTop = MIN(MAX(self.originalTop + translationY, minimumTop), maximumTop);
        long newStartTimestamp = [self boundaryTimestampForTimelineY:newTop];
        newStartTimestamp = MIN(MAX(newStartTimestamp, self.minimumTimestamp), self.maximumTimestamp - duration);
        frame.origin.y = [self timelineYForTimestamp:newStartTimestamp];
        frame.size.height = self.originalHeight;
    }
    self.frame = frame;
}

- (void)commitDrag
{
    TimelineScheduleDragMode dragMode = self.dragMode;
    long newStartTimestamp = self.originalStartTimestamp;
    long newEndTimestamp = self.originalEndTimestamp;
    if (dragMode == TimelineScheduleDragModeStart) {
        newStartTimestamp = [self boundaryTimestampForTimelineY:CGRectGetMinY(self.frame)];
        newStartTimestamp = MIN(MAX(newStartTimestamp, self.minimumTimestamp), self.originalEndTimestamp - kMinSeconds);
    } else if (dragMode == TimelineScheduleDragModeEnd) {
        newEndTimestamp = [self boundaryTimestampForTimelineY:CGRectGetMaxY(self.frame)];
        newEndTimestamp = MIN(MAX(newEndTimestamp, self.originalStartTimestamp + kMinSeconds), self.maximumTimestamp);
    } else if (dragMode == TimelineScheduleDragModeMove) {
        long duration = self.originalEndTimestamp - self.originalStartTimestamp;
        newStartTimestamp = [self boundaryTimestampForTimelineY:CGRectGetMinY(self.frame)];
        newStartTimestamp = MIN(MAX(newStartTimestamp, self.minimumTimestamp), self.maximumTimestamp - duration);
        newEndTimestamp = newStartTimestamp + duration;
    }
    
    self.dragMode = TimelineScheduleDragModeNone;
    if (dragMode == TimelineScheduleDragModeStart && newStartTimestamp != self.originalStartTimestamp) {
        [self.delegate timelineScheduleView:self didCommitStartTimestamp:newStartTimestamp];
    } else if (dragMode == TimelineScheduleDragModeEnd && newEndTimestamp != self.originalEndTimestamp) {
        [self.delegate timelineScheduleView:self didCommitEndTimestamp:newEndTimestamp];
    } else if (dragMode == TimelineScheduleDragModeMove && (newStartTimestamp != self.originalStartTimestamp || newEndTimestamp != self.originalEndTimestamp)) {
        [self.delegate timelineScheduleView:self didCommitStartTimestamp:newStartTimestamp endTimestamp:newEndTimestamp];
    } else {
        CGRect frame = self.frame;
        frame.origin.y = self.originalTop;
        frame.size.height = self.originalHeight;
        self.frame = frame;
    }
}

- (void)cancelDrag
{
    CGRect frame = self.frame;
    frame.origin.y = self.originalTop;
    frame.size.height = self.originalHeight;
    self.frame = frame;
    self.dragMode = TimelineScheduleDragModeNone;
    [self.delegate timelineScheduleView:self didChangeScrollEnabled:YES];
}

- (void)setHandlesHidden:(BOOL)hidden
{
    self.startHandleView.hidden = hidden;
    self.endHandleView.hidden = hidden;
}

- (CGFloat)timelineYForTimestamp:(long)timestamp
{
    long clampedTimestamp = MIN(MAX(timestamp, self.dayStartTimestamp), self.dayEndTimestamp);
    return ((CGFloat)(clampedTimestamp - self.dayStartTimestamp) / 3600.0) * self.hourHeight;
}

- (long)boundaryTimestampForTimelineY:(CGFloat)y
{
    NSInteger hourCount = (self.dayEndTimestamp - self.dayStartTimestamp) / 3600;
    CGFloat clampedY = MIN(MAX(y, 0), self.hourHeight * hourCount);
    NSInteger quarterHours = lround((clampedY / self.hourHeight) * 4.0);
    NSInteger maxQuarterHours = (self.dayEndTimestamp - self.dayStartTimestamp) / (15 * 60);
    quarterHours = MIN(MAX(quarterHours, 0), maxQuarterHours);
    return self.dayStartTimestamp + quarterHours * 15 * 60;
}

#pragma mark - UIEditMenuInteractionDelegate

- (UIMenu *)editMenuInteraction:(UIEditMenuInteraction *)interaction menuForConfiguration:(UIEditMenuConfiguration *)configuration suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0))
{
    if ([self.delegate respondsToSelector:@selector(menuForTimelineScheduleView:)]) {
        return [self.delegate menuForTimelineScheduleView:self];
    }
    return nil;
}

- (void)editMenuInteraction:(UIEditMenuInteraction *)interaction willDismissMenuForConfiguration:(UIEditMenuConfiguration *)configuration animator:(id<UIEditMenuInteractionAnimating>)animator API_AVAILABLE(ios(16.0))
{
    if (!self.isInlineEditing) {
        [self endSelection];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        return self.isInlineEditing;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

@end
