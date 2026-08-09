//
//  MirrorTaskModel.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/5.
//

#import "MirrorTaskModel.h"

@implementation MirrorTaskModel

- (instancetype)initWithTitle:(NSString *)taskName createdTime:(long)createTime colorType:(MirrorColorType)colorType isHidden:(BOOL)isHidden isAddTask:(BOOL)isAddTaskModel
{
    self = [super init];
    if (self) {
        _taskName = taskName;
        _createdTime = createTime;
        _color = colorType;
        _isHidden = isHidden;
        _isAddTaskModel = isAddTaskModel;
    }
    return self;
}

#pragma mark - Encode Decode

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:self.taskName forKey:@"task_name"];
    [encoder encodeBool:self.isHidden forKey:@"is_hidden"];
    [encoder encodeInt:[@(self.color) intValue] forKey:@"color"];
    [encoder encodeInt64:self.createdTime forKey:@"created_time"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        self.taskName = [decoder decodeObjectForKey:@"task_name"];
        self.isHidden = [decoder decodeBoolForKey:@"is_hidden"];
        self.color = [decoder decodeIntForKey:@"color"];
        self.createdTime = [decoder decodeInt64ForKey:@"created_time"];
    }
    return self;
}

@end
