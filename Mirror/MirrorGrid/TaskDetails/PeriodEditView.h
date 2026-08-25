//
//  PeriodEditView.h
//  Mirror
//

#import <UIKit/UIKit.h>
#import "MirrorRecordModel.h"
#import "MirrorTaskModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^PeriodEditViewActionHandler)(void);

@interface PeriodEditView : UIView

@property (nonatomic, copy, nullable) PeriodEditViewActionHandler cancelHandler;
@property (nonatomic, copy, nullable) PeriodEditViewActionHandler doneHandler;

- (instancetype)initWithRecord:(MirrorRecordModel *)record
                         tasks:(NSArray<MirrorTaskModel *> *)tasks
              minimumTimestamp:(NSNumber * _Nullable)minimumTimestamp
              maximumTimestamp:(NSNumber * _Nullable)maximumTimestamp;

- (MirrorRecordModel *)editedRecord;
- (void)refreshAppearanceForCurrentTheme;

@end

NS_ASSUME_NONNULL_END
