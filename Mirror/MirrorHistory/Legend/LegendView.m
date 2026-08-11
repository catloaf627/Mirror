//
//  LegendView.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import "LegendView.h"
#import <Masonry/Masonry.h>
#import "MirrorStorage.h"
#import "LegendCollectionViewCell.h"

static CGFloat const kCellHeight = 30; // 一个legend的高度
static NSInteger const kNumOfCellPerRow = 3; // 一行固定放三个cell

@interface LegendView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<MirrorReadModel *> *data;

@end


@implementation LegendView

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        self.layer.cornerRadius = 14;
        self.data = data;
        // legend
        [self addSubview:self.collectionView];
        [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.left.right.offset(0);
        }];
    }
    return self;
}

- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data
{
    self.data = data;
    [self.collectionView reloadData];
}

- (CGFloat)legendViewHeight
{
    return (self.data.count/kNumOfCellPerRow + ((self.data.count%kNumOfCellPerRow) ? 1:0)) * kCellHeight;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.data.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    LegendCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[LegendCollectionViewCell identifier] forIndexPath:indexPath];
    [cell configCellWithTaskname:self.data[indexPath.item].taskModel.taskName];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellWidth = self.bounds.size.width / kNumOfCellPerRow;
    return CGSizeMake(cellWidth, kCellHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.data.count <= indexPath.item) {
        return;
    }
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [MirrorStorage switchHiddenTask:self.data[indexPath.item].taskModel.taskName];
}


#pragma mark - Getters

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerClass:[LegendCollectionViewCell class] forCellWithReuseIdentifier:[LegendCollectionViewCell identifier]];
    }
    return _collectionView;
}

@end
