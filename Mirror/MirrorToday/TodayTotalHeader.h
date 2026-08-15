//
//  TodayTotalHeader.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/21.
//

#import <UIKit/UIKit.h>
#import "MirrorRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TodayTotalHeader : UICollectionViewCell

- (void)configWithRecords:(NSMutableArray<MirrorRecordModel *> *)todayRecords;
- (void)configWithDate:(NSDate *)date records:(NSMutableArray<MirrorRecordModel *> *)records datePickerHandler:(void (^)(void))datePickerHandler;
- (void)configWithDate:(NSDate *)date records:(NSMutableArray<MirrorRecordModel *> *)records datePickerHandler:(void (^)(void))datePickerHandler specialDayTapHandler:(void (^)(void))specialDayTapHandler;

@end

NS_ASSUME_NONNULL_END
