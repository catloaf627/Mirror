//
//  TaskColorCirclePickerViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "UIColor+MirrorColor.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^TaskColorCirclePickerCompletion)(MirrorColorType color);

@interface TaskColorCirclePickerViewController : UIViewController

- (instancetype)initWithColors:(NSArray<NSNumber *> *)colors
                 selectedColor:(MirrorColorType)selectedColor
                   anchorFrame:(CGRect)anchorFrame
                     completion:(TaskColorCirclePickerCompletion)completion;

@end

NS_ASSUME_NONNULL_END
