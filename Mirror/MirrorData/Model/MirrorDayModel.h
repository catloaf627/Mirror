//
//  MirrorDayModel.h
//  Mirror
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MirrorDayModel : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, copy) NSString *dateStr;
@property (nonatomic, copy) NSString *info;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *color;

- (instancetype)initWithDateStr:(NSString *)dateStr info:(NSString *)info icon:(NSString *)icon;
- (instancetype)initWithDateStr:(NSString *)dateStr info:(NSString *)info icon:(NSString *)icon color:(NSString *)color;

@end

NS_ASSUME_NONNULL_END
