//
//  MirrorReadModel.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/4.
//

#import "MirrorReadModel.h"

@implementation MirrorReadModel

- (instancetype)initWithTask:(MirrorTaskModel *)taskModel records:(NSMutableArray<MirrorRecordModel *> *)records
{
    self = [super init];
    if (self) {
        _taskModel = taskModel;
        _records = records;
    }
    return self;
}


@end
