//
//  TodayPeriodCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/21.
//

#import "TodayPeriodCollectionViewCell.h"
#import "MirrorSettings.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "MirrorLanguage.h"
#import "MirrorStorage.h"
#import "MirrorMacro.h"
#import "MirrorTimeText.h"

static const CGFloat kHorizontalPadding = 20;
static const CGFloat kVerticalPadding = 10;
static const CGFloat kDeleteButtonWidth = 72;
static const CGFloat kCellRadius = 12;

@interface TodayPeriodCollectionViewCell ()

@property (nonatomic, strong) NSString *taskName;
@property (nonatomic, assign) NSInteger periodIndex;

@property (nonatomic, strong) UIView *foregroundView;
@property (nonatomic, strong) UILabel *taskNameLabel;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UILabel *totalLabel; // 总时长
@property (nonatomic, strong) UIDatePicker *startPicker;
@property (nonatomic, strong) UILabel *dashLabel;
@property (nonatomic, strong) UIDatePicker *endPicker;

@end

@implementation TodayPeriodCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configWithTaskname:(NSString *)taskName periodIndex:(NSInteger)index
{
    self.taskName = taskName;
    self.periodIndex = index;
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
    self.taskNameLabel.text = self.taskName;
    long start = allRecords[self.periodIndex].startTime;
    long end = allRecords[self.periodIndex].endTime;
    NSString *prefix =  [MirrorSettings appliedShowIndex] ? [[@"No." stringByAppendingString:[@(self.periodIndex) stringValue]] stringByAppendingString:@" "] : @"";
    self.totalLabel.text = [prefix stringByAppendingString:[[MirrorLanguage mirror_stringWithKey:@"lasted"] stringByAppendingString:[MirrorTimeText XdXhXmXsShortWithstart:start end:end]]];
    self.startPicker.date = [NSDate dateWithTimeIntervalSince1970:start];
    self.startPicker.maximumDate = [self startMaxDate];
    self.startPicker.minimumDate = [self startMinDate];
    self.endPicker.date = [NSDate dateWithTimeIntervalSince1970:end];
    self.endPicker.maximumDate = [self endMaxDate];
    self.endPicker.minimumDate = [self endMinDate];
}

- (void)p_setupUI
{
    if (self.totalLabel.superview) return;

    self.contentView.layer.cornerRadius = kCellRadius;
    self.contentView.layer.masksToBounds = YES;

    [self.contentView addSubview:self.deleteButton];
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.bottom.right.offset(0);
        make.width.mas_equalTo(kDeleteButtonWidth);
    }];

    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showDeleteButton)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.foregroundView addGestureRecognizer:leftSwipe];

    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideDeleteButton)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.foregroundView addGestureRecognizer:rightSwipe];

    [self.contentView addSubview:self.foregroundView];
    [self.foregroundView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];

    [self.foregroundView addSubview:self.totalLabel];
    [self.totalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
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
    [self.foregroundView addSubview:self.taskNameLabel];
    [self.taskNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
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
    }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];

    [deleteButtonAlert addAction:cancelAction];
    [deleteButtonAlert addAction:deleteAction];
    [self.delegate presentViewController:deleteButtonAlert animated:YES completion:nil];
}

- (void)showDeleteButton
{
    [self showDeleteButtonAnimated:YES];
}

- (void)hideDeleteButton
{
    [self hideDeleteButtonAnimated:YES];
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

- (UILabel *)totalLabel
{
    if (!_totalLabel) {
        _totalLabel = [UILabel new];
        _totalLabel.adjustsFontSizeToFitWidth = YES;
        _totalLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _totalLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:17];
    }
    return _totalLabel;
}


- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [UIButton new];
        _deleteButton.backgroundColor = [UIColor systemRedColor];
        _deleteButton.titleLabel.font = [UIFont fontWithName:@"TrebuchetMS-Bold" size:14];
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

- (UILabel *)taskNameLabel
{
    if (!_taskNameLabel) {
        _taskNameLabel = [UILabel new];
        _taskNameLabel.adjustsFontSizeToFitWidth = YES;
        _taskNameLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _taskNameLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:12];
    }
    return _taskNameLabel;
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
