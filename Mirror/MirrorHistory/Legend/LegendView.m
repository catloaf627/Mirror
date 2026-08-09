//
//  LegendView.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import "LegendView.h"
#import <Masonry/Masonry.h>
#import "MirrorSettings.h"
#import "MirrorStorage.h"
#import "LegendCollectionViewCell.h"
#import "SpecificRecordsViewController.h"
#import "MirrorLanguage.h"
#import "MirrorTimeText.h"

static CGFloat const kCellHeight = 30; // 一个legend的高度
static NSInteger const kNumOfCellPerRow = 3; // 一行固定放三个cell

@interface LegendView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<MirrorDataModel *> *data;

@property (nonatomic, assign) NSInteger spanType;
@property (nonatomic, assign) NSInteger offset;

@end


@implementation LegendView

- (instancetype)initWithData:(NSMutableArray<MirrorDataModel *> *)data
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

- (void)updateWithData:(NSMutableArray<MirrorDataModel *> *)data
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

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.data.count > indexPath.item && self.data[indexPath.item].records.count > 0) {
        MirrorDataModel *data = self.data[indexPath.item];
        NSString *format = [MirrorLanguage mirror_stringWithKey:@"check_task_records_for_period_?"];
        NSString *rangeText = self.confirmationRangeText.length > 0 ? self.confirmationRangeText : [self timeRangeTextWithRecords:data.records];
        NSString *message = [NSString stringWithFormat:format, data.taskModel.taskName, rangeText];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            SpecificRecordsViewController *recordsVC = [[SpecificRecordsViewController alloc] initWithRecords:data.records];
            [self.delegate.navigationController pushViewController:recordsVC animated:YES];
        }]];
        [self.delegate presentViewController:alertController animated:YES completion:nil];
    }
}

- (NSString *)timeRangeTextWithRecords:(NSMutableArray<MirrorRecordModel *> *)records
{
    long start = LONG_MAX;
    long end = LONG_MIN;
    for (MirrorRecordModel *record in records) {
        start = MIN(start, record.startTime);
        end = MAX(end, record.endTime);
    }
    
    NSString *startText = [MirrorTimeText YYYYmmdd:[NSDate dateWithTimeIntervalSince1970:start]];
    NSString *endText = [MirrorTimeText YYYYmmdd:[NSDate dateWithTimeIntervalSince1970:end]];
    if ([startText isEqualToString:endText]) {
        return startText;
    }
    return [NSString stringWithFormat:@"%@ - %@", startText, endText];
}

#pragma mark - HistogramDelegate

- (void)twinkleTaskname:(NSString *)taskname
{
    NSInteger index = NSNotFound;
    for (int i=0; i<self.data.count; i++) {
        if ([self.data[i].taskModel.taskName isEqualToString:taskname]) {
            index = i;
            break;
        }
    }
    if (index == NSNotFound) return;
    LegendCollectionViewCell *targetCell = (LegendCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:taskname];
    UIColor *pulseColor = [UIColor mirrorColorNamed:task.color]; // pulse color 展示原色即可（因为cell本身是没有颜色的）
    UIColor *color = [UIColor clearColor];
    [UIView animateWithDuration:0.5 animations:^{
        targetCell.backgroundColor = pulseColor;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5 animations:^{
            targetCell.backgroundColor = color;
        } completion:^(BOOL finished) {
            
        }];
    }];
}

#pragma mark - PiechartDelegate

- (void)highlightTaskname:(NSString *)taskname
{
    NSInteger index = NSNotFound;
    for (int i=0; i<self.data.count; i++) {
        if ([self.data[i].taskModel.taskName isEqualToString:taskname]) {
            index = i;
            break;
        }
    }
    if (index == NSNotFound) return;
    LegendCollectionViewCell *targetCell = (LegendCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:taskname];
    UIColor *pulseColor = [UIColor mirrorColorNamed:task.color]; // pulse color 展示原色即可（因为cell本身是没有颜色的）
    [UIView animateWithDuration:0.5 animations:^{
        targetCell.backgroundColor = pulseColor;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)cancelHighlightTaskname:(NSString *)taskname
{
    NSInteger index = NSNotFound;
    for (int i=0; i<self.data.count; i++) {
        if ([self.data[i].taskModel.taskName isEqualToString:taskname]) {
            index = i;
            break;
        }
    }
    if (index == NSNotFound) return;
    LegendCollectionViewCell *targetCell = (LegendCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    UIColor *color = [UIColor clearColor];
    [UIView animateWithDuration:0.5 animations:^{
        targetCell.backgroundColor = color;
    } completion:^(BOOL finished) {
        
    }];
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
