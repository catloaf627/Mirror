//
//  MirrorManualVideoViewController.m
//  Mirror
//

#import "MirrorManualVideoViewController.h"
#import "UIColor+MirrorColor.h"
#import <AVFoundation/AVFoundation.h>

static NSString * const kMirrorManualVideoItemTitleKey = @"title";
static NSString * const kMirrorManualVideoItemURLKey = @"url";

@interface MirrorManualVideoViewController ()

@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *videoItems;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIView *borderContainerView;
@property (nonatomic, strong) UIStackView *contentStackView;
@property (nonatomic, strong) UIView *videoContainerView;
@property (nonatomic, strong) UIScrollView *thumbnailScrollView;
@property (nonatomic, strong) UIStackView *thumbnailStackView;
@property (nonatomic, copy) NSArray<UIButton *> *thumbnailButtons;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, assign) BOOL didScrollToInitialThumbnail;

@end

@implementation MirrorManualVideoViewController

- (instancetype)initWithVideoItems:(NSArray<NSDictionary<NSString *, id> *> *)videoItems currentIndex:(NSInteger)currentIndex
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _videoItems = [videoItems copy];
        _currentIndex = MAX(0, MIN(currentIndex, (NSInteger)videoItems.count - 1));
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.blackColor;
    [self configurePlayer];
    [self configureViews];
    [self configureGestures];
    [self loadVideoAtIndex:self.currentIndex shouldPlay:NO];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.playerLayer.frame = self.videoContainerView.bounds;
    self.thumbnailScrollView.contentOffset = CGPointMake(0, self.thumbnailScrollView.contentOffset.y);
    if (!self.didScrollToInitialThumbnail) {
        self.didScrollToInitialThumbnail = YES;
        [self scrollSelectedThumbnailIntoViewAnimated:NO];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self playVideo];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)configurePlayer
{
    self.player = [AVPlayer new];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
}

- (void)configureViews
{
    self.borderContainerView = [UIView new];
    self.borderContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.borderContainerView.backgroundColor = UIColor.blackColor;
    self.borderContainerView.layer.cornerRadius = 18;
    self.borderContainerView.clipsToBounds = YES;
    [self.view addSubview:self.borderContainerView];

    self.contentStackView = [UIStackView new];
    self.contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentStackView.axis = UILayoutConstraintAxisHorizontal;
    self.contentStackView.alignment = UIStackViewAlignmentFill;
    self.contentStackView.distribution = UIStackViewDistributionFill;
    self.contentStackView.spacing = 8;
    [self.borderContainerView addSubview:self.contentStackView];

    self.videoContainerView = [UIView new];
    self.videoContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.videoContainerView.backgroundColor = UIColor.blackColor;
    self.videoContainerView.clipsToBounds = YES;
    self.videoContainerView.layer.cornerRadius = 14;
    [self.videoContainerView.layer addSublayer:self.playerLayer];
    [self.contentStackView addArrangedSubview:self.videoContainerView];

    self.thumbnailScrollView = [UIScrollView new];
    self.thumbnailScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.thumbnailScrollView.showsVerticalScrollIndicator = NO;
    self.thumbnailScrollView.showsHorizontalScrollIndicator = NO;
    self.thumbnailScrollView.alwaysBounceHorizontal = NO;
    self.thumbnailScrollView.directionalLockEnabled = YES;
    if (@available(iOS 11.0, *)) {
        self.thumbnailScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.contentStackView addArrangedSubview:self.thumbnailScrollView];

    self.thumbnailStackView = [UIStackView new];
    self.thumbnailStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.thumbnailStackView.axis = UILayoutConstraintAxisVertical;
    self.thumbnailStackView.alignment = UIStackViewAlignmentFill;
    self.thumbnailStackView.distribution = UIStackViewDistributionFillEqually;
    self.thumbnailStackView.spacing = 6;
    [self.thumbnailScrollView addSubview:self.thumbnailStackView];
    [self configureThumbnailButtons];

    self.titleLabel = [UILabel new];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.titleLabel.numberOfLines = 2;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.titleLabel];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *closeImage = [UIImage systemImageNamed:@"xmark"];
    [self.closeButton setImage:closeImage forState:UIControlStateNormal];
    self.closeButton.tintColor = UIColor.whiteColor;
    self.closeButton.backgroundColor = [self closeButtonColor];
    self.closeButton.layer.cornerRadius = 8;
    [self.closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.borderContainerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.borderContainerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:8],
        [self.borderContainerView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.88],
        [self.borderContainerView.widthAnchor constraintLessThanOrEqualToConstant:360],
        [self.borderContainerView.heightAnchor constraintEqualToAnchor:self.borderContainerView.widthAnchor multiplier:1.45],
        [self.borderContainerView.heightAnchor constraintLessThanOrEqualToAnchor:self.view.safeAreaLayoutGuide.heightAnchor multiplier:0.72],

        [self.contentStackView.topAnchor constraintEqualToAnchor:self.borderContainerView.topAnchor constant:8],
        [self.contentStackView.leadingAnchor constraintEqualToAnchor:self.borderContainerView.leadingAnchor constant:8],
        [self.contentStackView.trailingAnchor constraintEqualToAnchor:self.borderContainerView.trailingAnchor constant:-8],
        [self.contentStackView.bottomAnchor constraintEqualToAnchor:self.borderContainerView.bottomAnchor constant:-8],

        [self.videoContainerView.widthAnchor constraintEqualToAnchor:self.videoContainerView.heightAnchor multiplier:9.0 / 16.0],
        [self.thumbnailScrollView.widthAnchor constraintEqualToConstant:46],

        [self.thumbnailStackView.topAnchor constraintEqualToAnchor:self.thumbnailScrollView.contentLayoutGuide.topAnchor],
        [self.thumbnailStackView.leadingAnchor constraintEqualToAnchor:self.thumbnailScrollView.contentLayoutGuide.leadingAnchor],
        [self.thumbnailStackView.trailingAnchor constraintEqualToAnchor:self.thumbnailScrollView.contentLayoutGuide.trailingAnchor],
        [self.thumbnailStackView.bottomAnchor constraintEqualToAnchor:self.thumbnailScrollView.contentLayoutGuide.bottomAnchor],
        [self.thumbnailStackView.widthAnchor constraintEqualToAnchor:self.thumbnailScrollView.frameLayoutGuide.widthAnchor],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.borderContainerView.leadingAnchor constant:8],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.borderContainerView.trailingAnchor constant:-8],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.borderContainerView.topAnchor constant:-14],

        [self.closeButton.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:18],
        [self.closeButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:18],
        [self.closeButton.widthAnchor constraintEqualToConstant:32],
        [self.closeButton.heightAnchor constraintEqualToConstant:32]
    ]];
}

- (NSArray<UIColor *> *)taskPulseColors
{
    NSArray<NSNumber *> *colorTypes = @[
        @(MirrorColorTypeCellPinkPulse),
        @(MirrorColorTypeCellOrangePulse),
        @(MirrorColorTypeCellYellowPulse),
        @(MirrorColorTypeCellGreenPulse),
        @(MirrorColorTypeCellTealPulse),
        @(MirrorColorTypeCellBluePulse),
        @(MirrorColorTypeCellPurplePulse),
        @(MirrorColorTypeCellGrayPulse)
    ];
    NSMutableArray<UIColor *> *colors = [NSMutableArray new];
    for (NSNumber *colorType in colorTypes) {
        [colors addObject:[UIColor mirrorColorNamed:colorType.integerValue]];
    }
    return [colors copy];
}

- (UIColor *)closeButtonColor
{
    UIColor *firstColor = [UIColor mirrorColorNamed:MirrorColorTypeCellPurplePulse];
    UIColor *secondColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse];
    CGFloat firstRed = 0;
    CGFloat firstGreen = 0;
    CGFloat firstBlue = 0;
    CGFloat firstAlpha = 0;
    CGFloat secondRed = 0;
    CGFloat secondGreen = 0;
    CGFloat secondBlue = 0;
    CGFloat secondAlpha = 0;
    [firstColor getRed:&firstRed green:&firstGreen blue:&firstBlue alpha:&firstAlpha];
    [secondColor getRed:&secondRed green:&secondGreen blue:&secondBlue alpha:&secondAlpha];
    return [UIColor colorWithRed:(firstRed + secondRed) / 2.0 green:(firstGreen + secondGreen) / 2.0 blue:(firstBlue + secondBlue) / 2.0 alpha:0.92];
}

- (void)configureThumbnailButtons
{
    NSMutableArray<UIButton *> *buttons = [NSMutableArray new];
    for (NSInteger index = 0; index < self.videoItems.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.tag = index;
        button.backgroundColor = [UIColor colorWithWhite:1 alpha:0.14];
        button.clipsToBounds = YES;
        button.layer.cornerRadius = 6;
        button.layer.borderWidth = 2;
        button.layer.borderColor = UIColor.clearColor.CGColor;
        button.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [button setImage:[self thumbnailImageForVideoAtIndex:index] forState:UIControlStateNormal];
        [button addTarget:self action:@selector(thumbnailButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.thumbnailStackView addArrangedSubview:button];
        [NSLayoutConstraint activateConstraints:@[
            [button.heightAnchor constraintEqualToAnchor:button.widthAnchor multiplier:16.0 / 9.0]
        ]];
        [buttons addObject:button];
    }
    self.thumbnailButtons = [buttons copy];
}

- (UIImage *)thumbnailImageForVideoAtIndex:(NSInteger)index
{
    NSDictionary<NSString *, id> *item = self.videoItems[index];
    NSURL *videoURL = item[kMirrorManualVideoItemURLKey];
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    imageGenerator.maximumSize = CGSizeMake(92, 164);

    NSError *error = nil;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(0.1, 600) actualTime:nil error:&error];
    if (!imageRef) {
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

- (void)configureGestures
{
    UISwipeGestureRecognizer *leftSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showNextVideo)];
    leftSwipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:leftSwipeGesture];

    UISwipeGestureRecognizer *rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showPreviousVideo)];
    rightSwipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:rightSwipeGesture];
}

- (void)loadVideoAtIndex:(NSInteger)index shouldPlay:(BOOL)shouldPlay
{
    if (self.videoItems.count == 0) {
        return;
    }

    self.currentIndex = (index + self.videoItems.count) % self.videoItems.count;
    NSDictionary<NSString *, id> *item = self.videoItems[self.currentIndex];
    NSURL *videoURL = item[kMirrorManualVideoItemURLKey];
    NSString *title = item[kMirrorManualVideoItemTitleKey];

    self.titleLabel.text = title;
    [self updateThumbnailSelection];
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:videoURL]];
    [self resetPlayerEndObserver];

    if (shouldPlay) {
        [self playVideo];
    }
}

- (void)updateThumbnailSelection
{
    UIColor *selectedColor = [UIColor mirrorColorNamed:MirrorColorTypeCellGrayPulse];
    for (NSInteger index = 0; index < self.thumbnailButtons.count; index++) {
        UIButton *button = self.thumbnailButtons[index];
        BOOL isSelected = index == self.currentIndex;
        button.layer.borderColor = isSelected ? selectedColor.CGColor : UIColor.clearColor.CGColor;
        button.alpha = isSelected ? 1 : 0.58;
    }

    if (self.currentIndex < self.thumbnailButtons.count) {
        [self scrollSelectedThumbnailIntoViewAnimated:YES];
    }
}

- (void)scrollSelectedThumbnailIntoViewAnimated:(BOOL)animated
{
    if (self.currentIndex >= self.thumbnailButtons.count) {
        return;
    }

    [self.thumbnailScrollView layoutIfNeeded];
    [self.thumbnailStackView layoutIfNeeded];

    UIButton *selectedButton = self.thumbnailButtons[self.currentIndex];
    CGFloat visibleHeight = CGRectGetHeight(self.thumbnailScrollView.bounds);
    CGFloat contentHeight = self.thumbnailScrollView.contentSize.height;
    if (visibleHeight <= 0 || contentHeight <= visibleHeight) {
        self.thumbnailScrollView.contentOffset = CGPointZero;
        return;
    }

    CGFloat targetY = CGRectGetMidY(selectedButton.frame) - visibleHeight / 2.0;
    CGFloat maxY = MAX(0, contentHeight - visibleHeight);
    targetY = MAX(0, MIN(targetY, maxY));
    [self.thumbnailScrollView setContentOffset:CGPointMake(0, targetY) animated:animated];
}

- (void)resetPlayerEndObserver
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(playerDidFinishPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

- (void)playVideo
{
    [self.player play];
}

- (void)showNextVideo
{
    [self transitionToVideoAtIndex:self.currentIndex + 1 subtype:kCATransitionFromTop];
}

- (void)showPreviousVideo
{
    [self transitionToVideoAtIndex:self.currentIndex - 1 subtype:kCATransitionFromBottom];
}

- (void)transitionToVideoAtIndex:(NSInteger)index subtype:(NSString *)subtype
{
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionPush;
    transition.subtype = subtype;
    transition.duration = 0.22;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.videoContainerView.layer addAnimation:transition forKey:@"manualVideoSwitch"];
    [self loadVideoAtIndex:index shouldPlay:YES];
}

- (void)thumbnailButtonTapped:(UIButton *)button
{
    if (button.tag == self.currentIndex) {
        return;
    }

    NSString *subtype = button.tag > self.currentIndex ? kCATransitionFromTop : kCATransitionFromBottom;
    [self transitionToVideoAtIndex:button.tag subtype:subtype];
}

- (void)playerDidFinishPlaying
{
    [self.player seekToTime:kCMTimeZero];
    [self playVideo];
}

- (void)closeButtonTapped
{
    [self.player pause];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
