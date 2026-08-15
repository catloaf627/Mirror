//
//  TaskRecordsViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorReadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TaskRecordsViewController : UIViewController

- (instancetype)initWithData:(MirrorReadModel *)data;
- (instancetype)initWithData:(MirrorReadModel *)data highlightedRecords:(NSMutableArray<MirrorRecordModel *> *)highlightedRecords;

@end

NS_ASSUME_NONNULL_END
