//
//  SpecificRecordsViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/6/9.
//

#import "SpecificRecordsViewController.h"
#import <Masonry/Masonry.h>
#import "UIColor+MirrorColor.h"
#import "MirrorMacro.h"
#import "TaskPeriodCollectionViewCell.h"
#import "MirrorStorage.h"
#import "MirrorLanguage.h"
#import "MirrorNaviManager.h"

#define kCellSpacing (20*kWidthRatio) // left right spacing
static NSString * const kMirrorSpecificRecordsDeleteHintShownKey = @"MirrorSpecificRecordsDeleteHintShown";

@interface SpecificRecordsViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, VCForPeriodCellProtocol>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *records;
@property (nonatomic, copy) NSString *titleKey;
@end

@implementation SpecificRecordsViewController

- (instancetype)initWithRecords:(NSMutableArray<MirrorRecordModel *> *)records
{
    return [self initWithRecords:records titleKey:@"records"];
}

- (instancetype)initWithRecords:(NSMutableArray<MirrorRecordModel *> *)records titleKey:(NSString *)titleKey
{
    self = [super init];
    if (self) {
        self.records = records;
        self.titleKey = titleKey;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartVC) name:MirrorSwitchThemeNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodDeleteNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:MirrorPeriodEditNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadData
{
    [self.collectionView reloadData];
}

- (void)restartVC
{
    // update navibar
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:[MirrorLanguage mirror_stringWithKey:self.titleKey] leftButton:nil rightButton:nil];
    // 将vc.view里的所有subviews全部置为nil
    self.collectionView = nil;
    // 将vc.view里的所有subviews从父view上移除
    [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self  p_setupUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[MirrorNaviManager sharedInstance] updateNaviItemWithTitle:[MirrorLanguage mirror_stringWithKey:self.titleKey] leftButton:nil rightButton:nil];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)p_setupUI
{
    // collection view
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view).offset(kCellSpacing);
        make.right.mas_equalTo(self.view).offset(-kCellSpacing);
        make.top.mas_equalTo(self.view).offset(self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height);
        make.bottom.mas_equalTo(self.view);
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.records.count;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.item != 0 || [[NSUserDefaults standardUserDefaults] boolForKey:kMirrorSpecificRecordsDeleteHintShownKey]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kMirrorSpecificRecordsDeleteHintShownKey];
    [(TaskPeriodCollectionViewCell *)cell previewDeleteButton];
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TaskPeriodCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[TaskPeriodCollectionViewCell identifier] forIndexPath:indexPath];
    MirrorRecordModel *record = self.records[indexPath.item];
    [cell configWithTaskname:record.taskName periodIndex:record.originalIndex type:BottomRightTypeTotal];
    cell.delegate = self;
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(kScreenWidth - 2*kCellSpacing, 80*kHeightRatio);
}

#pragma mark - Update UI after delete a record

// 只是简单删掉了被删掉的那个cell，数据源并没有得到彻底的update（original index的改动是手动计算的，并没有经过数据库重新计算、校对），这么写容易出现crash但也没什么更好的办法
- (void)updateUIAfterDeleteDataAtIndex:(NSInteger)index
{
    NSInteger indexInThisVC = NSNotFound;
    for (int i=0; i<self.records.count; i++) {
        if (self.records[i].originalIndex == index) {
            indexInThisVC = i;
        } else if (self.records[i].originalIndex > index) {
            self.records[i].originalIndex = self.records[i].originalIndex - 1; // 前面数据被删了，理论上自己的original index应该前移一位
        } else if (self.records[i].originalIndex < index) {
            // 保持不变
        }
    }
    if (indexInThisVC != NSNotFound) {
        [self.records removeObjectAtIndex:indexInThisVC];
        [self.collectionView reloadData];
    }
}

#pragma mark - Getters

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumLineSpacing = 10*kHeightRatio;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.view.backgroundColor;
        
        [_collectionView registerClass:[TaskPeriodCollectionViewCell class] forCellWithReuseIdentifier:[TaskPeriodCollectionViewCell identifier]];
    }
    return _collectionView;
}

- (NSMutableArray<MirrorRecordModel *> *)records
{
    if (!_records) {
        _records = [NSMutableArray new];
    }
    return _records;
}

- (NSString *)titleKey
{
    if (!_titleKey) {
        _titleKey = @"records";
    }
    return _titleKey;
}


@end
