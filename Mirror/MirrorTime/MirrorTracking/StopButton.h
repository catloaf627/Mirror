//
//  StopButton.h
//  Mirror
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface StopButton : UIButton

- (instancetype)initWithTaskColor:(UIColor *)taskColor;
- (void)updateProgress:(CGFloat)progress;

@end

NS_ASSUME_NONNULL_END
