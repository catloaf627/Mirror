//
//  TodayViewController.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/4.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TodayViewController : UIViewController

//TodayViewController 拥有 header
//OneDayTimelineViewController 负责摆放 header
//OneDayTimelineViewController reload 后把当天 records 回传
//TodayViewController 用 records 更新 TodayTotalHeader

@end

NS_ASSUME_NONNULL_END
