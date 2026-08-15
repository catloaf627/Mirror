//
//  GridCollectionViewCell.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/2.
//

#import <UIKit/UIKit.h>
#import "MirrorStorage.h"

NS_ASSUME_NONNULL_BEGIN

@interface GridCollectionViewCell : UICollectionViewCell

@property (nonatomic, assign) long totalTime; // config cell的时候算过一次了，did select cell的时候就不要再算一次了，直接用这里的值

+ (NSString *)identifier;
- (void)configWithData:(NSMutableArray<MirrorReadModel *> *)data day:(MirrorDayModel * _Nullable)day isSelected:(BOOL)isSelected;

@end

NS_ASSUME_NONNULL_END
