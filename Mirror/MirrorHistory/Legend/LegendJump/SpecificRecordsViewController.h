//
//  SpecificRecordsViewController.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/6/9.
//

#import <UIKit/UIKit.h>
#import "MirrorRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SpecificRecordsViewController : UIViewController

- (instancetype)initWithRecords:(NSMutableArray<MirrorRecordModel *> *)records;
- (instancetype)initWithRecords:(NSMutableArray<MirrorRecordModel *> *)records titleKey:(NSString *)titleKey;

@end

NS_ASSUME_NONNULL_END
