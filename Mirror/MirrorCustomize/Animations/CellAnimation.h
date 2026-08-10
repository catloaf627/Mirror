//
//  CellAnimation.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/24.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CellAnimation : NSObject<UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) BOOL isPresent; // is present or is dismiss
@property (nonatomic, strong) UIColor *cellColor;
@property (nonatomic, assign) CGRect cellFrame;

@end

NS_ASSUME_NONNULL_END
