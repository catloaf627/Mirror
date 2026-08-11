//
//  LinechartView.h
//  Mirror
//
//  Created by Yuqing Wang on 2024/2/29.
//

#import <UIKit/UIKit.h>
#import "MirrorReadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LinechartView : UIView

- (void)refactorData:(NSMutableArray<NSMutableArray<MirrorReadModel *> *> *)originalData
            dateKeys:(NSMutableArray<NSString *> *)dateKeys;

@end

NS_ASSUME_NONNULL_END
