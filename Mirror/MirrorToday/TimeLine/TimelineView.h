//
//  TimelineView.h
//  Mirror
//

#import <UIKit/UIKit.h>

@class TimelineView;

NS_ASSUME_NONNULL_BEGIN

@protocol TimelineViewDelegate <NSObject>

@optional
- (BOOL)timelineViewShouldBeginAddingRecord:(TimelineView *)timelineView;
- (void)timelineViewDidAddRecord:(TimelineView *)timelineView;

@end

@interface TimelineView : UIView

@property (nonatomic, weak) id<TimelineViewDelegate> delegate;
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, assign) CGFloat bottomInset;

- (void)configureWithHourHeight:(CGFloat)hourHeight
              dayStartTimestamp:(long)dayStartTimestamp
                dayEndTimestamp:(long)dayEndTimestamp;
- (void)dismissTaskPicker;

@end

NS_ASSUME_NONNULL_END
