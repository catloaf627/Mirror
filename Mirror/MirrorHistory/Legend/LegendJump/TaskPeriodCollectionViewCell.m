//
//  TaskPeriodCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/15.
//

#import "TaskPeriodCollectionViewCell.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "MirrorLanguage.h"
#import "MirrorStorage.h"
#import "MirrorSettings.h"
#import "MirrorMacro.h"
#import "MirrorTimeText.h"
#import "UIFont+MirrorFont.h"

static const CGFloat kCellRadius = 12;
#define kHorizontalPadding (20*kWidthRatio)
#define kVerticalPadding (10*kHeightRatio)
#define kDeleteButtonWidth (72*kWidthRatio)


@interface TaskPeriodCollectionViewCell () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSString *taskName;
@property (nonatomic, assign) NSInteger periodIndex;
@property (nonatomic, assign) BottomRightType type;

@property (nonatomic, strong) UIView *foregroundView;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UILabel *bottomRightLabel; // 总时长
@property (nonatomic, strong) UIDatePicker *startPicker;
@property (nonatomic, strong) UILabel *dashLabel;
@property (nonatomic, strong) UIDatePicker *endPicker;
@property (nonatomic, assign) BOOL isDeleteButtonShown;

@end

@implementation TaskPeriodCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configWithTaskname:(NSString *)taskName periodIndex:(NSInteger)index type:(BottomRightType)type
{
    self.taskName = taskName;
    self.periodIndex = index;
    self.type = type;
    self.layer.cornerRadius = kCellRadius;
    self.layer.masksToBounds = YES;
    [self p_setupUI];
    [self hideDeleteButtonAnimated:NO];
    [self updateCellInfo];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self hideDeleteButtonAnimated:NO];
}

- (void)updateCellInfo
{
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:self.taskName];
    NSMutableArray<MirrorRecordModel *> *allRecords = [MirrorStorage retriveMirrorRecords];
    self.backgroundColor = [UIColor mirrorColorNamed:task.color];
    self.contentView.backgroundColor = [UIColor systemRedColor];
    self.foregroundView.backgroundColor = [UIColor mirrorColorNamed:task.color];
    NSString *prefix =  [MirrorSettings appliedShowIndex] ? [[@"No." stringByAppendingString:[@(self.periodIndex) stringValue]] stringByAppendingString:@" "] : @"";
    self.dateLabel.text = [prefix stringByAppendingString:[MirrorTimeText YYYYmmddWeekdayWithStart:allRecords[self.periodIndex].startTime]];
    long start = allRecords[self.periodIndex].startTime;
    long end =  allRecords[self.periodIndex].endTime;
    if (self.type == BottomRightTypeTotal) {
        self.bottomRightLabel.text = [MirrorTimeText XdXhXmXsShortWithstart:start end:end];
    } else {
        self.bottomRightLabel.text = self.taskName;
    }

    self.startPicker.date = [NSDate dateWithTimeIntervalSince1970:start];
    self.startPicker.maximumDate = [self startMaxDate];
    self.startPicker.minimumDate = [self startMinDate];
    self.endPicker.date = [NSDate dateWithTimeIntervalSince1970:end];
    self.endPicker.maximumDate = [self endMaxDate];
    self.endPicker.minimumDate = [self endMinDate];
}

- (void)p_setupUI
{
    if (self.dateLabel.superview) return;

    self.contentView.layer.cornerRadius = kCellRadius;
    self.contentView.layer.masksToBounds = YES;

    [self.contentView addSubview:self.deleteButton];
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.offset(0);
        make.width.mas_equalTo(kDeleteButtonWidth);
    }];

    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleHorizontalPan:)];
    panGestureRecognizer.delegate = self;
    panGestureRecognizer.cancelsTouchesInView = YES;
    [self.foregroundView addGestureRecognizer:panGestureRecognizer];

    [self.contentView addSubview:self.foregroundView];
    [self.foregroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];

    [self.foregroundView addSubview:self.dateLabel];
    [self.dateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(kVerticalPadding);
        make.left.offset(kHorizontalPadding);
        make.width.mas_equalTo(self.bounds.size.width - 3*kHorizontalPadding - 20);
        make.height.mas_equalTo((self.bounds.size.height - 2*kVerticalPadding)/2);
    }];

    [self.foregroundView addSubview:self.startPicker];
    [self.startPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-kVerticalPadding);
        make.left.offset(kHorizontalPadding);
        make.height.mas_equalTo((self.bounds.size.height - 2*kVerticalPadding)/2);
    }];
    [self.foregroundView addSubview:self.dashLabel];
    [self.dashLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-kVerticalPadding);
        make.left.mas_equalTo(self.startPicker.mas_right);
        make.width.height.mas_equalTo((self.bounds.size.height - 2*kVerticalPadding)/2);
    }];
    [self.foregroundView addSubview:self.endPicker];
    [self.endPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-kVerticalPadding);
        make.left.mas_equalTo(self.dashLabel.mas_right);
        make.height.mas_equalTo((self.bounds.size.height - 2*kVerticalPadding)/2);
    }];
    [self.foregroundView addSubview:self.bottomRightLabel];
    [self.bottomRightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(-kVerticalPadding);
        make.right.offset(-kHorizontalPadding);
        make.height.mas_equalTo((self.bounds.size.height - 2*kVerticalPadding)/2);
    }];

}

#pragma mark - Actions

- (void)changeStartTime
{
    long startTime = [self.startPicker.date timeIntervalSince1970];
    [MirrorStorage editPeriodIsStartTime:YES to:startTime periodIndex:self.periodIndex];
    [self updateCellInfo];
}
- (void)changeEndTime
{
    long endTime = [self.endPicker.date timeIntervalSince1970];
    [MirrorStorage editPeriodIsStartTime:NO to:endTime periodIndex:self.periodIndex];
    [self updateCellInfo];
}

- (void)deletePeriod
{
    UIAlertController* deleteButtonAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete_period_?"] message:nil preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [MirrorStorage deletePeriodAtIndex:self.periodIndex];
        [self.delegate updateUIAfterDeleteDataAtIndex:self.periodIndex];
    }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];

    [deleteButtonAlert addAction:cancelAction];
    [deleteButtonAlert addAction:deleteAction];
    [self.delegate presentViewController:deleteButtonAlert animated:YES completion:nil];
}

- (void)showDeleteButtonAnimated:(BOOL)animated
{
    void (^animations)(void) = ^{
        self.foregroundView.transform = CGAffineTransformMakeTranslation(-kDeleteButtonWidth, 0);
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    } else {
        animations();
    }
    self.isDeleteButtonShown = YES;
}

- (void)hideDeleteButtonAnimated:(BOOL)animated
{
    void (^animations)(void) = ^{
        self.foregroundView.transform = CGAffineTransformIdentity;
    };
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    } else {
        animations();
    }
    self.isDeleteButtonShown = NO;
}

- (void)handleHorizontalPan:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGFloat translationX = [panGestureRecognizer translationInView:self.foregroundView].x;
    CGFloat startOffset = self.isDeleteButtonShown ? -kDeleteButtonWidth : 0;

    if (panGestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat offset = MIN(0, MAX(-kDeleteButtonWidth, startOffset + translationX));
        self.foregroundView.transform = CGAffineTransformMakeTranslation(offset, 0);
    } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded || panGestureRecognizer.state == UIGestureRecognizerStateCancelled) {
        CGFloat velocityX = [panGestureRecognizer velocityInView:self.foregroundView].x;
        CGFloat currentOffset = self.foregroundView.transform.tx;
        if (velocityX < -200 || currentOffset < -kDeleteButtonWidth / 2) {
            [self showDeleteButtonAnimated:YES];
        } else {
            [self hideDeleteButtonAnimated:YES];
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (![gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        return YES;
    }

    UIPanGestureRecognizer *panGestureRecognizer = (UIPanGestureRecognizer *)gestureRecognizer;
    CGPoint velocity = [panGestureRecognizer velocityInView:self.foregroundView];
    return fabs(velocity.x) > fabs(velocity.y);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

#pragma mark - Getters

- (UIView *)foregroundView
{
    if (!_foregroundView) {
        _foregroundView = [UIView new];
        _foregroundView.layer.cornerRadius = kCellRadius;
        _foregroundView.layer.masksToBounds = YES;
    }
    return _foregroundView;
}

- (UILabel *)bottomRightLabel
{
    if (!_bottomRightLabel) {
        _bottomRightLabel = [UILabel new];
        _bottomRightLabel.adjustsFontSizeToFitWidth = YES;
        _bottomRightLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _bottomRightLabel.font = [UIFont mirrorHintFont];
    }
    return _bottomRightLabel;
}


- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [UIButton new];
        _deleteButton.backgroundColor = [UIColor systemRedColor];
        _deleteButton.titleLabel.font = [UIFont mirrorLabelFont];
        [_deleteButton setTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] forState:UIControlStateNormal];
        [_deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deletePeriod) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}


- (UIDatePicker *)startPicker
{
    if (!_startPicker) {
        _startPicker = [UIDatePicker new];
        _startPicker.datePickerMode = UIDatePickerModeTime;
        _startPicker.timeZone = [NSTimeZone systemTimeZone];
        _startPicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
        _startPicker.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_startPicker addTarget:self action:@selector(changeStartTime) forControlEvents:UIControlEventEditingDidEnd];
    }
    return _startPicker;
}

- (UILabel *)dashLabel
{
    if (!_dashLabel) {
        _dashLabel = [UILabel new];
        _dashLabel.text = @"-";
        _dashLabel.textAlignment = NSTextAlignmentCenter;
        _dashLabel.adjustsFontSizeToFitWidth = YES;
        _dashLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    }
    return _dashLabel;
}

- (UIDatePicker *)endPicker
{
    if (!_endPicker) {
        _endPicker = [UIDatePicker new];
        _endPicker.datePickerMode = UIDatePickerModeTime;
        _endPicker.timeZone = [NSTimeZone systemTimeZone];
        _endPicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
        _endPicker.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_endPicker addTarget:self action:@selector(changeEndTime) forControlEvents:UIControlEventEditingDidEnd];
    }
    return _endPicker;
}

- (UILabel *)dateLabel
{
    if (!_dateLabel) {
        _dateLabel = [UILabel new];
        _dateLabel.adjustsFontSizeToFitWidth = YES;
        _dateLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _dateLabel.font = [UIFont mirrorLabelFont];
    }
    return _dateLabel;
}


#pragma mark - Privates

- (NSDate *)startMaxDate
{
    MirrorRecordModel *record = [MirrorStorage retriveMirrorRecords][self.periodIndex];
    long maxTime = 0;
    // 对于一个开始时间来说，最大不能大于自己的结束时间-kMinSeconds
    maxTime = record.endTime - kMinSeconds; // 至多比自己的结束时间小一分钟
    return [NSDate dateWithTimeIntervalSince1970:maxTime];
}

- (NSDate *)endMaxDate
{
    long maxTime = 0;
    // 对于一个结束时间来说，最大不能大于下一个task的开始时间（如果有下一个task的话）
    if (self.periodIndex+1 <= [MirrorStorage retriveMirrorRecords].count-1) { // 如果有下一个task的话
        MirrorRecordModel *nextRecord = [MirrorStorage retriveMirrorRecords][self.periodIndex+1];
        maxTime = nextRecord.startTime; // 至多也要等于下一个task的开始时间
    } else {
        maxTime = LONG_MAX;
    }
    return [NSDate dateWithTimeIntervalSince1970:maxTime];
}


- (NSDate *)startMinDate
{
    long minTime = 0;
    // 对于一个开始时间来说，它最小不能小于上一个task的结束时间（如果有上一个task的话
    if (self.periodIndex-1 >= 0) { //如果有上一个task的话
        MirrorRecordModel *formmerRecord = [MirrorStorage retriveMirrorRecords][self.periodIndex-1];
        minTime = formmerRecord.endTime; // 至少等于前一个task的结束时间
    } else {
        minTime = 0;
    }

    return [NSDate dateWithTimeIntervalSince1970:minTime];
}

- (NSDate *)endMinDate
{
    MirrorRecordModel *record = [MirrorStorage retriveMirrorRecords][self.periodIndex];
    long minTime = 0;
    // 对于一个结束时间来说，它最小不能小于自己的开始时间+kMinSeconds
    minTime = record.startTime + kMinSeconds;// 至少比开始的时间多一分钟
    return [NSDate dateWithTimeIntervalSince1970:minTime];
}



@end
