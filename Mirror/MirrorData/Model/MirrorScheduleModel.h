//
//  MirrorScheduleModel.h
//  Mirror
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorScheduleModel : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, assign) NSInteger originalIndex;
@property (nonatomic, copy) NSString *scheduleInfo;
@property (nonatomic, assign) long startTime;
@property (nonatomic, assign) long endTime;

- (instancetype)initWithInfo:(NSString *)scheduleInfo startTime:(long)startTime endTime:(long)endTime;

@end

NS_ASSUME_NONNULL_END
