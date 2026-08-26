//
//  TimeTrackerViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import "TimeViewController.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorDebugAlert.h"
#import "TimeTrackerTaskCollectionViewCell.h"
#import "TimeTrackerAddTaskCollectionViewCell.h"
#import "MirrorMacro.h"
#import "MirrorTabsManager.h"
#import "MirrorNaviManager.h"
#import "TimeTrackingViewController.h"
#import "MirrorStorage.h"
#import "MirrorTool.h"
#import "MirrorSettings.h"
#import "CellAnimation.h"
#import "MirrorLanguage.h"
#import "HintFooter.h"
#import "TaskPickerViewController.h"
#import "MirrorSupportManualAlert.h"
#import "UIImage+MirrorSymbol.h"

#import "Mirror-Swift.h"

#define kCellSpacing (16 * kHeightRatio)// cell之间的上下间距
#define kCollectionViewPadding (20 * kWidthRatio) // 左右留白
static NSString * const kNaviIconUsesCustomConfigurationIdentifier = @"MirrorNaviIconUsesCustomConfiguration";

@interface TimeViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TimeTrackerTaskCollectionViewCellDelegate, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL isLoaded;
@property (nonatomic, strong) UIView *navigationDebugHitView;
@property (nonatomic, assign) NSInteger navigationDebugTapCount;
@property (nonatomic, strong) NSDate *lastNavigationDebugTapDate;
// Navibar
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIButton *supportButton;
// Data source
@property (nonatomic, strong) NSMutableArray<MirrorTaskModel *> *data;
// Mark
@property (nonatomic, assign) CGRect selectedCellFrame; // cell.x, cell.y, cell.width, cell.height
@property (nonatomic, strong) UIColor *selectedTaskColor;
@property (nonatomic, assign) BOOL isEditingTasks;
// UI
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UITapGestureRecognizer *editingDismissTapRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *taskReorderLongPressRecognizer;
@property (nonatomic, weak) TimeTrackerTaskCollectionViewCell *reorderSelectedCell;

@end

@implementation TimeViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 设置通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
        // 数据通知 (直接数据驱动UI，本地数据变动必然导致这里的UI变动)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStopNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskStartNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskEditNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskMergeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorTaskChangeOrderNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
        
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    _isLoaded = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshNavigationButtonColors];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:self.supportButton];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self exitEditingTasksIfNeededAnimated:NO];
    [self removeNavigationDebugGesture];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
    }];
    [self addNavigationDebugGesture];
    [self presentGoingOnTaskIfNeeded];
}

- (void)restartVC
{
    if (!_isLoaded) return;
    // update navibar
    [[MirrorTabsManager sharedInstance] updateTimeTabItemWithTabController:self.tabBarController];
    if (self.tabBarController.selectedIndex == 0) {
        [self refreshNavigationButtonColors];
        [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:self.supportButton];
        [self addNavigationDebugGesture];
    }
    // reset ui
    self.collectionView = nil;
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self p_setupUI];
}

- (void)reloadData
{
    if (!_isLoaded) return;
    self.data = [MirrorStorage tasksWithAddNew];
    [self.collectionView reloadData];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.collectionView];
    [self.view addGestureRecognizer:self.editingDismissTapRecognizer];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kCollectionViewPadding);
        make.right.mas_equalTo(self.view).offset(-kCollectionViewPadding);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.bottom.mas_equalTo(self.view).offset(-self.tabBarController.tabBar.frame.size.height);
    }];
}

- (void)refreshNavigationButtonColors
{
    [self updateSettingsButtonIcon];
    [self updateSupportButtonIcon];
    self.settingsButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    self.supportButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
}

- (void)updateSettingsButtonIcon
{
    UIImage *iconImage = [[UIImage mirror_systemImageNamed:[self languageGlobeIconName] fallbackName:@"globe"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_settingsButton setImage:iconImage forState:UIControlStateNormal];
}

- (void)updateSupportButtonIcon
{
    UIImageSymbolConfiguration *headsetConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightRegular];
    UIImageSymbolConfiguration *fallbackConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:22 weight:UIImageSymbolWeightRegular];
    UIImage *iconImage = [UIImage mirror_systemImageNamed:@"headset" fallbackName:@"questionmark.circle" configuration:headsetConfiguration fallbackConfiguration:fallbackConfiguration];
    [_supportButton setImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [_supportButton setTitle:iconImage ? nil : @"?" forState:UIControlStateNormal];
    _supportButton.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightRegular];
    [_supportButton setPreferredSymbolConfiguration:nil forImageInState:UIControlStateNormal];
    [_supportButton setPreferredSymbolConfiguration:nil forImageInState:UIControlStateHighlighted];
}

- (NSString *)languageGlobeIconName
{
    MirrorLanguageKey languageKey = [MirrorSettings preferredLanguageKey];
    if (languageKey == MirrorLanguageKeySimplifiedChinese ||
        languageKey == MirrorLanguageKeyJapanese ||
        languageKey == MirrorLanguageKeyKorean) return @"globe.asia.australia";
    if (languageKey == MirrorLanguageKeyFrench ||
        languageKey == MirrorLanguageKeyGerman ||
        languageKey == MirrorLanguageKeyRussian) return @"globe.europe.africa";
    return @"globe.americas";
}

#pragma mark - Actions

- (void)enterEditingTasksIfNeededAnimated:(BOOL)animated
{
    if (self.isEditingTasks) {
        return;
    }
    self.isEditingTasks = YES;
    self.editingDismissTapRecognizer.enabled = YES;
    [self updateVisibleTaskCellsForEditingModeAnimated:animated];
}

- (void)updateVisibleTaskCellsForEditingModeAnimated:(BOOL)animated
{
    for (TimeTrackerTaskCollectionViewCell *cell in self.collectionView.visibleCells) {
        if (![cell isKindOfClass:TimeTrackerTaskCollectionViewCell.class]) {
            continue;
        }
        [cell setEditingModeEnabled:self.isEditingTasks animated:animated];
    }
}

- (void)dismissEditingTasksFromBackgroundTap:(UITapGestureRecognizer *)tapRecognizer
{
    if (tapRecognizer.state != UIGestureRecognizerStateRecognized) {
        return;
    }
    [self exitEditingTasksIfNeededAnimated:YES];
}

- (void)exitEditingTasksIfNeededAnimated:(BOOL)animated
{
    if (!self.isEditingTasks) {
        return;
    }
    self.isEditingTasks = NO;
    self.editingDismissTapRecognizer.enabled = NO;
    [self clearReorderSelectedCellAnimated:animated];
    [self updateVisibleTaskCellsForEditingModeAnimated:animated];
}

#pragma mark - Actions

- (void)addNavigationDebugGesture
{
    [self removeNavigationDebugGesture];

    UIWindow *window = self.view.window;
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (!window || !navigationBar) {
        return;
    }

    CGRect navigationBarFrame = [navigationBar.superview convertRect:navigationBar.frame toView:window];
    UIView *hitView = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetMidX(navigationBarFrame) - 80,
                                                               CGRectGetMinY(navigationBarFrame),
                                                               160,
                                                               CGRectGetHeight(navigationBarFrame))];
    hitView.backgroundColor = UIColor.clearColor;
    hitView.userInteractionEnabled = YES;
    self.navigationDebugHitView = hitView;
    [window addSubview:hitView];

    UITapGestureRecognizer *debugTapRecognizer = [UITapGestureRecognizer new];
    debugTapRecognizer.numberOfTouchesRequired = 1;
    [debugTapRecognizer addTarget:self action:@selector(countNavigationDebugTap:)];
    [hitView addGestureRecognizer:debugTapRecognizer];
}

- (void)removeNavigationDebugGesture
{
    [self.navigationDebugHitView removeFromSuperview];
    self.navigationDebugHitView = nil;
    self.navigationDebugTapCount = 0;
    self.lastNavigationDebugTapDate = nil;
}

- (void)countNavigationDebugTap:(UITapGestureRecognizer *)tapRecognizer
{
    if (tapRecognizer.state != UIGestureRecognizerStateRecognized || self.presentedViewController) {
        return;
    }

    NSDate *now = [NSDate date];
    if (self.lastNavigationDebugTapDate && [now timeIntervalSinceDate:self.lastNavigationDebugTapDate] > 2) {
        self.navigationDebugTapCount = 0;
    }

    self.lastNavigationDebugTapDate = now;
    self.navigationDebugTapCount += 1;
    if (self.navigationDebugTapCount < 11) {
        return;
    }

    self.navigationDebugTapCount = 0;
    self.lastNavigationDebugTapDate = nil;
    [MirrorDebugAlert presentFromViewController:self];
}

- (void)showSupportAlert
{
    [MirrorSupportManualAlert presentFromViewController:self];
}

- (void)showLanguagePicker
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    NSArray<NSNumber *> *languageKeys = @[
        @(MirrorLanguageKeyEnglish),
        @(MirrorLanguageKeySimplifiedChinese),
        @(MirrorLanguageKeySpanish),
        @(MirrorLanguageKeyFrench),
        @(MirrorLanguageKeyJapanese),
        @(MirrorLanguageKeyKorean),
        @(MirrorLanguageKeyGerman),
        @(MirrorLanguageKeyRussian)
    ];
    NSArray<NSString *> *languageNames = @[@"English", @"中文", @"Español", @"Français", @"日本語", @"한국어", @"Deutsch", @"Русский"];
    MirrorLanguageKey preferredLanguageKey = [MirrorSettings preferredLanguageKey];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [languageNames enumerateObjectsUsingBlock:^(NSString *languageName, NSUInteger index, BOOL *stop) {
        MirrorLanguageKey languageKey = languageKeys[index].integerValue;
        NSString *title = languageKey == preferredLanguageKey ? [languageName stringByAppendingString:@" ✓"] : languageName;
        [alertController addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [MirrorSettings changeLanguageWithKey:languageKey];
        }]];
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil]];
    alertController.popoverPresentationController.sourceView = self.settingsButton;
    alertController.popoverPresentationController.sourceRect = self.settingsButton.bounds;
    alertController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (BOOL)canMoveTaskAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == nil || indexPath.item >= self.data.count) {
        return NO;
    }
    return !self.data[indexPath.item].isAddTaskModel;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer != self.editingDismissTapRecognizer || !self.isEditingTasks) {
        return YES;
    }

    UIView *view = touch.view;
    while (view && view != self.view) {
        if ([view isKindOfClass:TimeTrackerTaskCollectionViewCell.class]) {
            return NO;
        }
        view = view.superview;
    }
    return YES;
}

- (void)handleTaskReorderLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint location = [gestureRecognizer locationInView:self.collectionView];
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
            if (![self canMoveTaskAtIndexPath:indexPath]) {
                return;
            }
            if (!self.isEditingTasks) {
                [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium] impactOccurred];
                [self enterEditingTasksIfNeededAnimated:YES];
                return;
            }
            TimeTrackerTaskCollectionViewCell *cell = (TimeTrackerTaskCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            self.reorderSelectedCell = cell;
            [cell setReorderSelected:YES animated:YES];
            [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
            [self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
            break;
        }
        case UIGestureRecognizerStateChanged:
            if (!self.reorderSelectedCell) {
                return;
            }
            [self.collectionView updateInteractiveMovementTargetPosition:location];
            break;
        case UIGestureRecognizerStateEnded:
            if (!self.reorderSelectedCell) {
                return;
            }
            [self clearReorderSelectedCellAnimated:YES];
            [self.collectionView endInteractiveMovement];
            break;
        default:
            if (!self.reorderSelectedCell) {
                return;
            }
            [self clearReorderSelectedCellAnimated:YES];
            [self.collectionView cancelInteractiveMovement];
            break;
    }
}

- (void)clearReorderSelectedCellAnimated:(BOOL)animated
{
    if (!self.reorderSelectedCell) {
        return;
    }
    [self.reorderSelectedCell setReorderSelected:NO animated:animated];
    self.reorderSelectedCell = nil;
}

- (void)presentEditTaskSheetAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self canMoveTaskAtIndexPath:indexPath]) {
        return;
    }
    MirrorTaskModel *task = self.data[indexPath.item];
    NSMutableArray<UIButton *> *colorButtons = [NSMutableArray new];
    UIAlertController *editAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"edit_task"] message:nil preferredStyle:UIAlertControllerStyleAlert];
    [editAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = task.taskName;
        textField.placeholder = [MirrorLanguage mirror_stringWithKey:@"edit_task"];
        textField.textAlignment = NSTextAlignmentCenter;
    }];
    [editAlert setValue:[self colorSelectionContentViewControllerWithSelectedColor:task.color colorButtons:colorButtons] forKey:@"contentViewController"];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"save"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *newTaskName = editAlert.textFields.firstObject.text;
        BOOL textIsEmpty = !newTaskName || [newTaskName isEqualToString:@""];
        BOOL textIsTheSame = [newTaskName isEqualToString:task.taskName];
        TaskNameExistsType existType = [MirrorStorage taskNameExists:newTaskName];
        if (textIsEmpty) {
            [self showTaskEditErrorWithTitleKey:@"name_field_cannot_be_empty"];
            return;
        }
        if (!textIsTheSame && existType != TaskNameExistsTypeValid) {
            [self showTaskEditErrorWithTitleKey:@"task_cannot_be_duplicated"];
            return;
        }
        MirrorColorType selectedColor = [self selectedColorFromColorButtons:colorButtons fallback:task.color];
        TimeTrackerTaskCollectionViewCell *editedCell = (TimeTrackerTaskCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [editedCell setActionButtonsVisible:NO animated:YES];
        if (!textIsTheSame) {
            [MirrorStorage editTask:task.taskName name:newTaskName];
        }
        if (selectedColor != task.color) {
            [MirrorStorage editTask:newTaskName color:selectedColor];
        }
    }];
    [editAlert addAction:cancelAction];
    [editAlert addAction:saveAction];
    [self presentViewController:editAlert animated:YES completion:nil];
}

- (void)presentMergeTaskPickerAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self canMoveTaskAtIndexPath:indexPath]) {
        return;
    }
    
    MirrorTaskModel *sourceTask = self.data[indexPath.item];
    NSArray<MirrorTaskModel *> *tasks = [MirrorStorage retriveMirrorTasks];
    TaskPickerViewController *taskPicker = [[TaskPickerViewController alloc] initWithTasks:tasks sourceTaskName:sourceTask.taskName completion:^(MirrorTaskModel *task, BOOL shouldPrefixRecordNotes) {
        [self presentMergeTaskAlertWithSourceTask:sourceTask targetTask:task shouldPrefixRecordNotes:shouldPrefixRecordNotes];
    }];
    [self presentViewController:taskPicker animated:YES completion:nil];
}

- (void)presentMergeTaskAlertWithSourceTask:(MirrorTaskModel *)sourceTask targetTask:(MirrorTaskModel *)targetTask shouldPrefixRecordNotes:(BOOL)shouldPrefixRecordNotes
{
    UIAlertController *mergeTaskAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"merge_tasks_?"] message:[MirrorLanguage mirror_stringWithKey:@"merge_task_warning"] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *mergeAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"merge"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [MirrorStorage mergeTask:sourceTask.taskName toTask:targetTask.taskName shouldPrefixRecordNotes:shouldPrefixRecordNotes];
    }];
    [mergeTaskAlert addAction:cancelAction];
    [mergeTaskAlert addAction:mergeAction];
    [self presentViewController:mergeTaskAlert animated:YES completion:nil];
}

- (void)showTaskEditErrorWithTitleKey:(NSString *)titleKey
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:titleKey] message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *understandAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"gotcha"] style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:understandAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSArray<NSNumber *> *)taskColorOptions
{
    return @[@(MirrorColorTypeCellPink), @(MirrorColorTypeCellOrange), @(MirrorColorTypeCellYellow), @(MirrorColorTypeCellGreen), @(MirrorColorTypeCellTeal), @(MirrorColorTypeCellBlue), @(MirrorColorTypeCellPurple), @(MirrorColorTypeCellGray)];
}

- (void)presentAddTaskAlert
{
    MirrorColorType defaultColor = [self randomTaskColor];
    NSMutableArray<UIButton *> *colorButtons = [NSMutableArray new];
    UIAlertController *addAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"create_a_new_task"] message:nil preferredStyle:UIAlertControllerStyleAlert];
    [addAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = [MirrorLanguage mirror_stringWithKey:@"enter_task_title"];
        textField.textAlignment = NSTextAlignmentCenter;
    }];

    [addAlert setValue:[self colorSelectionContentViewControllerWithSelectedColor:defaultColor colorButtons:colorButtons] forKey:@"contentViewController"];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *createAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"create"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *taskName = addAlert.textFields.firstObject.text;
        BOOL textIsEmpty = !taskName || [taskName isEqualToString:@""];
        TaskNameExistsType existType = [MirrorStorage taskNameExists:taskName];
        if (textIsEmpty) {
            [self showTaskEditErrorWithTitleKey:@"name_field_cannot_be_empty"];
            return;
        }
        if (existType != TaskNameExistsTypeValid) {
            [self showTaskEditErrorWithTitleKey:@"task_cannot_be_duplicated"];
            return;
        }
        MirrorColorType selectedColor = [self selectedColorFromColorButtons:colorButtons fallback:defaultColor];
        long createdTime = (long)[[NSDate now] timeIntervalSince1970];
        MirrorTaskModel *task = [[MirrorTaskModel alloc] initWithTitle:taskName createdTime:createdTime colorType:selectedColor isHidden:NO isAddTask:NO];
        [MirrorStorage createTask:task];
    }];
    [addAlert addAction:cancelAction];
    [addAlert addAction:createAction];
    [self presentViewController:addAlert animated:YES completion:nil];
}

- (UIViewController *)colorSelectionContentViewControllerWithSelectedColor:(MirrorColorType)selectedColor colorButtons:(NSMutableArray<UIButton *> *)colorButtons
{
    UIViewController *contentViewController = [UIViewController new];
    contentViewController.preferredContentSize = CGSizeMake(248, 44);
    UIStackView *colorStackView = [UIStackView new];
    colorStackView.axis = UILayoutConstraintAxisHorizontal;
    colorStackView.alignment = UIStackViewAlignmentCenter;
    colorStackView.distribution = UIStackViewDistributionEqualSpacing;
    colorStackView.spacing = 8;
    [contentViewController.view addSubview:colorStackView];
    [colorStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(contentViewController.view);
        make.centerY.equalTo(contentViewController.view);
    }];

    for (NSNumber *colorNumber in [self taskColorOptions]) {
        MirrorColorType color = colorNumber.integerValue;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = color;
        button.backgroundColor = [UIColor mirrorColorNamed:color];
        button.layer.cornerRadius = 12;
        button.layer.borderColor = [UIColor mirrorColorPulsed:color].CGColor;
        button.layer.borderWidth = color == selectedColor ? 3 : 0;
        [button addTarget:self action:@selector(selectTaskColorButton:) forControlEvents:UIControlEventTouchUpInside];
        [colorStackView addArrangedSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(24);
        }];
        [colorButtons addObject:button];
    }
    return contentViewController;
}

- (void)selectTaskColorButton:(UIButton *)sender
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    for (UIView *subview in sender.superview.subviews) {
        if (![subview isKindOfClass:[UIButton class]]) {
            continue;
        }
        UIButton *button = (UIButton *)subview;
        button.layer.borderWidth = button == sender ? 3 : 0;
    }
}

- (MirrorColorType)selectedColorFromColorButtons:(NSArray<UIButton *> *)colorButtons fallback:(MirrorColorType)fallback
{
    for (UIButton *button in colorButtons) {
        if (button.layer.borderWidth > 0) {
            return button.tag;
        }
    }
    return fallback;
}

- (MirrorColorType)randomTaskColor
{
    NSArray<NSNumber *> *colors = [self taskColorOptions];
    return colors[arc4random() % colors.count].integerValue;
}

- (void)presentDeleteTaskAlertAtIndexPath:(NSIndexPath *)indexPath
{
    if (![self canMoveTaskAtIndexPath:indexPath]) {
        return;
    }
    NSString *taskName = self.data[indexPath.item].taskName;
    UIAlertController *deleteTaskAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete_task_?"] message:[MirrorLanguage mirror_stringWithKey:@"delete_task_warning"] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [MirrorStorage deleteTask:taskName];
    }];
    UIAlertAction *mergeAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"merge"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self presentMergeTaskPickerAtIndexPath:indexPath];
    }];
    [deleteTaskAlert addAction:deleteAction];
    [deleteTaskAlert addAction:mergeAction];
    [deleteTaskAlert addAction:cancelAction];
    [self presentViewController:deleteTaskAlert animated:YES completion:nil];
}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)selectedIndexPath
{
    MirrorTaskModel *selectedModel = self.data[selectedIndexPath.item];
    // 点击了[+]
    if (selectedModel.isAddTaskModel) {
        [self presentAddTaskAlert];
        return;
    }
    // 点击了task model
    TimeTrackerTaskCollectionViewCell *selectedCell = (TimeTrackerTaskCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:selectedIndexPath];
    if (self.isEditingTasks) {
        return;
    }
    if ([selectedCell dismissActionButtonsIfNeeded]) {
        return;
    }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    self.selectedCellFrame = selectedCell.frame; // update selected cell frame的时机
    self.selectedTaskColor = [UIColor mirrorColorNamed:selectedModel.color];
    NSString *goingOnTask = [MirrorStorage isGoingOnTask];
    if (goingOnTask.length > 0) {
        if ([goingOnTask isEqualToString:selectedModel.taskName]) {
            [self presentTrackingViewControllerWithTaskName:selectedModel.taskName accurateStartDate:nil animated:YES];
        }
        return;
    }

    NSDate *startDate = [NSDate now];
    if ([self isNowOccupiedByRecord]) {
        [self showCurrentTimeOccupiedAlert];
        return;
    }
    [MirrorStorage startTask:selectedModel.taskName at:startDate];
    [self presentTrackingViewControllerWithTaskName:selectedModel.taskName accurateStartDate:startDate animated:YES];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.isEditingTasks && [self canMoveTaskAtIndexPath:indexPath];
}

- (NSIndexPath *)collectionView:(UICollectionView *)collectionView targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)originalIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath
{
    if (![self canMoveTaskAtIndexPath:proposedIndexPath]) {
        NSInteger lastTaskIndex = MAX(0, (NSInteger)[MirrorStorage retriveMirrorTasks].count - 1);
        return [NSIndexPath indexPathForItem:lastTaskIndex inSection:originalIndexPath.section];
    }
    return proposedIndexPath;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (![self canMoveTaskAtIndexPath:sourceIndexPath] || ![self canMoveTaskAtIndexPath:destinationIndexPath]) {
        [collectionView reloadData];
        return;
    }

    MirrorTaskModel *movedTask = self.data[sourceIndexPath.item];
    [self.data removeObjectAtIndex:sourceIndexPath.item];
    [self.data insertObject:movedTask atIndex:destinationIndexPath.item];

    NSMutableArray<MirrorTaskModel *> *orderedTasks = [NSMutableArray new];
    for (MirrorTaskModel *task in self.data) {
        if (!task.isAddTaskModel) {
            [orderedTasks addObject:task];
        }
    }
    [MirrorStorage reorderTasks:orderedTasks];
}

- (BOOL)isNowOccupiedByRecord
{
    long now = [[NSDate now] timeIntervalSince1970];
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    for (MirrorRecordModel *record in records) {
        if (record.endTime <= record.startTime) {
            continue;
        }
        if (record.startTime > now) {
            break;
        }
        if (record.startTime <= now && now < record.endTime) {
            return YES;
        }
    }
    return NO;
}

- (void)showCurrentTimeOccupiedAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:[MirrorLanguage mirror_stringWithKey:@"current_time_occupied_cannot_start_counting"]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentGoingOnTaskIfNeeded
{
    if (self.presentedViewController) {
        return;
    }

    NSString *goingOnTask = [MirrorStorage isGoingOnTask];
    if (goingOnTask.length == 0) {
        return;
    }
    NSDictionary *autoFinishInfo = [MirrorStorage finishGoingOnTaskIfExceededMaximumEndDate];
    if (autoFinishInfo) {
        [self reloadData];
        [self showAutoFinishedCountingAlert:autoFinishInfo];
        return;
    }

    NSInteger taskIndex = NSNotFound;
    for (NSInteger index = 0; index < self.data.count; index++) {
        MirrorTaskModel *task = self.data[index];
        if (!task.isAddTaskModel && [task.taskName isEqualToString:goingOnTask]) {
            taskIndex = index;
            self.selectedTaskColor = [UIColor mirrorColorNamed:task.color];
            break;
        }
    }
    if (taskIndex == NSNotFound) {
        return;
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:taskIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
    [self.collectionView layoutIfNeeded];
    UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:indexPath];
    if (cell) {
        self.selectedCellFrame = cell.frame;
    } else {
        UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
        self.selectedCellFrame = attributes ? attributes.frame : CGRectZero;
    }

    [self presentTrackingViewControllerWithTaskName:goingOnTask accurateStartDate:nil animated:NO];
}

- (void)showAutoFinishedCountingAlert:(NSDictionary *)autoFinishInfo
{
    NSString *taskName = autoFinishInfo[@"taskName"] ?: @"";
    BOOL didSaveRecord = [autoFinishInfo[@"didSaveRecord"] boolValue];
    NSString *messageKey = didSaveRecord ? @"counting_auto_stopped_due_to_next_record" : @"counting_auto_cancelled_due_to_next_record";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:[MirrorLanguage mirror_stringWithKey:messageKey with1Placeholder:taskName]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)presentTrackingViewControllerWithTaskName:(NSString *)taskName accurateStartDate:(NSDate *)accurateStartDate animated:(BOOL)animated
{
    TimeTrackingViewController *timeTrackingVC = [[TimeTrackingViewController alloc] initWithTaskName:taskName accurateStartDate:accurateStartDate];
    timeTrackingVC.transitioningDelegate = self;
    timeTrackingVC.modalPresentationStyle = UIModalPresentationCustom;
    timeTrackingVC.cellFrame = CGRectMake(self.collectionView.frame.origin.x + self.selectedCellFrame.origin.x, self.collectionView.frame.origin.y + self.selectedCellFrame.origin.y - self.collectionView.contentOffset.y, self.selectedCellFrame.size.width, self.selectedCellFrame.size.height);
    [self presentViewController:timeTrackingVC animated:animated completion:nil];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MirrorTaskModel *taskModel = self.data[indexPath.item];
    if (taskModel.isAddTaskModel) {
        TimeTrackerAddTaskCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[TimeTrackerAddTaskCollectionViewCell identifier] forIndexPath:indexPath];
        [cell setupAddTaskCell];
        return cell;
    } else {
        TimeTrackerTaskCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[TimeTrackerTaskCollectionViewCell identifier] forIndexPath:indexPath];
        cell.delegate = self;
        [cell configWithTaskname:taskModel.taskName];
        [cell setEditingModeEnabled:self.isEditingTasks];
        return cell;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.data.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake((kScreenWidth - kCollectionViewPadding - kCollectionViewPadding -kCellSpacing)/2, kScreenHeight/8);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return kCellSpacing;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return kCellSpacing;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader) {
        UICollectionViewCell *header;
        header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
        return header;
    } else {
        HintFooter *footer;
        footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer" forIndexPath:indexPath];
        [footer config];
        return footer;
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake(kScreenWidth, 5); // 给collectionview一个小小的header，让第一行cell的shadow的过度更自然（没有截断的效果）
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    return CGSizeMake(kScreenWidth, 30*kHeightRatio); // 起到提示效果
}

#pragma mark - TimeTrackerTaskCollectionViewCellDelegate

- (void)timeTrackerTaskCollectionViewCellDidTapEdit:(TimeTrackerTaskCollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [self presentEditTaskSheetAtIndexPath:indexPath];
}

- (void)timeTrackerTaskCollectionViewCellDidTapDelete:(TimeTrackerTaskCollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [self presentDeleteTaskAlertAtIndexPath:indexPath];
}

#pragma mark - Getters

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.view.backgroundColor;
        [_collectionView addGestureRecognizer:self.taskReorderLongPressRecognizer];
        
        [_collectionView registerClass:[TimeTrackerTaskCollectionViewCell class] forCellWithReuseIdentifier:[TimeTrackerTaskCollectionViewCell identifier]];
        [_collectionView registerClass:[TimeTrackerAddTaskCollectionViewCell class] forCellWithReuseIdentifier:[TimeTrackerAddTaskCollectionViewCell identifier]];
        [_collectionView registerClass:[UICollectionViewCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
        [_collectionView registerClass:[HintFooter class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    }
    return _collectionView;
}

- (UITapGestureRecognizer *)editingDismissTapRecognizer
{
    if (!_editingDismissTapRecognizer) {
        _editingDismissTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissEditingTasksFromBackgroundTap:)];
        _editingDismissTapRecognizer.cancelsTouchesInView = YES;
        _editingDismissTapRecognizer.delegate = self;
        _editingDismissTapRecognizer.enabled = NO;
    }
    return _editingDismissTapRecognizer;
}

- (UILongPressGestureRecognizer *)taskReorderLongPressRecognizer
{
    if (!_taskReorderLongPressRecognizer) {
        _taskReorderLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTaskReorderLongPress:)];
        _taskReorderLongPressRecognizer.minimumPressDuration = 0.5;
    }
    return _taskReorderLongPressRecognizer;
}

- (UIButton *)settingsButton
{
    if (!_settingsButton) {
        _settingsButton = [UIButton new];
        [self updateSettingsButtonIcon];
        _settingsButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight];
        [_settingsButton addTarget:self action:@selector(showLanguagePicker) forControlEvents:UIControlEventTouchUpInside];
    }
    return _settingsButton;
}

- (UIButton *)supportButton
{
    if (!_supportButton) {
        _supportButton = [UIButton new];
        _supportButton.accessibilityIdentifier = kNaviIconUsesCustomConfigurationIdentifier;
        [self updateSupportButtonIcon];
        _supportButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeTabbarIconTextHightlight];
        [_supportButton addTarget:self action:@selector(showSupportAlert) forControlEvents:UIControlEventTouchUpInside];
    }
    return _supportButton;
}

- (NSMutableArray<MirrorTaskModel *> *)data
{
    if (!_data) {
        _data = [MirrorStorage tasksWithAddNew];
    }
    return _data;
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    CellAnimation *animation = [CellAnimation new];
    animation.isPresent = YES;
    animation.cellColor = self.selectedTaskColor;
    animation.cellFrame = CGRectMake(self.collectionView.frame.origin.x + self.selectedCellFrame.origin.x, self.collectionView.frame.origin.y -  self.collectionView.contentOffset.y + self.selectedCellFrame.origin.y, self.selectedCellFrame.size.width, self.selectedCellFrame.size.height);
    return animation;
}

@end
