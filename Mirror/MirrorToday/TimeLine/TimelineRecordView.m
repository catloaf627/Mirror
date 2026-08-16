//
//  TimelineRecordView.m
//  Mirror
//

#import "TimelineRecordView.h"
#import "MirrorRecordModel.h"
#import "MirrorStorage.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"

#define kTimelineRecordResizeHandleHeight (24*kWidthRatio)
#define kTimelineRecordResizeHandleSideWidth (120*kWidthRatio)
#define kTimelineRecordHandleSize (10*kWidthRatio)
#define kTimelineRecordResizeTouchOutset (14*kWidthRatio)
#define kTimelineRecordEditAnimationKey @"TimelineRecordEditAnimation"

typedef NS_ENUM(NSInteger, TimelineRecordDragMode) {
    TimelineRecordDragModeNone,
    TimelineRecordDragModeStart,
    TimelineRecordDragModeEnd,
    TimelineRecordDragModeMove,
};

@interface TimelineRecordView () <UIGestureRecognizerDelegate, UIEditMenuInteractionDelegate>

@property (nonatomic, assign) NSInteger periodIndex;
@property (nonatomic, assign) BOOL isInlineEditing;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, assign) BOOL allowsMoveDrag;
@property (nonatomic, assign) TimelineRecordDragMode dragMode;
@property (nonatomic, assign) long originalStartTimestamp;
@property (nonatomic, assign) long originalEndTimestamp;
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
@property (nonatomic, strong) UIView *debugStartRangeView;
@property (nonatomic, strong) UIView *debugEndRangeView;
@property (nonatomic, strong) UIView *debugMoveRangeView;
@property (nonatomic, strong) UIColor *recordPulseColor;
@property (nonatomic, strong) UIEditMenuInteraction *editMenuInteraction API_AVAILABLE(ios(16.0));

@end

@implementation TimelineRecordView

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
    self.accessibilityIdentifier = @"TimelineRecordView";
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = NO;

    self.foregroundView = [[UIView alloc] initWithFrame:self.bounds];
    self.foregroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.foregroundView.layer.cornerRadius = 5;
    self.foregroundView.layer.masksToBounds = YES;
    [self addSubview:self.foregroundView];

    self.startHandleView = [self handleView];
    self.endHandleView = [self handleView];
    [self addSubview:self.startHandleView];
    [self addSubview:self.endHandleView];
    [self setHandlesHidden:YES];

    if (@available(iOS 16.0, *)) {
        self.editMenuInteraction = [[UIEditMenuInteraction alloc] initWithDelegate:self];
        [self.foregroundView addInteraction:self.editMenuInteraction];
    }

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecordView:)];
    tapRecognizer.delegate = self;
    [self.foregroundView addGestureRecognizer:tapRecognizer];

    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressRecordView:)];
    longPressRecognizer.delegate = self;
    longPressRecognizer.minimumPressDuration = 0.65;
    [self.foregroundView addGestureRecognizer:longPressRecognizer];

    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panRecord:)];
    panRecognizer.delegate = self;
    [self addGestureRecognizer:panRecognizer];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (!self.isInlineEditing) {
        return [super pointInside:point withEvent:event];
    }
    if (self.allowsMoveDrag) {
        return CGRectContainsPoint(CGRectInset(self.bounds, -kTimelineRecordResizeTouchOutset, -kTimelineRecordResizeTouchOutset), point);
    }
    return CGRectContainsPoint(self.bounds, point) || CGRectContainsPoint([self startResizeTouchRect], point) || CGRectContainsPoint([self endResizeTouchRect], point);
}

- (UIView *)handleView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kTimelineRecordHandleSize, kTimelineRecordHandleSize)];
    view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    view.layer.cornerRadius = kTimelineRecordHandleSize / 2.0;
    view.layer.borderWidth = 2;
    view.layer.borderColor = UIColor.whiteColor.CGColor;
    view.userInteractionEnabled = NO;
    return view;
}

- (void)configureWithRecord:(MirrorRecordModel *)record
                  showsText:(BOOL)showsText
{
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:record.taskName];
    MirrorColorType colorType = task ? task.color : MirrorColorTypeCellGray;
    UIColor *recordColor = [UIColor mirrorColorNamed:colorType];
    self.recordPulseColor = [UIColor mirrorColorPulsed:colorType];
    self.periodIndex = record.originalIndex;
    self.tag = record.originalIndex;
    self.foregroundView.tag = record.originalIndex;
    self.foregroundView.backgroundColor = [recordColor colorWithAlphaComponent:0.7];
    [self updateSelectionColors];
    self.originalStartTimestamp = record.startTime;
    self.originalEndTimestamp = record.endTime;

    [self.titleLabel removeFromSuperview];
    self.titleLabel = nil;
    if (!showsText) {
        return;
    }

    UILabel *titleLabel = [UILabel new];
    titleLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    titleLabel.font = [UIFont mirrorHintFont_Card];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    titleLabel.attributedText = [self attributedTimelineTextForRecord:record font:titleLabel.font];
    [self.foregroundView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    [self layoutTitleLabel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutTitleLabel];
    [self layoutHandles];
    [self updateDebugRangeViews];
}

- (void)layoutTitleLabel
{
    if (!self.titleLabel) {
        return;
    }
    CGFloat labelPadding = 5*kWidthRatio;
    CGFloat labelHeight = 15*kWidthRatio;
    self.titleLabel.frame = CGRectMake(
        labelPadding,
        labelPadding,
        CGRectGetWidth(self.bounds) - 2*labelPadding,
        labelHeight
    );
}

- (void)layoutHandles
{
    CGFloat handleSize = kTimelineRecordHandleSize;
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
    CGFloat sideLength = MAX(44.0, kTimelineRecordHandleSize + 2*kTimelineRecordResizeTouchOutset);
    return CGRectMake(center.x - sideLength / 2.0,
                      center.y - sideLength / 2.0,
                      sideLength,
                      sideLength);
}

- (void)tapRecordView:(UITapGestureRecognizer *)recognizer
{
    if (self.isInlineEditing) {
        [self endInlineEditing];
        return;
    }
    if ([self.delegate respondsToSelector:@selector(timelineRecordViewDidRequestMenuDismissal:)]) {
        [self.delegate timelineRecordViewDidRequestMenuDismissal:self];
    }
    [self.delegate timelineRecordViewDidRequestInlineEditing:self];
}

- (void)longPressRecordView:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    if ([self.delegate respondsToSelector:@selector(timelineRecordViewDidRequestMenuDismissal:)]) {
        [self.delegate timelineRecordViewDidRequestMenuDismissal:self];
    }
    if ([self.delegate respondsToSelector:@selector(timelineRecordViewDidRequestMoveEditing:)]) {
        [self.delegate timelineRecordViewDidRequestMoveEditing:self];
    } else {
        [self beginSelectionShowsHandles:NO animated:YES];
    }
    if (@available(iOS 16.0, *)) {
        CGPoint point = [recognizer locationInView:self.foregroundView];
        UIEditMenuConfiguration *configuration = [UIEditMenuConfiguration configurationWithIdentifier:nil sourcePoint:point];
        [self.editMenuInteraction presentEditMenuWithConfiguration:configuration];
    }
}

- (void)panRecord:(UIPanGestureRecognizer *)recognizer
{
    if (!self.isInlineEditing) {
        return;
    }

    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.dragMode = [self dragModeForLocation:[recognizer locationInView:self.foregroundView]];
        if (self.dragMode == TimelineRecordDragModeNone) {
            return;
        }
        self.originalTop = CGRectGetMinY(self.frame);
        self.originalHeight = CGRectGetHeight(self.frame);
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (self.dragMode == TimelineRecordDragModeNone) {
            return;
        }
        [self updateFrameWithTranslation:[recognizer translationInView:self.superview].y];
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.dragMode == TimelineRecordDragModeNone) {
            return;
        }
        [self commitDrag];
    } else if (recognizer.state == UIGestureRecognizerStateCancelled || recognizer.state == UIGestureRecognizerStateFailed) {
        [self cancelDrag];
    }
}

- (TimelineRecordDragMode)dragModeForLocation:(CGPoint)location
{
    if (CGRectContainsPoint([self startResizeTouchRect], location)) {
        return TimelineRecordDragModeStart;
    }
    if (CGRectContainsPoint([self endResizeTouchRect], location)) {
        return TimelineRecordDragModeEnd;
    }
    return self.allowsMoveDrag ? TimelineRecordDragModeMove : TimelineRecordDragModeNone;
}

- (void)beginInlineEditingWithMinimumTimestamp:(long)minimumTimestamp
                              maximumTimestamp:(long)maximumTimestamp
                                    hourHeight:(CGFloat)hourHeight
                             dayStartTimestamp:(long)dayStartTimestamp
                               dayEndTimestamp:(long)dayEndTimestamp
{
    [self beginEditingWithMinimumTimestamp:minimumTimestamp
                          maximumTimestamp:maximumTimestamp
                                hourHeight:hourHeight
                         dayStartTimestamp:dayStartTimestamp
                           dayEndTimestamp:dayEndTimestamp
                              showsHandles:YES
                            allowsMoveDrag:NO
                                  animated:NO];
}

- (void)beginMoveEditingWithMinimumTimestamp:(long)minimumTimestamp
                            maximumTimestamp:(long)maximumTimestamp
                                  hourHeight:(CGFloat)hourHeight
                           dayStartTimestamp:(long)dayStartTimestamp
                             dayEndTimestamp:(long)dayEndTimestamp
{
    [self beginEditingWithMinimumTimestamp:minimumTimestamp
                          maximumTimestamp:maximumTimestamp
                                hourHeight:hourHeight
                         dayStartTimestamp:dayStartTimestamp
                           dayEndTimestamp:dayEndTimestamp
                              showsHandles:NO
                            allowsMoveDrag:YES
                                  animated:YES];
}

- (void)beginEditingWithMinimumTimestamp:(long)minimumTimestamp
                        maximumTimestamp:(long)maximumTimestamp
                              hourHeight:(CGFloat)hourHeight
                       dayStartTimestamp:(long)dayStartTimestamp
                         dayEndTimestamp:(long)dayEndTimestamp
                            showsHandles:(BOOL)showsHandles
                          allowsMoveDrag:(BOOL)allowsMoveDrag
                                animated:(BOOL)animated
{
    self.isInlineEditing = YES;
    self.allowsMoveDrag = allowsMoveDrag;
    self.minimumTimestamp = minimumTimestamp;
    self.maximumTimestamp = maximumTimestamp;
    self.hourHeight = hourHeight;
    self.dayStartTimestamp = dayStartTimestamp;
    self.dayEndTimestamp = dayEndTimestamp;
    self.originalTop = CGRectGetMinY(self.frame);
    self.originalHeight = CGRectGetHeight(self.frame);
    [self beginSelectionShowsHandles:showsHandles animated:animated];
    [self updateDebugRangeViews];
    [self.delegate timelineRecordView:self didChangeScrollEnabled:NO];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
}

- (void)endInlineEditing
{
    if (!self.isInlineEditing && !self.isSelected) {
        return;
    }
    self.isInlineEditing = NO;
    self.allowsMoveDrag = NO;
    self.dragMode = TimelineRecordDragModeNone;
    [self endSelection];
    [self.delegate timelineRecordView:self didChangeScrollEnabled:YES];
}

- (void)endSelection
{
    self.isSelected = NO;
    [self removeDebugRangeViews];
    [self removeEditingAnimation];
    self.layer.borderWidth = 0;
    self.layer.borderColor = nil;
    [self setHandlesHidden:YES];
}

- (BOOL)containsTimelinePoint:(CGPoint)point
{
    return CGRectContainsPoint(self.frame, point);
}

- (void)updateFrameWithTranslation:(CGFloat)translationY
{
    CGRect frame = self.frame;
    CGFloat originalBottom = self.originalTop + self.originalHeight;
    if (self.dragMode == TimelineRecordDragModeStart) {
        long maximumStartTimestamp = self.originalEndTimestamp - kMinSeconds;
        CGFloat minimumTop = [self timelineYForTimestamp:self.minimumTimestamp];
        CGFloat maximumTop = [self timelineYForTimestamp:maximumStartTimestamp];
        CGFloat newTop = MIN(MAX(self.originalTop + translationY, minimumTop), maximumTop);
        long timestamp = [self boundaryTimestampForTimelineY:newTop];
        timestamp = MIN(MAX(timestamp, self.minimumTimestamp), maximumStartTimestamp);
        newTop = [self timelineYForTimestamp:timestamp];
        frame.origin.y = newTop;
        frame.size.height = originalBottom - newTop;
    } else if (self.dragMode == TimelineRecordDragModeEnd) {
        long minimumEndTimestamp = self.originalStartTimestamp + kMinSeconds;
        CGFloat minimumBottom = [self timelineYForTimestamp:minimumEndTimestamp];
        CGFloat maximumBottom = [self timelineYForTimestamp:self.maximumTimestamp];
        CGFloat newBottom = MIN(MAX(originalBottom + translationY, minimumBottom), maximumBottom);
        long timestamp = [self boundaryTimestampForTimelineY:newBottom];
        timestamp = MIN(MAX(timestamp, minimumEndTimestamp), self.maximumTimestamp);
        newBottom = [self timelineYForTimestamp:timestamp];
        frame.size.height = newBottom - CGRectGetMinY(frame);
    } else if (self.dragMode == TimelineRecordDragModeMove) {
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
    [self updateDebugRangeViews];
}

- (void)commitDrag
{
    TimelineRecordDragMode dragMode = self.dragMode;
    long newStartTimestamp = self.originalStartTimestamp;
    long newEndTimestamp = self.originalEndTimestamp;
    if (dragMode == TimelineRecordDragModeStart) {
        newStartTimestamp = [self boundaryTimestampForTimelineY:CGRectGetMinY(self.frame)];
        newStartTimestamp = MIN(MAX(newStartTimestamp, self.minimumTimestamp), self.originalEndTimestamp - kMinSeconds);
    } else if (dragMode == TimelineRecordDragModeEnd) {
        newEndTimestamp = [self boundaryTimestampForTimelineY:CGRectGetMaxY(self.frame)];
        newEndTimestamp = MIN(MAX(newEndTimestamp, self.originalStartTimestamp + kMinSeconds), self.maximumTimestamp);
    } else if (dragMode == TimelineRecordDragModeMove) {
        long duration = self.originalEndTimestamp - self.originalStartTimestamp;
        newStartTimestamp = [self boundaryTimestampForTimelineY:CGRectGetMinY(self.frame)];
        newStartTimestamp = MIN(MAX(newStartTimestamp, self.minimumTimestamp), self.maximumTimestamp - duration);
        newEndTimestamp = newStartTimestamp + duration;
    }

    self.dragMode = TimelineRecordDragModeNone;
    if (dragMode == TimelineRecordDragModeStart && newStartTimestamp != self.originalStartTimestamp) {
        [self.delegate timelineRecordView:self didCommitStartTimestamp:newStartTimestamp];
    } else if (dragMode == TimelineRecordDragModeEnd && newEndTimestamp != self.originalEndTimestamp) {
        [self.delegate timelineRecordView:self didCommitEndTimestamp:newEndTimestamp];
    } else if (dragMode == TimelineRecordDragModeMove && (newStartTimestamp != self.originalStartTimestamp || newEndTimestamp != self.originalEndTimestamp)) {
        [self.delegate timelineRecordView:self didCommitStartTimestamp:newStartTimestamp endTimestamp:newEndTimestamp];
    }
}

- (void)cancelDrag
{
    CGRect frame = self.frame;
    frame.origin.y = self.originalTop;
    frame.size.height = self.originalHeight;
    self.frame = frame;
    self.dragMode = TimelineRecordDragModeNone;
    [self.delegate timelineRecordView:self didChangeScrollEnabled:YES];
}

- (void)beginSelectionShowsHandles:(BOOL)showsHandles animated:(BOOL)animated
{
    self.isSelected = YES;
    self.layer.borderWidth = 2;
    self.layer.borderColor = self.recordPulseColor.CGColor;
    [self updateSelectionColors];
    [self setHandlesHidden:!showsHandles];
    if (animated) {
        [self applyEditingAnimation];
    } else {
        [self removeEditingAnimation];
    }
}

- (void)setHandlesHidden:(BOOL)hidden
{
    self.startHandleView.hidden = hidden;
    self.endHandleView.hidden = hidden;
}

- (void)updateDebugRangeViews
{
    if (!is_debug || !self.isInlineEditing) {
        [self removeDebugRangeViews];
        return;
    }

    [self ensureDebugRangeViews];
    CGFloat outset = kTimelineRecordResizeTouchOutset;

    if (self.allowsMoveDrag) {
        self.debugMoveRangeView.hidden = NO;
        self.debugStartRangeView.hidden = YES;
        self.debugEndRangeView.hidden = YES;
        self.debugMoveRangeView.frame = CGRectInset(self.foregroundView.frame, -outset, -outset);
        [self sendSubviewToBack:self.debugMoveRangeView];
        return;
    }

    self.debugStartRangeView.hidden = NO;
    self.debugEndRangeView.hidden = NO;
    self.debugMoveRangeView.hidden = YES;
    self.debugStartRangeView.frame = [self startResizeTouchRect];
    self.debugEndRangeView.frame = [self endResizeTouchRect];
    [self sendSubviewToBack:self.debugStartRangeView];
    [self sendSubviewToBack:self.debugEndRangeView];
}

- (void)ensureDebugRangeViews
{
    if (!self.debugStartRangeView) {
        self.debugStartRangeView = [self debugRangeViewWithColor:[UIColor systemBlueColor]];
        [self addSubview:self.debugStartRangeView];
    }
    if (!self.debugEndRangeView) {
        self.debugEndRangeView = [self debugRangeViewWithColor:[UIColor systemOrangeColor]];
        [self addSubview:self.debugEndRangeView];
    }
    if (!self.debugMoveRangeView) {
        self.debugMoveRangeView = [self debugRangeViewWithColor:[UIColor systemGreenColor]];
        [self addSubview:self.debugMoveRangeView];
    }
    [self sendSubviewToBack:self.debugStartRangeView];
    [self sendSubviewToBack:self.debugEndRangeView];
    [self sendSubviewToBack:self.debugMoveRangeView];
}

- (UIView *)debugRangeViewWithColor:(UIColor *)color
{
    UIView *view = [UIView new];
    view.userInteractionEnabled = NO;
    view.backgroundColor = [color colorWithAlphaComponent:0.45];
    view.layer.cornerRadius = 2;
    return view;
}

- (void)removeDebugRangeViews
{
    [self.debugStartRangeView removeFromSuperview];
    self.debugStartRangeView = nil;
    [self.debugEndRangeView removeFromSuperview];
    self.debugEndRangeView = nil;
    [self.debugMoveRangeView removeFromSuperview];
    self.debugMoveRangeView = nil;
}

- (void)updateSelectionColors
{
    UIColor *pulseColor = self.recordPulseColor ?: [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    self.startHandleView.backgroundColor = pulseColor;
    self.endHandleView.backgroundColor = pulseColor;
    if (self.isSelected) {
        self.layer.borderColor = pulseColor.CGColor;
    }
}

- (void)applyEditingAnimation
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    animation.values = @[@(-0.025), @(0.025), @(-0.025)];
    animation.duration = 0.16;
    animation.repeatCount = HUGE_VALF;
    animation.autoreverses = YES;
    [self.layer addAnimation:animation forKey:kTimelineRecordEditAnimationKey];
}

- (void)removeEditingAnimation
{
    [self.layer removeAnimationForKey:kTimelineRecordEditAnimationKey];
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

- (NSAttributedString *)attributedTimelineTextForRecord:(MirrorRecordModel *)record font:(UIFont *)font
{
    NSString *taskName = record.taskName ?: @"";
    NSString *note = record.note ?: @"";
    NSString *text = note.length > 0 ? [NSString stringWithFormat:@"%@  %@", taskName, note] : taskName;
    if (is_debug) {
        text = note.length > 0 ? [NSString stringWithFormat:@"%@  %@ #%ld", taskName, note, (long)record.originalIndex] : [NSString stringWithFormat:@"%@ #%ld", taskName, (long)record.originalIndex];
    }
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor mirrorColorNamed:MirrorColorTypeTextHint]
    }];
    [attributedText addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:font.pointSize] range:NSMakeRange(0, taskName.length)];
    return attributedText;
}

#pragma mark - UIEditMenuInteractionDelegate

- (UIMenu *)editMenuInteraction:(UIEditMenuInteraction *)interaction menuForConfiguration:(UIEditMenuConfiguration *)configuration suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0))
{
    if ([self.delegate respondsToSelector:@selector(menuForTimelineRecordView:)]) {
        return [self.delegate menuForTimelineRecordView:self];
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
