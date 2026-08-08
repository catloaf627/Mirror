//
//  LanguageCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/28.
//

#import "LanguageCollectionViewCell.h"

@implementation LanguageCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configCell
{
    [super configCellWithTitle:@"language" color:MirrorColorTypeCellPink];
    self.toggle.hidden = YES;
}

@end
