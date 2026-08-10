//
//  HistogramView.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import <UIKit/UIKit.h>
#import "MirrorMacro.h"
#import "MirrorDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@class HistogramView;

@protocol HistogramDelegate <NSObject>

- (void)histogramView:(HistogramView *)histogramView didSelectData:(MirrorDataModel *)data;

@end

@interface HistogramView : UIView

@property (nonatomic, weak) id<HistogramDelegate> delegate;

- (instancetype)initWithData:(NSMutableArray<MirrorDataModel *> *)data;
- (void)updateWithData:(NSMutableArray<MirrorDataModel *> *)data;

@end

NS_ASSUME_NONNULL_END
