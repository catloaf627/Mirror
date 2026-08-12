//
//  TimelineRangeAxisView.h
//  Mirror
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^TimelineRangeAxisValueChanged)(BOOL isStartTime, long timestamp);

@interface TimelineRangeAxisView : UIView

@property (nonatomic, assign) long minimumTimestamp;
@property (nonatomic, assign) long maximumTimestamp;
@property (nonatomic, assign) long startTimestamp;
@property (nonatomic, assign) long endTimestamp;
@property (nonatomic, assign) BOOL canDragStart;
@property (nonatomic, assign) BOOL canDragEnd;
@property (nonatomic, strong) UIColor *axisColor;
@property (nonatomic, copy) TimelineRangeAxisValueChanged valueChanged;

- (void)configureWithMinimumTimestamp:(long)minimumTimestamp
                     maximumTimestamp:(long)maximumTimestamp
                        startTimestamp:(long)startTimestamp
                          endTimestamp:(long)endTimestamp
                          canDragStart:(BOOL)canDragStart
                            canDragEnd:(BOOL)canDragEnd;

@end

NS_ASSUME_NONNULL_END
