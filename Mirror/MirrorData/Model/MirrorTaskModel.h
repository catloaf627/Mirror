//
//  MirrorTaskModel.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/5.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIColor+MirrorColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface MirrorTaskModel : NSObject <NSCoding, NSSecureCoding>

// 存在本地
@property (nonatomic, strong) NSString *taskName;
@property (nonatomic, assign) BOOL isHidden;
@property (nonatomic, assign) MirrorColorType color;
@property (nonatomic, assign) long createdTime;
// 外部赋值
@property (nonatomic, assign) BOOL isAddTaskModel;

- (instancetype)initWithTitle:(NSString *)taskName createdTime:(long)createTime colorType:(MirrorColorType)colorType isHidden:(BOOL)isHidden isAddTask:(BOOL)isAddTaskModel;


@end

NS_ASSUME_NONNULL_END
