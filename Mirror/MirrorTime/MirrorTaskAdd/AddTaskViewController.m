//
//  AddTaskViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2022/9/30.
//

#import "AddTaskViewController.h"
#import "ColorCollectionViewCell.h"
#import "MirrorMacro.h"
#import <Masonry/Masonry.h>
#import "MirrorLanguage.h"
#import "UIColor+MirrorColor.h"
#import "MirrorStorage.h"
#import "UIFont+MirrorFont.h"

static CGFloat const kAddTaskVCPadding = 20;

@interface AddTaskViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, strong) MirrorTaskModel *brandNewTaskModel; //新创建的task，由于OC不允许使用new作为property的前缀，这里使用了brand new
@property (nonatomic, strong) NSString *editingTaskName;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *editTaskNameTextField;
@property (nonatomic, strong) UILabel *addTaskNameHint;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<MirrorColorModel *> *colorBlocks;
@property (nonatomic, strong) UIButton *discardButton;
@property (nonatomic, strong) UIButton *createButton;

@end

@implementation AddTaskViewController

- (instancetype)initWithTaskName:(NSString *)taskName
{
    self = [super init];
    if (self) {
        _editingTaskName = taskName; // if empty, then it's a create page, if not, then it's a edit page.
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self.editTaskNameTextField becomeFirstResponder];
}

- (void)viewDidLayoutSubviews
{
    self.view.layer.cornerRadius = 20;
    self.view.layer.masksToBounds = YES;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(viewGetsTapped:)];
    tapRecognizer.numberOfTapsRequired = 1;
    tapRecognizer.delegate = self;
    [self.view.superview addGestureRecognizer:tapRecognizer];
}

- (void)clickCreateBtn
{
    NSString *currentText = self.editTaskNameTextField.text;
    BOOL textIsEmpty = !currentText || [currentText isEqualToString:@""];
    BOOL textIsTheSame = [currentText isEqualToString:self.editingTaskName];
    TaskNameExistsType existType = [MirrorStorage taskNameExists:currentText];
    if (textIsEmpty) {
        UIAlertController* newNameIsEmptyAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"name_field_cannot_be_empty"] message:nil preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* understandAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"gotcha"] style:UIAlertActionStyleDefault handler:nil];
        [newNameIsEmptyAlert addAction:understandAction];
        [self presentViewController:newNameIsEmptyAlert animated:YES completion:nil];
    } else if (!textIsTheSame && existType != TaskNameExistsTypeValid) {
        UIAlertController* newNameIsDuplicateAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"task_cannot_be_duplicated"] message: [MirrorLanguage mirror_stringWithKey:@"this_task_exists_in_current_task_list"] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* understandAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"gotcha"] style:UIAlertActionStyleDefault handler:nil];
        [newNameIsDuplicateAlert addAction:understandAction];
        [self presentViewController:newNameIsDuplicateAlert animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.editingTaskName.length > 0) {
                if (!textIsTheSame) {
                    [MirrorStorage editTask:self.editingTaskName name:currentText];
                }
                [MirrorStorage editTask:currentText color:self.brandNewTaskModel.color];
            } else {
                self.brandNewTaskModel.taskName = currentText; //taskname退出时更新
                self.brandNewTaskModel.createdTime = (long)[[NSDate now] timeIntervalSince1970]; //获取当前时间
                [MirrorStorage createTask:self.brandNewTaskModel];
            }
        }];
    }

}

- (void)clickDiscardButton
{
    if (self.editingTaskName.length == 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    UIAlertController* deleteButtonAlert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete_task_?"] message:[MirrorLanguage mirror_stringWithKey:@"delete_task_warning"] preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* deleteAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
        [self dismissViewControllerAnimated:YES completion:^{
            [MirrorStorage deleteTask:self.editingTaskName];
        }];
    }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"cancel"] style:UIAlertActionStyleDefault handler:nil];
    [deleteButtonAlert addAction:cancelAction];
    [deleteButtonAlert addAction:deleteAction];
    [self presentViewController:deleteButtonAlert animated:YES completion:nil];
}

- (void)p_setupUI
{
    self.view.backgroundColor = [UIColor mirrorColorNamed:self.brandNewTaskModel.color];
    BOOL isEditingTask = self.editingTaskName.length > 0;
    self.titleLabel.text = [MirrorLanguage mirror_stringWithKey:isEditingTask ? @"edit_this_task" : @"create_a_new_task"];
    self.editTaskNameTextField.text = self.brandNewTaskModel.taskName;
    [self.view addSubview:self.titleLabel];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(20);
        make.centerX.offset(0);
        make.width.mas_equalTo(kScreenWidth - 2*kAddTaskVCPadding);
    }];
    [self.view addSubview:self.editTaskNameTextField];
    [self.editTaskNameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(16);
        make.centerX.offset(0);
        make.width.mas_equalTo(kScreenWidth - 2*kAddTaskVCPadding);
    }];
    if (!isEditingTask) {
        [self.view addSubview:self.addTaskNameHint];
        [self.addTaskNameHint mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.editTaskNameTextField.mas_bottom).offset(8);
            make.centerX.offset(0);
            make.width.mas_equalTo(kScreenWidth - 2*kAddTaskVCPadding);
        }];
    }
    
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        if (isEditingTask) {
            make.top.mas_equalTo(self.editTaskNameTextField.mas_bottom).offset(16);
        } else {
            make.top.mas_equalTo(self.addTaskNameHint.mas_bottom).offset(16);
        }
        make.centerX.offset(0);
        make.width.mas_equalTo(kScreenWidth - 2*kAddTaskVCPadding);
        make.height.mas_equalTo([self p_colorBlockWidth]);
    }];
    
    if (isEditingTask) {
        [self.discardButton setImage:[[UIImage systemImageNamed:@"delete.left"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.discardButton setTitle:[MirrorLanguage mirror_stringWithKey:@"delete"] forState:UIControlStateNormal];
        [self.createButton setTitle:[MirrorLanguage mirror_stringWithKey:@"save"] forState:UIControlStateNormal];
    }
    [self.view addSubview:self.discardButton];
    [self.view addSubview:self.createButton];
    [self.discardButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.collectionView.mas_bottom).offset(20);
        make.left.offset(kAddTaskVCPadding);
        make.width.mas_equalTo(kScreenWidth/2-kAddTaskVCPadding);
        make.height.mas_equalTo(40);
    }];
    [self.createButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.collectionView.mas_bottom).offset(20);
        make.left.mas_equalTo(self.discardButton.mas_right).offset(0);
        make.width.mas_equalTo(kScreenWidth/2-kAddTaskVCPadding);
        make.height.mas_equalTo(40);
    }];
    
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 选中某色块时，更新背景颜色为该色块颜色，更新model的颜色为该色块颜色
    MirrorColorType selectedColor =  self.colorBlocks[indexPath.item].color;
    self.view.backgroundColor = [UIColor mirrorColorNamed:selectedColor];
    self.brandNewTaskModel.color = selectedColor; // 颜色实时更新
    [collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return kMaxColorNum;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 展示所有色块
    MirrorColorModel *taskModel = (MirrorColorModel *)self.colorBlocks[indexPath.item];
    taskModel.isSelected = CGColorEqualToColor([UIColor mirrorColorNamed:taskModel.color].CGColor, [UIColor mirrorColorNamed:self.brandNewTaskModel.color].CGColor); // 如果某色块和当前model的颜色一致，标记为选中
    ColorCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[ColorCollectionViewCell identifier] forIndexPath:indexPath];
    // 更新色块（颜色、是否选中）
    [cell configWithModel:taskModel];
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

#pragma mark - Actions
// 给superview添加了点击手势（为了在点击上方不属于self.view的地方可以dismiss掉self）
- (void)viewGetsTapped:(UIGestureRecognizer *)tapRecognizer
{
    CGPoint touchPoint = [tapRecognizer locationInView:self.view];
    if (touchPoint.y <= 0) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIGestureRecognizerDelegate
// 这里需要判断下，如果点击的位置属于self.view，这时候忽略superview上的手势
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint touchPoint = [touch locationInView:self.view];
    if (touchPoint.y <= 0) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Getters

- (MirrorTaskModel *)brandNewTaskModel
{
    if (!_brandNewTaskModel) {
        if (self.editingTaskName.length > 0) {
            MirrorTaskModel *task = [MirrorStorage getTaskModelFromDB:self.editingTaskName];
            _brandNewTaskModel = [[MirrorTaskModel alloc] initWithTitle:task.taskName createdTime:task.createdTime colorType:task.color isHidden:task.isHidden isAddTask:NO];
        } else {
            NSArray *allColorType = @[@(MirrorColorTypeCellPink), @(MirrorColorTypeCellOrange), @(MirrorColorTypeCellYellow), @(MirrorColorTypeCellGreen), @(MirrorColorTypeCellTeal), @(MirrorColorTypeCellBlue), @(MirrorColorTypeCellPurple),@(MirrorColorTypeCellGray)];
            MirrorColorType type = [allColorType[arc4random() % allColorType.count] integerValue]; // 随机生成一个颜色
            _brandNewTaskModel = [[MirrorTaskModel alloc] initWithTitle:[MirrorLanguage mirror_stringWithKey:@"untitled"] createdTime:[@(0) longValue] colorType:type isHidden:NO isAddTask:NO];
        }
    }
    return _brandNewTaskModel;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _titleLabel.font = [UIFont mirrorTitleFont];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UITextField *)editTaskNameTextField
{
    if (!_editTaskNameTextField) {
        _editTaskNameTextField = [UITextField new];
        _editTaskNameTextField.placeholder = [MirrorLanguage mirror_stringWithKey:self.editingTaskName.length > 0 ? @"edit_task_title" : @"enter_task_title"];
        _editTaskNameTextField.textColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        _editTaskNameTextField.font = [UIFont mirrorLabelFont];
        _editTaskNameTextField.enabled = YES;
        _editTaskNameTextField.textAlignment = NSTextAlignmentCenter;
    }
    return _editTaskNameTextField;
}

- (UILabel *)addTaskNameHint
{
    if (!_addTaskNameHint) {
        _addTaskNameHint = [UILabel new];
        _addTaskNameHint.text = [MirrorLanguage mirror_stringWithKey:@"add_taskname_hint"];
        _addTaskNameHint.textColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint];
        _addTaskNameHint.font = [UIFont mirrorHintFont];
        _addTaskNameHint.textAlignment = NSTextAlignmentCenter;
        
    }
    return _addTaskNameHint;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView){
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor clearColor];
        
        [_collectionView registerClass:[ColorCollectionViewCell class] forCellWithReuseIdentifier:[ColorCollectionViewCell identifier]];
    }
    return _collectionView;
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

- (UIButton *)createButton
{
    if (!_createButton) {
        _createButton = [UIButton new];
        // icon
        [_createButton setImage:[[UIImage systemImageNamed:@"checkmark.rectangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _createButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        // title
        [_createButton setTitle:[MirrorLanguage mirror_stringWithKey:@"create"] forState:UIControlStateNormal];
        [_createButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeText] forState:UIControlStateNormal];
        _createButton.titleLabel.font = [UIFont mirrorButtonFont];
        // padding
        _createButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
        // action
        [_createButton addTarget:self action:@selector(clickCreateBtn) forControlEvents:UIControlEventTouchUpInside];
    }
    return _createButton;
}

- (UIButton *)discardButton
{
    if (!_discardButton) {
        _discardButton = [UIButton new];
        // icon
        [_discardButton setImage:[[UIImage systemImageNamed:@"xmark.rectangle"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _discardButton.tintColor = [UIColor mirrorColorNamed:MirrorColorTypeText];
        // title
        [_discardButton setTitle:[MirrorLanguage mirror_stringWithKey:@"discard"] forState:UIControlStateNormal];
        [_discardButton setTitleColor:[UIColor mirrorColorNamed:MirrorColorTypeText] forState:UIControlStateNormal];
        _discardButton.titleLabel.font = [UIFont mirrorButtonFont];
        // padding
        _discardButton.titleEdgeInsets = UIEdgeInsetsMake(0, 20, 0, 0);
        // action
        [_discardButton addTarget:self action:@selector(clickDiscardButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _discardButton;
}

#pragma mark - Private methods

- (CGFloat)p_colorBlockWidth
{
    return (kScreenWidth - 2*kAddTaskVCPadding)/kMaxColorNum;
}


@end
