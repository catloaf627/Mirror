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
#import "UIImage+MirrorSymbol.h"
#import "SpecialDayEditViewController.h"

static CGFloat const kSpecialDaysPadding = 20;
static CGFloat const kSpecialDaysRowHeight = 58;
static CGFloat const kSpecialDaysTimelineIconSize = 26;
static NSString * const kSpecialDayFallbackIconName = @"star.fill";
static NSString * const kSpecialDayCellIdentifier = @"SpecialDayCollectionViewCell";

#define kSpecialDaysTimelineX (kScreenWidth * 0.33)

@interface SpecialDayCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) UIView *topLine;
@property (nonatomic, strong) UIView *bottomLine;
@property (nonatomic, strong) UIButton *iconButton;
@property (nonatomic, strong) UILabel *leftDateLabel;
@property (nonatomic, strong) UILabel *leftYearLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) UIEditMenuInteraction *editMenuInteraction API_AVAILABLE(ios(16.0));

- (void)configureWithDay:(MirrorDayModel *)day timestamp:(long)timestamp isFirst:(BOOL)isFirst isLast:(BOOL)isLast;
- (void)installInteractionsWithTarget:(id<UIEditMenuInteractionDelegate>)target;
- (void)setShowsSelectionBorder:(BOOL)showsSelectionBorder color:(UIColor *)color;

@end

@implementation SpecialDayCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.contentView.backgroundColor = UIColor.clearColor;
        [self setupUI];
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.contentView.layer.borderWidth = 0;
    self.contentView.layer.borderColor = nil;
    self.contentView.backgroundColor = UIColor.clearColor;
    [self.contentView.layer removeAnimationForKey:@"selectedRowShake"];
}

- (void)setupUI
{
    self.topLine = [UIView new];
    [self.contentView addSubview:self.topLine];
    [self.topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.contentView.mas_left).offset(kSpecialDaysPadding + kSpecialDaysTimelineX);
        make.top.mas_equalTo(self.contentView);
        make.width.mas_equalTo(2);
        make.bottom.mas_equalTo(self.contentView.mas_centerY).offset(-kSpecialDaysTimelineIconSize / 2);
    }];

    self.bottomLine = [UIView new];
    [self.contentView addSubview:self.bottomLine];
    [self.bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.topLine);
        make.top.mas_equalTo(self.contentView.mas_centerY).offset(kSpecialDaysTimelineIconSize / 2);
        make.width.mas_equalTo(2);
        make.bottom.mas_equalTo(self.contentView);
    }];

    self.iconButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.iconButton.userInteractionEnabled = NO;
    self.iconButton.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.iconButton];
    [self.iconButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.topLine);
        make.centerY.mas_equalTo(self.contentView);
        make.width.height.mas_equalTo(kSpecialDaysTimelineIconSize);
    }];

    self.leftDateLabel = [UILabel new];
    self.leftDateLabel.font = [UIFont mirrorHighlightFont];
    self.leftDateLabel.alpha = 0.7;
    self.leftDateLabel.textAlignment = NSTextAlignmentRight;
    self.leftDateLabel.adjustsFontSizeToFitWidth = YES;
    self.leftDateLabel.minimumScaleFactor = 0.7;
    [self.contentView addSubview:self.leftDateLabel];
    [self.leftDateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.contentView).offset(4 * kWidthRatio);
        make.right.mas_equalTo(self.iconButton.mas_left).offset(-10 * kWidthRatio);
        make.centerY.mas_equalTo(self.iconButton.mas_centerY).offset(-6 * kHeightRatio);
    }];

    self.leftYearLabel = [UILabel new];
    self.leftYearLabel.font = [UIFont mirrorHintFont];
    self.leftYearLabel.alpha = 0.7;
    self.leftYearLabel.textAlignment = NSTextAlignmentRight;
    self.leftYearLabel.adjustsFontSizeToFitWidth = YES;
    self.leftYearLabel.minimumScaleFactor = 0.7;
    [self.contentView addSubview:self.leftYearLabel];
    [self.leftYearLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.leftDateLabel);
        make.top.mas_equalTo(self.leftDateLabel.mas_bottom).offset(4 * kHeightRatio);
        make.bottom.mas_lessThanOrEqualTo(self.contentView).offset(-10 * kHeightRatio);
    }];

    self.infoLabel = [UILabel new];
    self.infoLabel.font = [UIFont mirrorLabelFont];
    self.infoLabel.numberOfLines = 0;
    [self.contentView addSubview:self.infoLabel];
    [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.iconButton.mas_right).offset(12 * kWidthRatio);
        make.right.mas_equalTo(self.contentView).offset(-kSpecialDaysPadding);
        make.top.mas_greaterThanOrEqualTo(self.contentView).offset(12);
        make.centerY.mas_equalTo(self.iconButton);
        make.bottom.mas_lessThanOrEqualTo(self.contentView).offset(-12);
    }];
}

- (void)configureWithDay:(MirrorDayModel *)day timestamp:(long)timestamp isFirst:(BOOL)isFirst isLast:(BOOL)isLast
{
    UIColor *dayColor = [UIColor mirrorSystemColorNamed:day.color];
    UIColor *lineColor = [dayColor colorWithAlphaComponent:0.38];

    self.topLine.backgroundColor = lineColor;
    self.topLine.alpha = isFirst ? 0 : 1;
    self.bottomLine.backgroundColor = lineColor;
    self.bottomLine.alpha = isLast ? 0 : 1;
    self.iconButton.tintColor = dayColor;
    [self.iconButton setImage:[UIImage mirror_systemImageNamed:day.icon fallbackName:kSpecialDayFallbackIconName] forState:UIControlStateNormal];
    self.leftDateLabel.textColor = dayColor;
    self.leftDateLabel.text = [MirrorTool timelineMonthDayTextForTimestamp:timestamp];
    self.leftYearLabel.textColor = dayColor;
    self.leftYearLabel.text = [MirrorTool timelineYearTextForTimestamp:timestamp];
    self.infoLabel.textColor = dayColor;
    self.infoLabel.text = day.info.length > 0 ? day.info : day.dateStr;
}

- (void)installInteractionsWithTarget:(id<UIEditMenuInteractionDelegate>)target
{
    if (!self.tapRecognizer) {
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:target action:@selector(specialDayRowTapped:)];
        [self.contentView addGestureRecognizer:self.tapRecognizer];
    }
    if (!self.longPressRecognizer) {
        self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:target action:@selector(showSpecialDayEditMenu:)];
        [self.tapRecognizer requireGestureRecognizerToFail:self.longPressRecognizer];
        [self.contentView addGestureRecognizer:self.longPressRecognizer];
    }
    if (!self.editMenuInteraction) {
        self.editMenuInteraction = [[UIEditMenuInteraction alloc] initWithDelegate:target];
        [self.contentView addInteraction:self.editMenuInteraction];
    }
}

- (void)setShowsSelectionBorder:(BOOL)showsSelectionBorder color:(UIColor *)color
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.contentView.layer.cornerRadius = 8;
    self.contentView.layer.masksToBounds = YES;
    self.contentView.layer.borderWidth = showsSelectionBorder ? 1.5 : 0;
    self.contentView.layer.borderColor = showsSelectionBorder ? color.CGColor : nil;
    [CATransaction commit];
}

@end

@interface SpecialDaysViewController () <UIEditMenuInteractionDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) NSMutableArray<MirrorDayModel *> *days;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, copy) NSString *focusDateStr;
@property (nonatomic, assign) BOOL didFocusInitialDate;
@property (nonatomic, assign) NSInteger selectedDayIndex;
@property (nonatomic, assign) BOOL isSpecialDayEditMenuVisible;
@property (nonatomic, assign) BOOL shouldSuppressNextSpecialDayEditMenu;
@property (nonatomic, weak) UIView *borderedSpecialDayRow;
@property (nonatomic, assign) BOOL shouldSuppressNextSpecialDayReload;
@property (nonatomic, weak) UIEditMenuInteraction *visibleSpecialDayEditMenuInteraction API_AVAILABLE(ios(16.0));

@end

@implementation SpecialDaysViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _selectedDayIndex = NSNotFound;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVisibleUI) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVisibleUI) name:MirrorSwitchLanguageNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVisibleUI) name:MirrorSignificantTimeChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorImportDataNotificaiton object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorDayCreateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorDayDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorDayEditNotification object:nil];
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
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];

    [self.view addSubview:self.emptyLabel];
    [self.emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self.view);
        make.left.right.mas_equalTo(self.view).inset(kSpecialDaysPadding);
    }];
}

- (void)reloadData
{
    if (self.shouldSuppressNextSpecialDayReload) {
        self.shouldSuppressNextSpecialDayReload = NO;
        return;
    }
    self.days = [MirrorStorage retriveMirrorDays];
    [self sortSpecialDays:self.days];
    self.emptyLabel.hidden = self.days.count > 0;
    [self refreshVisibleUI];
}

- (void)refreshVisibleUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.addButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    [self updateNavigationItemIfNeeded];
    self.emptyLabel.text = [MirrorLanguage mirror_stringWithKey:@"no_special_days"];
    self.emptyLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    self.emptyLabel.hidden = self.days.count > 0;
    [self.collectionView reloadData];
}

- (void)updateNavigationItemIfNeeded
{
    if (self.navigationController.topViewController != self) {
        return;
    }
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:[MirrorLanguage mirror_stringWithKey:@"special_days"] leftButton:nil rightButton:self.addButton];
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
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:focusIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.32 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView *focusRow = [self rowViewForIndex:focusIndex];
        if (focusRow && focusIndex < self.days.count) {
            [self highlightRow:focusRow withDay:self.days[focusIndex]];
        }
    });
}

- (NSInteger)indexOfSpecialDayWithDateStr:(NSString *)dateStr
{
    return [self indexOfSpecialDayWithDateStr:dateStr inDays:self.days];
}

- (NSInteger)indexOfSpecialDayWithDateStr:(NSString *)dateStr inDays:(NSArray<MirrorDayModel *> *)days
{
    for (NSInteger index = 0; index < days.count; index++) {
        MirrorDayModel *day = days[index];
        if ([day.dateStr isEqualToString:dateStr]) {
            return index;
        }
    }
    return NSNotFound;
}

- (UIView *)rowViewForIndex:(NSInteger)index
{
    if (index < 0 || index >= self.days.count) {
        return nil;
    }
    SpecialDayCollectionViewCell *cell = (SpecialDayCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return [cell isKindOfClass:[SpecialDayCollectionViewCell class]] ? cell.contentView : nil;
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.days.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    SpecialDayCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kSpecialDayCellIdentifier forIndexPath:indexPath];
    if (indexPath.item >= self.days.count) {
        return cell;
    }

    MirrorDayModel *day = self.days[indexPath.item];
    [cell configureWithDay:day timestamp:[self timestampFromDay:day] isFirst:indexPath.item == 0 isLast:indexPath.item == self.days.count - 1];
    [cell setShowsSelectionBorder:indexPath.item == self.selectedDayIndex color:[UIColor mirrorSystemColorNamed:day.color]];
    [cell installInteractionsWithTarget:self];

    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(CGRectGetWidth(collectionView.bounds), kSpecialDaysRowHeight);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(kSpecialDaysPadding, 0, kSpecialDaysPadding, 0);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (void)specialDayRowTapped:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    UIView *row = recognizer.view;
    NSIndexPath *indexPath = [self indexPathForSpecialDayRowView:row];
    if (!indexPath) {
        return;
    }
    NSInteger index = indexPath.item;
    if (index < 0 || index >= self.days.count) {
        return;
    }

    NSInteger previousDayIndex = self.selectedDayIndex;
    self.selectedDayIndex = index;
    [self reloadSelectionFromPreviousDayIndex:previousDayIndex currentDayIndex:self.selectedDayIndex];
}

- (NSIndexPath *)indexPathForSpecialDayRowView:(UIView *)view
{
    UIView *candidate = view;
    while (candidate && candidate != self.collectionView) {
        if ([candidate isKindOfClass:[UICollectionViewCell class]]) {
            return [self.collectionView indexPathForCell:(UICollectionViewCell *)candidate];
        }
        candidate = candidate.superview;
    }
    
    CGPoint point = [view convertPoint:CGPointMake(CGRectGetMidX(view.bounds), CGRectGetMidY(view.bounds)) toView:self.collectionView];
    return [self.collectionView indexPathForItemAtPoint:point];
}

- (void)reloadSelectionFromPreviousDayIndex:(NSInteger)previousDayIndex currentDayIndex:(NSInteger)currentDayIndex
{
    if (previousDayIndex >= 0 && previousDayIndex < self.days.count && previousDayIndex != currentDayIndex) {
        NSIndexPath *previousIndexPath = [NSIndexPath indexPathForItem:previousDayIndex inSection:0];
        SpecialDayCollectionViewCell *previousCell = (SpecialDayCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:previousIndexPath];
        [previousCell setShowsSelectionBorder:NO color:nil];
    }

    if (currentDayIndex >= 0 && currentDayIndex < self.days.count) {
        NSIndexPath *currentIndexPath = [NSIndexPath indexPathForItem:currentDayIndex inSection:0];
        SpecialDayCollectionViewCell *currentCell = (SpecialDayCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:currentIndexPath];
        UIColor *borderColor = [UIColor mirrorSystemColorNamed:self.days[currentDayIndex].color];
        [currentCell setShowsSelectionBorder:YES color:borderColor];
        self.borderedSpecialDayRow = currentCell.contentView;
    }
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
    
    UIView *view = recognizer.view;
    NSIndexPath *indexPath = [self indexPathForSpecialDayRowView:view];
    if (!indexPath) {
        return;
    }
    NSInteger index = indexPath.item;
    if (index < 0 || index >= self.days.count) {
        return;
    }

    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback impactOccurred];

    NSInteger previousDayIndex = self.selectedDayIndex;
    self.selectedDayIndex = index;
    [self reloadSelectionFromPreviousDayIndex:previousDayIndex currentDayIndex:self.selectedDayIndex];
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

    MirrorDayModel *editingDay = self.days[index];
    NSString *originalDateStr = [editingDay.dateStr copy];
    __weak typeof(self) weakSelf = self;
    SpecialDayEditViewController *editViewController = [[SpecialDayEditViewController alloc] initWithDay:editingDay validation:^BOOL(MirrorDayModel *day, NSString **errorTitleKey) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return NO;
        }
        NSMutableArray<MirrorDayModel *> *days = [MirrorStorage retriveMirrorDays];
        [self sortSpecialDays:days];
        NSInteger currentIndex = [self indexOfSpecialDayWithDateStr:originalDateStr inDays:days];
        if (currentIndex == NSNotFound) {
            if (errorTitleKey) {
                *errorTitleKey = @"no_data";
            }
            return NO;
        }
        if ([self specialDayExistsForDateStr:day.dateStr inDays:days excludingIndex:currentIndex]) {
            if (errorTitleKey) {
                *errorTitleKey = @"special_day_cannot_be_duplicated";
            }
            return NO;
        }
        return YES;
    } completion:^(MirrorDayModel *day) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        NSMutableArray<MirrorDayModel *> *days = [MirrorStorage retriveMirrorDays];
        [self sortSpecialDays:days];
        NSInteger currentIndex = [self indexOfSpecialDayWithDateStr:originalDateStr inDays:days];
        if (currentIndex == NSNotFound) {
            [self reloadData];
            return;
        }
        [MirrorStorage editMirrorDay:day atIndex:currentIndex];
    }];
    [self presentSpecialDayEditViewController:editViewController];
}

- (void)deleteSpecialDayAtIndex:(NSInteger)index
{
    if (index < 0 || index >= self.days.count) {
        return;
    }

    if (self.selectedDayIndex == index) {
        self.selectedDayIndex = NSNotFound;
    } else if (self.selectedDayIndex > index) {
        self.selectedDayIndex -= 1;
    }
    self.borderedSpecialDayRow = nil;
    self.shouldSuppressNextSpecialDayReload = YES;
    [self.days removeObjectAtIndex:index];
    [MirrorStorage deleteMirrorDayAtIndex:index];
    self.emptyLabel.hidden = self.days.count > 0;

    NSIndexPath *deletedIndexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:@[deletedIndexPath]];
    } completion:^(BOOL finished) {
        NSMutableArray<NSIndexPath *> *reloadIndexPaths = [NSMutableArray new];
        if (index - 1 >= 0) {
            [reloadIndexPaths addObject:[NSIndexPath indexPathForItem:index - 1 inSection:0]];
        }
        if (index < self.days.count) {
            [reloadIndexPaths addObject:[NSIndexPath indexPathForItem:index inSection:0]];
        }
        if (reloadIndexPaths.count > 0) {
            [self.collectionView reloadItemsAtIndexPaths:reloadIndexPaths];
        }
    }];
}

- (void)showAddDialog
{
    __weak typeof(self) weakSelf = self;
    SpecialDayEditViewController *editViewController = [[SpecialDayEditViewController alloc] initWithDay:nil validation:^BOOL(MirrorDayModel *day, NSString **errorTitleKey) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return NO;
        }
        NSMutableArray<MirrorDayModel *> *days = [MirrorStorage retriveMirrorDays];
        [self sortSpecialDays:days];
        if ([self specialDayExistsForDateStr:day.dateStr inDays:days]) {
            if (errorTitleKey) {
                *errorTitleKey = @"special_day_cannot_be_duplicated";
            }
            return NO;
        }
        return YES;
    } completion:^(MirrorDayModel *day) {
        [MirrorStorage createMirrorDay:day];
    }];
    [self presentSpecialDayEditViewController:editViewController];
}

- (void)presentSpecialDayEditViewController:(SpecialDayEditViewController *)editViewController
{
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:editViewController];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self presentViewController:navigationController animated:YES completion:nil];
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

- (void)sortSpecialDays:(NSMutableArray<MirrorDayModel *> *)days
{
    [days sortUsingComparator:^NSComparisonResult(MirrorDayModel *day1, MirrorDayModel *day2) {
        return [day1.dateStr compare:day2.dateStr];
    }];
}

#pragma mark - Getters

- (UIButton *)addButton
{
    if (!_addButton) {
        _addButton = [UIButton new];
        [_addButton setImage:[UIImage mirror_systemImageNamed:@"plus" fallbackName:@"plus"] forState:UIControlStateNormal];
        _addButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_addButton addTarget:self action:@selector(showAddDialog) forControlEvents:UIControlEventTouchUpInside];
    }
    return _addButton;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.scrollDirection = UICollectionViewScrollDirectionVertical;
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;

        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        [_collectionView registerClass:[SpecialDayCollectionViewCell class] forCellWithReuseIdentifier:kSpecialDayCellIdentifier];
    }
    return _collectionView;
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

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"yyyy-MM-dd";
    }
    return _dateFormatter;
}

@end
