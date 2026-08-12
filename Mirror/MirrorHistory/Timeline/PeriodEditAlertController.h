//
//  PeriodEditAlertController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "TimelineRangeAxisView.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^PeriodEditAlertRangeValueChanged)(BOOL isStartTime, long timestamp);
typedef void (^PeriodEditAlertDismissed)(NSString *note);

@interface PeriodEditAlertController : NSObject

@property (nonatomic, strong, readonly) TimelineRangeAxisView *rangeAxisView;
@property (nonatomic, assign, readonly, getter=isPresented) BOOL presented;

- (instancetype)initWithTitle:(NSString *)title
                    axisColor:(UIColor *)axisColor
              minimumTimestamp:(long)minimumTimestamp
              maximumTimestamp:(long)maximumTimestamp
                startTimestamp:(long)startTimestamp
                  endTimestamp:(long)endTimestamp
                  canDragStart:(BOOL)canDragStart
                    canDragEnd:(BOOL)canDragEnd
                          note:(nullable NSString *)note
                  valueChanged:(PeriodEditAlertRangeValueChanged)valueChanged
                     dismissed:(PeriodEditAlertDismissed)dismissed;

- (void)presentFromViewController:(UIViewController *)viewController;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
