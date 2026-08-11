//
//  MirrorReadModel.h
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/4.
//

#import <Foundation/Foundation.h>
#import "MirrorTaskModel.h"
#import "MirrorRecordModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MirrorReadModel : NSObject // 拼接数据，仅用于读取，不用于修改。

@property (nonatomic, strong) MirrorTaskModel *taskModel;
@property (nonatomic, strong) NSMutableArray<MirrorRecordModel *> *records;

- (instancetype)initWithTask:(MirrorTaskModel *)taskModel records:(NSMutableArray<MirrorRecordModel *> *)records;

@end

NS_ASSUME_NONNULL_END
