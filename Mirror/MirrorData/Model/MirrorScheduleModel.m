//
//  MirrorScheduleModel.m
//  Mirror
//

#import "MirrorScheduleModel.h"

@implementation MirrorScheduleModel

- (instancetype)initWithInfo:(NSString *)scheduleInfo startTime:(long)startTime endTime:(long)endTime
{
    self = [super init];
    if (self) {
        _scheduleInfo = [scheduleInfo isKindOfClass:NSString.class] ? [scheduleInfo copy] : @"";
        _startTime = startTime;
        _endTime = endTime;
    }
    return self;
}

- (void)setScheduleInfo:(NSString *)scheduleInfo
{
    _scheduleInfo = [scheduleInfo isKindOfClass:NSString.class] ? [scheduleInfo copy] : @"";
}

#pragma mark - Encode Decode

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.scheduleInfo forKey:@"schedule_info"];
    [encoder encodeInt64:self.startTime forKey:@"start_time"];
    [encoder encodeInt64:self.endTime forKey:@"end_time"];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init])) {
        self.scheduleInfo = [decoder decodeObjectOfClass:NSString.class forKey:@"schedule_info"] ?: @"";
        self.startTime = [decoder decodeInt64ForKey:@"start_time"];
        self.endTime = [decoder decodeInt64ForKey:@"end_time"];
    }
    return self;
}

@end
