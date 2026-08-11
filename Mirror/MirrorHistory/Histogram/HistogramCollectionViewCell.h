//
//  HistogramCollectionViewCell.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/14.
//

#import <UIKit/UIKit.h>
#import "MirrorReadModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface HistogramCollectionViewCell : UICollectionViewCell

+ (NSString *)identifier;
- (void)configCellWithData:(NSMutableArray<MirrorReadModel *> *)data index:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
