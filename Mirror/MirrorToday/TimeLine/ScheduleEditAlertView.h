//
//  ScheduleEditAlertView.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorScheduleModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^ScheduleEditCompletion)(MirrorScheduleModel *schedule);

@interface ScheduleEditAlertView : UIView

@property (nonatomic, assign, readonly, getter=isPresented) BOOL presented;

- (instancetype)initWithSchedule:(MirrorScheduleModel *)schedule
                        dayStart:(long)dayStart
                          dayEnd:(long)dayEnd
                           isNew:(BOOL)isNew
                      completion:(ScheduleEditCompletion)completion;

- (void)presentFromViewController:(UIViewController *)viewController;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
