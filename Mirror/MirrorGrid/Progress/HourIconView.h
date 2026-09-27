//
//  HourIconView.h
//  Mirror
//
//  Created by Yuqing Wang on 2026/9/27.
//

#import <UIKit/UIKit.h>
#import "UIColor+MirrorColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface HourIconView : UIView

- (void)updateWithHours:(CGFloat)hours color:(MirrorColorType)color;

@end

NS_ASSUME_NONNULL_END
