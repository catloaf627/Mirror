//
//  HiddenViewController.m
//  Mirror
//
//  Created by Yuqing Wang on 2023/5/27.
//

#import "HiddenViewController.h"
#import "HiddenAnimation.h"
#import "UIColor+MirrorColor.h"
#import <Masonry/Masonry.h>
#import "MirrorSettings.h"
#import "HiddenCollectionViewCell.h"
#import "MirrorStorage.h"
#import "MirrorMacro.h"

@interface HiddenViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<MirrorTaskModel *> *data;

@end

@implementation HiddenViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor mirrorColorNamed:MirrorColorTypeBackground];
    self.view.layer.cornerRadius = 14;
    self.view.layer.borderColor = [UIColor mirrorColorNamed:MirrorColorTypeTextHint].CGColor;
    self.view.layer.borderWidth = 1;
    
    [self p_setupUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // 手势(点击外部dismiss)
    UITapGestureRecognizer *tapRecognizer = [UITapGestureRecognizer new];
    tapRecognizer.delegate = self;
    [self.view.superview addGestureRecognizer:tapRecognizer];
    // 动画
    self.transitioningDelegate = self;
}


- (void)p_setupUI
{
    [self.view addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.offset(20*kHeightRatio);
        make.bottom.equalTo(self.view.mas_bottom).offset(-20*kHeightRatio);
        make.left.offset(20*kWidthRatio);
        make.right.offset(-20*kWidthRatio);
    }];
    
}

#pragma mark - CollectionView

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.data.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.collectionView.frame.size.width, 40*kHeightRatio);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    HiddenCollectionViewCell *cell =[collectionView dequeueReusableCellWithReuseIdentifier:[HiddenCollectionViewCell identifier] forIndexPath:indexPath];
    [cell configCellWithTaskname:self.data[indexPath.item].taskName];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [MirrorStorage switchHiddenTask:self.data[indexPath.item].taskName];
    self.data = [MirrorStorage retriveMirrorTasks];
    [self.collectionView reloadData];
}

#pragma mark - Getters

- (NSMutableArray<MirrorTaskModel *> *)data
{
    if (!_data) {
        _data = [MirrorStorage retriveMirrorTasks];
    }
    return _data;
}

- (UICollectionView *)collectionView
{
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = self.view.backgroundColor;
        [_collectionView registerClass:[HiddenCollectionViewCell class] forCellWithReuseIdentifier:[HiddenCollectionViewCell identifier]];
    }
    return _collectionView;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:UITapGestureRecognizer.class]) {
        CGPoint touchPoint = [touch locationInView:self.view];
        if (touchPoint.x<0 || touchPoint.y>self.view.frame.origin.y + self.view.frame.size.height) {
            [self dismissViewControllerAnimated:YES completion:nil];// 点了view外面
        } else {
            // 点了view里面
        }
    }
    return NO;
}


#pragma mark - UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    HiddenAnimation *animation = [HiddenAnimation new];
    animation.isPresent = NO;
    animation.buttonFrame = self.buttonFrame;
    return animation;
}


@end
