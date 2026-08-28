//
//  OneDayTimelineViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^OneDayTimelineHeaderConfiguration)(UIView *headerView, NSMutableArray<MirrorRecordModel *> *records);

@interface OneDayTimelineViewController : UIViewController

//bg line 的 date = OneDayTimelineViewController.date
//record 显示用的 date = OneDayTimelineViewController.date 的 dayStart/dayEnd
//add record 的 date = OneDayTimelineViewController.date + 点击位置换算出的时间

- (instancetype)initWithDate:(NSDate *)date
                  headerView:(UIView * _Nullable)headerView
                headerHeight:(CGFloat)headerHeight
                headerInsets:(UIEdgeInsets)headerInsets
         headerConfiguration:(OneDayTimelineHeaderConfiguration _Nullable)headerConfiguration;

- (void)updateDate:(NSDate *)date;
- (void)reloadData;
- (void)dismissTransientEditingState;

@end

NS_ASSUME_NONNULL_END
