//
//  LegendView.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/20.
//

#import <UIKit/UIKit.h>
#import "MirrorMacro.h"
#import "MirrorReadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LegendView : UIView

- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data;
- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data;
- (CGFloat)legendViewHeight;

@end

NS_ASSUME_NONNULL_END
