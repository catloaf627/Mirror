//
//  MirrorDataModel.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/4.
//

#import "MirrorRecordModel.h"

static NSInteger const kMirrorRecordMaxNoteLength = 200;

@implementation MirrorRecordModel

- (instancetype)initWithTitle:(NSString *)taskName startTime:(long)startTime endTime:(long)endTime
{
    self = [super init];
    if (self) {
        _taskName = taskName;
        _startTime = startTime;
        _endTime = endTime;
        _note = @"";
    }
    return self;
}

- (void)setNote:(NSString *)note
{
    if (![note isKindOfClass:NSString.class]) {
        _note = @"";
        return;
    }
    
    if (note.length > kMirrorRecordMaxNoteLength) {
        _note = [note substringToIndex:kMirrorRecordMaxNoteLength];
    } else {
        _note = [note copy];
    }
}

#pragma mark - Encode Decode

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.taskName forKey:@"task_name"];
    [encoder encodeInt64:self.startTime forKey:@"start_time"];
    [encoder encodeInt64:self.endTime forKey:@"end_time"];
    [encoder encodeObject:self.note forKey:@"note"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.taskName = [decoder decodeObjectOfClass:NSString.class forKey:@"task_name"];
        self.startTime = [decoder decodeInt64ForKey:@"start_time"];
        self.endTime = [decoder decodeInt64ForKey:@"end_time"];
        self.note = [decoder decodeObjectOfClass:NSString.class forKey:@"note"] ?: @"";
    }
    return self;
}


@end
