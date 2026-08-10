//
//  PiechartDataCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/30.
//

#import "PiechartDataCollectionViewCell.h"
#import "MirrorSettings.h"

@implementation PiechartDataCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCell
{
    [super configCellWithTitle:@"show_piechart_on_data" color:MirrorColorTypeCellBlue];
    self.toggle.hidden = NO;
    [self.toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    if ([MirrorSettings appliedPieChartData]) {
        [self.toggle setOn:YES animated:YES];
    } else {
        [self.toggle setOn:NO animated:YES];
    }
}

- (void)switchChanged:(UISwitch *)sender {
    [MirrorSettings switchChartTypeData];
}

@end
