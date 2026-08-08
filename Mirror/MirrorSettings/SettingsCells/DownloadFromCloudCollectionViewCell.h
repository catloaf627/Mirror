//
//  DownloadFromCloudCollectionViewCell.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/5.
//

#import "ToggleCollectionViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface DownloadFromCloudCollectionViewCell : ToggleCollectionViewCell

+ (NSString *)identifier;
- (void)configCell;

@end

NS_ASSUME_NONNULL_END
