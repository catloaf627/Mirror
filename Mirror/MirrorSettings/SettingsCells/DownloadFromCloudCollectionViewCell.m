//
//  DownloadFromCloudCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/5.
//

#import "DownloadFromCloudCollectionViewCell.h"

@implementation DownloadFromCloudCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCell
{
    [super configCellWithTitle:@"download_from_icloud" color:MirrorColorTypeCellOrange];
    self.toggle.hidden = YES;
}


@end
