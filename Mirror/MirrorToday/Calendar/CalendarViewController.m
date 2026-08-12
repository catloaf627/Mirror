//
//  CalendarViewController.m
//  Mirror
//

#import "CalendarViewController.h"
#import "OneDayTimelineViewController.h"
#import "MirrorNaviManager.h"
#import "MirrorStorage.h"
#import "MirrorTool.h"
#import "MirrorSettings.h"
#import "MirrorTimeText.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorMacro.h"
#import <Masonry/Masonry.h>

#define kLeftRightSpacing (20*kWidthRatio)
#define kDatePickerHeaderHeight (44*kHeightRatio)

@interface CalendarPickerViewController : UIViewController <UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate>

- (instancetype)initWithSelectedDate:(NSDate *)selectedDate selectionHandler:(void (^)(NSDate *date))selectionHandler;

@end

@interface CalendarPickerViewController ()

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, copy) void (^selectionHandler)(NSDate *date);
@property (nonatomic, strong) UICalendarView *calendarView;
@property (nonatomic, strong) UICalendarSelectionSingleDate *dateSelection;
@property (nonatomic, strong) NSDictionary<NSString *, NSMutableArray<MirrorReadModel *> *> *gridData;

@end

@implementation CalendarPickerViewController

- (instancetype)initWithSelectedDate:(NSDate *)selectedDate selectionHandler:(void (^)(NSDate *date))selectionHandler
{
    self = [super init];
    if (self) {
        _selectedDate = selectedDate ?: [NSDate now];
        _selectionHandler = [selectionHandler copy];
        _gridData = [MirrorStorage getGridData];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.calendarView];
    [self.calendarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
}

- (UICalendarView *)calendarView API_AVAILABLE(ios(16.0))
{
    if (!_calendarView) {
        _calendarView = [UICalendarView new];
        _calendarView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _calendarView.calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
        _calendarView.calendar.timeZone = [NSTimeZone systemTimeZone];
        _calendarView.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _calendarView.delegate = self;
        _calendarView.wantsDateDecorations = YES;
        _calendarView.selectionBehavior = self.dateSelection;
    }
    return _calendarView;
}

- (UICalendarSelectionSingleDate *)dateSelection API_AVAILABLE(ios(16.0))
{
    if (!_dateSelection) {
        _dateSelection = [[UICalendarSelectionSingleDate alloc] initWithDelegate:self];
        NSDateComponents *components = [self.calendarView.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.selectedDate];
        [_dateSelection setSelectedDate:components animated:NO];
    }
    return _dateSelection;
}

#pragma mark - UICalendarViewDelegate

- (UICalendarViewDecoration *)calendarView:(UICalendarView *)calendarView decorationForDateComponents:(NSDateComponents *)dateComponents API_AVAILABLE(ios(16.0))
{
    NSDate *date = dateComponents.date;
    if (!date) return nil;

    UIColor *color = [self gridColorForDate:date];
    if (!color) return nil;
    CGFloat decorationWidth = [self gridDecorationWidthForDate:date];

    return [UICalendarViewDecoration decorationWithCustomViewProvider:^UIView * _Nonnull{
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, decorationWidth, 6)];
        backgroundView.backgroundColor = color;
        backgroundView.layer.cornerRadius = 3;
        backgroundView.clipsToBounds = YES;
        return backgroundView;
    }];
}

#pragma mark - UICalendarSelectionSingleDateDelegate

- (BOOL)dateSelection:(UICalendarSelectionSingleDate *)selection canSelectDate:(NSDateComponents *)dateComponents API_AVAILABLE(ios(16.0))
{
    return dateComponents != nil;
}

- (void)dateSelection:(UICalendarSelectionSingleDate *)selection didSelectDate:(NSDateComponents *)dateComponents API_AVAILABLE(ios(16.0))
{
    NSDate *date = dateComponents.date;
    if (!date) return;
    if (self.selectionHandler) {
        self.selectionHandler(date);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Color

- (UIColor *)gridColorForDate:(NSDate *)date
{
    NSMutableArray<MirrorReadModel *> *data = self.gridData[[self keyFromDate:date]];
    if (data.count == 0) return nil;

    long totalTime = 0;
    NSMutableArray<NSNumber *> *taskTimes = [NSMutableArray array];
    NSMutableArray<UIColor *> *taskColors = [NSMutableArray array];
    for (MirrorReadModel *readModel in data) {
        long taskTime = [MirrorTool getTotalTimeOfPeriods:readModel.records];
        if (taskTime > 0) {
            [taskTimes addObject:@(taskTime)];
            [taskColors addObject:[UIColor mirrorColorNamed:readModel.taskModel.color]];
        }
        totalTime += taskTime;
    }
    if (totalTime == 0) return nil;

    UIColor *mixedColor = [self mixedColorWithTaskColors:taskColors taskTimes:taskTimes totalTime:totalTime];
    return [mixedColor colorWithAlphaComponent:1];
}

- (CGFloat)gridDecorationWidthForDate:(NSDate *)date
{
    NSMutableArray<MirrorReadModel *> *data = self.gridData[[self keyFromDate:date]];
    long totalTime = 0;
    for (MirrorReadModel *readModel in data) {
        totalTime += [MirrorTool getTotalTimeOfPeriods:readModel.records];
    }
    if (totalTime == 0) return 0;

    CGFloat widthRatio = MIN(1.0, 0.2 + floor(totalTime / 3600) * 0.1);
    return 28 * widthRatio;
}

- (UIColor *)mixedColorWithTaskColors:(NSMutableArray<UIColor *> *)taskColors taskTimes:(NSMutableArray<NSNumber *> *)taskTimes totalTime:(long)totalTime
{
    if (taskColors.count == 0 || taskTimes.count == 0 || totalTime == 0) {
        return [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    }

    CGFloat mixedRed = 0;
    CGFloat mixedGreen = 0;
    CGFloat mixedBlue = 0;
    CGFloat mixedAlpha = 0;
    for (int i=0; i<taskColors.count; i++) {
        CGFloat red = 0;
        CGFloat green = 0;
        CGFloat blue = 0;
        CGFloat colorAlpha = 0;
        if (![taskColors[i] getRed:&red green:&green blue:&blue alpha:&colorAlpha]) {
            return taskColors.firstObject;
        }

        CGFloat weight = taskTimes[i].doubleValue / (CGFloat)totalTime;
        mixedRed += red * weight;
        mixedGreen += green * weight;
        mixedBlue += blue * weight;
        mixedAlpha += colorAlpha * weight;
    }

    return [UIColor colorWithRed:mixedRed green:mixedGreen blue:mixedBlue alpha:mixedAlpha];
}

- (NSString *)keyFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.timeZone = [NSTimeZone systemTimeZone];
    return [formatter stringFromDate:date];
}

@end

@interface CalendarViewController ()

@property (nonatomic, strong) NSDate *selectedDate;
@property (nonatomic, strong) UIButton *dateButton;
@property (nonatomic, strong) OneDayTimelineViewController *timelineViewController;

@end

@implementation CalendarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.selectedDate = [NSDate now];
    [self p_setupUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"Calendar" leftButton:nil rightButton:nil];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];

    OneDayTimelineViewController *timelineViewController = [[OneDayTimelineViewController alloc] initWithDate:self.selectedDate
                                                                                                  headerView:self.dateButton
                                                                                                headerHeight:kDatePickerHeaderHeight
                                                                                                headerInsets:UIEdgeInsetsMake(0, kLeftRightSpacing, 8*kHeightRatio, kLeftRightSpacing)
                                                                                         headerConfiguration:nil];
    self.timelineViewController = timelineViewController;
    [self addChildViewController:timelineViewController];
    [self.view addSubview:timelineViewController.view];
    [timelineViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.left.right.bottom.offset(0);
    }];
    [timelineViewController didMoveToParentViewController:self];
}

#pragma mark - Actions

- (void)showCalendarPicker
{
    __weak typeof(self) weakSelf = self;
    CalendarPickerViewController *pickerVC = [[CalendarPickerViewController alloc] initWithSelectedDate:self.selectedDate selectionHandler:^(NSDate *date) {
        weakSelf.selectedDate = date;
        [weakSelf updateDateButtonTitle];
        [weakSelf.timelineViewController updateDate:date];
    }];
    pickerVC.modalPresentationStyle = UIModalPresentationPopover;
    pickerVC.preferredContentSize = CGSizeMake(360, 340);
    UIPopoverPresentationController *popover = pickerVC.popoverPresentationController;
    popover.sourceView = self.dateButton;
    popover.sourceRect = self.dateButton.bounds;
    popover.permittedArrowDirections = UIPopoverArrowDirectionUp;
    [self presentViewController:pickerVC animated:YES completion:nil];
}

#pragma mark - Getters

- (UIButton *)dateButton
{
    if (!_dateButton) {
        _dateButton = [UIButton new];
        _dateButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _dateButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_dateButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeText] forState:UIControlStateNormal];
        _dateButton.titleLabel.font = [UIFont mirrorTitleFont];
        UIImage *iconImage = [[UIImage systemImageNamed:@"calendar"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_dateButton setImage:iconImage forState:UIControlStateNormal];
        _dateButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 8*kWidthRatio);
        _dateButton.titleEdgeInsets = UIEdgeInsetsMake(0, 8*kWidthRatio, 0, 0);
        [_dateButton addTarget:self action:@selector(showCalendarPicker) forControlEvents:UIControlEventTouchUpInside];
        [self updateDateButtonTitle];
    }
    return _dateButton;
}

- (void)updateDateButtonTitle
{
    [_dateButton setTitle:[MirrorTimeText YYYYmmddWeekday:self.selectedDate ?: [NSDate now]] forState:UIControlStateNormal];
}

@end
