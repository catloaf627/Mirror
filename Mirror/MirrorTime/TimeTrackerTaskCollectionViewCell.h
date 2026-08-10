//
//  TimeTrackerTaskCollectionViewCell.h
//  Mirror
//
//  Created by wangyuqing on 2022/9/26.
//

#import <UIKit/UIKit.h>
#import "MirrorTaskModel.h"

NS_ASSUME_NONNULL_BEGIN

static CGFloat const kInterspacing = 16;

@class TimeTrackerTaskCollectionViewCell;

@protocol TimeTrackerTaskCollectionViewCellDelegate <NSObject>

- (void)timeTrackerTaskCollectionViewCellDidTapEdit:(TimeTrackerTaskCollectionViewCell *)cell;
- (void)timeTrackerTaskCollectionViewCellDidTapColor:(TimeTrackerTaskCollectionViewCell *)cell;
- (void)timeTrackerTaskCollectionViewCellDidTapDelete:(TimeTrackerTaskCollectionViewCell *)cell;

@end

@interface TimeTrackerTaskCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) id<TimeTrackerTaskCollectionViewCellDelegate> delegate;

+ (NSString *)identifier;
- (void)configWithTaskname:(NSString *)taskName;
- (BOOL)dismissActionButtonsIfNeeded;

@end

NS_ASSUME_NONNULL_END
