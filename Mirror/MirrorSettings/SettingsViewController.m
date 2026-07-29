//
//  SettingsViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/25.
//

#import "SettingsViewController.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorMacro.h"

#import "LanguageCollectionViewCell.h"
#import "WeekStartsOnCollectionViewCell.h"
#import "ShowIndexCollectionViewCell.h"
#import "PiechartDataCollectionViewCell.h"
#import "PiechartRecordCollectionViewCell.h"
#import "HeatmapCollectionViewCell.h"
#import "ExportImportCollectionViewCell.h"
#import "ReportBugCollectionViewCell.h"
#import "MirrorTabsManager.h"
#import "MirrorLanguage.h"
#import "LeftAnimation.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "MirrorTaskModel.h"
#import "MirrorRecordModel.h"
#import "MirrorSettings.h"
#import "MirrorTimeText.h"
#import "MirrorStorage.h"

static CGFloat const kCellSpacing = 10; // cell之间的上下间距
static CGFloat const kCollectionViewPadding = 20; // 左右留白

typedef NS_ENUM(NSInteger, MirrorSettingType) {
    MirrorSettingTypeLanguage,
    MirrorSettingTypeShowIndex,
    MirrorSettingTypeWeekStartsOn,
    MirrorSettingTypeHeatmap,
    MirrorSettingTypePiechartRecord,
    MirrorSettingTypePiechartData,
    MirrorSettingTypeExportImport,
    MirrorSettingTypeReportBug,
};

@interface SettingsViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate, UIDocumentPickerDelegate>

@property (nonatomic, strong) UIButton *motto;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UILabel *versionLabel;
@property (nonatomic, strong) UIView *loveView;
@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactiveTransition;

@end

@implementation SettingsViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchLanguageNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)restartVC
{
    // 将vc.view里的所有subviews全部置为nil
    self.motto = nil;
    self.collectionView = nil;
    self.versionLabel = nil;
    self.loveView = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self  p_setupUI];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self  p_setupUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 手势(点击外部dismiss)
    UITapGestureRecognizer *tapRecognizer = [UITapGestureRecognizer new];
    tapRecognizer.delegate = self;
    [self.view.superview addGestureRecognizer:tapRecognizer];
    // 手势(滑动内部dismiss)
    UIPanGestureRecognizer *panRecognizer = [UIPanGestureRecognizer new];
    [panRecognizer addTarget:self action:@selector(panGestureRecognizerAction:)];
    [self.view addGestureRecognizer:panRecognizer];
    // Love
    UITapGestureRecognizer *loveRecognizer = [UITapGestureRecognizer new];
    loveRecognizer.numberOfTouchesRequired = 2;
    loveRecognizer.numberOfTapsRequired = 11;
    [loveRecognizer addTarget:self action:@selector(showLove)];
    [self.view addGestureRecognizer:loveRecognizer];
    
    // 动画
    self.transitioningDelegate = self;
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeAddTaskCellBG];
    [self.view addSubview:self.motto];
    [self.motto mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kCollectionViewPadding);
        make.right.mas_equalTo(self.view).offset(-kCollectionViewPadding);
        make.top.mas_equalTo(self.view).offset(80);
        make.height.mas_equalTo([self mottoHeight]);
    }];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kCollectionViewPadding);
        make.right.mas_equalTo(self.view).offset(-kCollectionViewPadding);
        make.top.mas_equalTo(self.motto.mas_bottom).offset(20);
        make.height.mas_equalTo((52*kLeftSheetRatio+kCellSpacing)*self.dataSource.count);
    }];
    [self.view addSubview:self.versionLabel];
    [self.versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kCollectionViewPadding);
        make.right.mas_equalTo(self.view).offset(-kCollectionViewPadding);
        make.bottom.mas_equalTo(self.view).offset(-kTabBarHeight);
        make.height.mas_equalTo(20);
    }];
    
    [self.view addSubview:self.loveView];
    [self.loveView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kCollectionViewPadding);
        make.right.mas_equalTo(self.view).offset(-kCollectionViewPadding);
        make.bottom.mas_equalTo(self.view).offset(-kTabBarHeight);
        make.height.mas_equalTo(20);
    }];
    self.loveView.hidden = YES;
}

#pragma mark - Actions

- (void)tapMotto
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"motto"]
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"save"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *motto = alertController.textFields[0].text;
        [MirrorSettings saveUserMotto:motto];
        [self.motto setTitle:[MirrorSettings userMotto] forState:UIControlStateNormal];
        [self.motto mas_updateConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo([self mottoHeight]);
        }];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showLove
{
    self.versionLabel.hidden = YES;
    self.loveView.hidden = NO;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:UITapGestureRecognizer.class]) {
        CGPoint touchPoint = [touch locationInView:self.view];
        if (touchPoint.x <= self.view.frame.size.width) {
            // 点了view里面
        } else {
            [self dismiss];// 点了view外面
        }
    }
    if ([gestureRecognizer isKindOfClass:UIPanGestureRecognizer.class]) {
        return YES;
    }
    return NO;
}

- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)pan
{
    //产生百分比
    CGFloat process = -[pan translationInView:self.view].x / (self.view.frame.size.width);
    
    process = MIN(1.0,(MAX(0.0, process)));
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.interactiveTransition = [UIPercentDrivenInteractiveTransition new];
        //触发dismiss转场动画
        [self dismissViewControllerAnimated:YES completion:nil];
    }else if (pan.state == UIGestureRecognizerStateChanged){
        [self.interactiveTransition updateInteractiveTransition:process];
    }else if (pan.state == UIGestureRecognizerStateEnded
              || pan.state == UIGestureRecognizerStateCancelled){
        if (process > 0.5) {
            [ self.interactiveTransition finishInteractiveTransition];
        }else{
            [ self.interactiveTransition cancelInteractiveTransition];
        }
        self.interactiveTransition = nil;
    }
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    // 获取授权
    BOOL fileUrlAuthozied = [urls.firstObject startAccessingSecurityScopedResource];
    if (fileUrlAuthozied) {
        // 通过文件协调工具来得到新的文件地址，以此得到文件保护功能
        NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
        NSError *error;
        
        [fileCoordinator coordinateReadingItemAtURL:urls.firstObject options:0 error:&error byAccessor:^(NSURL *newURL) {
            // 读取文件
            NSError *error = nil;
            NSData *data = [NSData dataWithContentsOfURL:newURL options:NSDataReadingMappedIfSafe error:&error];
            if (error) {
                // 读取出错
            } else {
                NSDictionary *dataDict = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[MirrorTaskModel.class, MirrorRecordModel.class, NSMutableArray.class, NSArray.class, NSDictionary.class, NSString.class, NSNumber.class]] fromData:data error:nil];
                BOOL taskIsValid = [dataDict.allKeys containsObject:TASKS] && [dataDict[TASKS] isKindOfClass:[NSMutableArray<MirrorTaskModel *> class]];
                BOOL recordIsValid = [dataDict.allKeys containsObject:RECORDS] && [dataDict[RECORDS] isKindOfClass:[NSMutableArray<MirrorRecordModel *> class]];
                BOOL secondIsValid = [dataDict.allKeys containsObject:SECONDS] && [dataDict[SECONDS] isKindOfClass:[NSNumber class]];
                if (taskIsValid && recordIsValid && secondIsValid) {
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"import_data_?"] message:[MirrorLanguage mirror_stringWithKey:@"import_data_?_message"] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* importAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"import"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                        // 解析
                        NSMutableArray<MirrorTaskModel *> *tasks = dataDict[TASKS];
                        NSMutableArray<MirrorRecordModel *> *records = dataDict[RECORDS];
                        NSNumber *secondsFromGMT = dataDict[SECONDS];
                        // 覆盖本地数据
                        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:@{TASKS:tasks, RECORDS:records, SECONDS:secondsFromGMT} requiringSecureCoding:YES error:nil];
                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                        NSString *path = [paths objectAtIndex:0];
                        NSString *filePath = [path stringByAppendingPathComponent:@"mirror.data"];
                        [data writeToFile:filePath atomically:YES]; // 所有的数据全部导入
                        [MirrorStorage saveSecondsFromGMT:@([NSTimeZone systemTimeZone].secondsFromGMT)]; // 导入后修改数据以适应本地system timezone
                        [[NSNotificationCenter defaultCenter] postNotificationName:MirrorImportDataNotificaiton object:nil];
                    }];
                    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];
                    [alert addAction:cancelAction];
                    [alert addAction:importAction];
                    [self presentViewController:alert animated:YES completion:nil];
                } else {
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"wrong_data_format"] message:nil preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction* okAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil];
                    [alert addAction:okAction];
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }
        }];
        [urls.firstObject stopAccessingSecurityScopedResource];
    } else {
        // 授权失败
    }
}

# pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item >= self.dataSource.count) {
        return;
    } else if (indexPath.item == MirrorSettingTypeExportImport) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"export_or_import"]
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        // Export
        [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"export_data"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *path = [paths objectAtIndex:0];
            NSData *data = [NSData dataWithContentsOfFile:[path stringByAppendingPathComponent:@"mirror.data"] options:0 error:nil];
            if (data==nil) { // 本地没有数据
                UIAlertController *nodataController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"no_data"]
                                                                                         message:nil
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                [nodataController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];
                [self presentViewController:nodataController animated:YES completion:nil];
            } else { // 唤起路径
                // create url
                NSString *filename = [@"Mirror" stringByAppendingString:[MirrorTimeText getPreciseTimeString]];
                NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:filename]];
                [data writeToURL:url atomically:NO]; // 给data创建一个url：为了起名字
                NSArray *activityItems = @[url];
                UIActivityViewController *activityViewControntroller = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
                activityViewControntroller.excludedActivityTypes = @[];
                activityViewControntroller.popoverPresentationController.sourceView = self.view;
                activityViewControntroller.popoverPresentationController.sourceRect = CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/4, 0, 0);
                [self presentViewController:activityViewControntroller animated:true completion:nil];
            }
        }]];
        // Import 唤起路径
        [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"import_data"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeData]]; // allow any file type
                documentPicker.delegate = self;
                documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
                [self presentViewController:documentPicker animated:YES completion:nil];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}]];
        [self presentViewController:alertController animated:YES completion:nil];
    } else if (indexPath.item == MirrorSettingTypeReportBug) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"copy_email_address_to_clipboard"]
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {

        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"copy"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = @"yuqingwang.dev@gmail.com";
        }]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item >= self.dataSource.count) {
        return [UICollectionViewCell new];
    } else if (indexPath.item == MirrorSettingTypeLanguage) {
        LanguageCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[LanguageCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypeShowIndex) {
        ShowIndexCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[ShowIndexCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypeWeekStartsOn) {
        WeekStartsOnCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[WeekStartsOnCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypeHeatmap) {
        HeatmapCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[HeatmapCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypePiechartRecord) {
        PiechartRecordCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[PiechartRecordCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypePiechartData) {
        PiechartDataCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[PiechartDataCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypeExportImport) {
        ExportImportCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[ExportImportCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    } else if (indexPath.item == MirrorSettingTypeReportBug) {
        ReportBugCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[ReportBugCollectionViewCell identifier] forIndexPath:indexPath];
        [cell configCell];
        return cell;
    }
    
    return [UICollectionViewCell new];
   
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.frame.size.width, 52*kLeftSheetRatio);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

#pragma mark - Getters

- (UIButton *)motto
{
    if (!_motto) {
        _motto = [UIButton new];
        [_motto setTitle:[MirrorSettings userMotto] forState:UIControlStateNormal];
        [_motto setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeTextHint] forState:UIControlStateNormal];
        _motto.titleLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:14];
        _motto.titleLabel.textAlignment = NSTextAlignmentLeft;
        _motto.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [_motto setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 10)];
        _motto.titleLabel.numberOfLines = 0;
        [_motto addTarget:self action:@selector(tapMotto) forControlEvents:UIControlEventTouchUpInside];
    }
    return _motto;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        layout.minimumLineSpacing = kCellSpacing;
        _collectionView.backgroundColor = self.view.backgroundColor;
        [_collectionView registerClass:[LanguageCollectionViewCell class] forCellWithReuseIdentifier:[LanguageCollectionViewCell identifier]];
        [_collectionView registerClass:[WeekStartsOnCollectionViewCell class] forCellWithReuseIdentifier:[WeekStartsOnCollectionViewCell identifier]];
        [_collectionView registerClass:[ShowIndexCollectionViewCell class] forCellWithReuseIdentifier:[ShowIndexCollectionViewCell identifier]];
        [_collectionView registerClass:[PiechartDataCollectionViewCell class] forCellWithReuseIdentifier:[PiechartDataCollectionViewCell identifier]];
        [_collectionView registerClass:[PiechartRecordCollectionViewCell class] forCellWithReuseIdentifier:[PiechartRecordCollectionViewCell identifier]];
        [_collectionView registerClass:[HeatmapCollectionViewCell class] forCellWithReuseIdentifier:[HeatmapCollectionViewCell identifier]];
        [_collectionView registerClass:[ExportImportCollectionViewCell class] forCellWithReuseIdentifier:[ExportImportCollectionViewCell identifier]];
        [_collectionView registerClass:[ReportBugCollectionViewCell class] forCellWithReuseIdentifier:[ReportBugCollectionViewCell identifier]];
    }
    return _collectionView;
}

- (UILabel *)versionLabel
{
    if (!_versionLabel) {
        _versionLabel = [UILabel new];
        _versionLabel.text = @"Version 1.0";
        _versionLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _versionLabel.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:14];
        _versionLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _versionLabel;
}

- (UIView *)loveView
{
    if (!_loveView) {
        _loveView = [UIView new];
        
        UIImageView *heartView = [UIImageView new];
        heartView.image = [[UIImage systemImageNamed:@"heart.fill"]imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [heartView setTintColor:[UIColor mirrorColorNamed:MirrorColorTypeTextHint]];
        
        UILabel *yuqing = [UILabel new];
        yuqing.text = @"Yuqing Wang";
        yuqing.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        yuqing.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:14];
        yuqing.textAlignment = NSTextAlignmentRight;
        
        UILabel *chunshu = [UILabel new];
        chunshu.text = @"Chunshu Wu";
        chunshu.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        chunshu.font = [UIFont fontWithName:@"TrebuchetMS-Italic" size:14];
        chunshu.textAlignment = NSTextAlignmentLeft;
        
        [_loveView addSubview:heartView];
        [heartView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.offset(0);
            make.height.width.mas_equalTo(10);
        }];
        [_loveView addSubview:yuqing];
        [yuqing mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.offset(0);
            make.right.mas_equalTo(heartView.mas_left).offset(-10);
            make.height.mas_equalTo(20);
            make.left.mas_equalTo(_loveView.mas_left);
        }];
        [_loveView addSubview:chunshu];
        [chunshu mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.offset(0);
            make.left.mas_equalTo(heartView.mas_right).offset(10);
            make.height.mas_equalTo(20);
            make.right.mas_equalTo(_loveView.mas_right);
        }];
    }
    return _loveView;
}

- (NSArray *)dataSource
{
    if (!_dataSource) {
        _dataSource = @[@(MirrorSettingTypeLanguage), @(MirrorSettingTypeShowIndex), @(MirrorSettingTypeWeekStartsOn), @(MirrorSettingTypeHeatmap), @(MirrorSettingTypePiechartRecord), @(MirrorSettingTypePiechartData), @(MirrorSettingTypeExportImport), @(MirrorSettingTypeReportBug)];
    }
    return _dataSource;
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    LeftAnimation *animation = [LeftAnimation new];
    animation.isPresent = NO;
    return animation;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator
{
    return self.interactiveTransition;
}

#pragma mark - Privates

- (CGFloat)mottoHeight
{
    // label自适应的height
    CGFloat width  = kScreenWidth*kLeftSheetRatio - 2*kCollectionViewPadding - 2*10;
    NSDictionary *textAttrs = @{NSFontAttributeName : [UIFont fontWithName:@"TrebuchetMS-Italic" size:14]};
    CGFloat height = [[MirrorSettings userMotto] boundingRectWithSize:CGSizeMake(width, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:textAttrs context:nil].size.height;
    // 考虑到collectionView和version，这个label高度也要有极限的
    CGFloat collectionViewHeight = (52*kLeftSheetRatio+kCellSpacing)*self.dataSource.count; // collection view height (包含最后一个小的padding)
    CGFloat versionHeight = 20;
    CGFloat maxHeight = kScreenHeight - 80 - 20 - collectionViewHeight - versionHeight - kTabBarHeight;
    return MIN(height, maxHeight);
}

@end
