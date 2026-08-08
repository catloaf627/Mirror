//
//  LanguageCollectionViewCell.h
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/28.
//

#import "ToggleCollectionViewCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface LanguageCollectionViewCell : ToggleCollectionViewCell

+ (NSString *)identifier;
- (void)configCell;

@end

NS_ASSUME_NONNULL_END
