//
//  HistogramCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/14.
//

#import "HistogramCollectionViewCell.h"
#import "MirrorTool.h"
#import <Masonry/Masonry.h>
#import "MirrorTimeText.h"

static const CGFloat kLabelHeight = 20;

@interface HistogramCollectionViewCell ()

@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIView *coloredView;

@end

@implementation HistogramCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCellWithData:(NSMutableArray<MirrorDataModel *> *)data index:(NSInteger)index
{
    float percentage = [self percentageFromData:data index:index];
    // 每次update都重新init coloredView以保证实时更新，先removeFromSuperview再设置为nil才是正确的顺序！
    [self.coloredView removeFromSuperview];
    self.coloredView = nil;

    [self addSubview:self.coloredView];
    self.coloredView.backgroundColor = [UIColor mirrorColorNamed:data[index].taskModel.color];
    [self.coloredView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.offset(0);
        make.height.mas_equalTo((self.frame.size.height - kLabelHeight) * percentage);
    }];
    
    [self addSubview:self.timeLabel];
    self.timeLabel.text = [MirrorTimeText XdXhXmXsShort:[MirrorTool getTotalTimeOfPeriods:data[index].records]];
    self.timeLabel.textColor = [UIColor mirrorColorNamed:[UIColor mirror_getPulseColorType:data[index].taskModel.color]];
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.offset(0);
        make.bottom.mas_equalTo(self.coloredView.mas_top);
        make.height.mas_equalTo(kLabelHeight);
    }];
}

- (float)percentageFromData:(NSMutableArray<MirrorDataModel *> *)data index:(NSInteger)index
{
    long maxTime = 0;
    for (int i=0; i<data.count; i++) {
        long taskiTime = [MirrorTool getTotalTimeOfPeriods:data[i].records]; // 第i个task的总时间
        if (taskiTime > maxTime) maxTime = taskiTime;
    }
    float percentage = maxTime ? [MirrorTool getTotalTimeOfPeriods:data[index].records]/(double)maxTime : 0;
    return percentage;
}

- (UIView *)coloredView
{
    if (!_coloredView) {
        _coloredView = [UIView new];
        // cell自己的圆角
        CAShapeLayer * maskLayer = [CAShapeLayer layer];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: self.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: (CGSize){14., 14.}].CGPath;
        _coloredView.layer.mask = maskLayer;
    }
    return _coloredView;
}

- (UILabel *)timeLabel
{
    if (!_timeLabel) {
        _timeLabel = [UILabel new];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.font = [UIFont systemFontOfSize:12];
    }
    return _timeLabel;
}

@end
