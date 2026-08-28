//
//  TimelineBackgroundView.h
//  Mirror
//

#import <UIKit/UIKit.h>

@class TimelineBackgroundView;

NS_ASSUME_NONNULL_BEGIN

@protocol TimelineBackgroundViewDelegate <NSObject>

- (long)timelineView:(TimelineBackgroundView *)timelineView timestampForTimelineY:(CGFloat)y;
- (void)timelineView:(TimelineBackgroundView *)timelineView didSelectTaskName:(NSString *)taskName startTimestamp:(long)startTimestamp;

@optional
- (BOOL)timelineViewShouldBeginAddingRecord:(TimelineBackgroundView *)timelineView;

@end

@interface TimelineBackgroundView : UIView

@property (nonatomic, weak) id<TimelineBackgroundViewDelegate> delegate;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, assign) CGFloat bottomInset;

- (void)dismissTaskPicker;

@end

NS_ASSUME_NONNULL_END
