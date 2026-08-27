//
//  SpecialDayEditViewController.m
//  Mirror
//

#import "SpecialDayEditViewController.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "MirrorMacro.h"
#import "MirrorSettings.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"
#import "UIImage+MirrorSymbol.h"

static CGFloat const kSpecialDayEditPadding = 20;
static CGFloat const kSpecialDayEditControlHeight = 40;
static CGFloat const kSpecialDayIconSide = 30;
static NSInteger const kSpecialDayIconColumns = 7;
static CGFloat const kSpecialDayIconPageControlHeight = 24;
static CGFloat const kSpecialDayIconPageControlSpacing = 8;
static NSString * const kSpecialDayEditFallbackIconName = @"star.fill";

@interface SpecialDayEditViewController () <UITextFieldDelegate, UIScrollViewDelegate>

@property (nonatomic, strong, nullable) MirrorDayModel *editingDay;
@property (nonatomic, copy, nullable) SpecialDayEditValidation validation;
@property (nonatomic, copy) SpecialDayEditCompletion completion;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIButton *iconPreviewButton;
@property (nonatomic, strong) UITextField *infoTextField;
@property (nonatomic, strong) UIStackView *colorPickerView;
@property (nonatomic, strong) UITextField *searchTextField;
@property (nonatomic, strong) UIView *iconGridView;
@property (nonatomic, strong) UIScrollView *iconPagesScrollView;
@property (nonatomic, strong) UILabel *iconPageLabel;
@property (nonatomic, strong) NSArray<UIButton *> *colorButtons;
@property (nonatomic, strong) NSArray<UIView *> *colorFillViews;
@property (nonatomic, strong) NSArray<NSString *> *allIconOptions;
@property (nonatomic, strong) NSArray<NSString *> *filteredIconOptions;
@property (nonatomic, strong, nullable) MASConstraint *iconGridBottomConstraint;
@property (nonatomic, assign) MirrorSystemColorType selectedColor;
@property (nonatomic, copy) NSString *selectedIconName;
@property (nonatomic, assign) NSInteger currentIconPage;
@property (nonatomic, assign) NSInteger iconPageCapacity;

@end

@implementation SpecialDayEditViewController

- (instancetype)initWithDay:(MirrorDayModel *)day validation:(SpecialDayEditValidation)validation completion:(SpecialDayEditCompletion)completion
{
    self = [super init];
    if (self) {
        _editingDay = day;
        _validation = [validation copy];
        _completion = [completion copy];
        _selectedColor = day ? day.color : [self randomSpecialDayColor];
        _selectedIconName = day.icon.length > 0 ? [day.icon copy] : kSpecialDayEditFallbackIconName;
        self.modalPresentationStyle = UIModalPresentationPageSheet;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVisibleUI) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshVisibleUI) name:MirrorSwitchLanguageNotification object:nil];
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
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:@selector(cancelTapped)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStyleDone target:self action:@selector(saveTapped)];
    [self setupUI];
    [self configureInitialValues];
    [self refreshVisibleUI];
}

- (void)setupUI
{
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.contentView];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.view);
    }];
    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self.scrollView);
        make.width.mas_equalTo(self.scrollView);
    }];

    [self.contentView addSubview:self.datePicker];
    [self.contentView addSubview:self.colorPickerView];
    [self.contentView addSubview:self.iconPreviewButton];
    [self.contentView addSubview:self.infoTextField];
    [self.contentView addSubview:self.searchTextField];
    [self.contentView addSubview:self.iconGridView];

    [self.datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.contentView);
        make.top.mas_equalTo(self.contentView).offset(18);
        make.height.mas_equalTo(kSpecialDayEditControlHeight);
    }];
    [self.colorPickerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.contentView).inset(kSpecialDayEditPadding);
        make.top.mas_equalTo(self.datePicker.mas_bottom).offset(14);
        make.height.mas_equalTo(28);
    }];
    [self.iconPreviewButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.contentView).offset(kSpecialDayEditPadding);
        make.top.mas_equalTo(self.colorPickerView.mas_bottom).offset(18);
        make.width.height.mas_equalTo(kSpecialDayEditControlHeight);
    }];
    [self.infoTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.iconPreviewButton.mas_right).offset(10);
        make.right.mas_equalTo(self.contentView).offset(-kSpecialDayEditPadding);
        make.centerY.mas_equalTo(self.iconPreviewButton);
        make.height.mas_equalTo(kSpecialDayEditControlHeight);
    }];
    [self.searchTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.contentView).inset(kSpecialDayEditPadding);
        make.top.mas_equalTo(self.infoTextField.mas_bottom).offset(20);
        make.height.mas_equalTo(kSpecialDayEditControlHeight);
    }];
    [self.iconGridView addSubview:self.iconPagesScrollView];
    [self.iconGridView addSubview:self.iconPageLabel];
    [self.iconGridView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.contentView).inset(kSpecialDayEditPadding);
        make.top.mas_equalTo(self.searchTextField.mas_bottom).offset(14);
        self.iconGridBottomConstraint = make.height.mas_equalTo(44);
        make.bottom.mas_equalTo(self.contentView).offset(-8);
    }];
    [self.iconPagesScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(self.iconGridView);
        make.bottom.mas_equalTo(self.iconPageLabel.mas_top).offset(-kSpecialDayIconPageControlSpacing);
    }];
    [self.iconPageLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(self.iconGridView);
        make.height.mas_equalTo(kSpecialDayIconPageControlHeight);
    }];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateIconGridPageCapacityIfNeeded];
}

- (void)refreshVisibleUI
{
    UIUserInterfaceStyle interfaceStyle = [MirrorSettings appliedDarkMode] ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
    self.overrideUserInterfaceStyle = interfaceStyle;
    self.navigationController.overrideUserInterfaceStyle = interfaceStyle;
    self.title = [MirrorLanguage mirror_stringWithKey:self.editingDay ? @"edit" : @"add_special_day"];
    self.navigationItem.leftBarButtonItem.title = [MirrorLanguage mirror_stringWithKey:@"cancel"];
    self.navigationItem.rightBarButtonItem.title = [MirrorLanguage mirror_stringWithKey:self.editingDay ? @"done" : @"add"];
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    self.contentView.backgroundColor = self.view.backgroundColor;
    self.infoTextField.placeholder = [MirrorLanguage mirror_stringWithKey:@"special_day_info"];
    self.infoTextField.backgroundColor = [self controlBackgroundColor];
    self.searchTextField.placeholder = [MirrorLanguage mirror_stringWithKey:@"special_day_icon_search"];
    self.searchTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
    self.searchTextField.backgroundColor = [self controlBackgroundColor];
    self.iconPageLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    self.iconPreviewButton.backgroundColor = [self controlBackgroundColor];
    [self updateColorPickerAppearance];
    [self updateSelectedColorAppearance];
    [self reloadIcons];
}

- (void)updateColorPickerAppearance
{
    NSArray<NSNumber *> *colorOptions = [self specialDayColorOptions];
    for (NSInteger index = 0; index < self.colorButtons.count && index < colorOptions.count; index++) {
        MirrorSystemColorType colorType = colorOptions[index].integerValue;
        UIColor *systemColor = [UIColor mirrorSystemColorNamed:colorType];
        self.colorButtons[index].layer.borderColor = systemColor.CGColor;
        self.colorFillViews[index].backgroundColor = systemColor;
    }
}

- (void)configureInitialValues
{
    NSDate *editingDate = self.editingDay ? [self.dateFormatter dateFromString:self.editingDay.dateStr] : nil;
    if (editingDate) {
        self.datePicker.date = editingDate;
    }
    self.infoTextField.text = self.editingDay.info;
    [self updateSelectedColorAppearance];
    [self updateSelectedIconAppearance];
}

- (void)cancelTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveTapped
{
    [self.view endEditing:YES];
    MirrorDayModel *day = [[MirrorDayModel alloc] initWithDateStr:[self.dateFormatter stringFromDate:self.datePicker.date]
                                                             info:self.infoTextField.text ?: @""
                                                             icon:self.selectedIconName
                                                            color:self.selectedColor];
    NSString *errorTitleKey = nil;
    if (self.validation && !self.validation(day, &errorTitleKey)) {
        [self showErrorWithTitleKey:errorTitleKey ?: @"special_day_cannot_be_duplicated"];
        return;
    }
    if (self.completion) {
        self.completion(day);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showErrorWithTitleKey:(NSString *)titleKey
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:titleKey] message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *understandAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"gotcha"] style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:understandAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)colorButtonTapped:(UIButton *)button
{
    NSInteger index = [self.colorButtons indexOfObject:button];
    if (index == NSNotFound || index >= [self specialDayColorOptions].count) {
        return;
    }
    self.selectedColor = [self specialDayColorOptions][index].integerValue;
    [self updateSelectedColorAppearance];
}

- (void)updateSelectedColorAppearance
{
    NSArray<NSNumber *> *colorOptions = [self specialDayColorOptions];
    for (NSInteger index = 0; index < self.colorFillViews.count; index++) {
        MirrorSystemColorType colorType = colorOptions[index].integerValue;
        self.colorFillViews[index].hidden = colorType != self.selectedColor;
    }
    UIColor *color = [UIColor mirrorSystemColorNamed:self.selectedColor];
    self.iconPreviewButton.tintColor = color;
    self.datePicker.tintColor = color;
    [self updateInfoTextColor];
}

- (void)infoTextChanged
{
    [self updateInfoTextColor];
}

- (void)updateInfoTextColor
{
    NSString *trimmedInfo = [self.infoTextField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    self.infoTextField.textColor = trimmedInfo.length > 0 ? [UIColor mirrorSystemColorNamed:self.selectedColor] : [UIColor mirrorColorNamed:MirrorColorTypeText];
}

- (void)updateSelectedIconAppearance
{
    [self.iconPreviewButton setImage:[UIImage mirror_systemImageNamed:self.selectedIconName fallbackName:kSpecialDayEditFallbackIconName] forState:UIControlStateNormal];
}

- (void)searchTextChanged
{
    self.currentIconPage = 0;
    [self reloadIcons];
}

- (void)reloadIcons
{
    NSString *query = self.searchTextField.text ?: @"";
    NSString *normalizedQuery = [self normalizedSearchText:query];
    NSArray<NSString *> *searchTokens = [self searchTokensForQuery:normalizedQuery];
    NSArray<NSString *> *sourceOptions = self.allIconOptions;
    NSMutableArray<NSString *> *filteredOptions = [NSMutableArray new];
    for (NSString *iconName in sourceOptions) {
        if ((normalizedQuery.length == 0 || [self iconName:iconName matchesSearchTokens:searchTokens]) && [UIImage systemImageNamed:iconName]) {
            [filteredOptions addObject:iconName];
        }
    }

    NSString *trimmedQuery = [query stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    if (trimmedQuery.length > 0 && [UIImage systemImageNamed:trimmedQuery] && ![filteredOptions containsObject:trimmedQuery]) {
        [filteredOptions insertObject:trimmedQuery atIndex:0];
    }

    self.filteredIconOptions = filteredOptions;
    self.currentIconPage = MIN(self.currentIconPage, MAX([self iconPageCount] - 1, 0));
    [self renderVisibleIconPages];
}

- (void)updateIconGridPageCapacityIfNeeded
{
    CGFloat gridTop = [self.iconGridView.superview convertRect:self.iconGridView.frame toView:self.view].origin.y;
    CGFloat availableHeight = CGRectGetHeight(self.view.bounds) - self.view.safeAreaInsets.bottom - gridTop;
    CGFloat gridWidth = CGRectGetWidth(self.iconGridView.bounds);
    if (availableHeight <= 0 || gridWidth <= 0) {
        return;
    }

    CGFloat itemSpacing = [self iconItemSpacingForWidth:gridWidth];
    CGFloat iconAreaHeight = MAX(kSpecialDayIconSide, availableHeight - kSpecialDayIconPageControlHeight - kSpecialDayIconPageControlSpacing);
    NSInteger rowCount = MAX(floor((iconAreaHeight + itemSpacing) / (kSpecialDayIconSide + itemSpacing)), 1);
    NSInteger pageCapacity = MAX(rowCount * kSpecialDayIconColumns, kSpecialDayIconColumns);
    CGFloat gridHeight = rowCount * kSpecialDayIconSide + (rowCount - 1) * itemSpacing + kSpecialDayIconPageControlSpacing + kSpecialDayIconPageControlHeight;

    BOOL capacityChanged = self.iconPageCapacity != pageCapacity;
    self.iconPageCapacity = pageCapacity;
    [self.iconGridBottomConstraint setOffset:gridHeight];
    if (capacityChanged && self.filteredIconOptions) {
        self.currentIconPage = MIN(self.currentIconPage, MAX([self iconPageCount] - 1, 0));
        [self renderVisibleIconPages];
    }
}

- (void)renderVisibleIconPages
{
    [self.iconPagesScrollView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSInteger pageCount = [self iconPageCount];
    NSInteger currentPage = MIN(self.currentIconPage, MAX(pageCount - 1, 0));
    self.iconPageLabel.text = pageCount > 0 ? [NSString stringWithFormat:@"%ld / %ld", (long)currentPage + 1, (long)pageCount] : @"";

    CGFloat pageWidth = CGRectGetWidth(self.iconPagesScrollView.bounds);
    CGFloat pageHeight = CGRectGetHeight(self.iconPagesScrollView.bounds);
    if (pageWidth <= 0 || pageHeight <= 0) {
        return;
    }

    self.iconPagesScrollView.contentSize = CGSizeMake(pageWidth * MAX(pageCount, 1), pageHeight);
    [self.iconPagesScrollView setContentOffset:CGPointMake(pageWidth * currentPage, 0) animated:NO];

    if (self.filteredIconOptions.count == 0) {
        UILabel *emptyLabel = [UILabel new];
        emptyLabel.text = [MirrorLanguage mirror_stringWithKey:@"no_data"];
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.font = [UIFont mirrorHintFont];
        emptyLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        [self.iconPagesScrollView addSubview:emptyLabel];
        emptyLabel.frame = CGRectMake(0, 0, pageWidth, 44);
        return;
    }

    NSInteger firstPage = MAX(currentPage - 1, 0);
    NSInteger lastPage = MIN(currentPage + 1, pageCount - 1);
    CGFloat itemSpacing = [self iconItemSpacingForWidth:pageWidth];
    NSInteger capacity = [self currentIconPageCapacity];
    for (NSInteger page = firstPage; page <= lastPage; page++) {
        NSInteger startIndex = page * capacity;
        NSInteger endIndex = MIN(startIndex + capacity, self.filteredIconOptions.count);
        for (NSInteger index = startIndex; index < endIndex; index++) {
            NSString *iconName = self.filteredIconOptions[index];
            NSInteger localIndex = index - startIndex;
            [self addIconButtonWithName:iconName localIndex:localIndex page:page pageWidth:pageWidth itemSpacing:itemSpacing];
        }
    }
}

- (void)addIconButtonWithName:(NSString *)iconName localIndex:(NSInteger)localIndex page:(NSInteger)page pageWidth:(CGFloat)pageWidth itemSpacing:(CGFloat)itemSpacing
{
        UIButton *iconButton = [UIButton buttonWithType:UIButtonTypeSystem];
        iconButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        iconButton.backgroundColor = [iconName isEqualToString:self.selectedIconName] ? [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG] : UIColor.clearColor;
        iconButton.layer.cornerRadius = 6;
        iconButton.layer.masksToBounds = YES;
        [iconButton setImage:[UIImage mirror_systemImageNamed:iconName fallbackName:kSpecialDayEditFallbackIconName] forState:UIControlStateNormal];
        iconButton.accessibilityIdentifier = iconName;
        [iconButton addTarget:self action:@selector(iconButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.iconPagesScrollView addSubview:iconButton];

        NSInteger row = localIndex / kSpecialDayIconColumns;
        NSInteger column = localIndex % kSpecialDayIconColumns;
        iconButton.frame = CGRectMake(page * pageWidth + column * (kSpecialDayIconSide + itemSpacing),
                                      row * (kSpecialDayIconSide + itemSpacing),
                                      kSpecialDayIconSide,
                                      kSpecialDayIconSide);
}

- (void)iconButtonTapped:(UIButton *)button
{
    NSString *iconName = button.accessibilityIdentifier;
    if (iconName.length == 0) {
        return;
    }
    self.selectedIconName = iconName;
    [self updateSelectedIconAppearance];
    [self renderVisibleIconPages];
}

- (NSInteger)iconPageCount
{
    if (self.filteredIconOptions.count == 0) {
        return 0;
    }
    NSInteger capacity = [self currentIconPageCapacity];
    return (self.filteredIconOptions.count + capacity - 1) / capacity;
}

- (NSInteger)currentIconPageCapacity
{
    return MAX(self.iconPageCapacity, kSpecialDayIconColumns * 4);
}

- (CGFloat)iconItemSpacingForWidth:(CGFloat)width
{
    CGFloat availableWidth = width > 0 ? width : kScreenWidth - 2 * kSpecialDayEditPadding;
    return MAX(floor((availableWidth - kSpecialDayIconColumns * kSpecialDayIconSide) / MAX(kSpecialDayIconColumns - 1, 1)), 6);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.iconPagesScrollView) {
        [self updateCurrentIconPageFromScrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView == self.iconPagesScrollView) {
        [self updateCurrentIconPageFromScrollView];
    }
}

- (void)updateCurrentIconPageFromScrollView
{
    CGFloat pageWidth = CGRectGetWidth(self.iconPagesScrollView.bounds);
    if (pageWidth <= 0) {
        return;
    }
    self.currentIconPage = MIN(MAX((NSInteger)llround(self.iconPagesScrollView.contentOffset.x / pageWidth), 0), MAX([self iconPageCount] - 1, 0));
    [self renderVisibleIconPages];
}

- (NSString *)normalizedSearchText:(NSString *)text
{
    return [[text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] lowercaseString] ?: @"";
}

- (NSArray<NSString *> *)searchTokensForQuery:(NSString *)query
{
    if (query.length == 0) {
        return @[];
    }

    NSMutableOrderedSet<NSString *> *tokens = [NSMutableOrderedSet orderedSetWithObject:query];
    NSDictionary<NSString *, NSArray<NSString *> *> *localizedKeywords = [self localizedIconSearchKeywords];
    [localizedKeywords enumerateKeysAndObjectsUsingBlock:^(NSString *keyword, NSArray<NSString *> *mappedTokens, BOOL *stop) {
        if ([keyword containsString:query] || [query containsString:keyword]) {
            for (NSString *token in mappedTokens) {
                [tokens addObject:token];
            }
        }
    }];
    return tokens.array;
}

- (BOOL)iconName:(NSString *)iconName matchesSearchTokens:(NSArray<NSString *> *)tokens
{
    NSString *lowercaseIconName = iconName.lowercaseString;
    for (NSString *token in tokens) {
        if ([lowercaseIconName containsString:token]) {
            return YES;
        }
    }
    return NO;
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)localizedIconSearchKeywords
{
    return @{
        @"爱": @[@"heart", @"love"], @"心": @[@"heart"], @"喜欢": @[@"heart", @"hand.thumbsup"],
        @"家": @[@"house", @"home", @"bed", @"sofa"], @"房子": @[@"house", @"building"],
        @"食物": @[@"fork", @"knife", @"cup", @"mug", @"cake", @"cart"], @"吃": @[@"fork", @"knife", @"cup"], @"咖啡": @[@"cup", @"mug"],
        @"旅行": @[@"airplane", @"car", @"bus", @"map", @"location", @"globe"], @"交通": @[@"car", @"bus", @"tram", @"airplane"],
        @"运动": @[@"figure", @"sport", @"ball", @"dumbbell", @"trophy"], @"跑步": @[@"figure.run"], @"游泳": @[@"swim"],
        @"工作": @[@"briefcase", @"folder", @"doc", @"calendar", @"clock"], @"学习": @[@"book", @"graduationcap", @"student"],
        @"科技": @[@"desktop", @"laptop", @"iphone", @"keyboard", @"terminal", @"wifi"], @"电脑": @[@"desktop", @"laptop"], @"手机": @[@"iphone"],
        @"健康": @[@"heart", @"cross", @"pill", @"bandage", @"stethoscope", @"thermometer"], @"医疗": @[@"cross", @"pill", @"stethoscope"],
        @"生日": @[@"birthday", @"cake", @"balloon", @"gift"], @"礼物": @[@"gift"], @"节日": @[@"star", @"sparkles", @"party", @"gift"],
        @"音乐": @[@"music", @"mic", @"headphones", @"speaker"], @"照片": @[@"photo", @"camera"], @"相机": @[@"camera"],
        @"安全": @[@"lock", @"key", @"shield"], @"警告": @[@"exclamationmark", @"warning"], @"天气": @[@"sun", @"moon", @"cloud", @"rain", @"snow", @"wind"],
        @"amor": @[@"heart"], @"casa": @[@"house", @"home"], @"comida": @[@"fork", @"knife", @"cup"], @"viaje": @[@"airplane", @"map", @"location"], @"deporte": @[@"sport", @"figure", @"ball"],
        @"amour": @[@"heart"], @"maison": @[@"house", @"home"], @"cuisine": @[@"fork", @"knife", @"cup"], @"voyage": @[@"airplane", @"map", @"location"], @"sante": @[@"heart", @"cross", @"pill"], @"santé": @[@"heart", @"cross", @"pill"],
        @"愛": @[@"heart"], @"家": @[@"house", @"home"], @"食事": @[@"fork", @"knife", @"cup"], @"旅行": @[@"airplane", @"map", @"location"], @"運動": @[@"sport", @"figure", @"ball"], @"健康": @[@"heart", @"cross", @"pill"],
        @"사랑": @[@"heart"], @"집": @[@"house", @"home"], @"음식": @[@"fork", @"knife", @"cup"], @"여행": @[@"airplane", @"map", @"location"], @"운동": @[@"sport", @"figure", @"ball"], @"건강": @[@"heart", @"cross", @"pill"],
        @"liebe": @[@"heart"], @"zuhause": @[@"house", @"home"], @"essen": @[@"fork", @"knife", @"cup"], @"reise": @[@"airplane", @"map", @"location"], @"gesundheit": @[@"heart", @"cross", @"pill"],
        @"любовь": @[@"heart"], @"дом": @[@"house", @"home"], @"еда": @[@"fork", @"knife", @"cup"], @"поездка": @[@"airplane", @"map", @"location"], @"спорт": @[@"sport", @"figure", @"ball"], @"здоровье": @[@"heart", @"cross", @"pill"]
    };
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (UIColor *)controlBackgroundColor
{
    return [UIColor tertiarySystemFillColor];
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

- (NSArray<NSString *> *)featuredSpecialDayIconOptions
{
    return @[
        @"star.fill", @"heart.fill", @"pin.fill", @"gift.fill", @"flag.fill", @"bookmark.fill", @"tag.fill", @"bell.fill", @"bolt.fill", @"flame.fill",
        @"sun.max.fill", @"moon.fill", @"cloud.fill", @"drop.fill", @"leaf.fill", @"camera.fill", @"photo.fill", @"music.note", @"mic.fill", @"film.fill",
        @"tv.fill", @"gamecontroller.fill", @"paintbrush.fill", @"book.fill", @"graduationcap.fill", @"briefcase.fill", @"folder.fill", @"doc.fill", @"calendar", @"clock.fill",
        @"alarm.fill", @"timer", @"map.fill", @"location.fill", @"house.fill", @"building.2.fill", @"car.fill", @"airplane", @"bicycle", @"figure.walk",
        @"figure.run", @"sportscourt.fill", @"soccerball", @"basketball.fill", @"football.fill", @"baseball.fill", @"tennisball.fill", @"dumbbell.fill", @"fork.knife", @"cup.and.saucer.fill",
        @"mug.fill", @"wineglass.fill", @"birthday.cake.fill", @"balloon.fill", @"cart.fill", @"bag.fill", @"creditcard.fill", @"chart.bar.fill", @"chart.pie.fill", @"target",
        @"trophy.fill", @"medal.fill", @"crown.fill", @"sparkles", @"person.fill", @"person.2.fill", @"hands.clap.fill", @"face.smiling.fill", @"brain.head.profile", @"lightbulb.fill",
        @"gear", @"wrench.fill", @"hammer.fill", @"stethoscope", @"cross.case.fill", @"pills.fill", @"bandage.fill", @"bed.double.fill", @"shower.fill", @"trash.fill",
        @"envelope.fill", @"phone.fill", @"message.fill", @"globe", @"lock.fill", @"key.fill", @"checkmark.circle.fill", @"exclamationmark.triangle.fill", @"tree.fill", @"desktopcomputer"
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
    for (NSString *symbolName in [self featuredSpecialDayIconOptions]) {
        [iconNames addObject:symbolName];
    }
    return iconNames.array;
}

#pragma mark - Getters

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"yyyy-MM-dd";
    }
    return _dateFormatter;
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
        _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    }
    return _scrollView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [UIView new];
    }
    return _contentView;
}

- (UIDatePicker *)datePicker
{
    if (!_datePicker) {
        _datePicker = [UIDatePicker new];
        _datePicker.datePickerMode = UIDatePickerModeDate;
        _datePicker.locale = [NSLocale localeWithLocaleIdentifier:[MirrorLanguage mirror_stringWithKey:@"locale_Identifier"]];
        if (@available(iOS 13.4, *)) {
            _datePicker.preferredDatePickerStyle = UIDatePickerStyleCompact;
        }
    }
    return _datePicker;
}

- (UIButton *)iconPreviewButton
{
    if (!_iconPreviewButton) {
        _iconPreviewButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _iconPreviewButton.userInteractionEnabled = NO;
        _iconPreviewButton.backgroundColor = [self controlBackgroundColor];
        _iconPreviewButton.layer.cornerRadius = 8;
        _iconPreviewButton.layer.masksToBounds = YES;
    }
    return _iconPreviewButton;
}

- (UITextField *)infoTextField
{
    if (!_infoTextField) {
        _infoTextField = [UITextField new];
        _infoTextField.placeholder = [MirrorLanguage mirror_stringWithKey:@"special_day_info"];
        _infoTextField.returnKeyType = UIReturnKeyDone;
        _infoTextField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _infoTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _infoTextField.backgroundColor = [self controlBackgroundColor];
        _infoTextField.layer.cornerRadius = 8;
        _infoTextField.layer.masksToBounds = YES;
        _infoTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
        _infoTextField.leftViewMode = UITextFieldViewModeAlways;
        _infoTextField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
        _infoTextField.rightViewMode = UITextFieldViewModeAlways;
        _infoTextField.delegate = self;
        [_infoTextField addTarget:self action:@selector(infoTextChanged) forControlEvents:UIControlEventEditingChanged];
    }
    return _infoTextField;
}

- (UIStackView *)colorPickerView
{
    if (!_colorPickerView) {
        UIStackView *stackView = [UIStackView new];
        stackView.axis = UILayoutConstraintAxisHorizontal;
        stackView.alignment = UIStackViewAlignmentCenter;
        stackView.distribution = UIStackViewDistributionEqualSpacing;
        stackView.spacing = 8;
        NSMutableArray<UIButton *> *buttons = [NSMutableArray new];
        NSMutableArray<UIView *> *fillViews = [NSMutableArray new];
        for (NSNumber *colorNumber in [self specialDayColorOptions]) {
            MirrorSystemColorType colorType = colorNumber.integerValue;
            UIColor *systemColor = [UIColor mirrorSystemColorNamed:colorType];
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.backgroundColor = UIColor.clearColor;
            button.layer.cornerRadius = 13;
            button.layer.borderColor = systemColor.CGColor;
            button.layer.borderWidth = 2;
            [button addTarget:self action:@selector(colorButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            UIView *fillView = [UIView new];
            fillView.userInteractionEnabled = NO;
            fillView.backgroundColor = systemColor;
            fillView.layer.cornerRadius = 10;
            fillView.layer.masksToBounds = YES;
            [button addSubview:fillView];
            [fillView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.edges.mas_equalTo(button).inset(3);
            }];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.width.height.mas_equalTo(26);
            }];
            [stackView addArrangedSubview:button];
            [buttons addObject:button];
            [fillViews addObject:fillView];
        }
        self.colorButtons = buttons;
        self.colorFillViews = fillViews;
        _colorPickerView = stackView;
    }
    return _colorPickerView;
}

- (UITextField *)searchTextField
{
    if (!_searchTextField) {
        _searchTextField = [UITextField new];
        _searchTextField.placeholder = [MirrorLanguage mirror_stringWithKey:@"special_day_icon_search"];
        _searchTextField.returnKeyType = UIReturnKeyDone;
        _searchTextField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
        _searchTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _searchTextField.backgroundColor = [self controlBackgroundColor];
        _searchTextField.layer.cornerRadius = 8;
        _searchTextField.layer.masksToBounds = YES;
        _searchTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 1)];
        _searchTextField.leftViewMode = UITextFieldViewModeAlways;
        _searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _searchTextField.delegate = self;
        [_searchTextField addTarget:self action:@selector(searchTextChanged) forControlEvents:UIControlEventEditingChanged];
    }
    return _searchTextField;
}

- (UIView *)iconGridView
{
    if (!_iconGridView) {
        _iconGridView = [UIView new];
    }
    return _iconGridView;
}

- (UIScrollView *)iconPagesScrollView
{
    if (!_iconPagesScrollView) {
        _iconPagesScrollView = [UIScrollView new];
        _iconPagesScrollView.pagingEnabled = YES;
        _iconPagesScrollView.showsHorizontalScrollIndicator = NO;
        _iconPagesScrollView.showsVerticalScrollIndicator = NO;
        _iconPagesScrollView.delegate = self;
        _iconPagesScrollView.bounces = YES;
    }
    return _iconPagesScrollView;
}

- (UILabel *)iconPageLabel
{
    if (!_iconPageLabel) {
        _iconPageLabel = [UILabel new];
        _iconPageLabel.textAlignment = NSTextAlignmentCenter;
        _iconPageLabel.font = [UIFont mirrorHintFont];
        _iconPageLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
    }
    return _iconPageLabel;
}

- (NSArray<NSString *> *)allIconOptions
{
    if (!_allIconOptions) {
        _allIconOptions = [self allSpecialDayIconOptions];
    }
    return _allIconOptions;
}

@end
