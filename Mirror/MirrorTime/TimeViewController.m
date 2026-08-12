//
//  TimeTrackerViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import "TimeViewController.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "TimeTrackerTaskCollectionViewCell.h"
#import "TimeTrackerAddTaskCollectionViewCell.h"
#import "MirrorMacro.h"
#import "MirrorTabsManager.h"
#import "MirrorNaviManager.h"
#import "TimeTrackingViewController.h"
#import "MirrorStorage.h"
#import "MirrorTool.h"
#import "MirrorSettings.h"
#import "SettingsViewController.h"
#import "RecordsTimelineViewController.h"
#import "LeftAnimation.h"
#import "CellAnimation.h"
#import "MirrorLanguage.h"
#import "HintFooter.h"
#import "TaskPickerViewController.h"

#import "Mirror-Swift.h"

#define kCellSpacing (16 * kHeightRatio)// cell之间的上下间距
#define kCollectionViewPadding (20 * kWidthRatio) // 左右留白

@interface TimeViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, TimeTrackerTaskCollectionViewCellDelegate, UIViewControllerTransitioningDelegate>

@property (nonatomic, assign) BOOL isLoaded;
// Navibar
@property (nonatomic, strong) UIButton *settingsButton;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactiveTransition;
// Data source
@property (nonatomic, strong) NSMutableArray<MirrorTaskModel *> *data;
// Mark
@property (nonatomic, assign) CGRect selectedCellFrame; // cell.x, cell.y, cell.width, cell.height
@property (nonatomic, strong) UIColor *selectedTaskColor;
@property (nonatomic, strong) NSIndexPath *movingIndexPath;
@property (nonatomic, assign) CGPoint longPressStartPoint;
@property (nonatomic, assign) BOOL didMoveLongPressedTask;
// UI
@property (nonatomic, strong) UICollectionView *collectionView;

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
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.collectionView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
    }];
    [self presentGoingOnTaskIfNeeded];
}

- (void)restartVC
{
    if (!_isLoaded) return;
    // update navibar
    [[MirrorTabsManager sharedInstance] updateTimeTabItemWithTabController:self.tabBarController];
    if (self.tabBarController.selectedIndex == 0) {
        [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:@"" leftButton:self.settingsButton rightButton:nil];
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
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kCollectionViewPadding);
        make.right.mas_equalTo(self.view).offset(-kCollectionViewPadding);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.bottom.mas_equalTo(self.view).offset(-self.tabBarController.tabBar.frame.size.height);
    }];
    UIScreenEdgePanGestureRecognizer *edgeRecognizer = [UIScreenEdgePanGestureRecognizer new];
    edgeRecognizer.edges = UIRectEdgeLeft;
    [edgeRecognizer addTarget:self action:@selector(edgeGestureRecognizerAction:)];
    [self.view addGestureRecognizer:edgeRecognizer];
}

#pragma mark - Actions

- (void)goToSettings
{
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    SettingsViewController * settingsVC = [[SettingsViewController alloc] init];
    settingsVC.transitioningDelegate = self;
    settingsVC.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:settingsVC animated:YES completion:nil];
}

- (void)longPressTask:(UILongPressGestureRecognizer *)longPress
{
    CGPoint location = [longPress locationInView:self.collectionView];
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan:
        {
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
            if (![self canMoveTaskAtIndexPath:indexPath]) {
                return;
            }
            self.movingIndexPath = indexPath;
            self.longPressStartPoint = location;
            self.didMoveLongPressedTask = NO;
            UICollectionViewCell *selectedCell = [self.collectionView cellForItemAtIndexPath:indexPath];
            selectedCell.layer.shadowColor = [UIColor mirrorColorNamed:MirrorColorTypeShadow].CGColor;
            selectedCell.layer.shadowRadius = 4;
            selectedCell.layer.shadowOpacity = 1;
            [self.collectionView beginInteractiveMovementForItemAtIndexPath:indexPath];
        }
            break;
        case UIGestureRecognizerStateChanged:
            if (self.movingIndexPath == nil) {
                return;
            }
            CGFloat xOffset = location.x - self.longPressStartPoint.x;
            CGFloat yOffset = location.y - self.longPressStartPoint.y;
            if (sqrt(xOffset * xOffset + yOffset * yOffset) > 8) {
                self.didMoveLongPressedTask = YES;
            }
            [self.collectionView updateInteractiveMovementTargetPosition:location];
            break;
        case UIGestureRecognizerStateEnded:
            if (self.movingIndexPath == nil) {
                return;
            }
            [self resetLongPressedCellShadow];
            if (self.didMoveLongPressedTask) {
                [self.collectionView endInteractiveMovement];
            } else {
                [self.collectionView cancelInteractiveMovement];
            }
            self.movingIndexPath = nil;
            self.didMoveLongPressedTask = NO;
            break;
        default:
            [self resetLongPressedCellShadow];
            [self.collectionView cancelInteractiveMovement];
            self.movingIndexPath = nil;
            self.didMoveLongPressedTask = NO;
            break;
    }
}

- (BOOL)canMoveTaskAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == nil || indexPath.item >= self.data.count) {
        return NO;
    }
    return !self.data[indexPath.item].isAddTaskModel;
}

- (void)resetLongPressedCellShadow
{
    UICollectionViewCell *selectedCell = [self.collectionView cellForItemAtIndexPath:self.movingIndexPath];
    selectedCell.layer.shadowColor = [UIColor clearColor].CGColor;
    selectedCell.layer.shadowRadius = 0;
    selectedCell.layer.shadowOpacity = 0;
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
    TaskPickerViewController *taskPicker = [[TaskPickerViewController alloc] initWithTasks:tasks sourceTaskName:sourceTask.taskName completion:^(MirrorTaskModel *task) {
        [self presentMergeTaskAlertWithSourceTask:sourceTask targetTask:task];
    }];
    [self presentViewController:taskPicker animated:YES completion:nil];
}

- (void)presentMergeTaskAlertWithSourceTask:(MirrorTaskModel *)sourceTask targetTask:(MirrorTaskModel *)targetTask
{
    UIAlertController *mergeTaskAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"merge_tasks_?"] message:[MirrorLanguage mirror_stringWithKey:@"merge_task_warning"] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];
    UIAlertAction *mergeAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"merge"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [MirrorStorage mergeTask:sourceTask.taskName toTask:targetTask.taskName];
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
    [deleteTaskAlert addAction:cancelAction];
    [deleteTaskAlert addAction:deleteAction];
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
    if ([selectedCell dismissActionButtonsIfNeeded]) {
        return;
    }
    self.selectedCellFrame = selectedCell.frame; // update selected cell frame的时机
    self.selectedTaskColor = [UIColor mirrorColorNamed:selectedModel.color];
    NSString *goingOnTask = [MirrorStorage isGoingOnTask];
    if (goingOnTask.length > 0) {
        if ([goingOnTask isEqualToString:selectedModel.taskName]) {
            [self presentTrackingViewControllerWithTaskName:selectedModel.taskName accurateStartDate:nil animated:YES];
        } else {
            [self showStartNowUnavailableAlert];
        }
        return;
    }

    if (![self canStartTaskNow]) {
        [self showStartNowUnavailableAlert];
        return;
    }

    NSDate *startDate = [NSDate now];
    [MirrorStorage startTask:selectedModel.taskName at:startDate];
    [self presentTrackingViewControllerWithTaskName:selectedModel.taskName accurateStartDate:startDate animated:YES];
}

- (BOOL)canStartTaskNow
{
    return [self occupiedRecords].count == 0;
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

- (void)showStartNowUnavailableAlert
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"now_is_occupied"] message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"check_occupied_records"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showOccupiedRecords];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showOccupiedRecords
{
    NSMutableArray<MirrorRecordModel *> *occupiedRecords = [self occupiedRecords];
    RecordsTimelineViewController *recordsVC = [[RecordsTimelineViewController alloc] initWithRecords:occupiedRecords titleKey:@"occupied_records"];
    [self.navigationController pushViewController:recordsVC animated:YES];
}

- (NSMutableArray<MirrorRecordModel *> *)occupiedRecords
{
    NSMutableArray<MirrorRecordModel *> *occupiedRecords = [NSMutableArray new];
    NSMutableArray<MirrorRecordModel *> *records = [MirrorStorage retriveMirrorRecords];
    long now = [[NSDate now] timeIntervalSince1970];
    for (MirrorRecordModel *record in records) {
        if (record.endTime == 0 || record.endTime > now) {
            [occupiedRecords addObject:record];
        }
    }
    return occupiedRecords;
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

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self canMoveTaskAtIndexPath:indexPath];
}

- (NSIndexPath *)collectionView:(UICollectionView *)collectionView targetIndexPathForMoveFromItemAtIndexPath:(NSIndexPath *)originalIndexPath toProposedIndexPath:(NSIndexPath *)proposedIndexPath
{
    if ([self canMoveTaskAtIndexPath:proposedIndexPath]) {
        return proposedIndexPath;
    }
    NSInteger lastTaskIndex = MAX(0, self.data.count - 2);
    return [NSIndexPath indexPathForItem:lastTaskIndex inSection:0];
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    if (![self canMoveTaskAtIndexPath:sourceIndexPath]) {
        return;
    }
    NSInteger destinationItem = MIN(destinationIndexPath.item, self.data.count - 2);
    NSMutableArray<MirrorTaskModel *> *allTasks = [MirrorStorage retriveMirrorTasks];
    MirrorTaskModel *selectedTask = allTasks[sourceIndexPath.item];
    [allTasks removeObjectAtIndex:sourceIndexPath.item];
    [allTasks insertObject:selectedTask atIndex:destinationItem];
    [MirrorStorage reorderTasks:allTasks];
    self.data = [MirrorStorage tasksWithAddNew];
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

- (void)timeTrackerTaskCollectionViewCellDidTapMerge:(TimeTrackerTaskCollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    [self presentMergeTaskPickerAtIndexPath:indexPath];
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
        
        [_collectionView registerClass:[TimeTrackerTaskCollectionViewCell class] forCellWithReuseIdentifier:[TimeTrackerTaskCollectionViewCell identifier]];
        [_collectionView registerClass:[TimeTrackerAddTaskCollectionViewCell class] forCellWithReuseIdentifier:[TimeTrackerAddTaskCollectionViewCell identifier]];
        [_collectionView registerClass:[UICollectionViewCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
        [_collectionView registerClass:[HintFooter class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressTask:)];
        [_collectionView addGestureRecognizer:longPress];
    }
    return _collectionView;
}

- (UIButton *)settingsButton
{
    if (!_settingsButton) {
        _settingsButton = [UIButton new];
        UIImage *iconImage = [[UIImage systemImageNamed:@"line.horizontal.3"]  imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [_settingsButton setImage:[iconImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [_settingsButton addTarget:self action:@selector(goToSettings) forControlEvents:UIControlEventTouchUpInside];
    }
    return _settingsButton;
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
    if ([presented isKindOfClass:SettingsViewController.class]) { // Settings
        LeftAnimation *animation = [LeftAnimation new];
        animation.isPresent = YES;
        return animation;
    } else { // Time editing / Time tracking
        CellAnimation *animation = [CellAnimation new];
        animation.isPresent = YES;
        animation.cellColor = self.selectedTaskColor;
        animation.cellFrame = CGRectMake(self.collectionView.frame.origin.x + self.selectedCellFrame.origin.x, self.collectionView.frame.origin.y -  self.collectionView.contentOffset.y + self.selectedCellFrame.origin.y, self.selectedCellFrame.size.width, self.selectedCellFrame.size.height);
        return animation;
    }
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactiveTransition;
}

// 从左边缘滑动唤起settings
- (void)edgeGestureRecognizerAction:(UIScreenEdgePanGestureRecognizer *)pan
{
    //产生百分比
    CGFloat sheetWidth = self.view.frame.size.width * kLeftSheetRatio;
    CGFloat process = [pan translationInView:self.view].x / sheetWidth;
    
    process = MIN(1.0,(MAX(0.0, process)));
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.interactiveTransition = [UIPercentDrivenInteractiveTransition new];
        // 触发present转场动画
        [self goToSettings];
    }else if (pan.state == UIGestureRecognizerStateChanged){
        [self.interactiveTransition updateInteractiveTransition:process];
    }else if (pan.state == UIGestureRecognizerStateEnded
              || pan.state == UIGestureRecognizerStateCancelled){
        if (process > 0.3) {
            [ self.interactiveTransition finishInteractiveTransition];
        }else{
            [ self.interactiveTransition cancelInteractiveTransition];
        }
        self.interactiveTransition = nil;
    }
}


@end
