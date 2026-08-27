//
//  SpecialDayEditViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorDayModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^SpecialDayEditValidation)(MirrorDayModel *day, NSString * _Nullable * _Nullable errorTitleKey);
typedef void (^SpecialDayEditCompletion)(MirrorDayModel *day);

@interface SpecialDayEditViewController : UIViewController

- (instancetype)initWithDay:(MirrorDayModel * _Nullable)day
                 validation:(SpecialDayEditValidation _Nullable)validation
                 completion:(SpecialDayEditCompletion)completion;

@end

NS_ASSUME_NONNULL_END
