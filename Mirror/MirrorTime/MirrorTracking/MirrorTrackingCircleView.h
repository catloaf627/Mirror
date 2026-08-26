//
//  MirrorTrackingCircleView.h
//  Mirror
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

extern CGFloat const MirrorTrackingCircleLineWidth;

@interface MirrorTrackingCircleView : UIView

@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) CGFloat startAngle;
@property (nonatomic, strong) UIColor *taskColor;
@property (nonatomic, strong) UIColor *pulseColor;

@end

NS_ASSUME_NONNULL_END
