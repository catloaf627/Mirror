//
//  HistogramView.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import "HistogramView.h"
#import "MirrorStorage.h"
#import "HistogramCollectionViewCell.h"
#import "MirrorMacro.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorSettings.h"
#import "MirrorLanguage.h"

static CGFloat const kCellSpacing = 14; // histogram cell左右的距离

// 5-6的时候自适应是最好看的，小于5按照5取size（有header/footer padding），大于6按照5.5取size（右侧展示出来半个cell，提示用户需要滚动才能看全）
static NSInteger const kPrettyCountMin = 5;
static NSInteger const kPrettyCountMax = 6;
static CGFloat const kPrettyCountShowHalf = 5.5;

@interface HistogramView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray<MirrorDataModel *> *data;

@property (nonatomic, assign) NSInteger spanType;
@property (nonatomic, assign) NSInteger offset;

@end

@implementation HistogramView

- (instancetype)initWithData:(NSMutableArray<MirrorDataModel *> *)data
{
    self = [super init];
    if (self) {
        self.data = data;
        self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        // histogram
        [self addSubview:self.collectionView];
        [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.left.right.offset(0);
        }];
    }
    return self;
}

- (void)updateWithData:(NSMutableArray<MirrorDataModel *> *)data{
    self.data = data;
    [self.collectionView reloadData];
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
    HistogramCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[HistogramCollectionViewCell identifier] forIndexPath:indexPath];
    [cell configCellWithData:self.data index:indexPath.item];
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.data.count == 0) return CGSizeZero;
    if (self.data.count < kPrettyCountMin) {
        CGFloat cellWidth = (self.bounds.size.width - (kPrettyCountMin - 1)*kCellSpacing) / kPrettyCountMin;
        return CGSizeMake(cellWidth, self.bounds.size.height);
    } else if (self.data.count >= kPrettyCountMin && self.data.count <= kPrettyCountMax) {
        CGFloat cellWidth = (self.bounds.size.width - (self.data.count - 1)*kCellSpacing) / self.data.count;
        return CGSizeMake(cellWidth, self.bounds.size.height);
    } else {
        CGFloat cellWidth = (self.bounds.size.width - [@(kPrettyCountShowHalf) integerValue]*kCellSpacing) / kPrettyCountShowHalf;
        return CGSizeMake(cellWidth, self.bounds.size.height);
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *view = nil;
    if ([kind isEqualToString:@"UICollectionElementKindSectionHeader"]) {
        UICollectionViewCell *headerView = [collectionView   dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header" forIndexPath:indexPath];
        return headerView;
    }
    if ([kind isEqualToString:@"UICollectionElementKindSectionFooter"]) {
        UICollectionViewCell *footerView = [collectionView   dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer" forIndexPath:indexPath];
        return footerView;
    }
    return view;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    if (self.data.count == 0) return CGSizeZero;
    if (self.data.count < kPrettyCountMin) {
        CGFloat cellWidth = (self.bounds.size.width - (kPrettyCountMin - 1 )*kCellSpacing) / kPrettyCountMin;
        CGFloat width = cellWidth * self.data.count + kCellSpacing * (self.data.count-1);
        return CGSizeMake((self.bounds.size.width - width)/2, self.bounds.size.height);
    } else {
        return CGSizeMake(0, 0);
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section
{
    if (self.data.count == 0) return CGSizeZero;
    if (self.data.count < kPrettyCountMin) {
        CGFloat cellWidth = (self.bounds.size.width - (kPrettyCountMin - 1)*kCellSpacing) / kPrettyCountMin;
        CGFloat width = cellWidth * self.data.count + kCellSpacing * (self.data.count-1);
        return CGSizeMake((self.bounds.size.width - width)/2, self.bounds.size.height);
    } else {
        return CGSizeMake(0, 0);
    }
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.data.count <= indexPath.item) {
        return;
    }
    [self.delegate histogramView:self didSelectData:self.data[indexPath.item]];
}

#pragma mark - Getters

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumLineSpacing = 14;
        layout.minimumInteritemSpacing = 14;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor]; // 设置为透明色，可以将后面的emptyhint露出来
        [_collectionView registerClass:[HistogramCollectionViewCell class] forCellWithReuseIdentifier:[HistogramCollectionViewCell identifier]];

        [_collectionView registerClass:[UICollectionViewCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"header"];
        [_collectionView registerClass:[UICollectionViewCell class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"footer"];
    }
    return _collectionView;
}

@end
