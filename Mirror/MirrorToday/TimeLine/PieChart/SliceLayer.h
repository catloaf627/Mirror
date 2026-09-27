//
//  SliceLayer.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/9.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import "UIColor+MirrorColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface SliceLayer : CAShapeLayer

@property (nonatomic, assign) CGFloat pieWidth ;
@property (nonatomic, assign) CGFloat startAngle;
@property (nonatomic, assign) CGFloat endAngle;
@property (nonatomic, assign) CGPoint centerPoint;
@property (nonatomic, assign) MirrorColorType colorType;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) BOOL showsOnlyPercentageText;
@property (nonatomic, assign) CGFloat textFontScale;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) CATextLayer *textLayer;
 
- (void)create;
 
@end

NS_ASSUME_NONNULL_END
