//
//  TodayTotalHeader.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/21.
//

#import "TodayTotalHeader.h"
#import "MirrorTaskModel.h"
#import "MirrorDayModel.h"
#import "MirrorStorage.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "UIFont+MirrorFont.h"
#import "PiechartView.h"
#import "MirrorTimeText.h"
#import "MirrorMacro.h"
#import "UIFont+MirrorFont.h"

#define kLeftRightSpacing (20*kWidthRatio)

@interface TodayTotalHeader ()

@property (nonatomic, assign) long count;

@property (nonatomic, strong) UIView *todayViewLeft;
@property (nonatomic, strong) UIView *todayViewRight;
@property (nonatomic, strong) UILabel *todayLabel;
@property (nonatomic, strong) UIButton *datePickerButton;
@property (nonatomic, strong) UIButton *calendarIconButton;
@property (nonatomic, strong) UILabel *todayDateLabel;
@property (nonatomic, strong) PiechartView *pieChart;
@property (nonatomic, strong) UIButton *crownButton;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, assign) float pieChartWidth;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) MirrorDayModel *specialDay;
@property (nonatomic, copy) void (^datePickerHandler)(void);
@property (nonatomic, copy) void (^specialDayTapHandler)(void);

@end

@implementation TodayTotalHeader

- (void)configWithRecords:(NSMutableArray<MirrorRecordModel *> *)todayRecords
{
    [self configWithDate:[NSDate now] records:todayRecords datePickerHandler:nil specialDayTapHandler:nil];
}

- (void)configWithDate:(NSDate *)date records:(NSMutableArray<MirrorRecordModel *> *)records datePickerHandler:(void (^)(void))datePickerHandler
{
    [self configWithDate:date records:records datePickerHandler:datePickerHandler specialDayTapHandler:nil];
}

- (void)configWithDate:(NSDate *)date records:(NSMutableArray<MirrorRecordModel *> *)records datePickerHandler:(void (^)(void))datePickerHandler specialDayTapHandler:(void (^)(void))specialDayTapHandler
{
    long count = 0;
    for (int i=0; i<records.count; i++) {
        MirrorRecordModel *record = records[i];
        count = count + (record.endTime -  record.startTime);
    }
    self.count = count;
    self.date = date ?: [NSDate now];
    self.specialDay = [self specialDayForDate:self.date];
    self.datePickerHandler = datePickerHandler;
    self.specialDayTapHandler = specialDayTapHandler;
    [self p_setupUI];
}

- (void)p_setupUI
{
    if (self.todayViewLeft.superview) {
        [self updateDateViews];
        self.countLabel.text = self.count ? [[MirrorLanguage mirror_stringWithKey:@"total"] stringByAppendingString:[MirrorTimeText XdXhXmXsFull:self.count]] : @"";
        [self updateSpecialDayDecorationViews];
        NSArray *startEndTime = [self startEndTimeForDate:self.date];
        long startTime = [startEndTime[0] longValue];
        long endTime = [startEndTime[1] longValue];
        NSMutableArray<MirrorReadModel *> *todayRecordsSortByTasks = [MirrorStorage getAllRecordsInTaskOrderWithStart:startTime end:endTime shouldHideHidden:NO];
        self.pieChart.showsOnlyPercentageText = YES;
        [self.pieChart updateWithData:todayRecordsSortByTasks width:self.pieChartWidth enableInteractive:YES];
        return;
    }

    float viewWidth = kScreenWidth-2*kLeftRightSpacing;

    // split to 2 subviews: left 3/5, right 2/5
    [self addSubview:self.todayViewLeft];
    [self.todayViewLeft mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(0);
        make.bottom.offset(-30); //make some room for the total label
        make.left.offset(0);
        make.right.offset(-viewWidth/5*2);
    }];
    [self addSubview:self.todayViewRight];
    [self.todayViewRight mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(0);
        make.bottom.offset(-30); //make some room for the total label
        make.right.offset(0);
        make.left.offset(viewWidth/5*3);
    }];
    
    // LEFT
    [self.todayViewLeft addSubview:self.todayLabel];
    [self.todayLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-10);
        make.centerY.offset(-10); // slightly higher than the middle
        make.width.mas_lessThanOrEqualTo(viewWidth/5*3-30); // left padding 20, right padding 10
    }];
    [self.todayViewLeft addSubview:self.datePickerButton];
    [self.datePickerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-10);
        make.centerY.offset(-10);
        make.width.mas_lessThanOrEqualTo(viewWidth/5*3-30);
    }];
    [self.todayViewLeft addSubview:self.todayDateLabel];
    [self.todayDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-10);
        make.top.mas_equalTo(self.todayLabel.mas_bottom);
        make.width.mas_lessThanOrEqualTo(viewWidth/5*3-30); // left padding 20, right padding 10
    }];
    [self.todayViewLeft addSubview:self.calendarIconButton];
    [self.calendarIconButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-10);
        make.top.mas_equalTo(self.datePickerButton.mas_bottom);
        make.width.height.mas_equalTo(26);
    }];
    [self.todayViewLeft addSubview:self.crownButton];
    [self.crownButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.todayLabel.mas_left);
        make.centerY.mas_equalTo(self.todayLabel.mas_top);
        make.width.height.mas_equalTo(25);
    }];
    
    // RIGHT
    [self.todayViewRight addSubview:self.pieChart];
    [self.pieChart mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.offset(0);
        make.left.offset(10);
        make.width.height.mas_equalTo(self.pieChartWidth);
    }];
    
    [self addSubview:self.countLabel];
    self.countLabel.text = self.count ? [[MirrorLanguage mirror_stringWithKey:@"total"] stringByAppendingString:[MirrorTimeText XdXhXmXsFull:self.count]] : @"";
    [self.countLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(20);
        make.right.offset(-20);
        make.top.mas_equalTo(self.todayViewLeft.mas_bottom);
        make.height.mas_equalTo(20);
    }];
    
    [self updateDateViews];
    [self updateSpecialDayDecorationViews];
    NSArray *startEndTime = [self startEndTimeForDate:self.date];
    long startTime = [startEndTime[0] longValue];
    long endTime = [startEndTime[1] longValue];
    NSMutableArray<MirrorReadModel *> *todayRecordsSortByTasks = [MirrorStorage getAllRecordsInTaskOrderWithStart:startTime end:endTime shouldHideHidden:NO];
    self.pieChart.showsOnlyPercentageText = YES;
    [self.pieChart updateWithData:todayRecordsSortByTasks width:self.pieChartWidth enableInteractive:YES];

}

#pragma mark - Actions

- (void)crownAnimation
{
    if (self.specialDayTapHandler) {
        self.specialDayTapHandler();
    }
}

- (void)updateSpecialDayDecorationViews
{
    MirrorDayModel *specialDay = self.specialDay;
    UIImage *calendarImage = [[UIImage systemImageNamed:@"calendar"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (specialDay.icon.length == 0) {
        self.crownButton.hidden = YES;
        [self.crownButton setImage:nil forState:UIControlStateNormal];
        [self.calendarIconButton setImage:calendarImage forState:UIControlStateNormal];
        self.calendarIconButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        return;
    }
    
    UIImage *iconImage = [self specialDayIconImage];
    UIColor *iconColor = [self systemColorNamed:specialDay.color];
    if ([self usesRelativeDateLabel]) {
        self.crownButton.hidden = NO;
        self.crownButton.transform = CGAffineTransformIdentity;
        [self.crownButton setImage:iconImage forState:UIControlStateNormal];
        self.crownButton.tintColor = iconColor;
        [self.calendarIconButton setImage:calendarImage forState:UIControlStateNormal];
        self.calendarIconButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    } else {
        self.crownButton.hidden = YES;
        [self.crownButton setImage:nil forState:UIControlStateNormal];
        [self.calendarIconButton setImage:iconImage forState:UIControlStateNormal];
        self.calendarIconButton.tintColor = iconColor;
    }
}

- (MirrorDayModel *)specialDayForDate:(NSDate *)date
{
    NSString *dateKey = [self dateKeyFromDate:date ?: [NSDate now]];
    for (MirrorDayModel *day in [MirrorStorage retriveMirrorDays]) {
        if ([day.dateStr isEqualToString:dateKey]) {
            return day;
        }
    }
    return nil;
}

- (NSString *)dateKeyFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:date];
}

- (UIColor *)systemColorNamed:(NSString *)colorName
{
    if ([colorName isEqualToString:@"systemRed"]) return [UIColor systemRedColor];
    if ([colorName isEqualToString:@"systemOrange"]) return [UIColor systemOrangeColor];
    if ([colorName isEqualToString:@"systemYellow"]) return [UIColor systemYellowColor];
    if ([colorName isEqualToString:@"systemGreen"]) return [UIColor systemGreenColor];
    if ([colorName isEqualToString:@"systemMint"]) {
        if (@available(iOS 15.0, *)) {
            return [UIColor systemMintColor];
        }
        return [UIColor systemTealColor];
    }
    if ([colorName isEqualToString:@"systemPurple"]) return [UIColor systemPurpleColor];
    if ([colorName isEqualToString:@"systemGray"]) return [UIColor systemGrayColor];
    return [UIColor systemBlueColor];
}

- (void)datePickerButtonTapped
{
    if (self.datePickerHandler) {
        self.datePickerHandler();
    }
}

- (void)calendarIconButtonTapped
{
    if (self.specialDay.icon.length > 0 && ![self usesRelativeDateLabel]) {
        if (self.specialDayTapHandler) {
            self.specialDayTapHandler();
        }
        return;
    }
    [self datePickerButtonTapped];
}

#pragma mark - Getters

- (float) pieChartWidth {
    float rightViewHeight = kTodayHeaderHeight;
    float rightViewWidth = (kScreenWidth-2*kLeftRightSpacing)/5*2;
    if (rightViewWidth<rightViewHeight) {
        return rightViewWidth/4*3;
    } else {
        return rightViewHeight/4*3;
    }
}
- (UIView *)todayViewLeft
{
    if (!_todayViewLeft) {
        _todayViewLeft = [UIView new];
    }
    return _todayViewLeft;
}

- (UIView *)todayViewRight
{
    if (!_todayViewRight) {
        _todayViewRight = [UIView new];
    }
    return _todayViewRight;
}

- (UILabel *)todayLabel
{
    if (!_todayLabel) {
        _todayLabel = [UILabel new];
        _todayLabel.text = [MirrorLanguage mirror_stringWithKey:@"today"];
        _todayLabel.font = [UIFont mirrorTodayFont];
        _todayLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _todayLabel.adjustsFontSizeToFitWidth = YES;
        _todayLabel.textAlignment = NSTextAlignmentRight;
        _todayLabel.userInteractionEnabled = YES;
        [_todayLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(datePickerButtonTapped)]];
    }
    return _todayLabel;
}

- (UIButton *)datePickerButton
{
    if (!_datePickerButton) {
        _datePickerButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _datePickerButton.titleLabel.font = [UIFont mirrorTodayFont];
        _datePickerButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _datePickerButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _datePickerButton.contentEdgeInsets = UIEdgeInsetsZero;
        [_datePickerButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeText] forState:UIControlStateNormal];
        [_datePickerButton addTarget:self action:@selector(datePickerButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _datePickerButton;
}

- (UIButton *)calendarIconButton
{
    if (!_calendarIconButton) {
        _calendarIconButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_calendarIconButton setImage:[UIImage systemImageNamed:@"calendar"] forState:UIControlStateNormal];
        _calendarIconButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_calendarIconButton addTarget:self action:@selector(calendarIconButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _calendarIconButton;
}

- (UILabel *)todayDateLabel
{
    if (!_todayDateLabel) {
        _todayDateLabel = [UILabel new];
        _todayDateLabel.text = [MirrorTimeText YYYYmmddWeekday:self.date ?: [NSDate now]];
        _todayDateLabel.font = [UIFont mirrorSubtitleFont];
        _todayDateLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse]; // 和nickname的文字颜色保持一致
        _todayDateLabel.adjustsFontSizeToFitWidth = YES;
        _todayDateLabel.textAlignment = NSTextAlignmentRight;
        _todayDateLabel.userInteractionEnabled = YES;
        [_todayDateLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(datePickerButtonTapped)]];

    }
    return _todayDateLabel;
}

- (PiechartView *)pieChart
{
    if (!_pieChart) {
        NSArray *startEndTime = [self startEndTimeForDate:self.date ?: [NSDate now]];
        long startTime = [startEndTime[0] longValue];
        long endTime = [startEndTime[1] longValue];
        NSMutableArray<MirrorReadModel *> *todayRecordsSortByTasks = [MirrorStorage getAllRecordsInTaskOrderWithStart:startTime end:endTime shouldHideHidden:NO];
        _pieChart = [[PiechartView alloc] initWithData:todayRecordsSortByTasks width:self.pieChartWidth enableInteractive:YES];
        _pieChart.showsOnlyPercentageText = YES;
    }
    return _pieChart;
}


- (UIButton *)crownButton
{
    if (!_crownButton) {
        _crownButton = [UIButton new];
        _crownButton.transform = CGAffineTransformIdentity;
        _crownButton.hidden = YES;
        [_crownButton addTarget:self action:@selector(crownAnimation) forControlEvents:UIControlEventTouchUpInside];
    }
    return _crownButton;
}



- (UILabel *)countLabel
{
    if (!_countLabel) {
        _countLabel = [UILabel new];
        _countLabel.adjustsFontSizeToFitWidth = YES;
        _countLabel.textAlignment = NSTextAlignmentLeft;
        _countLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _countLabel.font = [UIFont mirrorHintFont];
    }
    return _countLabel;
}

#pragma mark - Privates

- (void)updateDateViews
{
    NSDate *date = self.date ?: [NSDate now];
    NSInteger dayOffset = [self dayOffsetFromTodayForDate:date];
    BOOL usesRelativeDateLabel = dayOffset >= -1 && dayOffset <= 1;

    self.todayLabel.hidden = !usesRelativeDateLabel;
    self.datePickerButton.hidden = usesRelativeDateLabel;
    self.todayDateLabel.hidden = !usesRelativeDateLabel;
    self.calendarIconButton.hidden = usesRelativeDateLabel;

    self.todayLabel.text = [self relativeDateTitleForDayOffset:dayOffset];
    self.todayLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    self.todayDateLabel.text = [MirrorTimeText YYYYmmddWeekday:date];
    self.todayDateLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse];

    [self.datePickerButton setTitle:[MirrorTimeText YYYYmmdd:date] forState:UIControlStateNormal];
    [self.datePickerButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeText] forState:UIControlStateNormal];
    self.datePickerButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    self.datePickerButton.backgroundColor = UIColor.clearColor;
    self.datePickerButton.layer.borderWidth = 0;
    [self.crownButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (usesRelativeDateLabel) {
            make.centerX.mas_equalTo(self.todayLabel.mas_left);
            make.centerY.mas_equalTo(self.todayLabel.mas_top);
        } else {
            make.centerX.mas_equalTo(self.datePickerButton.mas_left);
            make.centerY.mas_equalTo(self.datePickerButton.mas_top);
        }
        make.width.height.mas_equalTo(25);
    }];
}

- (BOOL)usesRelativeDateLabel
{
    NSDate *date = self.date ?: [NSDate now];
    NSInteger dayOffset = [self dayOffsetFromTodayForDate:date];
    return dayOffset >= -1 && dayOffset <= 1;
}

- (UIImage *)specialDayIconImage
{
    UIImage *iconImage = [[UIImage systemImageNamed:self.specialDay.icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (!iconImage) {
        iconImage = [[UIImage systemImageNamed:@"star.fill"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return iconImage;
}

- (NSInteger)dayOffsetFromTodayForDate:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDate *startOfDate = [gregorian startOfDayForDate:date ?: [NSDate now]];
    NSDate *startOfToday = [gregorian startOfDayForDate:[NSDate now]];
    return [gregorian components:NSCalendarUnitDay fromDate:startOfToday toDate:startOfDate options:0].day;
}

- (NSString *)relativeDateTitleForDayOffset:(NSInteger)dayOffset
{
    if (dayOffset == -1) return [MirrorLanguage mirror_stringWithKey:@"yesterday"];
    if (dayOffset == 1) return [MirrorLanguage mirror_stringWithKey:@"tomorrow"];
    return [MirrorLanguage mirror_stringWithKey:@"today"];
}

- (NSArray *)startEndTimeForDate:(NSDate *)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    gregorian.timeZone = [NSTimeZone systemTimeZone];
    NSDate *startOfDay = [gregorian startOfDayForDate:date ?: [NSDate now]];
    NSDate *startOfNextDay = [gregorian dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfDay options:0];
    long startTime = round([startOfDay timeIntervalSince1970]);
    long endTime = round([startOfNextDay timeIntervalSince1970]);
    return @[@(startTime), @(endTime)];
}


@end
