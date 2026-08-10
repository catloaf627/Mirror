//
//  RecordsTimelineViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface RecordsTimelineViewController : UIViewController

- (instancetype)initWithData:(MirrorDataModel *)data;
- (instancetype)initWithData:(MirrorDataModel *)data highlightedRecords:(NSMutableArray<MirrorRecordModel *> *)highlightedRecords;
- (instancetype)initWithRecords:(NSMutableArray<MirrorRecordModel *> *)records titleKey:(NSString *)titleKey;

@end

NS_ASSUME_NONNULL_END
