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
#import "MirrorSettings.h"

static CGFloat const kSpecialDaysPadding = 20;
static CGFloat const kSpecialDaysRowHeight = 58;
static CGFloat const kSpecialDaysTimelineIconSize = 26;
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

@interface SpecialDaysViewController () <UITextFieldDelegate, UIEditMenuInteractionDelegate>

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
@property (nonatomic, weak) UIAlertController *iconPickerAlert;
@property (nonatomic, weak) UITextField *iconPickerSearchTextField;
@property (nonatomic, copy) void (^iconPickerReloadHandler)(NSString *query);
@property (nonatomic, assign) NSInteger selectedDayIndex;
@property (nonatomic, assign) BOOL isSpecialDayEditMenuVisible;
@property (nonatomic, assign) BOOL shouldSuppressNextSpecialDayEditMenu;
@property (nonatomic, weak) UIEditMenuInteraction *visibleSpecialDayEditMenuInteraction API_AVAILABLE(ios(16.0));

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorDayEditNotification object:nil];
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
    [self refreshIconPickerIfNeeded];
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
    if (@available(iOS 16.0, *)) {
        UIEditMenuInteraction *editMenuInteraction = [[UIEditMenuInteraction alloc] initWithDelegate:self];
        [row addInteraction:editMenuInteraction];
        UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showSpecialDayEditMenu:)];
        [row addGestureRecognizer:longPressRecognizer];
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

#pragma mark - Edit Menu

- (void)showSpecialDayEditMenu:(UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    if ([self dismissVisibleSpecialDayEditMenuIfNeeded]) {
        return;
    }
    if (self.shouldSuppressNextSpecialDayEditMenu) {
        self.shouldSuppressNextSpecialDayEditMenu = NO;
        return;
    }
    
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];
    
    UIView *view = recognizer.view;
    self.selectedDayIndex = view.tag;
    [self shakeSelectedRow:view];
    
    if (@available(iOS 16.0, *)) {
        UIEditMenuInteraction *editMenuInteraction = nil;
        for (id<UIInteraction> interaction in view.interactions) {
            if ([interaction isKindOfClass:[UIEditMenuInteraction class]]) {
                editMenuInteraction = (UIEditMenuInteraction *)interaction;
                break;
            }
        }
        if (!editMenuInteraction) {
            return;
        }
        
        CGPoint point = [recognizer locationInView:view];
        UIEditMenuConfiguration *configuration = [UIEditMenuConfiguration configurationWithIdentifier:nil sourcePoint:point];
        [editMenuInteraction presentEditMenuWithConfiguration:configuration];
    }
}

- (void)shakeSelectedRow:(UIView *)row
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.values = @[@0, @(-4 * kWidthRatio), @(4 * kWidthRatio), @(-2 * kWidthRatio), @(2 * kWidthRatio), @0];
    animation.duration = 0.18;
    [row.layer addAnimation:animation forKey:@"selectedRowShake"];
}

- (UIMenu *)specialDayMenuForIndex:(NSInteger)dayIndex
{
    if (dayIndex < 0 || dayIndex >= self.days.count) {
        return nil;
    }
    
    UIAction *editAction = [UIAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"edit"] image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [self editSpecialDayAtIndex:dayIndex];
    }];
    UIAction *deleteAction = [UIAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] image:nil identifier:nil handler:^(__kindof UIAction *action) {
        [self deleteSpecialDayAtIndex:dayIndex];
    }];
    deleteAction.attributes = UIMenuElementAttributesDestructive;
    return [UIMenu menuWithTitle:@"" children:@[editAction, deleteAction]];
}

- (UIMenu *)editMenuInteraction:(UIEditMenuInteraction *)interaction menuForConfiguration:(UIEditMenuConfiguration *)configuration suggestedActions:(NSArray<UIMenuElement *> *)suggestedActions API_AVAILABLE(ios(16.0))
{
    return [self specialDayMenuForIndex:self.selectedDayIndex];
}

- (void)editMenuInteraction:(UIEditMenuInteraction *)interaction willPresentMenuForConfiguration:(UIEditMenuConfiguration *)configuration animator:(id<UIEditMenuInteractionAnimating>)animator API_AVAILABLE(ios(16.0))
{
    self.isSpecialDayEditMenuVisible = YES;
    self.visibleSpecialDayEditMenuInteraction = interaction;
}

- (void)editMenuInteraction:(UIEditMenuInteraction *)interaction willDismissMenuForConfiguration:(UIEditMenuConfiguration *)configuration animator:(id<UIEditMenuInteractionAnimating>)animator API_AVAILABLE(ios(16.0))
{
    if (interaction == self.visibleSpecialDayEditMenuInteraction) {
        self.isSpecialDayEditMenuVisible = NO;
        self.visibleSpecialDayEditMenuInteraction = nil;
        self.shouldSuppressNextSpecialDayEditMenu = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.isSpecialDayEditMenuVisible) {
                self.shouldSuppressNextSpecialDayEditMenu = NO;
            }
        });
    }
}

- (BOOL)dismissVisibleSpecialDayEditMenuIfNeeded
{
    if (!self.isSpecialDayEditMenuVisible) {
        return NO;
    }
    if (@available(iOS 16.0, *)) {
        [self.visibleSpecialDayEditMenuInteraction dismissMenu];
    }
    self.isSpecialDayEditMenuVisible = NO;
    self.visibleSpecialDayEditMenuInteraction = nil;
    self.shouldSuppressNextSpecialDayEditMenu = NO;
    return YES;
}

- (void)editSpecialDayAtIndex:(NSInteger)index
{
    if (index < 0 || index >= self.days.count) {
        return;
    }
    
    [self showSpecialDayDialogWithEditingIndex:index day:self.days[index]];
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
    [self showSpecialDayDialogWithEditingIndex:NSNotFound day:nil];
}

- (void)showSpecialDayDialogWithEditingIndex:(NSInteger)editingIndex day:(MirrorDayModel *)editingDay
{
    [self.view endEditing:YES];

    BOOL isEditing = editingIndex != NSNotFound && editingDay != nil;
    __block MirrorSystemColorType selectedColor = isEditing ? editingDay.color : [self randomSpecialDayColor];
    
    UIDatePicker *datePicker = [UIDatePicker new];
    datePicker.datePickerMode = UIDatePickerModeDate;
    datePicker.locale = [NSLocale localeWithLocaleIdentifier:[MirrorLanguage mirror_stringWithKey:@"locale_Identifier"]];
    datePicker.tintColor = [UIColor mirrorSystemColorNamed:selectedColor];
    NSDate *editingDate = isEditing ? [self.dateFormatter dateFromString:editingDay.dateStr] : nil;
    if (editingDate) {
        datePicker.date = editingDate;
    }
    if (@available(iOS 13.4, *)) {
        datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
    }

    __block NSString *selectedIconName = isEditing && editingDay.icon.length > 0 ? editingDay.icon : @"star.fill";
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
    infoTextField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    infoTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    infoTextField.backgroundColor = [self specialDayAlertControlBackgroundColor];
    infoTextField.layer.cornerRadius = 8;
    infoTextField.layer.masksToBounds = YES;
    infoTextField.delegate = self;
    infoTextField.text = isEditing ? editingDay.info : nil;

    UIAlertController *addAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:isEditing ? @"edit" : @"add_special_day"] message:nil preferredStyle:UIAlertControllerStyleAlert];
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

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.iconPickerAlert = nil;
        self.iconPickerSearchTextField = nil;
        self.iconPickerReloadHandler = nil;
    }];
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:isEditing ? @"done" : @"add"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *dateStr = [self.dateFormatter stringFromDate:datePicker.date];
        NSMutableArray<MirrorDayModel *> *days = [MirrorStorage retriveMirrorDays];
        [self sortSpecialDays:days];
        if ([self specialDayExistsForDateStr:dateStr inDays:days excludingIndex:isEditing ? editingIndex : NSNotFound]) {
            [self showSpecialDayErrorWithTitleKey:@"special_day_cannot_be_duplicated"];
            return;
        }
        
        MirrorDayModel *day = [[MirrorDayModel alloc] initWithDateStr:dateStr
                                                                 info:infoTextField.text ?: @""
                                                                 icon:selectedIconName
                                                                color:selectedColor];
        if (isEditing) {
            [MirrorStorage editMirrorDay:day atIndex:editingIndex];
        } else {
            [MirrorStorage createMirrorDay:day];
        }
    }];
    [addAlert addAction:cancelAction];
    [addAlert addAction:saveAction];
    [self presentViewController:addAlert animated:YES completion:nil];
}

- (BOOL)specialDayExistsForDateStr:(NSString *)dateStr inDays:(NSArray<MirrorDayModel *> *)days
{
    return [self specialDayExistsForDateStr:dateStr inDays:days excludingIndex:NSNotFound];
}

- (BOOL)specialDayExistsForDateStr:(NSString *)dateStr inDays:(NSArray<MirrorDayModel *> *)days excludingIndex:(NSInteger)excludedIndex
{
    for (NSInteger index = 0; index < days.count; index++) {
        if (index == excludedIndex) {
            continue;
        }
        MirrorDayModel *day = days[index];
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
    contentViewController.preferredContentSize = CGSizeMake(248, 132);

    [contentViewController.view addSubview:datePicker];
    [contentViewController.view addSubview:iconPickerButton];
    [contentViewController.view addSubview:infoTextField];
    [contentViewController.view addSubview:colorPickerView];
    
    [colorPickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(contentViewController.view);
        make.top.mas_equalTo(contentViewController.view);
        make.height.mas_equalTo(26);
    }];

    [datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(contentViewController.view);
        make.top.mas_equalTo(colorPickerView.mas_bottom).offset(12);
        make.height.mas_equalTo(34);
    }];

    [iconPickerButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(contentViewController.view);
        make.top.mas_equalTo(datePicker.mas_bottom).offset(12);
        make.width.height.mas_equalTo(40);
    }];
    
    [infoTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(iconPickerButton.mas_right).offset(10);
        make.right.mas_equalTo(contentViewController.view);
        make.centerY.mas_equalTo(iconPickerButton);
        make.height.mas_equalTo(40);
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
    [self applyPreferredInterfaceStyleToViewController:iconAlert];
    [self applyPreferredInterfaceStyleToViewController:contentViewController];
    CGFloat pickerWidth = 248;
    CGFloat pickerHeight = 368;
    contentViewController.preferredContentSize = CGSizeMake(pickerWidth, pickerHeight);
    
    UISegmentedControl *primaryCategoryPicker = [[UISegmentedControl alloc] initWithItems:@[@"★", @"Love", @"Home", @"Food", @"Trip"]];
    primaryCategoryPicker.selectedSegmentIndex = 0;
    [contentViewController.view addSubview:primaryCategoryPicker];
    [primaryCategoryPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.top.mas_equalTo(contentViewController.view);
        make.width.mas_equalTo(pickerWidth);
        make.height.mas_equalTo(30);
    }];

    UISegmentedControl *secondaryCategoryPicker = [[UISegmentedControl alloc] initWithItems:@[@"Sport", @"Work", @"Tech", @"Health", @"More"]];
    secondaryCategoryPicker.selectedSegmentIndex = UISegmentedControlNoSegment;
    [contentViewController.view addSubview:secondaryCategoryPicker];
    [secondaryCategoryPicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(contentViewController.view);
        make.top.mas_equalTo(primaryCategoryPicker.mas_bottom).offset(6);
        make.width.mas_equalTo(pickerWidth);
        make.height.mas_equalTo(30);
    }];
    
    UITextField *searchTextField = [UITextField new];
    searchTextField.placeholder = @"Search symbols";
    searchTextField.returnKeyType = UIReturnKeyDone;
    searchTextField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    searchTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    searchTextField.backgroundColor = [self specialDayAlertControlBackgroundColor];
    searchTextField.layer.cornerRadius = 8;
    searchTextField.layer.masksToBounds = YES;
    searchTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
    searchTextField.leftViewMode = UITextFieldViewModeAlways;
    searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [contentViewController.view addSubview:searchTextField];
    [searchTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(contentViewController.view);
        make.top.mas_equalTo(secondaryCategoryPicker.mas_bottom).offset(8);
        make.width.mas_equalTo(pickerWidth);
        make.height.mas_equalTo(38);
    }];

    UIScrollView *iconScrollView = [UIScrollView new];
    iconScrollView.showsVerticalScrollIndicator = YES;
    [contentViewController.view addSubview:iconScrollView];
    [iconScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.bottom.mas_equalTo(contentViewController.view);
        make.width.mas_equalTo(pickerWidth);
        make.top.mas_equalTo(searchTextField.mas_bottom).offset(10);
    }];

    UIView *iconGridView = [UIView new];
    [iconScrollView addSubview:iconGridView];
    [iconGridView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(iconScrollView);
        make.width.mas_equalTo(pickerWidth);
    }];
    
    NSArray<NSString *> *iconOptions = [self allSpecialDayIconOptions];
    __block NSInteger selectedCategoryIndex = 0;
    __block MASConstraint *gridBottomConstraint = nil;
    __block void (^reloadIcons)(NSString *) = nil;
    reloadIcons = ^(NSString *query) {
        [iconGridView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [gridBottomConstraint uninstall];
        gridBottomConstraint = nil;
        
        NSString *normalizedQuery = query.lowercaseString ?: @"";
        NSMutableArray<NSString *> *filteredOptions = [NSMutableArray new];
        NSArray<NSString *> *sourceOptions = normalizedQuery.length > 0 ? iconOptions : [self specialDayIconOptionsForCategoryIndex:selectedCategoryIndex allIcons:iconOptions];
        NSInteger maxIconCount = 180;
        for (NSString *iconName in sourceOptions) {
            if ((normalizedQuery.length == 0 || [iconName.lowercaseString containsString:normalizedQuery]) && [UIImage systemImageNamed:iconName]) {
                [filteredOptions addObject:iconName];
            }
            if (filteredOptions.count >= maxIconCount) {
                break;
            }
        }
        NSString *trimmedQuery = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
        if (trimmedQuery.length > 0 && [UIImage systemImageNamed:trimmedQuery] && ![filteredOptions containsObject:trimmedQuery]) {
            [filteredOptions insertObject:trimmedQuery atIndex:0];
        }
        
        NSInteger columns = 8;
        CGFloat itemSide = 28;
        CGFloat itemSpacing = (pickerWidth - columns * itemSide) / (columns - 1);
        for (NSInteger index = 0; index < filteredOptions.count; index++) {
            NSString *iconName = filteredOptions[index];
            UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeSystem];
            iconButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
            iconButton.backgroundColor = [iconName isEqualToString:selectedIconName] ? [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG] : [UIColor clearColor];
            iconButton.layer.cornerRadius = 6;
            iconButton.layer.masksToBounds = YES;
            [iconButton setImage:[UIImage systemImageNamed:iconName] forState:UIControlStateNormal];
            [iconGridView addSubview:iconButton];
            if (@available(iOS 14.0, *)) {
                [iconButton addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
                if (completion) {
                    completion(iconName);
                }
                self.iconPickerAlert = nil;
                self.iconPickerSearchTextField = nil;
                self.iconPickerReloadHandler = nil;
                [iconAlert dismissViewControllerAnimated:YES completion:nil];
            }] forControlEvents:UIControlEventTouchUpInside];
            }
            [iconButton mas_makeConstraints:^(MASConstraintMaker *make) {
                NSInteger row = index / columns;
                NSInteger column = index % columns;
                make.left.mas_equalTo(iconGridView).offset(column * (itemSide + itemSpacing));
                make.top.mas_equalTo(iconGridView).offset(row * (itemSide + itemSpacing));
                make.width.height.mas_equalTo(itemSide);
                if (index == filteredOptions.count - 1) {
                    gridBottomConstraint = make.bottom.mas_equalTo(iconGridView);
                }
            }];
        }
        
        if (filteredOptions.count == 0) {
            UILabel *emptyLabel = [UILabel new];
            emptyLabel.text = [MirrorLanguage mirror_stringWithKey:@"no_data"];
            emptyLabel.textAlignment = NSTextAlignmentCenter;
            emptyLabel.font = [UIFont mirrorHintFont];
            emptyLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
            [iconGridView addSubview:emptyLabel];
            [emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.top.mas_equalTo(iconGridView);
                make.height.mas_equalTo(44);
                gridBottomConstraint = make.bottom.mas_equalTo(iconGridView);
            }];
        }
        [iconGridView layoutIfNeeded];
    };
    
    reloadIcons(nil);
    if (@available(iOS 14.0, *)) {
        [primaryCategoryPicker addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            selectedCategoryIndex = primaryCategoryPicker.selectedSegmentIndex;
            secondaryCategoryPicker.selectedSegmentIndex = UISegmentedControlNoSegment;
            reloadIcons(searchTextField.text);
        }] forControlEvents:UIControlEventValueChanged];
        [secondaryCategoryPicker addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            selectedCategoryIndex = secondaryCategoryPicker.selectedSegmentIndex + 5;
            primaryCategoryPicker.selectedSegmentIndex = UISegmentedControlNoSegment;
            reloadIcons(searchTextField.text);
        }] forControlEvents:UIControlEventValueChanged];
        [searchTextField addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
            reloadIcons(searchTextField.text);
        }] forControlEvents:UIControlEventEditingChanged];
    }

    [iconAlert setValue:contentViewController forKey:@"contentViewController"];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil];
    [iconAlert addAction:cancelAction];
    self.iconPickerAlert = iconAlert;
    self.iconPickerSearchTextField = searchTextField;
    self.iconPickerReloadHandler = reloadIcons;
    [addAlert presentViewController:iconAlert animated:YES completion:nil];
}

- (void)refreshIconPickerIfNeeded
{
    UIAlertController *iconAlert = self.iconPickerAlert;
    if (!iconAlert) {
        return;
    }
    
    [self applyPreferredInterfaceStyleToViewController:iconAlert];
    UIViewController *contentViewController = [iconAlert valueForKey:@"contentViewController"];
    [self applyPreferredInterfaceStyleToViewController:contentViewController];
    self.iconPickerSearchTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    self.iconPickerSearchTextField.backgroundColor = [self specialDayAlertControlBackgroundColor];
    if (self.iconPickerReloadHandler) {
        self.iconPickerReloadHandler(self.iconPickerSearchTextField.text);
    }
}

- (void)applyPreferredInterfaceStyleToViewController:(UIViewController *)viewController
{
    if (!viewController) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        viewController.overrideUserInterfaceStyle = [MirrorSettings appliedDarkMode] ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
        viewController.view.overrideUserInterfaceStyle = viewController.overrideUserInterfaceStyle;
    }
    viewController.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
}

- (NSArray<NSString *> *)specialDayIconOptions
{
    return @[
        @"star.fill", @"heart.fill", @"pin.fill", @"gift.fill", @"flag.fill", @"bookmark.fill", @"tag.fill", @"bell.fill", @"bolt.fill", @"flame.fill",
        @"sun.max.fill", @"moon.fill", @"cloud.fill", @"snowflake", @"drop.fill", @"leaf.fill", @"camera.fill", @"photo.fill", @"music.note", @"mic.fill",
        @"film.fill", @"tv.fill", @"headphones", @"speaker.wave.2.fill", @"gamecontroller.fill", @"paintbrush.fill", @"pencil", @"highlighter", @"book.fill", @"books.vertical.fill", @"graduationcap.fill", @"briefcase.fill", @"folder.fill", @"doc.fill", @"calendar",
        @"clock.fill", @"alarm.fill", @"timer", @"hourglass", @"map.fill", @"location.fill", @"mappin", @"house.fill", @"building.2.fill", @"car.fill",
        @"airplane", @"tram.fill", @"bus.fill", @"ferry.fill", @"bicycle", @"scooter", @"figure.walk", @"figure.run", @"figure.hiking", @"figure.pool.swim", @"figure.open.water.swim", @"figure.strengthtraining.traditional", @"figure.yoga", @"sportscourt.fill", @"soccerball", @"basketball.fill", @"football.fill", @"baseball.fill", @"tennisball.fill",
        @"dumbbell.fill", @"fork.knife", @"takeoutbag.and.cup.and.straw.fill", @"cup.and.saucer.fill", @"mug.fill", @"wineglass.fill", @"birthday.cake.fill", @"balloon.fill", @"cart.fill", @"bag.fill", @"creditcard.fill", @"banknote.fill", @"chart.bar.fill",
        @"chart.pie.fill", @"target", @"trophy.fill", @"medal.fill", @"rosette", @"crown.fill", @"sparkles", @"wand.and.stars", @"person.fill", @"person.2.fill",
        @"person.3.fill", @"figure.2.and.child.holdinghands", @"hands.clap.fill", @"hand.thumbsup.fill", @"face.smiling.fill", @"eye.fill", @"brain.head.profile", @"lightbulb.fill", @"gear", @"wrench.fill",
        @"hammer.fill", @"screwdriver.fill", @"paintbrush.pointed.fill", @"scissors", @"stethoscope", @"cross.case.fill", @"pills.fill", @"bandage.fill", @"heart.text.square.fill", @"bed.double.fill", @"shower.fill", @"bathtub.fill", @"washer.fill", @"trash.fill", @"shippingbox.fill",
        @"envelope.fill", @"phone.fill", @"message.fill", @"bubble.left.fill", @"network", @"wifi", @"antenna.radiowaves.left.and.right", @"globe", @"link", @"lock.fill", @"key.fill", @"checkmark.circle.fill", @"xmark.circle.fill", @"plus.circle.fill", @"minus.circle.fill", @"exclamationmark.triangle.fill",
        @"cat.fill", @"dog.fill", @"pawprint.fill", @"fish.fill", @"bird.fill", @"ladybug.fill", @"tree.fill", @"carrot.fill", @"fuelpump.fill", @"ev.charger.fill",
        @"desktopcomputer", @"laptopcomputer", @"iphone", @"ipad", @"applewatch", @"keyboard.fill", @"printer.fill", @"scanner.fill", @"externaldrive.fill", @"server.rack",
        @"app.fill", @"safari.fill", @"terminal.fill", @"curlybraces", @"chevron.left.forwardslash.chevron.right", @"number", @"m.circle.fill", @"at", @"qrcode", @"barcode",
        @"rectangle.and.pencil.and.ellipsis", @"list.bullet", @"checklist", @"square.and.arrow.up", @"square.and.arrow.down", @"tray.fill", @"archivebox.fill", @"paperclip", @"link.circle.fill", @"signature",
        @"lungs.fill", @"brain.fill", @"ear.fill", @"mouth.fill", @"nose.fill", @"eye.circle.fill", @"facemask.fill", @"syringe.fill", @"thermometer.medium", @"waveform.path.ecg",
        @"house.and.flag.fill", @"storefront.fill", @"building.columns.fill", @"theatermasks.fill", @"popcorn.fill", @"ticket.fill", @"party.popper.fill", @"chandelier.fill", @"door.left.hand.open", @"sofa.fill",
        @"star", @"heart", @"pin", @"gift", @"flag", @"bookmark", @"tag", @"bell", @"bolt", @"flame",
        @"sun.max", @"moon", @"cloud", @"drop", @"leaf", @"camera", @"photo", @"mic", @"film", @"tv",
        @"gamecontroller", @"paintbrush", @"book", @"graduationcap", @"briefcase", @"folder", @"doc", @"clock", @"alarm", @"map",
        @"location", @"house", @"building.2", @"car", @"tram", @"bus", @"ferry", @"sportscourt", @"basketball", @"football",
        @"baseball", @"tennisball", @"dumbbell", @"cup.and.saucer", @"mug", @"wineglass", @"birthday.cake", @"balloon", @"cart", @"bag",
        @"creditcard", @"banknote", @"chart.bar", @"chart.pie", @"trophy", @"medal", @"crown", @"person", @"person.2", @"person.3",
        @"hands.clap", @"hand.thumbsup", @"face.smiling", @"eye", @"lightbulb", @"wrench", @"hammer", @"screwdriver", @"cross.case", @"pills",
        @"bandage", @"bed.double", @"shower", @"bathtub", @"washer", @"trash", @"shippingbox", @"envelope", @"phone", @"message",
        @"bubble.left", @"lock", @"key", @"checkmark.circle", @"xmark.circle", @"plus.circle", @"minus.circle", @"exclamationmark.triangle", @"cat", @"dog",
        @"pawprint", @"fish", @"bird", @"ladybug", @"tree", @"carrot", @"fuelpump", @"desktopcomputer", @"keyboard", @"printer",
        @"scanner", @"externaldrive", @"app", @"safari", @"terminal", @"link.circle", @"lungs", @"brain", @"ear", @"mouth",
        @"nose", @"facemask", @"syringe", @"house.and.flag", @"storefront", @"building.columns", @"theatermasks", @"popcorn", @"ticket", @"party.popper",
        @"sofa", @"bed.double.circle.fill", @"fork.knife.circle.fill", @"fork.knife.circle", @"cup.and.saucer", @"figure.dance", @"figure.mind.and.body", @"figure.skiing.downhill", @"figure.snowboarding", @"figure.surfing",
        @"figure.tennis", @"figure.badminton", @"figure.basketball", @"figure.soccer", @"figure.socialdance", @"figure.climbing", @"figure.cooldown", @"figure.core.training", @"figure.cross.training", @"figure.flexibility",
        @"figure.golf", @"figure.outdoor.cycle", @"figure.roll", @"figure.rower", @"figure.stairs", @"figure.step.training", @"figure.strengthtraining.functional", @"figure.volleyball", @"figure.water.fitness", @"figure.wave",
        @"figure.kickboxing", @"figure.boxing", @"figure.archery", @"figure.baseball", @"figure.fishing", @"figure.equestrian.sports", @"figure.gymnastics", @"figure.jumprope", @"figure.martial.arts", @"figure.play",
        @"figure.skating", @"figure.hockey", @"figure.rugby", @"figure.softball", @"figure.table.tennis", @"figure.taichi", @"figure.track.and.field", @"figure.wrestling", @"shoeprints.fill", @"shoe.fill",
        @"bubbles.and.sparkles.fill", @"wand.and.rays", @"paintpalette.fill", @"paintpalette", @"camera.aperture", @"video.fill", @"video", @"record.circle", @"play.circle.fill", @"pause.circle.fill",
        @"stop.circle.fill", @"backward.fill", @"forward.fill", @"shuffle", @"repeat", @"guitars.fill", @"pianokeys", @"beats.headphones", @"hifispeaker.fill", @"radio.fill",
        @"newspaper.fill", @"magazine.fill", @"menucard.fill", @"text.book.closed.fill", @"character.book.closed.fill", @"bookmark.circle.fill", @"graduationcap.circle.fill", @"studentdesk", @"backpack.fill", @"case.fill",
        @"calendar.badge.plus", @"calendar.badge.minus", @"calendar.badge.clock", @"calendar.circle.fill", @"clock.badge.checkmark.fill", @"timer.circle.fill", @"stopwatch.fill", @"hourglass.circle.fill", @"hourglass.bottomhalf.filled", @"hourglass.tophalf.filled",
        @"map.circle.fill", @"mappin.circle.fill", @"location.circle.fill", @"location.north.fill", @"safari", @"compass.drawing", @"signpost.right.fill", @"road.lanes", @"car.side.fill", @"car.front.waves.up.fill",
        @"car.rear.fill", @"steeringwheel", @"bicycle.circle.fill", @"scooter.circle.fill", @"airplane.departure", @"airplane.arrival", @"fuelpump.circle.fill", @"ev.charger.circle.fill", @"parkingsign.circle.fill", @"sailboat.fill",
        @"mountain.2.fill", @"beach.umbrella.fill", @"tent.fill", @"tree.circle.fill", @"laurel.leading", @"laurel.trailing", @"camera.macro", @"binoculars.fill", @"globe.americas.fill", @"globe.europe.africa.fill",
        @"globe.asia.australia.fill", @"network.badge.shield.half.filled", @"wifi.circle.fill", @"antenna.radiowaves.left.and.right.circle.fill", @"dot.radiowaves.left.and.right", @"personalhotspot", @"lock.shield.fill", @"key.horizontal.fill", @"person.badge.key.fill", @"checkmark.shield.fill",
        @"heart.circle.fill", @"heart.text.square", @"cross.circle.fill", @"staroflife.fill", @"medical.thermometer.fill", @"ivfluid.bag.fill", @"cross.vial.fill", @"microbe.fill", @"allergens.fill", @"pill.circle.fill",
        @"pawprint.circle.fill", @"lizard.fill", @"tortoise.fill", @"hare.fill", @"ant.fill", @"fossil.shell.fill", @"camera.filters", @"rainbow", @"cloud.sun.fill", @"cloud.moon.fill",
        @"cloud.rain.fill", @"cloud.snow.fill", @"cloud.bolt.fill", @"wind", @"tornado", @"thermometer.sun.fill", @"aqi.medium", @"water.waves", @"fireplace.fill", @"light.recessed.fill"
    ];
}

- (NSArray<NSString *> *)allSpecialDayIconOptions
{
    NSMutableOrderedSet<NSString *> *iconNames = [NSMutableOrderedSet orderedSet];
    NSString *symbolsPath = [NSBundle.mainBundle pathForResource:@"SFSymbolNames" ofType:@"plist"];
    NSArray<NSString *> *bundledSymbols = [NSArray arrayWithContentsOfFile:symbolsPath];
    if ([bundledSymbols isKindOfClass:NSArray.class]) {
        for (NSString *symbolName in bundledSymbols) {
            if ([symbolName isKindOfClass:NSString.class] && symbolName.length > 0) {
                [iconNames addObject:symbolName];
            }
        }
    }
    
    for (NSString *symbolName in [self specialDayIconOptions]) {
        [iconNames addObject:symbolName];
    }
    return iconNames.array;
}

- (NSArray<NSString *> *)specialDayIconOptionsForCategoryIndex:(NSInteger)categoryIndex allIcons:(NSArray<NSString *> *)allIcons
{
    NSArray<NSString *> *keywords = [self iconCategoryKeywordsForIndex:categoryIndex];
    if (keywords.count == 0) {
        return [self specialDayIconOptions];
    }
    
    NSMutableArray<NSString *> *icons = [NSMutableArray new];
    for (NSString *iconName in allIcons) {
        NSString *lowercaseName = iconName.lowercaseString;
        for (NSString *keyword in keywords) {
            if ([lowercaseName containsString:keyword]) {
                [icons addObject:iconName];
                break;
            }
        }
        if (icons.count >= 240) {
            break;
        }
    }
    return icons;
}

- (NSArray<NSString *> *)iconCategoryKeywordsForIndex:(NSInteger)categoryIndex
{
    switch (categoryIndex) {
        case 1:
            return @[@"heart", @"sparkle", @"gift", @"balloon", @"party", @"cake", @"crown", @"rosette", @"person", @"hand", @"face", @"star"];
        case 2:
            return @[@"house", @"home", @"sofa", @"bed", @"bath", @"shower", @"washer", @"lamp", @"light", @"door", @"chandelier", @"building", @"storefront"];
        case 3:
            return @[@"fork", @"knife", @"cup", @"mug", @"wine", @"takeout", @"menucard", @"cart", @"bag", @"birthday", @"cake", @"popcorn", @"carrot"];
        case 4:
            return @[@"car", @"bus", @"tram", @"airplane", @"ferry", @"bicycle", @"scooter", @"map", @"location", @"mappin", @"globe", @"compass", @"signpost", @"road", @"sailboat"];
        case 5:
            return @[@"figure", @"sport", @"ball", @"tennis", @"soccer", @"basketball", @"football", @"baseball", @"dumbbell", @"swim", @"run", @"walk", @"hike", @"bike", @"bicycle", @"trophy", @"medal", @"target"];
        case 6:
            return @[@"briefcase", @"folder", @"doc", @"book", @"graduation", @"calendar", @"clock", @"chart", @"student", @"backpack", @"case", @"newspaper", @"magazine"];
        case 7:
            return @[@"desktop", @"laptop", @"keyboard", @"terminal", @"curly", @"chevron", @"number", @"server", @"printer", @"scanner", @"app", @"safari", @"network", @"wifi", @"qrcode", @"barcode"];
        case 8:
            return @[@"medical", @"heart", @"cross", @"pill", @"bandage", @"stethoscope", @"brain", @"lungs", @"syringe", @"thermometer", @"waveform", @"allergen", @"microbe", @"facemask"];
        case 9:
            return @[@"sun", @"moon", @"cloud", @"snow", @"rain", @"wind", @"tree", @"leaf", @"paw", @"cat", @"dog", @"fish", @"bird", @"camera", @"music", @"paint", @"game", @"lock", @"key", @"gear", @"wrench", @"hammer", @"trash", @"shipping"];
        default:
            return @[];
    }
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
