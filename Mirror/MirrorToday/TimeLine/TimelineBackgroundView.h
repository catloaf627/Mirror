//
//  TimelineBackgroundView.h
//  Mirror
//

#import <UIKit/UIKit.h>

@class TimelineBackgroundView;

NS_ASSUME_NONNULL_BEGIN

@protocol TimelineBackgroundViewDelegate <NSObject>

@optional
- (BOOL)timelineViewShouldBeginAddingRecord:(TimelineBackgroundView *)timelineView;
- (void)timelineViewDidAddRecord:(TimelineBackgroundView *)timelineView;

@end

@interface TimelineBackgroundView : UIView

@property (nonatomic, weak) id<TimelineBackgroundViewDelegate> delegate;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, assign) CGFloat bottomInset;

- (void)configureWithHourHeight:(CGFloat)hourHeight
              dayStartTimestamp:(long)dayStartTimestamp
                dayEndTimestamp:(long)dayEndTimestamp;
- (void)dismissTaskPicker;

@end

NS_ASSUME_NONNULL_END
