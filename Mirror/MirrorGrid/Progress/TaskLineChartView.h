//
//  TaskLineChartView.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorReadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TaskLineChartView : UIView

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data dateKeys:(NSArray<NSString *> *)dateKeys;
- (void)setRangeSelectionActive:(BOOL)active;
- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data dateKeys:(NSArray<NSString *> *)dateKeys;

@end

NS_ASSUME_NONNULL_END
