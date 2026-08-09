//
//  TimeTrackingViewController.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TimeTrackingViewController : UIViewController

@property (nonatomic, assign) CGRect cellFrame;
- (instancetype)initWithTaskName:(NSString *)taskName;
- (instancetype)initWithTaskName:(NSString *)taskName accurateStartDate:(NSDate *)accurateStartDate;

@end

NS_ASSUME_NONNULL_END
