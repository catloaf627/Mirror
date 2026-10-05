//
//  TaskPieChartView.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "PiechartView.h"

NS_ASSUME_NONNULL_BEGIN

@interface TaskPieChartView : UIView

@property (nonatomic, weak) UIView<PiechartDelegate> *delegate;
@property (nonatomic, assign) CGFloat textFontScale;

+ (CGFloat)maximumPieWidthForAvailableWidth:(CGFloat)availableWidth;
+ (CGFloat)totalHeightForPieWidth:(CGFloat)pieWidth;
- (instancetype)initWithData:(NSMutableArray<MirrorReadModel *> *)data width:(CGFloat)width enableInteractive:(BOOL)enableInteractive;
- (void)setRangeSelectionActive:(BOOL)active;
- (void)updateWithData:(NSMutableArray<MirrorReadModel *> *)data width:(CGFloat)width enableInteractive:(BOOL)enableInteractive;

@end

NS_ASSUME_NONNULL_END
