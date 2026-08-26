//
//  MirrorManualVideoViewController.h
//  Mirror
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorManualVideoViewController : UIViewController

- (instancetype)initWithVideoItems:(NSArray<NSDictionary<NSString *, id> *> *)videoItems currentIndex:(NSInteger)currentIndex;

@end

NS_ASSUME_NONNULL_END
