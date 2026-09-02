//
//  TimelineScheduleView.h
//  Mirror
//

#import <UIKit/UIKit.h>

@class MirrorScheduleModel;
@class TimelineScheduleView;

NS_ASSUME_NONNULL_BEGIN

@protocol TimelineScheduleViewDelegate <NSObject>

- (UIMenu *)menuForTimelineScheduleView:(TimelineScheduleView *)scheduleView API_AVAILABLE(ios(16.0));
- (void)timelineScheduleViewDidRequestLongSelection:(TimelineScheduleView *)scheduleView;

@end

@interface TimelineScheduleView : UIView

@property (nonatomic, weak) id<TimelineScheduleViewDelegate> delegate;
@property (nonatomic, assign, readonly) NSInteger scheduleIndex;

- (void)configureWithSchedule:(MirrorScheduleModel *)schedule;
- (void)beginLongSelection;
- (void)endSelection;

@end

NS_ASSUME_NONNULL_END
