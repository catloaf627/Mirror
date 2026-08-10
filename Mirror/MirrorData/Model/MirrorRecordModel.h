//
//  MirrorDataModel.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorRecordModel : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, assign) NSInteger originalIndex; // records被taskname切割、被时间段切割的时候才赋值

@property (nonatomic, strong) NSString *taskName;
@property (nonatomic, assign) long startTime;
@property (nonatomic, assign) long endTime;
@property (nonatomic, copy) NSString *note;

- (instancetype)initWithTitle:(NSString *)taskName startTime:(long)startTime endTime:(long)endTime;

@end

NS_ASSUME_NONNULL_END
