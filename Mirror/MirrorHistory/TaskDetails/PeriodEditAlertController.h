//
//  PeriodEditAlertController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^PeriodEditAlertTimeValueChanged)(BOOL isStartTime, long timestamp);
typedef void (^PeriodEditAlertDismissed)(NSString *note);

@interface PeriodEditAlertController : NSObject

@property (nonatomic, assign, readonly, getter=isPresented) BOOL presented;

- (instancetype)initWithRecord:(MirrorRecordModel *)record
               minimumTimestamp:(NSNumber * _Nullable)minimumTimestamp
               maximumTimestamp:(NSNumber * _Nullable)maximumTimestamp
                   valueChanged:(PeriodEditAlertTimeValueChanged)valueChanged
                      dismissed:(PeriodEditAlertDismissed)dismissed;

- (void)presentFromViewController:(UIViewController *)viewController;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
