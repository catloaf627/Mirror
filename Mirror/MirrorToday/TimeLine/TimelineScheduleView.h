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
- (void)timelineScheduleViewDidRequestInlineEditing:(TimelineScheduleView *)scheduleView;
- (void)timelineScheduleViewDidRequestLongSelection:(TimelineScheduleView *)scheduleView;
- (void)timelineScheduleView:(TimelineScheduleView *)scheduleView didChangeScrollEnabled:(BOOL)enabled;
- (void)timelineScheduleView:(TimelineScheduleView *)scheduleView didCommitStartTimestamp:(long)timestamp;
- (void)timelineScheduleView:(TimelineScheduleView *)scheduleView didCommitEndTimestamp:(long)timestamp;
- (void)timelineScheduleView:(TimelineScheduleView *)scheduleView didCommitStartTimestamp:(long)startTimestamp endTimestamp:(long)endTimestamp;

@end

@interface TimelineScheduleView : UIView

@property (nonatomic, weak) id<TimelineScheduleViewDelegate> delegate;
@property (nonatomic, assign, readonly) NSInteger scheduleIndex;
@property (nonatomic, assign, readonly) BOOL isInlineEditing;
@property (nonatomic, assign, readonly) long originalStartTimestamp;
@property (nonatomic, assign, readonly) long originalEndTimestamp;
@property (nonatomic, copy, readonly) NSString *scheduleTitle;

- (void)configureWithSchedule:(MirrorScheduleModel *)schedule;
- (void)beginInlineEditingWithMinimumTimestamp:(long)minimumTimestamp
                              maximumTimestamp:(long)maximumTimestamp
                                    hourHeight:(CGFloat)hourHeight
                             dayStartTimestamp:(long)dayStartTimestamp
                               dayEndTimestamp:(long)dayEndTimestamp;
- (void)endInlineEditing;
- (void)beginLongSelection;
- (void)endSelection;

@end

NS_ASSUME_NONNULL_END
