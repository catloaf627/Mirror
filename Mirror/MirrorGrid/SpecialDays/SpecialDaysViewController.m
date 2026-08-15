//
//  SpecialDaysViewController.m
//  Mirror
//

#import "SpecialDaysViewController.h"
#import <Masonry/Masonry.h>
#import "MirrorDayModel.h"
#import "MirrorMacro.h"
#import "MirrorNaviManager.h"
#import "MirrorStorage.h"
#import "MirrorTool.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "MirrorLanguage.h"

static CGFloat const kSpecialDaysPadding = 20;
static CGFloat const kSpecialDaysRowHeight = 58;
static CGFloat const kSpecialDaysTimelineIconSize = 26;
static CGFloat const kSpecialDaysDialogWidth = 280;
static CGFloat const kSpecialDaysDialogPadding = 16;
static CGFloat const kSpecialDaysDialogCornerRadius = 12;
static CGFloat const kSpecialDaysBackdropAlpha = 0.45;

#define kSpecialDaysTimelineX (kScreenWidth * 0.33)

@interface SpecialDayDialogView : UIView

@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UITextField *infoTextField;
@property (nonatomic, strong) UISegmentedControl *iconPicker;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *addButton;

@end

@implementation SpecialDayDialogView

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        self.layer.cornerRadius = kSpecialDaysDialogCornerRadius;
        self.layer.masksToBounds = YES;
        [self setupUI];
    }
    return self;
}

- (void)setupUI
{
    [self addSubview:self.datePicker];
    [self.datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.mas_equalTo(self).inset(kSpecialDaysDialogPadding);
        make.height.mas_equalTo(120);
    }];

    [self addSubview:self.infoTextField];
    [self.infoTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self).inset(kSpecialDaysDialogPadding);
        make.top.mas_equalTo(self.datePicker.mas_bottom).offset(12);
        make.height.mas_equalTo(36);
    }];

    [self addSubview:self.iconPicker];
    [self.iconPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self).inset(kSpecialDaysDialogPadding);
        make.top.mas_equalTo(self.infoTextField.mas_bottom).offset(12);
        make.height.mas_equalTo(32);
    }];

    [self addSubview:self.cancelButton];
    [self.cancelButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self).offset(kSpecialDaysDialogPadding);
        make.top.mas_equalTo(self.iconPicker.mas_bottom).offset(14);
        make.height.mas_equalTo(36);
        make.bottom.mas_equalTo(self).offset(-kSpecialDaysDialogPadding);
    }];

    [self addSubview:self.addButton];
    [self.addButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.cancelButton.mas_right).offset(12);
        make.right.mas_equalTo(self).offset(-kSpecialDaysDialogPadding);
        make.top.bottom.width.mas_equalTo(self.cancelButton);
    }];
}

- (UIDatePicker *)datePicker
{
    if (!_datePicker) {
        _datePicker = [UIDatePicker new];
        _datePicker.datePickerMode = UIDatePickerModeDate;
        if (@available(iOS 13.4, *)) {
            _datePicker.preferredDatePickerStyle = UIDatePickerStyleWheels;
        }
    }
    return _datePicker;
}

- (UITextField *)infoTextField
{
    if (!_infoTextField) {
        _infoTextField = [UITextField new];
        _infoTextField.placeholder = @"Info";
        _infoTextField.font = [UIFont mirrorHintFont_Card];
        _infoTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _infoTextField.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
        _infoTextField.layer.cornerRadius = 8;
        _infoTextField.layer.masksToBounds = YES;
        _infoTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
        _infoTextField.leftViewMode = UITextFieldViewModeAlways;
    }
    return _infoTextField;
}

- (UISegmentedControl *)iconPicker
{
    if (!_iconPicker) {
        _iconPicker = [[UISegmentedControl alloc] initWithItems:@[
            [UIImage systemImageNamed:@"star"],
            [UIImage systemImageNamed:@"heart"],
            [UIImage systemImageNamed:@"pin"],
            [UIImage systemImageNamed:@"gift"]
        ]];
        _iconPicker.selectedSegmentIndex = 0;
    }
    return _iconPicker;
}

- (UIButton *)cancelButton
{
    if (!_cancelButton) {
        _cancelButton = [UIButton new];
        [_cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
        [_cancelButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeText] forState:UIControlStateNormal];
        _cancelButton.titleLabel.font = [UIFont mirrorButtonFont];
    }
    return _cancelButton;
}

- (UIButton *)addButton
{
    if (!_addButton) {
        _addButton = [UIButton new];
        [_addButton setTitle:@"Add" forState:UIControlStateNormal];
        [_addButton setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
        _addButton.titleLabel.font = [UIFont mirrorButtonFont];
    }
    return _addButton;
}

@end

@interface SpecialDaysViewController () <UITextFieldDelegate, UIContextMenuInteractionDelegate>

@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) UIView *dialogBackdropView;
@property (nonatomic, strong) SpecialDayDialogView *dialogView;
@property (nonatomic, strong) MASConstraint *dialogCenterYConstraint;
@property (nonatomic, strong) NSMutableArray<MirrorDayModel *> *days;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, copy) NSString *focusDateStr;
@property (nonatomic, assign) BOOL didFocusInitialDate;

@end

@implementation SpecialDaysViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVisibleUI) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVisibleUI) name:MirrorSwitchLanguageNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVisibleUI) name:MirrorSignificantTimeChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorDayCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorDayDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (instancetype)initWithFocusDateStr:(NSString *)focusDateStr
{
    self = [self init];
    if (self) {
        _focusDateStr = [focusDateStr copy];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self setupUI];
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNavigationItemIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self focusInitialDateIfNeeded];
}

- (void)setupUI
{
    [self.view addSubview:self.scrollView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    
    [self.scrollView addSubview:self.contentView];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.scrollView);
        make.width.mas_equalTo(self.scrollView);
    }];

    [self.view addSubview:self.emptyLabel];
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
        make.left.right.mas_equalTo(self.view).inset(kSpecialDaysPadding);
    }];
}

- (void)reloadData
{
    self.days = [MirrorStorage retriveMirrorDays];
    [self sortSpecialDays:self.days];
    self.emptyLabel.hidden = self.days.count > 0;
    [self refreshVisibleUI];
}

- (void)refreshVisibleUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.addButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    [self updateNavigationItemIfNeeded];
    self.emptyLabel.text = [MirrorLanguage mirror_stringWithKey:@"no_special_days"];
    self.emptyLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    self.emptyLabel.hidden = self.days.count > 0;
    [self rebuildTimeline];
}

- (void)updateNavigationItemIfNeeded
{
    if (self.navigationController.topViewController != self) {
        return;
    }
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"special_days"] leftButton:nil rightButton:self.addButton];
}

- (void)rebuildTimeline
{
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UIView *previousRow = nil;
    for (NSInteger index = 0; index < self.days.count; index++) {
        MirrorDayModel *day = self.days[index];
        UIView *row = [self timelineRowWithDay:day isFirst:index == 0 isLast:index == self.days.count - 1];
        row.tag = index;
        [self.contentView addSubview:row];
        [row mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.mas_equalTo(self.contentView);
            make.height.mas_greaterThanOrEqualTo(kSpecialDaysRowHeight);
            if (previousRow) {
                make.top.mas_equalTo(previousRow.mas_bottom);
            } else {
                make.top.mas_equalTo(self.contentView).offset(kSpecialDaysPadding);
            }
        }];
        previousRow = row;
    }
    
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.scrollView);
        make.width.mas_equalTo(self.scrollView);
        if (previousRow) {
            make.bottom.mas_equalTo(previousRow.mas_bottom).offset(kSpecialDaysPadding);
        } else {
            make.bottom.mas_equalTo(self.scrollView);
        }
    }];
}

- (void)focusInitialDateIfNeeded
{
    if (self.didFocusInitialDate || self.focusDateStr.length == 0 || self.days.count == 0) {
        return;
    }
    self.didFocusInitialDate = YES;
    
    NSInteger focusIndex = [self indexOfSpecialDayWithDateStr:self.focusDateStr];
    if (focusIndex == NSNotFound) {
        return;
    }
    
    [self.view layoutIfNeeded];
    UIView *focusRow = [self rowViewForIndex:focusIndex];
    if (!focusRow) {
        return;
    }
    
    CGFloat visibleHeight = CGRectGetHeight(self.scrollView.bounds);
    UIEdgeInsets adjustedInset = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        adjustedInset = self.scrollView.adjustedContentInset;
    } else {
        adjustedInset = self.scrollView.contentInset;
    }
    
    CGFloat minOffsetY = -adjustedInset.top;
    CGFloat maxOffsetY = MAX(minOffsetY, self.scrollView.contentSize.height - visibleHeight + adjustedInset.bottom);
    CGFloat targetOffsetY = CGRectGetMidY(focusRow.frame) - visibleHeight / 2.0;
    targetOffsetY = MIN(MAX(targetOffsetY, minOffsetY), maxOffsetY);
    [self.scrollView setContentOffset:CGPointMake(0, targetOffsetY) animated:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.32 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self highlightRow:focusRow withDay:self.days[focusIndex]];
    });
}

- (NSInteger)indexOfSpecialDayWithDateStr:(NSString *)dateStr
{
    for (NSInteger index = 0; index < self.days.count; index++) {
        MirrorDayModel *day = self.days[index];
        if ([day.dateStr isEqualToString:dateStr]) {
            return index;
        }
    }
    return NSNotFound;
}

- (UIView *)rowViewForIndex:(NSInteger)index
{
    for (UIView *row in self.contentView.subviews) {
        if (row.tag == index) {
            return row;
        }
    }
    return nil;
}

- (void)highlightRow:(UIView *)row withDay:(MirrorDayModel *)day
{
    UIColor *highlightColor = [[UIColor mirrorSystemColorNamed:day.color] colorWithAlphaComponent:0.16];
    row.layer.cornerRadius = 8;
    row.layer.masksToBounds = YES;
    row.backgroundColor = UIColor.clearColor;
    [UIView animateKeyframesWithDuration:0.7 delay:0 options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.18 animations:^{
            row.backgroundColor = highlightColor;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.18 relativeDuration:0.18 animations:^{
            row.backgroundColor = UIColor.clearColor;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.18 animations:^{
            row.backgroundColor = highlightColor;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.68 relativeDuration:0.32 animations:^{
            row.backgroundColor = UIColor.clearColor;
        }];
    } completion:^(BOOL finished) {
        row.backgroundColor = UIColor.clearColor;
    }];
}

- (UIView *)timelineRowWithDay:(MirrorDayModel *)day isFirst:(BOOL)isFirst isLast:(BOOL)isLast
{
    UIView *row = [UIView new];
    if (@available(iOS 13.0, *)) {
        UIContextMenuInteraction *menuInteraction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
        [row addInteraction:menuInteraction];
    }
    UIColor *dayColor = [UIColor mirrorSystemColorNamed:day.color];
    UIColor *lineColor = [dayColor colorWithAlphaComponent:0.38];
    
    UIView *topLine = [UIView new];
    topLine.backgroundColor = lineColor;
    topLine.alpha = isFirst ? 0 : 1;
    [row addSubview:topLine];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(row.mas_left).offset(kSpecialDaysPadding + kSpecialDaysTimelineX);
        make.top.mas_equalTo(row);
        make.width.mas_equalTo(2);
        make.bottom.mas_equalTo(row.mas_centerY).offset(-kSpecialDaysTimelineIconSize / 2);
    }];
    
    UIView *bottomLine = [UIView new];
    bottomLine.backgroundColor = lineColor;
    bottomLine.alpha = isLast ? 0 : 1;
    [row addSubview:bottomLine];
    [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(topLine);
        make.top.mas_equalTo(row.mas_centerY).offset(kSpecialDaysTimelineIconSize / 2);
        make.width.mas_equalTo(2);
        make.bottom.mas_equalTo(row);
    }];
    
    UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeSystem];
    iconButton.userInteractionEnabled = NO;
    iconButton.tintColor = dayColor;
    iconButton.backgroundColor = [UIColor clearColor];
    [iconButton setImage:[UIImage systemImageNamed:day.icon.length > 0 ? day.icon : @"star.fill"] forState:UIControlStateNormal];
    [row addSubview:iconButton];
    [iconButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(topLine);
        make.centerY.mas_equalTo(row);
        make.width.height.mas_equalTo(kSpecialDaysTimelineIconSize);
    }];
    
    long dayTimestamp = [self timestampFromDay:day];
    UILabel *leftDateLabel = [UILabel new];
    leftDateLabel.font = [UIFont mirrorHighlightFont];
    leftDateLabel.textColor = dayColor;
    leftDateLabel.alpha = 0.7;
    leftDateLabel.textAlignment = NSTextAlignmentRight;
    leftDateLabel.adjustsFontSizeToFitWidth = YES;
    leftDateLabel.minimumScaleFactor = 0.7;
    leftDateLabel.text = [MirrorTool timelineMonthDayTextForTimestamp:dayTimestamp];
    [row addSubview:leftDateLabel];
    [leftDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(row).offset(4 * kWidthRatio);
        make.right.mas_equalTo(iconButton.mas_left).offset(-10 * kWidthRatio);
        make.centerY.mas_equalTo(iconButton.mas_centerY).offset(-6 * kHeightRatio);
    }];
    
    UILabel *leftYearLabel = [UILabel new];
    leftYearLabel.font = [UIFont mirrorHintFont];
    leftYearLabel.textColor = dayColor;
    leftYearLabel.alpha = 0.7;
    leftYearLabel.textAlignment = NSTextAlignmentRight;
    leftYearLabel.adjustsFontSizeToFitWidth = YES;
    leftYearLabel.minimumScaleFactor = 0.7;
    leftYearLabel.text = [MirrorTool timelineYearTextForTimestamp:dayTimestamp];
    [row addSubview:leftYearLabel];
    [leftYearLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(leftDateLabel);
        make.top.mas_equalTo(leftDateLabel.mas_bottom).offset(4 * kHeightRatio);
        make.bottom.mas_lessThanOrEqualTo(row).offset(-10 * kHeightRatio);
    }];
    
    UILabel *infoLabel = [UILabel new];
    infoLabel.font = [UIFont mirrorLabelFont];
    infoLabel.textColor = dayColor;
    infoLabel.numberOfLines = 0;
    infoLabel.text = day.info.length > 0 ? day.info : day.dateStr;
    [row addSubview:infoLabel];
    [infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(iconButton.mas_right).offset(12 * kWidthRatio);
        make.right.mas_equalTo(row).offset(-kSpecialDaysPadding);
        make.top.mas_greaterThanOrEqualTo(row).offset(12);
        make.centerY.mas_equalTo(iconButton);
        make.bottom.mas_lessThanOrEqualTo(row).offset(-12);
    }];
    
    return row;
}

- (long)timestampFromDay:(MirrorDayModel *)day
{
    NSDate *date = [self.dateFormatter dateFromString:day.dateStr];
    if (!date) {
        return (long)[[NSDate date] timeIntervalSince1970];
    }
    return (long)[date timeIntervalSince1970];
}

#pragma mark - Context Menu

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location API_AVAILABLE(ios(13.0))
{
    NSInteger dayIndex = interaction.view.tag;
    if (dayIndex < 0 || dayIndex >= self.days.count) {
        return nil;
    }
    
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        UIAction *deleteAction = [UIAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"]
                                                     image:[UIImage systemImageNamed:@"trash"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {
            [self deleteSpecialDayAtIndex:dayIndex];
        }];
        deleteAction.attributes = UIMenuElementAttributesDestructive;
        return [UIMenu menuWithTitle:@"" children:@[deleteAction]];
    }];
}

- (void)deleteSpecialDayAtIndex:(NSInteger)index
{
    if (index < 0 || index >= self.days.count) {
        return;
    }
    
    [MirrorStorage deleteMirrorDayAtIndex:index];
}

- (void)showAddDialog
{
    [self.view endEditing:YES];

    __block MirrorSystemColorType selectedColor = [self randomSpecialDayColor];
    
    UIDatePicker *datePicker = [UIDatePicker new];
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:[MirrorLanguage mirror_stringWithKey:@"locale_Identifier"]];
    datePicker.tintColor = [UIColor mirrorSystemColorNamed:selectedColor];
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    }

    __block NSString *selectedIconName = @"star.fill";
    UIButton *iconPickerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [iconPickerButton setImage:[UIImage systemImageNamed:selectedIconName] forState:UIControlStateNormal];
    iconPickerButton.tintColor = [UIColor mirrorSystemColorNamed:selectedColor];
    iconPickerButton.titleLabel.font = [UIFont mirrorButtonFont];
    iconPickerButton.backgroundColor = [self specialDayAlertControlBackgroundColor];
    iconPickerButton.layer.cornerRadius = 8;
    iconPickerButton.layer.masksToBounds = YES;
    
    UITextField *infoTextField = [UITextField new];
    infoTextField.placeholder = [MirrorLanguage mirror_stringWithKey:@"special_day_info"];
    infoTextField.textAlignment = NSTextAlignmentCenter;
    infoTextField.returnKeyType = UIReturnKeyDone;
    infoTextField.font = [UIFont mirrorHintFont_Card];
    infoTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    infoTextField.backgroundColor = [self specialDayAlertControlBackgroundColor];
    infoTextField.layer.cornerRadius = 8;
    infoTextField.layer.masksToBounds = YES;
    infoTextField.delegate = self;

    UIAlertController *addAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"add_special_day"] message:nil preferredStyle:UIAlertControllerStyleAlert];
    if (@available(iOS 14.0, *)) {
        [iconPickerButton addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            [self presentIconPickerFromAlert:addAlert selectedIconName:selectedIconName completion:^(NSString *iconName) {
                selectedIconName = iconName;
                [iconPickerButton setImage:[UIImage systemImageNamed:iconName] forState:UIControlStateNormal];
            }];
        }] forControlEvents:UIControlEventTouchUpInside];
    }
    [addAlert setValue:[self specialDayContentViewControllerWithDatePicker:datePicker infoTextField:infoTextField iconPickerButton:iconPickerButton colorPickerView:[self colorPickerViewWithSelectedColor:selectedColor selectionHandler:^(MirrorSystemColorType color) {
        selectedColor = color;
        iconPickerButton.tintColor = [UIColor mirrorSystemColorNamed:color];
        datePicker.tintColor = [UIColor mirrorSystemColorNamed:color];
    }]] forKey:@"contentViewController"];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *addAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"add"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *dateStr = [self.dateFormatter stringFromDate:datePicker.date];
        NSMutableArray<MirrorDayModel *> *days = [MirrorStorage retriveMirrorDays];
        if ([self specialDayExistsForDateStr:dateStr inDays:days]) {
            [self showSpecialDayErrorWithTitleKey:@"special_day_cannot_be_duplicated"];
            return;
        }
        
        MirrorDayModel *day = [[MirrorDayModel alloc] initWithDateStr:dateStr
                                                                 info:infoTextField.text ?: @""
                                                                 icon:selectedIconName
                                                                color:selectedColor];
        [MirrorStorage createMirrorDay:day];
    }];
    [addAlert addAction:cancelAction];
    [addAlert addAction:addAction];
    [self presentViewController:addAlert animated:YES completion:nil];
}

- (BOOL)specialDayExistsForDateStr:(NSString *)dateStr inDays:(NSArray<MirrorDayModel *> *)days
{
    for (MirrorDayModel *day in days) {
        if ([day.dateStr isEqualToString:dateStr]) {
            return YES;
        }
    }
    return NO;
}

- (void)showSpecialDayErrorWithTitleKey:(NSString *)titleKey
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:titleKey] message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *understandAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"gotcha"] style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:understandAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)sortSpecialDays:(NSMutableArray<MirrorDayModel *> *)days
{
    [days sortUsingComparator:^NSComparisonResult(MirrorDayModel *day1, MirrorDayModel *day2) {
        return [day1.dateStr compare:day2.dateStr];
    }];
}

- (UIViewController *)specialDayContentViewControllerWithDatePicker:(UIDatePicker *)datePicker infoTextField:(UITextField *)infoTextField iconPickerButton:(UIButton *)iconPickerButton colorPickerView:(UIView *)colorPickerView
{
    UIViewController *contentViewController = [UIViewController new];
    contentViewController.preferredContentSize = CGSizeMake(248, 122);

    [contentViewController.view addSubview:datePicker];
    [contentViewController.view addSubview:iconPickerButton];
    [contentViewController.view addSubview:infoTextField];
    [contentViewController.view addSubview:colorPickerView];
    
    [datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.top.mas_equalTo(contentViewController.view);
        make.height.mas_equalTo(34);
    }];

    [iconPickerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(contentViewController.view);
        make.top.mas_equalTo(datePicker.mas_bottom).offset(12);
        make.width.height.mas_equalTo(36);
    }];
    
    [infoTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(iconPickerButton.mas_right).offset(10);
        make.right.mas_equalTo(contentViewController.view);
        make.centerY.mas_equalTo(iconPickerButton);
        make.height.mas_equalTo(36);
    }];

    [colorPickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(contentViewController.view);
        make.top.mas_equalTo(infoTextField.mas_bottom).offset(12);
        make.height.mas_equalTo(26);
    }];

    return contentViewController;
}

- (UIColor *)specialDayAlertControlBackgroundColor
{
    if (@available(iOS 13.0, *)) {
        return [UIColor tertiarySystemFillColor];
    }
    return [UIColor colorWithWhite:0.92 alpha:1];
}

- (UIView *)colorPickerViewWithSelectedColor:(MirrorSystemColorType)selectedColor selectionHandler:(void (^)(MirrorSystemColorType colorType))selectionHandler
{
    UIStackView *colorStackView = [UIStackView new];
    colorStackView.axis = UILayoutConstraintAxisHorizontal;
    colorStackView.alignment = UIStackViewAlignmentCenter;
    colorStackView.distribution = UIStackViewDistributionEqualSpacing;
    colorStackView.spacing = 8;

    NSMutableArray<UIButton *> *colorButtons = [NSMutableArray new];
    NSMutableArray<UIView *> *colorFillViews = [NSMutableArray new];
    for (NSNumber *colorNumber in [self specialDayColorOptions]) {
        MirrorSystemColorType colorType = colorNumber.integerValue;
        UIColor *systemColor = [UIColor mirrorSystemColorNamed:colorType];
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = [UIColor clearColor];
        button.layer.cornerRadius = 12;
        button.layer.borderColor = systemColor.CGColor;
        button.layer.borderWidth = 2;
        
        UIView *fillView = [UIView new];
        fillView.userInteractionEnabled = NO;
        fillView.hidden = colorType != selectedColor;
        fillView.backgroundColor = systemColor;
        fillView.layer.cornerRadius = 9;
        fillView.layer.masksToBounds = YES;
        [button addSubview:fillView];
        [fillView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.mas_equalTo(button).inset(3);
        }];
        
        [colorStackView addArrangedSubview:button];
        [colorButtons addObject:button];
        [colorFillViews addObject:fillView];
        if (@available(iOS 14.0, *)) {
            [button addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
                for (NSInteger index = 0; index < colorButtons.count; index++) {
                    colorFillViews[index].hidden = colorButtons[index] != button;
                }
                if (selectionHandler) {
                    selectionHandler(colorType);
                }
            }] forControlEvents:UIControlEventTouchUpInside];
        }
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(24);
        }];
    }

    return colorStackView;
}

- (NSArray<NSNumber *> *)specialDayColorOptions
{
    return @[
        @(MirrorSystemColorTypeRed),
        @(MirrorSystemColorTypeOrange),
        @(MirrorSystemColorTypeYellow),
        @(MirrorSystemColorTypeGreen),
        @(MirrorSystemColorTypeMint),
        @(MirrorSystemColorTypeBlue),
        @(MirrorSystemColorTypePurple),
        @(MirrorSystemColorTypeGray)
    ];
}

- (MirrorSystemColorType)randomSpecialDayColor
{
    NSArray<NSNumber *> *colorOptions = [self specialDayColorOptions];
    if (colorOptions.count == 0) {
        return MirrorSystemColorTypeBlue;
    }
    return colorOptions[arc4random_uniform((uint32_t)colorOptions.count)].integerValue;
}

- (void)presentIconPickerFromAlert:(UIAlertController *)addAlert selectedIconName:(NSString *)selectedIconName completion:(void (^)(NSString *iconName))completion
{
    UIAlertController *iconAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"special_day_icon"] message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIViewController *contentViewController = [UIViewController new];
    contentViewController.preferredContentSize = CGSizeMake(248, 248);
    UIView *iconGridView = [UIView new];
    [contentViewController.view addSubview:iconGridView];
    [iconGridView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(contentViewController.view);
        make.width.height.mas_equalTo(240);
    }];

    NSArray<NSString *> *iconOptions = [self specialDayIconOptions];
    for (NSInteger index = 0; index < iconOptions.count; index++) {
        NSString *iconName = iconOptions[index];
        UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeSystem];
        iconButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        iconButton.backgroundColor = [iconName isEqualToString:selectedIconName] ? [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG] : [UIColor clearColor];
        iconButton.layer.cornerRadius = 4;
        iconButton.layer.masksToBounds = YES;
        [iconButton setImage:[UIImage systemImageNamed:iconName] forState:UIControlStateNormal];
        [iconGridView addSubview:iconButton];
        if (@available(iOS 14.0, *)) {
            [iconButton addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
                if (completion) {
                    completion(iconName);
                }
                [iconAlert dismissViewControllerAnimated:YES completion:nil];
            }] forControlEvents:UIControlEventTouchUpInside];
        }
        [iconButton mas_makeConstraints:^(MASConstraintMaker *make) {
            NSInteger row = index / 10;
            NSInteger column = index % 10;
            make.left.mas_equalTo(iconGridView).offset(column * 24);
            make.top.mas_equalTo(iconGridView).offset(row * 24);
            make.width.height.mas_equalTo(22);
        }];
    }

    [iconAlert setValue:contentViewController forKey:@"contentViewController"];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil];
    [iconAlert addAction:cancelAction];
    [addAlert presentViewController:iconAlert animated:YES completion:nil];
}

- (NSArray<NSString *> *)specialDayIconOptions
{
    return @[
        @"star.fill", @"heart.fill", @"pin.fill", @"gift.fill", @"flag.fill", @"bookmark.fill", @"tag.fill", @"bell.fill", @"bolt.fill", @"flame.fill",
        @"sun.max.fill", @"moon.fill", @"cloud.fill", @"snowflake", @"drop.fill", @"leaf.fill", @"camera.fill", @"photo.fill", @"music.note", @"mic.fill",
        @"film.fill", @"gamecontroller.fill", @"paintbrush.fill", @"pencil", @"book.fill", @"graduationcap.fill", @"briefcase.fill", @"folder.fill", @"doc.fill", @"calendar",
        @"clock.fill", @"alarm.fill", @"timer", @"hourglass", @"map.fill", @"location.fill", @"mappin", @"house.fill", @"building.2.fill", @"car.fill",
        @"airplane", @"tram.fill", @"bicycle", @"figure.walk", @"figure.run", @"figure.hiking", @"sportscourt.fill", @"soccerball", @"basketball.fill", @"tennisball.fill",
        @"dumbbell.fill", @"fork.knife", @"cup.and.saucer.fill", @"wineglass.fill", @"birthday.cake.fill", @"cart.fill", @"bag.fill", @"creditcard.fill", @"banknote.fill", @"chart.bar.fill",
        @"chart.pie.fill", @"target", @"trophy.fill", @"medal.fill", @"rosette", @"crown.fill", @"sparkles", @"wand.and.stars", @"person.fill", @"person.2.fill",
        @"person.3.fill", @"figure.2.and.child.holdinghands", @"hands.clap.fill", @"hand.thumbsup.fill", @"face.smiling.fill", @"eye.fill", @"brain.head.profile", @"lightbulb.fill", @"gear", @"wrench.fill",
        @"hammer.fill", @"scissors", @"stethoscope", @"cross.case.fill", @"pills.fill", @"bed.double.fill", @"shower.fill", @"washer.fill", @"trash.fill", @"shippingbox.fill",
        @"envelope.fill", @"phone.fill", @"message.fill", @"bubble.left.fill", @"network", @"wifi", @"lock.fill", @"key.fill", @"checkmark.circle.fill", @"exclamationmark.triangle.fill"
    ];
}

- (void)dismissAddDialog
{
    [self.view endEditing:YES];
    [self.dialogBackdropView removeFromSuperview];
    [self.dialogView removeFromSuperview];
    self.dialogBackdropView = nil;
    self.dialogView = nil;
    self.dialogCenterYConstraint = nil;
}

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!self.dialogView.superview) {
        return;
    }

    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameInView = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat overlap = CGRectGetMaxY(self.dialogView.frame) - CGRectGetMinY(keyboardFrameInView) + kSpecialDaysDialogPadding;
    CGFloat offset = overlap > 0 ? -overlap : 0;
    [self updateDialogCenterYOffset:offset keyboardNotification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [self updateDialogCenterYOffset:0 keyboardNotification:notification];
}

- (void)updateDialogCenterYOffset:(CGFloat)offset keyboardNotification:(NSNotification *)notification
{
    [self.dialogCenterYConstraint setOffset:offset];

    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = ([notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)addSpecialDay
{
    NSString *dateStr = [self.dateFormatter stringFromDate:self.dialogView.datePicker.date];
    NSMutableArray<MirrorDayModel *> *days = [MirrorStorage retriveMirrorDays];
    if ([self specialDayExistsForDateStr:dateStr inDays:days]) {
        [self showSpecialDayErrorWithTitleKey:@"special_day_cannot_be_duplicated"];
        return;
    }
    
    MirrorDayModel *day = [[MirrorDayModel alloc] initWithDateStr:dateStr
                                                             info:self.dialogView.infoTextField.text ?: @""
                                                             icon:[self selectedIcon]
                                                            color:[self randomSpecialDayColor]];
    [MirrorStorage createMirrorDay:day];
    [self dismissAddDialog];
}

- (NSString *)selectedIcon
{
    NSArray<NSString *> *icons = @[@"star", @"heart", @"pin", @"gift"];
    NSInteger index = self.dialogView.iconPicker.selectedSegmentIndex;
    if (index < 0 || index >= icons.count) {
        return icons.firstObject;
    }
    return icons[index];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Getters

- (UIButton *)addButton
{
    if (!_addButton) {
        _addButton = [UIButton new];
        [_addButton setImage:[UIImage systemImageNamed:@"plus"] forState:UIControlStateNormal];
        _addButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_addButton addTarget:self action:@selector(showAddDialog) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addButton;
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    }
    return _scrollView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = [UIColor clearColor];
    }
    return _contentView;
}

- (UILabel *)emptyLabel
{
    if (!_emptyLabel) {
        _emptyLabel = [UILabel new];
        _emptyLabel.text = [MirrorLanguage mirror_stringWithKey:@"no_special_days"];
        _emptyLabel.textAlignment = NSTextAlignmentCenter;
        _emptyLabel.font = [UIFont mirrorHintFont];
        _emptyLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    }
    return _emptyLabel;
}

- (UIView *)dialogBackdropView
{
    if (!_dialogBackdropView) {
        _dialogBackdropView = [UIView new];
        _dialogBackdropView.backgroundColor = [[UIColor mirrorColorNamed:MirrorColorTypeText] colorWithAlphaComponent:kSpecialDaysBackdropAlpha];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
        [_dialogBackdropView addGestureRecognizer:tapGesture];
    }
    return _dialogBackdropView;
}

- (SpecialDayDialogView *)dialogView
{
    if (!_dialogView) {
        _dialogView = [SpecialDayDialogView new];
        _dialogView.infoTextField.returnKeyType = UIReturnKeyDone;
        _dialogView.infoTextField.delegate = self;
        [_dialogView.cancelButton addTarget:self action:@selector(dismissAddDialog) forControlEvents:UIControlEventTouchUpInside];
        [_dialogView.addButton addTarget:self action:@selector(addSpecialDay) forControlEvents:UIControlEventTouchUpInside];
    }
    return _dialogView;
}

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"yyyy-MM-dd";
    }
    return _dateFormatter;
}

@end
