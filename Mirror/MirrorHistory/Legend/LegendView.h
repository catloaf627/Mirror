//
//  LegendView.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import <UIKit/UIKit.h>
#import "MirrorMacro.h"
#import "MirrorDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LegendView : UIView

- (instancetype)initWithData:(NSMutableArray<MirrorDataModel *> *)data;
- (void)updateWithData:(NSMutableArray<MirrorDataModel *> *)data;
- (CGFloat)legendViewHeight;

@end

NS_ASSUME_NONNULL_END
