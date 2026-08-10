//
//  TaskPickerViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorTaskModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^TaskPickerCompletion)(MirrorTaskModel *task);

@interface TaskPickerViewController : UIViewController

- (instancetype)initWithTasks:(NSArray<MirrorTaskModel *> *)tasks
                   completion:(TaskPickerCompletion)completion;

@end

NS_ASSUME_NONNULL_END
