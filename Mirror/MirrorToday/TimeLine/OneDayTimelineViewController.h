//
//  OneDayTimelineViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^OneDayTimelineHeaderConfiguration)(UIView *headerView, NSMutableArray<MirrorRecordModel *> *records);

@interface OneDayTimelineViewController : UIViewController

- (instancetype)initWithDate:(NSDate *)date
                  headerView:(UIView * _Nullable)headerView
                headerHeight:(CGFloat)headerHeight
                headerInsets:(UIEdgeInsets)headerInsets
         headerConfiguration:(OneDayTimelineHeaderConfiguration _Nullable)headerConfiguration;

- (void)updateDate:(NSDate *)date;
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
