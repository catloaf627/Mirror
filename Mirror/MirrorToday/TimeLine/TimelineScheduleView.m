//
//  TimelineScheduleView.m
//  Mirror
//

#import "TimelineScheduleView.h"
#import "MirrorScheduleModel.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"

@interface TimelineScheduleView () <UIGestureRecognizerDelegate, UIEditMenuInteractionDelegate>

@property (nonatomic, assign) NSInteger scheduleIndex;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CAShapeLayer *selectionPatternLayer;
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
    self.layer.masksToBounds = YES;
    
    self.selectionPatternLayer = [CAShapeLayer layer];
    self.selectionPatternLayer.fillColor = UIColor.clearColor.CGColor;
    self.selectionPatternLayer.lineWidth = 1.0;
    [self.layer addSublayer:self.selectionPatternLayer];
    
    self.dottedBorderLayer = [CAShapeLayer layer];
    self.dottedBorderLayer.fillColor = UIColor.clearColor.CGColor;
    self.dottedBorderLayer.lineWidth = 1.2;
    self.dottedBorderLayer.lineDashPattern = @[@2, @3];
    [self.layer addSublayer:self.dottedBorderLayer];
    
    self.titleLabel = [UILabel new];
    self.titleLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeSchedule];
    self.titleLabel.font = [UIFont mirrorHintFont_Card];
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.titleLabel];
    
    if (@available(iOS 16.0, *)) {
        self.editMenuInteraction = [[UIEditMenuInteraction alloc] initWithDelegate:self];
        [self addInteraction:self.editMenuInteraction];
    }
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressSchedule:)];
    longPressRecognizer.delegate = self;
    longPressRecognizer.minimumPressDuration = 0.25;
    [self addGestureRecognizer:longPressRecognizer];
}

- (void)configureWithSchedule:(MirrorScheduleModel *)schedule
{
    self.scheduleIndex = schedule.originalIndex;
    self.tag = schedule.originalIndex;
    self.titleLabel.text = schedule.scheduleInfo ?: @"";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateScheduleAppearance];
    CGFloat padding = 5*kWidthRatio;
    self.titleLabel.frame = CGRectMake(padding, padding, CGRectGetWidth(self.bounds) - 2*padding, 16*kWidthRatio);
}

- (void)beginLongSelection
{
    self.longSelected = YES;
    [self updateScheduleAppearance];
}

- (void)endSelection
{
    self.longSelected = NO;
    [self updateScheduleAppearance];
}

- (void)updateScheduleAppearance
{
    UIColor *scheduleColor = [UIColor mirrorColorNamed:MirrorColorTypeSchedule];
    self.backgroundColor = UIColor.clearColor;
    self.selectionPatternLayer.frame = self.bounds;
    self.selectionPatternLayer.strokeColor = self.longSelected ? scheduleColor.CGColor : UIColor.clearColor.CGColor;
    self.selectionPatternLayer.path = [self selectionPatternPath].CGPath;
    self.dottedBorderLayer.frame = self.bounds;
    self.dottedBorderLayer.strokeColor = scheduleColor.CGColor;
    self.dottedBorderLayer.lineDashPattern = self.longSelected ? nil : @[@2, @3];
    self.dottedBorderLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(self.bounds, 0.6, 0.6) cornerRadius:self.layer.cornerRadius].CGPath;
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
        CGPoint point = [recognizer locationInView:self];
        UIEditMenuConfiguration *configuration = [UIEditMenuConfiguration configurationWithIdentifier:nil sourcePoint:point];
        [self.editMenuInteraction presentEditMenuWithConfiguration:configuration];
    }
}

#pragma mark - UIEditMenuInteractionDelegate

- (UIMenu *)editMenuInteraction:(UIEditMenuInteraction *)interaction menuForConfiguration:(UIEditMenuConfiguration *)configuration suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0))
{
    if ([self.delegate respondsToSelector:@selector(menuForTimelineScheduleView:)]) {
        return [self.delegate menuForTimelineScheduleView:self];
    }
    return nil;
}

@end
