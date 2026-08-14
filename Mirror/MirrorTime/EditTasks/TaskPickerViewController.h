//
//  TaskPickerViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorTaskModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^TaskPickerCompletion)(MirrorTaskModel *task, BOOL shouldPrefixRecordNotes);

@interface TaskPickerViewController : UIViewController

- (instancetype)initWithTasks:(NSArray<MirrorTaskModel *> *)tasks
                sourceTaskName:(NSString *)sourceTaskName
                   completion:(TaskPickerCompletion)completion;

@end

NS_ASSUME_NONNULL_END
