//
//  PeriodEditAlertView.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^PeriodEditAlertRecordChanged)(MirrorRecordModel *record);

@interface PeriodEditAlertView : UIView

@property (nonatomic, assign, readonly, getter=isPresented) BOOL presented;

- (instancetype)initWithRecord:(MirrorRecordModel *)record
                    periodIndex:(NSInteger)periodIndex
               minimumTimestamp:(NSNumber * _Nullable)minimumTimestamp
               maximumTimestamp:(NSNumber * _Nullable)maximumTimestamp
                  recordChanged:(PeriodEditAlertRecordChanged)recordChanged;

- (void)presentFromViewController:(UIViewController *)viewController;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
