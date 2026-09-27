//
//  TaskProgressListView.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import <UIKit/UIKit.h>
#import "MirrorMacro.h"
#import "MirrorReadModel.h"

NS_ASSUME_NONNULL_BEGIN

@class TaskProgressListView;

@protocol TaskProgressListDelegate <NSObject>

- (void)taskProgressListView:(TaskProgressListView *)taskProgressListView didSelectData:(MirrorReadModel *)data;

@end

@interface TaskProgressListView : UIView

@property (nonatomic, weak) id<TaskProgressListDelegate> delegate;

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data;
- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data;

@end

NS_ASSUME_NONNULL_END
