//
//  EditTaskCollectionViewCell.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/4/26.
//

#import "EditTaskCollectionViewCell.h"
#import "MirrorTaskModel.h"
#import "MirrorStorage.h"
#import "MirrorTool.h"
#import "UIColor+MirrorColor.h"
#import "ColorCollectionViewCell.h"
#import "MirrorMacro.h"
#import "MirrorLanguage.h"
#import <Masonry/Masonry.h>
#import "MirrorTimeText.h"
#import "MirrorSettings.h"
#import "UIFont+MirrorFont.h"

#define kPadding (10*kHeightRatio)
#define kElement (22*kHeightRatio)
@interface EditTaskCollectionViewCell () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate>
// Data
@property (nonatomic, strong) NSString *taskName;
// UI
@property (nonatomic, strong) UITextField *taskNameField;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UICollectionView *collectionView; // 色块collectionview
@property (nonatomic, strong) UIButton *archiveButton;
@property (nonatomic, strong) UIButton *totalTimeButton;

@end

@implementation EditTaskCollectionViewCell

+ (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (void)configWithIndex:(NSInteger)index
{
    self.taskName = [MirrorStorage retriveMirrorTasks][index].taskName;
    [self p_setupUI];
}

- (void)p_setupUI
{
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:self.taskName];
    UIColor *color = [UIColor mirrorColorNamed:task.color];
    BOOL isArchived = task.isArchived;
    
    self.backgroundColor = color;
    self.layer.cornerRadius = 14;
    
    [self addSubview:self.taskNameField];
    self.taskNameField.text = self.taskName;
    [self.taskNameField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.offset(kPadding);
        make.width.mas_equalTo(self.frame.size.width - 3*kPadding - 30);
        make.height.mas_equalTo(kElement);
    }];
    
    [self addSubview:self.deleteButton];
    [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.taskNameField);
        make.right.offset(-kPadding);
        make.width.height.mas_equalTo(kElement);
    }];
    
    [self addSubview:self.collectionView];
    [self.collectionView reloadData];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.taskNameField.mas_bottom).offset(kPadding);
        make.centerX.offset(0);
        make.width.mas_equalTo([self p_colorBlockWidth] * kMaxColorNum);
        make.height.mas_equalTo([self p_colorBlockWidth]);
    }];
    
    [self addSubview:self.archiveButton];
    [self.archiveButton setImage:[[[[UIImage systemImageNamed:isArchived ? @"archivebox.fill" : @"archivebox"] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeText]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.archiveButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.collectionView.mas_bottom).offset(kPadding);
        make.left.offset(kPadding);
        make.width.mas_equalTo(kElement);
        make.height.mas_equalTo(kElement);
    }];
    
    [self addSubview:self.totalTimeButton];
    long totalTime = [MirrorTool getTotalTimeOfPeriods:[MirrorStorage getAllTaskRecords:self.taskName]];
    [self.totalTimeButton setTitle:[[MirrorLanguage mirror_stringWithKey:@"total"] stringByAppendingString:[MirrorTimeText XdXhXmXsFull:totalTime]]forState:UIControlStateNormal];
    [self.totalTimeButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.collectionView.mas_bottom).offset(kPadding);
        make.right.offset(-kPadding);
        make.width.mas_equalTo(self.frame.size.width - kElement - 3*kPadding);
        make.height.mas_equalTo(kElement);
    }];
    
}

#pragma mark - Actions

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *currentText = textField.text;
    BOOL textIsTheSame = [currentText isEqualToString:self.taskName];
    BOOL textIsEmpty = !currentText || [currentText isEqualToString:@""];
    TaskNameExistsType existType = [MirrorStorage taskNameExists:currentText];
    if (textIsTheSame) { // taskname和之前一样
        
    } else if (textIsEmpty) { // taskname为空，不允许修改
        UIAlertController* newNameIsEmptyAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"name_field_cannot_be_empty"] message:nil preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* understandAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"gotcha"] style:UIAlertActionStyleDefault handler:nil];
        [newNameIsEmptyAlert addAction:understandAction];
        [self.delegate presentViewController:newNameIsEmptyAlert animated:YES completion:nil];
        [self.taskNameField setText:self.taskName];
    } else if (existType != TaskNameExistsTypeValid) { // taskname重复了，不允许修改
        UIAlertController* newNameIsDuplicateAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"task_cannot_be_duplicated"] message: [MirrorLanguage mirror_stringWithKey:existType == TaskNameExistsTypeExistsInCurrentTasks ? @"this_task_exists_in_current_task_list" : @"this_task_exists_in_the_archived_task_list"] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* understandAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"gotcha"] style:UIAlertActionStyleDefault handler:nil];
        [newNameIsDuplicateAlert addAction:understandAction];
        [self.delegate presentViewController:newNameIsDuplicateAlert animated:YES completion:nil];
        [self.taskNameField setText:self.taskName];
    } else { // taskname valid，允许修改
        [MirrorStorage editTask:self.taskName name:textField.text];
        self.taskName = textField.text;
    }
}

- (void)archiveAction
{
    MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:self.taskName];
    if (task.isArchived) {
        [MirrorStorage cancelArchiveTask:self.taskName];
        [self.archiveButton setImage:[[[[UIImage systemImageNamed:@"archivebox"] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeText]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    } else {
        [MirrorStorage archiveTask:self.taskName];
        [self.archiveButton setImage:[[[[UIImage systemImageNamed:@"archivebox.fill"] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeText]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    }
}

- (void)deleteAction
{
    UIAlertController* deleteButtonAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete_task_?"] message:nil preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        [self.delegate dismissViewControllerAnimated:YES completion:^{
            [MirrorStorage deleteTask:self.taskName];
        }];
    }];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];
    
    [deleteButtonAlert addAction:cancelAction];
    [deleteButtonAlert addAction:deleteAction];
    [self.delegate presentViewController:deleteButtonAlert animated:YES completion:nil];
}

#pragma mark - Getters

- (UITextField *)taskNameField
{
    if (!_taskNameField) {
        _taskNameField = [UITextField new];
        _taskNameField.placeholder = [MirrorLanguage mirror_stringWithKey:@"enter_task_title"];
        _taskNameField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _taskNameField.font = [UIFont mirrorLabelFont];
        _taskNameField.enabled = YES;
        _taskNameField.delegate = self;
        _taskNameField.textAlignment = NSTextAlignmentLeft;
    }
    return _taskNameField;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView){
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        _collectionView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        
        [_collectionView registerClass:[ColorCollectionViewCell class] forCellWithReuseIdentifier:[ColorCollectionViewCell identifier]];
    }
    return _collectionView;
}

- (UIButton *)archiveButton
{
    if (!_archiveButton) {
        _archiveButton = [UIButton new];
        UIImage *image = [[UIImage systemImageNamed:@"archivebox"] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeText]];
        UIImage *imageWithRightColor = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [_archiveButton setImage:[imageWithRightColor imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _archiveButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_archiveButton addTarget:self action:@selector(archiveAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _archiveButton;
}

- (UIButton *)deleteButton
{
    if (!_deleteButton) {
        _deleteButton = [UIButton new];
        UIImage *image = [[UIImage systemImageNamed:@"delete.left"] imageWithTintColor:[UIColor mirrorColorNamed:MirrorColorTypeText]];
        UIImage *imageWithRightColor = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [_deleteButton setImage:[imageWithRightColor imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _deleteButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        [_deleteButton addTarget:self action:@selector(deleteAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteButton;
}

- (UIButton *)totalTimeButton
{
    if (!_totalTimeButton) {
        _totalTimeButton = [UIButton new];
        _totalTimeButton.titleLabel.font = [UIFont mirrorHintFont];
        [_totalTimeButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeText] forState:UIControlStateNormal];
        _totalTimeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    }
    return _totalTimeButton;
}


#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 选中某色块时，更新背景颜色为该色块颜色，更新selectedColor为该色块颜色
    MirrorColorType selectedColor =  self.colorBlocks[indexPath.item].color;
    self.backgroundColor = [UIColor mirrorColorNamed:selectedColor];
    [MirrorStorage editTask:self.taskName color:selectedColor];
    [collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return kMaxColorNum;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 展示所有色块
    MirrorColorModel *colorModel = (MirrorColorModel *)self.colorBlocks[indexPath.item];
    colorModel.isSelected = CGColorEqualToColor([UIColor mirrorColorNamed:colorModel.color].CGColor, self.backgroundColor.CGColor); // 如果某色块和当前选中的颜色一致，标记为选中
    ColorCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[ColorCollectionViewCell identifier] forIndexPath:indexPath];
    // 更新色块（颜色、是否选中）
    [cell configWithModel:colorModel];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat width = [self p_colorBlockWidth];
    return CGSizeMake(width, width);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (NSArray<MirrorColorModel *> *)colorBlocks
{
    MirrorColorModel *pinkModel = [MirrorColorModel new];
    pinkModel.color = MirrorColorTypeCellPink;
    MirrorColorModel *orangeModel = [MirrorColorModel new];
    orangeModel.color = MirrorColorTypeCellOrange;
    MirrorColorModel *yellowModel = [MirrorColorModel new];
    yellowModel.color = MirrorColorTypeCellYellow;
    MirrorColorModel *greenModel = [MirrorColorModel new];
    greenModel.color = MirrorColorTypeCellGreen;
    MirrorColorModel *tealModel = [MirrorColorModel new];
    tealModel.color = MirrorColorTypeCellTeal;
    MirrorColorModel *blueModel = [MirrorColorModel new];
    blueModel.color = MirrorColorTypeCellBlue;
    MirrorColorModel *purpleModel = [MirrorColorModel new];
    purpleModel.color = MirrorColorTypeCellPurple;
    MirrorColorModel *grayModel = [MirrorColorModel new];
    grayModel.color = MirrorColorTypeCellGray;
    return @[pinkModel,orangeModel,yellowModel,greenModel,tealModel,blueModel,purpleModel,grayModel];
}


#pragma mark - Private methods

- (CGFloat)p_colorBlockWidth
{
    return (self.frame.size.width - 2*kPadding)/kMaxColorNum;
}


@end
