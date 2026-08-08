//
//  TodayTotalHeader.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/21.
//

#import "TodayTotalHeader.h"
#import "MirrorTaskModel.h"
#import "MirrorStorage.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "PiechartView.h"
#import "MirrorTimeText.h"
#import "MirrorMacro.h"

static CGFloat const kLeftRightSpacing = 20;

@interface TodayTotalHeader ()

@property (nonatomic, assign) long count;

@property (nonatomic, strong) UIView *todayViewLeft;
@property (nonatomic, strong) UIView *todayViewRight;
@property (nonatomic, strong) UILabel *todayLabel;
@property (nonatomic, strong) UILabel *todayDateLabel;
@property (nonatomic, strong) PiechartView *pieChart;
@property (nonatomic, strong) UIButton *crownButton;
@property (nonatomic, strong) UILabel *countLabel;
@property (nonatomic, assign) float pieChartWidth;

@end

@implementation TodayTotalHeader

- (void)configWithRecords:(NSMutableArray<MirrorRecordModel *> *)todayRecords
{
    long count = 0;
    for (int i=0; i<todayRecords.count; i++) {
        MirrorRecordModel *record = todayRecords[i];
        count = count + (record.endTime -  record.startTime);
    }
    self.count = count;
    [self p_setupUI];
}

- (void)p_setupUI
{
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
    [self.todayViewLeft addSubview:self.todayDateLabel];
    [self.todayDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-10);
        make.top.mas_equalTo(self.todayLabel.mas_bottom);
        make.width.mas_lessThanOrEqualTo(viewWidth/5*3-30); // left padding 20, right padding 10
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
    
    if (self.count >= 8*3600) { // 大于8小时，展示王冠
        self.crownButton.hidden = NO;
    } else { // 不到8小时，隐藏王冠
        self.crownButton.hidden = YES;
    }
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
    components.timeZone = [NSTimeZone systemTimeZone];
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    long startTime = [[gregorian dateFromComponents:components] timeIntervalSince1970];
    long endTime = startTime + 86400;
    NSMutableArray<MirrorDataModel *> *todayRecordsSortByTasks = [MirrorStorage getAllRecordsInTaskOrderWithStart:startTime end:endTime shouldHideHidden:NO];
    [self.pieChart updateWithData:todayRecordsSortByTasks width:self.pieChartWidth enableInteractive:NO];

}

#pragma mark - Actions

- (void)crownAnimation
{
    __weak typeof(self) weakSelf = self;
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];
    [UIView animateKeyframesWithDuration:0.1 delay:0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
        weakSelf.crownButton.transform = CGAffineTransformMakeRotation(-M_PI/4-0.2); //左
    } completion:^(BOOL finished) {
        [UIView animateKeyframesWithDuration:0.1 delay:0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
            weakSelf.crownButton.transform = CGAffineTransformMakeRotation(-M_PI/4+0.2); //右
        } completion:^(BOOL finished) {
            [UIView animateKeyframesWithDuration:0.1 delay:0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
                weakSelf.crownButton.transform = CGAffineTransformMakeRotation(-M_PI/4-0.2); //左
            } completion:^(BOOL finished) {
                [UIView animateKeyframesWithDuration:0.1 delay:0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
                    weakSelf.crownButton.transform = CGAffineTransformMakeRotation(-M_PI/4+0.2); //右
                } completion:^(BOOL finished) {
                    weakSelf.crownButton.transform = CGAffineTransformMakeRotation(-M_PI/4); //恢复
                }];
            }];
        }];
    }];
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
        _todayLabel.text =[MirrorLanguage mirror_stringWithKey:@"today"];
        _todayLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:37*kFontScale];
        _todayLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _todayLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _todayLabel;
}

- (UILabel *)todayDateLabel
{
    if (!_todayDateLabel) {
        _todayDateLabel = [UILabel new];
        _todayDateLabel.text = [MirrorTimeText YYYYmmddWeekday:[NSDate now]];
        _todayDateLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:17*kFontScale];
        _todayDateLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse]; // 和nickname的文字颜色保持一致
        _todayDateLabel.adjustsFontSizeToFitWidth = YES;

    }
    return _todayDateLabel;
}

- (PiechartView *)pieChart
{
    if (!_pieChart) {
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
        components.timeZone = [NSTimeZone systemTimeZone];
        components.hour = 0;
        components.minute = 0;
        components.second = 0;
        long startTime = [[gregorian dateFromComponents:components] timeIntervalSince1970];
        long endTime = startTime + 86400;
        NSMutableArray<MirrorDataModel *> *todayRecordsSortByTasks = [MirrorStorage getAllRecordsInTaskOrderWithStart:startTime end:endTime shouldHideHidden:NO];
        _pieChart = [[PiechartView alloc] initWithData:todayRecordsSortByTasks width:self.pieChartWidth enableInteractive:NO];
    }
    return _pieChart;
}


- (UIButton *)crownButton
{
    if (!_crownButton) {
        _crownButton = [UIButton new];
        UIImage *iconImage = [[UIImage systemImageNamed:@"crown.fill"]  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [_crownButton setImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _crownButton.transform = CGAffineTransformMakeRotation(-M_PI/4);
        _crownButton.tintColor = [UIColor systemYellowColor];
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
        _countLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:17];
    }
    return _countLabel;
}

#pragma mark - Privates

- (NSArray *)todayStartEndTime
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitWeekday | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond) fromDate:[NSDate now]];
    components.timeZone = [NSTimeZone systemTimeZone];
    components.hour = 0;
    components.minute = 0;
    components.second = 0;
    long startTime = [[gregorian dateFromComponents:components] timeIntervalSince1970];
    long endTime = startTime + 86400;
    return @[@(startTime), @(endTime)];
}


@end
