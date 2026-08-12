//
//  CalendarViewController.m
//  Mirror
//

#import "CalendarViewController.h"
#import "OneDayTimelineViewController.h"
#import "MirrorNaviManager.h"
#import "UIColor+MirrorColor.h"
#import "MirrorMacro.h"
#import <Masonry/Masonry.h>

#define kLeftRightSpacing (20*kWidthRatio)
#define kDatePickerHeaderHeight (44*kHeightRatio)

@interface CalendarViewController ()

@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) OneDayTimelineViewController *timelineViewController;

@end

@implementation CalendarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
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

    OneDayTimelineViewController *timelineViewController = [[OneDayTimelineViewController alloc] initWithDate:[NSDate now]
                                                                                                  headerView:self.datePicker
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

- (void)datePickerValueChanged
{
    [self.timelineViewController updateDate:self.datePicker.date];
}

#pragma mark - Getters

- (UIDatePicker *)datePicker
{
    if (!_datePicker) {
        _datePicker = [UIDatePicker new];
        _datePicker.datePickerMode = UIDatePickerModeDate;
        _datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
        _datePicker.date = [NSDate now];
        _datePicker.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _datePicker.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        [_datePicker addTarget:self action:@selector(datePickerValueChanged) forControlEvents:UIControlEventValueChanged];
    }
    return _datePicker;
}

@end
