//
//  TaskPeriodCollectionViewCell.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/15.
//

#import <UIKit/UIKit.h>
#import "MirrorTaskModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BottomRightType) {
    BottomRightTypeTotal, // 右下角展示任务总时长
    BottomRightTypeName, // 右下角展示任务名称
};

@protocol VCForPeriodCellProtocol <NSObject>

-(void)updateUIAfterDeleteDataAtIndex:(NSInteger)index;

@end

@interface TaskPeriodCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) UIViewController<VCForPeriodCellProtocol> *delegate;

+ (NSString *)identifier;
- (void)configWithTaskname:(NSString *)taskName periodIndex:(NSInteger)index type:(BottomRightType)type;
- (void)showDeleteButton;
- (void)toggleDeleteButton;
- (void)previewDeleteButton;


@end

NS_ASSUME_NONNULL_END
