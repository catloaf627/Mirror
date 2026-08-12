//
//  TimelineRecordView.h
//  Mirror
//

#import <UIKit/UIKit.h>

@class MirrorRecordModel;
@class TimelineRecordView;

NS_ASSUME_NONNULL_BEGIN

@protocol TimelineRecordViewDelegate <NSObject>

- (void)timelineRecordViewDidRequestInlineEditing:(TimelineRecordView *)recordView;
- (void)timelineRecordView:(TimelineRecordView *)recordView didChangeScrollEnabled:(BOOL)enabled;
- (void)timelineRecordView:(TimelineRecordView *)recordView didCommitStartTimestamp:(long)timestamp;
- (void)timelineRecordView:(TimelineRecordView *)recordView didCommitEndTimestamp:(long)timestamp;
- (void)timelineRecordView:(TimelineRecordView *)recordView didCommitStartTimestamp:(long)startTimestamp endTimestamp:(long)endTimestamp;

@optional
- (void)timelineRecordViewDidRequestMenuDismissal:(TimelineRecordView *)recordView;
- (UIMenu *)menuForTimelineRecordView:(TimelineRecordView *)recordView API_AVAILABLE(ios(16.0));

@end

@interface TimelineRecordView : UIView

@property (nonatomic, weak) id<TimelineRecordViewDelegate> delegate;
@property (nonatomic, assign, readonly) NSInteger periodIndex;
@property (nonatomic, assign, readonly) BOOL isInlineEditing;

- (void)configureWithRecord:(MirrorRecordModel *)record
                      color:(UIColor *)color
                  showsText:(BOOL)showsText;

- (void)beginInlineEditingWithMinimumTimestamp:(long)minimumTimestamp
                              maximumTimestamp:(long)maximumTimestamp
                                    hourHeight:(CGFloat)hourHeight
                             dayStartTimestamp:(long)dayStartTimestamp
                               dayEndTimestamp:(long)dayEndTimestamp;

- (void)endInlineEditing;
- (void)endSelection;
- (BOOL)containsTimelinePoint:(CGPoint)point;

@end

NS_ASSUME_NONNULL_END
