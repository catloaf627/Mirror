//
//  MirrorDayModel.h
//  Mirror
//

#import <Foundation/Foundation.h>
#import "UIColor+MirrorColor.h"

NS_ASSUME_NONNULL_BEGIN

@interface MirrorDayModel : NSObject <NSCoding, NSSecureCoding>

@property (nonatomic, copy) NSString *dateStr;
@property (nonatomic, copy) NSString *info;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, assign) MirrorSystemColorType color;

- (instancetype)initWithDateStr:(NSString *)dateStr info:(NSString *)info icon:(NSString *)icon;
- (instancetype)initWithDateStr:(NSString *)dateStr info:(NSString *)info icon:(NSString *)icon color:(MirrorSystemColorType)color;

@end

NS_ASSUME_NONNULL_END
