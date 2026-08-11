//
//  LinechartView.m
//  Mirror
//
//  Created by Yuqing Wang on 2024/2/29.
//

#import "LinechartView.h"
#import <Masonry/Masonry.h>
#import "LineChartCollectionViewCell.h"
#import "MirrorReadModel.h"
#import "MirrorTool.h"
#import "UIColor+MirrorColor.h"
#import "UIFont+MirrorFont.h"

static CGFloat const kMinCellWidth = 14;
static CGFloat const kTimelineLeftWidth = 36;
static CGFloat const kTimelineRightPadding = 4;
static CGFloat const kTimelineLineWidth = 5;

@interface LinechartView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView *timelineView;

@property (nonatomic, assign) long maxtime;
@property (nonatomic, strong) NSMutableArray<NSMutableDictionary<NSString *, NSNumber *> *> *data;

@end

@implementation LinechartView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    self.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    [self addSubview:self.timelineView];
    [self.timelineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(self).offset(0);
    }];
    [self addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self).offset(kTimelineLeftWidth);
        make.right.mas_equalTo(self).offset(-kTimelineRightPadding);
        make.top.bottom.mas_equalTo(self).offset(0);
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self renderTimeline];
}

#pragma mark - UICollectionViewDataSource

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    LineChartCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[LineChartCollectionViewCell identifier] forIndexPath:indexPath];
    // onedaydata
    NSMutableDictionary<NSString *,NSNumber *> *onedaydata = self.data[indexPath.item];
    [cell configCellWithOnedaydata:onedaydata maxtime:self.maxtime];
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.data.count;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.data.count == 0) {
        return CGSizeZero;
    }
    CGFloat width =  kMinCellWidth > collectionView.bounds.size.width/self.data.count ? kMinCellWidth : collectionView.bounds.size.width/self.data.count;
    return CGSizeMake(width, collectionView.bounds.size.height);
}

#pragma mark - Refactor Data

- (void)refactorData:(NSMutableArray<NSMutableArray<MirrorReadModel *> *> *)originalData
{
    
    // update maxtime
    self.maxtime = 0;
    
    NSMutableArray *allTasknames = [NSMutableArray new];
    for (int i=0; i<originalData.count; i++) {
        NSMutableArray<MirrorReadModel *> *oneday = originalData[i];
        long totalTime = 0;
        for (int j=0; j<oneday.count; j++) {
            MirrorReadModel *onedayonetask = oneday[j];
            long time = [MirrorTool getTotalTimeOfPeriods:onedayonetask.records];
            totalTime += time;
            if (![allTasknames containsObject:onedayonetask.taskModel.taskName]) { // 更新所有task的名单
                [allTasknames addObject:onedayonetask.taskModel.taskName];
            }
        }
        if (totalTime > self.maxtime) self.maxtime = totalTime; // 堆叠柱按单日总时长缩放
    }
    
    // update data
    self.data = [[NSMutableArray alloc] initWithCapacity:originalData.count];
    
    for (int i=0; i<originalData.count; i++) {
        NSMutableArray<MirrorReadModel *> *oneday = originalData[i];
        NSMutableDictionary<NSString *, NSNumber *> *onedayDict = [NSMutableDictionary new];
        for (int j=0; j<allTasknames.count; j++) {
            BOOL taskExisted = NO;
            NSMutableArray<MirrorRecordModel *> *periods = [@[] mutableCopy];
            for (int taskIndex=0; taskIndex<oneday.count; taskIndex++) {
                NSString *taskname0 = allTasknames[j];
                NSString *taskname1 = oneday[taskIndex].taskModel.taskName;
                if ([taskname0 isEqualToString:taskname1]) {
                    taskExisted = YES;
                    periods = oneday[taskIndex].records;
                    break;
                }
            }
            if (taskExisted) {
                NSString *key = allTasknames[j];
                NSNumber *value = @([MirrorTool getTotalTimeOfPeriods:periods]);
                [onedayDict setValue:value forKey:key];
            } else {
                NSString *key = allTasknames[j];
                NSNumber *value = @([MirrorTool getTotalTimeOfPeriods:periods]);
                [onedayDict setValue:value forKey:key];
            }
            
        }
        [self.data addObject:onedayDict];
    }
    [self.collectionView reloadData];
    [self renderTimeline];
    /*
     原数据
   { [taskA:10h, taskB:20h]
     [taskC:19h]
     [taskA:47h, taskC:20h, taskD:48h]
     [taskB:84h, taskD:97h] }
     整理为
     alltasknames = [taskA, taskB, taskC, taskD]
     mastime = 97h
     输出为
     mastime = 97h
     data =
     { [taskA->10h,taskB->20h,taskC->0h, taskD->0h]
       [taskA->0h, taskB->0h, taskC->19h,taskD->0h]
       [taskA->47h,taskB->0h, taskC->20h,taskD->48h]
       [taskA->0h, taskB->84h,taskC->0h, taskD->97h] }
     */
}

- (void)renderTimeline
{
    [self.timelineView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (self.maxtime <= 0 || CGRectGetHeight(self.bounds) <= 0 || CGRectGetWidth(self.bounds) <= 0) {
        return;
    }
    
    long step = self.maxtime >= 3600 ? 3600 : 15 * 60;
    long maxLineTime = (self.maxtime / step) * step;
    CGFloat drawableHeight = MAX(CGRectGetHeight(self.bounds) - kTimelineLineWidth, 0);
    CGFloat lineX = kTimelineLeftWidth;
    CGFloat lineWidth = CGRectGetWidth(self.bounds) - kTimelineLeftWidth - kTimelineRightPadding;
    
    for (long time = 0; time <= maxLineTime; time += step) {
        CGFloat percentage = time / (double)self.maxtime;
        CGFloat y = kTimelineLineWidth / 2 + (1 - percentage) * drawableHeight;
        
        UIView *line = [UIView new];
        line.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse];
        line.alpha = 0.2;
        [self.timelineView addSubview:line];
        line.frame = CGRectMake(lineX, y, lineWidth, 1);
        
        UILabel *timeLabel = [UILabel new];
        timeLabel.text = [self timelineTextWithSeconds:time];
        timeLabel.font = [UIFont mirrorMinFont];
        timeLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        timeLabel.alpha = 0.5;
        timeLabel.textAlignment = NSTextAlignmentRight;
        [self.timelineView addSubview:timeLabel];
        timeLabel.frame = CGRectMake(0, y - 10, kTimelineLeftWidth - 8, 20);
    }
}

- (NSString *)timelineTextWithSeconds:(long)seconds
{
    if (seconds >= 3600) {
        return [NSString stringWithFormat:@"%ldh", seconds / 3600];
    }
    return [NSString stringWithFormat:@"%ldm", seconds / 60];
}

#pragma mark - Getter

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        [_collectionView registerClass:[LineChartCollectionViewCell class] forCellWithReuseIdentifier:[LineChartCollectionViewCell identifier]];
    }
    return _collectionView;
}

- (UIView *)timelineView
{
    if (!_timelineView) {
        _timelineView = [UIView new];
        _timelineView.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
        _timelineView.userInteractionEnabled = NO;
    }
    return _timelineView;
}

@end
