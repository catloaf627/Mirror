//
//  RecordsTimelineViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorReadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RecordsTimelineViewController : UIViewController

- (instancetype)initWithData:(MirrorReadModel *)data;
- (instancetype)initWithData:(MirrorReadModel *)data highlightedRecords:(NSMutableArray<MirrorRecordModel *> *)highlightedRecords;
- (instancetype)initWithRecords:(NSMutableArray<MirrorRecordModel *> *)records titleKey:(NSString *)titleKey;

@end

NS_ASSUME_NONNULL_END
