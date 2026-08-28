//
//  TimelineBackgroundView.m
//  Mirror
//

#import "TimelineBackgroundView.h"
#import "TimelineRecordView.h"
#import "MirrorStorage.h"
#import "MirrorLanguage.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"

#define kTimelinePickerHorizontalInset (20*kWidthRatio)

@interface TimelineBackgroundView () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) long pendingStartTimestamp;
@property (nonatomic, strong) UIView *taskPickerOverlayView;

@end

@implementation TimelineBackgroundView

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
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTimeline:)];
    tapRecognizer.delegate = self;
    [self addGestureRecognizer:tapRecognizer];
}

- (void)tapTimeline:(UITapGestureRecognizer *)tapRecognizer
{
    CGPoint point = [tapRecognizer locationInView:self];
    if ([self pointHitsRecordView:point]) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(timelineViewShouldBeginAddingRecord:)] && ![self.delegate timelineViewShouldBeginAddingRecord:self]) {
        return;
    }

    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
    self.pendingStartTimestamp = [self.delegate timelineView:self timestampForTimelineY:point.y];
    [self showTaskPickerAtPoint:point];
}

- (void)showTaskPickerAtPoint:(CGPoint)point
{
    NSMutableArray<MirrorTaskModel *> *tasks = [MirrorStorage tasksWithAddNew];
    NSMutableArray<MirrorTaskModel *> *availableTasks = [NSMutableArray new];
    for (MirrorTaskModel *task in tasks) {
        if (!task.isAddTaskModel) {
            [availableTasks addObject:task];
        }
    }

    if (availableTasks.count == 0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"no_task"] message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
        [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }

    [self showCompactTaskPickerWithTasks:availableTasks atPoint:point];
}

- (void)showCompactTaskPickerWithTasks:(NSArray<MirrorTaskModel *> *)tasks atPoint:(CGPoint)point
{
    [self dismissTaskPicker];

    UIView *presentationView = self.presentingViewController.view ?: self;
    CGRect bounds = presentationView.bounds;
    CGFloat pickerWidth = 160*kWidthRatio;
    CGFloat titleHeight = 34;
    CGFloat rowHeight = 40;
    CGFloat pickerHeight = titleHeight + rowHeight*tasks.count + 8;
    CGPoint viewPoint = [self convertPoint:point toView:presentationView];
    CGFloat pickerX = MIN(MAX(viewPoint.x - pickerWidth/2, kTimelinePickerHorizontalInset), CGRectGetWidth(bounds) - pickerWidth - kTimelinePickerHorizontalInset);
    CGFloat pickerY = viewPoint.y + 8;
    if (pickerY + pickerHeight > CGRectGetHeight(bounds) - self.bottomInset) {
        pickerY = viewPoint.y - pickerHeight - 8;
    }
    pickerY = MAX(kTimelinePickerHorizontalInset, pickerY);

    UIView *overlayView = [[UIView alloc] initWithFrame:bounds];
    overlayView.backgroundColor = UIColor.clearColor;
    overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTaskPicker)];
    tapRecognizer.delegate = self;
    [overlayView addGestureRecognizer:tapRecognizer];

    UIView *pickerView = [[UIView alloc] initWithFrame:CGRectMake(pickerX, pickerY, pickerWidth, pickerHeight)];
    pickerView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    pickerView.layer.cornerRadius = 12;
    pickerView.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
    pickerView.layer.shadowOpacity = 0.18;
    pickerView.layer.shadowRadius = 8;
    pickerView.layer.shadowOffset = CGSizeMake(0, 3);
    [overlayView addSubview:pickerView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(14, 8, pickerWidth - 28, titleHeight - 8)];
    titleLabel.text = [self addRecordTitle];
    titleLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    titleLabel.font = [UIFont mirrorHintFont];
    titleLabel.adjustsFontSizeToFitWidth = YES;
    [pickerView addSubview:titleLabel];

    for (NSInteger index = 0; index < tasks.count; index++) {
        MirrorTaskModel *task = tasks[index];
        CGFloat rowY = titleHeight + rowHeight*index;
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, rowY, pickerWidth, rowHeight)];
        button.accessibilityIdentifier = task.taskName;
        [button addTarget:self action:@selector(taskPickerDidSelectTask:) forControlEvents:UIControlEventTouchUpInside];
        [pickerView addSubview:button];

        UIView *colorDot = [[UIView alloc] initWithFrame:CGRectMake(14, rowY + 12, 16, 16)];
        colorDot.backgroundColor = [UIColor mirrorColorNamed:task.color];
        colorDot.layer.cornerRadius = 8;
        [pickerView addSubview:colorDot];

        UILabel *taskLabel = [[UILabel alloc] initWithFrame:CGRectMake(42, rowY, pickerWidth - 56, rowHeight)];
        taskLabel.text = task.taskName;
        taskLabel.textColor = [UIColor mirrorColorPulsed:task.color];
        taskLabel.font = [UIFont mirrorTitleFont_Card];
        taskLabel.adjustsFontSizeToFitWidth = YES;
        [pickerView addSubview:taskLabel];
    }

    self.taskPickerOverlayView = overlayView;
    [presentationView addSubview:overlayView];
}

- (void)taskPickerDidSelectTask:(UIButton *)sender
{
    NSString *taskName = sender.accessibilityIdentifier;
    [self dismissTaskPicker];
    if (taskName.length == 0) {
        return;
    }
    [self addRecordWithTaskName:taskName];
}

- (void)dismissTaskPicker
{
    [self.taskPickerOverlayView removeFromSuperview];
    self.taskPickerOverlayView = nil;
}

- (void)addRecordWithTaskName:(NSString *)taskName
{
    [self.delegate timelineView:self didSelectTaskName:taskName startTimestamp:self.pendingStartTimestamp];
}

- (BOOL)pointHitsRecordView:(CGPoint)point
{
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:TimelineRecordView.class] && [(TimelineRecordView *)subview containsTimelinePoint:point]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)shortTimeFromTimestamp:(long)timestamp
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"H:mm";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:timestamp]];
}

- (NSString *)addRecordTitle
{
    return [NSString stringWithFormat:@"%@ %@", [MirrorLanguage mirror_stringWithKey:@"starts_at"], [self shortTimeFromTimestamp:self.pendingStartTimestamp]];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer.view == self.taskPickerOverlayView) {
        return touch.view == self.taskPickerOverlayView;
    }
    return YES;
}

@end
