//
//  MirrorDayModel.m
//  Mirror
//

#import "MirrorDayModel.h"

@implementation MirrorDayModel

- (instancetype)initWithDateStr:(NSString *)dateStr info:(NSString *)info icon:(NSString *)icon
{
    return [self initWithDateStr:dateStr info:info icon:icon color:MirrorSystemColorTypeBlue];
}

- (instancetype)initWithDateStr:(NSString *)dateStr info:(NSString *)info icon:(NSString *)icon color:(MirrorSystemColorType)color
{
    self = [super init];
    if (self) {
        _dateStr = [dateStr copy];
        _info = [info copy];
        _icon = [icon copy];
        _color = color;
    }
    return self;
}

- (void)setDateStr:(NSString *)dateStr
{
    _dateStr = [dateStr isKindOfClass:NSString.class] ? [dateStr copy] : @"";
}

- (void)setInfo:(NSString *)info
{
    _info = [info isKindOfClass:NSString.class] ? [info copy] : @"";
}

- (void)setIcon:(NSString *)icon
{
    _icon = [icon isKindOfClass:NSString.class] ? [icon copy] : @"";
}

- (void)setColor:(MirrorSystemColorType)color
{
    _color = color;
}

#pragma mark - Encode Decode

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.dateStr forKey:@"date_str"];
    [encoder encodeObject:self.info forKey:@"info"];
    [encoder encodeObject:self.icon forKey:@"icon"];
    [encoder encodeInteger:self.color forKey:@"color"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        self.dateStr = [decoder decodeObjectOfClass:NSString.class forKey:@"date_str"] ?: @"";
        self.info = [decoder decodeObjectOfClass:NSString.class forKey:@"info"] ?: @"";
        self.icon = [decoder decodeObjectOfClass:NSString.class forKey:@"icon"] ?: @"";
        self.color = [decoder decodeIntegerForKey:@"color"];
    }
    return self;
}

@end
