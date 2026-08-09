//
//  LegendView.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import <UIKit/UIKit.h>
#import "MirrorMacro.h"
#import "MirrorDataModel.h"
#import "HistogramView.h"
#import "PiechartView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PushAllRecordsDelegate <NSObject> // push viewcontroller用

@end

@interface LegendView : UIView <HistogramDelegate, PiechartDelegate>

@property (nonatomic, weak) UIViewController<PushAllRecordsDelegate> *delegate;
@property (nonatomic, copy) NSString *confirmationRangeText;
- (instancetype)initWithData:(NSMutableArray<MirrorDataModel *> *)data;
- (void)updateWithData:(NSMutableArray<MirrorDataModel *> *)data;
- (CGFloat)legendViewHeight;

@end

NS_ASSUME_NONNULL_END
