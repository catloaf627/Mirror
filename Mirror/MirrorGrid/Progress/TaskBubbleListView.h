//
//  TaskBubbleListView.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import <UIKit/UIKit.h>
#import "MirrorMacro.h"
#import "MirrorReadModel.h"

NS_ASSUME_NONNULL_BEGIN

@class TaskBubbleListView;

@protocol TaskBubbleListDelegate <NSObject>

- (void)taskBubbleListView:(TaskBubbleListView *)taskBubbleListView didSelectData:(MirrorReadModel *)data;

@end

@interface TaskBubbleListView : UIView

@property (nonatomic, weak) id<TaskBubbleListDelegate> delegate;

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data;
- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data;

@end

NS_ASSUME_NONNULL_END
