//
//  MirrorManualVideoViewController.m
//  Mirror
//

#import "MirrorManualVideoViewController.h"
#import "UIColor+MirrorColor.h"
#import <AVFoundation/AVFoundation.h>

NSString * const kMirrorManualLastWatchedVideoIndexKey = @"MirrorManualLastWatchedVideoIndex";

static NSString * const kMirrorManualVideoItemTitleKey = @"title";
static NSString * const kMirrorManualVideoItemURLKey = @"url";

@interface MirrorManualVideoViewController () <UIScrollViewDelegate>

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
@property (nonatomic, strong) UILabel *indexLabel;
@property (nonatomic, strong) UISegmentedControl *rateSegmentedControl;
@property (nonatomic, strong) UISlider *progressSlider;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, assign) BOOL didScrollToInitialThumbnail;
@property (nonatomic, assign) float playbackRate;
@property (nonatomic, strong) id playerTimeObserver;
@property (nonatomic, assign) BOOL isScrubbingProgress;
@property (nonatomic, assign) BOOL wasPlayingBeforeScrubbing;

@end

@implementation MirrorManualVideoViewController

- (instancetype)initWithVideoItems:(NSArray<NSDictionary<NSString *, id> *> *)videoItems currentIndex:(NSInteger)currentIndex
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _videoItems = [videoItems copy];
        _currentIndex = MAX(0, MIN(currentIndex, (NSInteger)videoItems.count - 1));
        _playbackRate = 0.75f;
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
    if (self.playerTimeObserver) {
        [self.player removeTimeObserver:self.playerTimeObserver];
    }
}

- (void)configurePlayer
{
    self.player = [AVPlayer new];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    __weak typeof(self) weakSelf = self;
    self.playerTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.1, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        [weakSelf updateProgressSliderForPlaybackTime:time];
    }];
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

    self.progressSlider = [UISlider new];
    self.progressSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressSlider.minimumValue = 0;
    self.progressSlider.maximumValue = 1;
    self.progressSlider.value = 0;
    self.progressSlider.continuous = YES;
    self.progressSlider.minimumTrackTintColor = [UIColor.whiteColor colorWithAlphaComponent:0.58];
    self.progressSlider.maximumTrackTintColor = [UIColor.whiteColor colorWithAlphaComponent:0.18];
    [self.progressSlider setThumbImage:[self progressSliderThumbImage] forState:UIControlStateNormal];
    [self.progressSlider setThumbImage:[self progressSliderThumbImage] forState:UIControlStateHighlighted];
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    [self.progressSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.progressSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.videoContainerView addSubview:self.progressSlider];

    self.thumbnailScrollView = [UIScrollView new];
    self.thumbnailScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.thumbnailScrollView.showsVerticalScrollIndicator = NO;
    self.thumbnailScrollView.showsHorizontalScrollIndicator = NO;
    self.thumbnailScrollView.alwaysBounceHorizontal = NO;
    self.thumbnailScrollView.alwaysBounceVertical = YES;
    self.thumbnailScrollView.directionalLockEnabled = YES;
    self.thumbnailScrollView.delegate = self;
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

    self.indexLabel = [UILabel new];
    self.indexLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.indexLabel.textColor = [UIColor.whiteColor colorWithAlphaComponent:0.78];
    self.indexLabel.font = [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightSemibold];
    self.indexLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.indexLabel];

    // Display labels are doubled: 1x / 1.5x / 2x map to actual AVPlayer rates 0.5 / 0.75 / 1.
    self.rateSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"1×", @"1.5×", @"2×"]];
    self.rateSegmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.rateSegmentedControl.selectedSegmentIndex = 1;
    self.rateSegmentedControl.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
    self.rateSegmentedControl.selectedSegmentTintColor = [UIColor colorWithWhite:1 alpha:0.28];
    NSDictionary *normalAttributes = @{
        NSForegroundColorAttributeName: [UIColor.whiteColor colorWithAlphaComponent:0.78],
        NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightSemibold]
    };
    NSDictionary *selectedAttributes = @{
        NSForegroundColorAttributeName: UIColor.blackColor,
        NSFontAttributeName: [UIFont monospacedDigitSystemFontOfSize:12 weight:UIFontWeightSemibold]
    };
    [self.rateSegmentedControl setTitleTextAttributes:normalAttributes forState:UIControlStateNormal];
    [self.rateSegmentedControl setTitleTextAttributes:selectedAttributes forState:UIControlStateSelected];
    [self.rateSegmentedControl addTarget:self action:@selector(rateSegmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.rateSegmentedControl];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *closeImage = [UIImage systemImageNamed:@"xmark"];
    [self.closeButton setImage:closeImage forState:UIControlStateNormal];
    self.closeButton.tintColor = UIColor.whiteColor;
    self.closeButton.backgroundColor = UIColor.clearColor;
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
        [self.progressSlider.leadingAnchor constraintEqualToAnchor:self.videoContainerView.leadingAnchor constant:10],
        [self.progressSlider.trailingAnchor constraintEqualToAnchor:self.videoContainerView.trailingAnchor constant:-10],
        [self.progressSlider.bottomAnchor constraintEqualToAnchor:self.videoContainerView.bottomAnchor constant:-6],
        [self.progressSlider.heightAnchor constraintEqualToConstant:18],

        [self.thumbnailScrollView.widthAnchor constraintEqualToConstant:46],

        [self.thumbnailStackView.topAnchor constraintEqualToAnchor:self.thumbnailScrollView.contentLayoutGuide.topAnchor],
        [self.thumbnailStackView.leadingAnchor constraintEqualToAnchor:self.thumbnailScrollView.contentLayoutGuide.leadingAnchor],
        [self.thumbnailStackView.trailingAnchor constraintEqualToAnchor:self.thumbnailScrollView.contentLayoutGuide.trailingAnchor],
        [self.thumbnailStackView.bottomAnchor constraintEqualToAnchor:self.thumbnailScrollView.contentLayoutGuide.bottomAnchor],
        [self.thumbnailStackView.widthAnchor constraintEqualToAnchor:self.thumbnailScrollView.frameLayoutGuide.widthAnchor],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.borderContainerView.leadingAnchor constant:8],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.borderContainerView.trailingAnchor constant:-8],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.borderContainerView.topAnchor constant:-14],

        [self.indexLabel.centerXAnchor constraintEqualToAnchor:self.thumbnailScrollView.centerXAnchor],
        [self.indexLabel.topAnchor constraintEqualToAnchor:self.borderContainerView.bottomAnchor constant:10],

        [self.rateSegmentedControl.leadingAnchor constraintEqualToAnchor:self.videoContainerView.leadingAnchor],
        [self.rateSegmentedControl.topAnchor constraintEqualToAnchor:self.borderContainerView.bottomAnchor constant:8],
        [self.rateSegmentedControl.widthAnchor constraintEqualToConstant:132],
        [self.rateSegmentedControl.heightAnchor constraintEqualToConstant:28],

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

- (UIImage *)progressSliderThumbImage
{
    CGFloat diameter = 8;
    CGRect rect = CGRectMake(0, 0, diameter, diameter);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:rect.size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [[UIColor.whiteColor colorWithAlphaComponent:0.72] setFill];
        CGContextFillEllipseInRect(context.CGContext, rect);
    }];
}

- (void)configureGestures
{
    UISwipeGestureRecognizer *upSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showNextVideo)];
    upSwipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [self.videoContainerView addGestureRecognizer:upSwipeGesture];

    UISwipeGestureRecognizer *downSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showPreviousVideo)];
    downSwipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    [self.videoContainerView addGestureRecognizer:downSwipeGesture];
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
    self.indexLabel.text = [NSString stringWithFormat:@"%ld/%ld", (long)(self.currentIndex + 1), (long)self.videoItems.count];
    self.progressSlider.value = 0;
    [[NSUserDefaults standardUserDefaults] setInteger:self.currentIndex forKey:kMirrorManualLastWatchedVideoIndexKey];
    [self updateThumbnailSelection];
    [self.player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:videoURL]];
    [self resetPlayerEndObserver];

    if (shouldPlay) {
        [self playVideo];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.thumbnailScrollView && scrollView.contentOffset.x != 0) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
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
    self.player.rate = self.playbackRate;
}

- (void)updateProgressSliderForPlaybackTime:(CMTime)time
{
    if (self.isScrubbingProgress) {
        return;
    }

    Float64 duration = CMTimeGetSeconds(self.player.currentItem.duration);
    Float64 currentTime = CMTimeGetSeconds(time);
    if (!isfinite(duration) || duration <= 0 || !isfinite(currentTime)) {
        self.progressSlider.value = 0;
        return;
    }

    self.progressSlider.value = MAX(0, MIN(1, currentTime / duration));
}

- (void)progressSliderTouchBegan:(UISlider *)slider
{
    self.isScrubbingProgress = YES;
    self.wasPlayingBeforeScrubbing = self.player.timeControlStatus != AVPlayerTimeControlStatusPaused;
    [self.player pause];
}

- (void)progressSliderValueChanged:(UISlider *)slider
{
    self.isScrubbingProgress = YES;
}

- (void)progressSliderTouchEnded:(UISlider *)slider
{
    Float64 duration = CMTimeGetSeconds(self.player.currentItem.duration);
    if (!isfinite(duration) || duration <= 0) {
        self.isScrubbingProgress = NO;
        return;
    }

    CMTime targetTime = CMTimeMakeWithSeconds(duration * slider.value, NSEC_PER_SEC);
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:targetTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
        self.isScrubbingProgress = NO;
        if (self.wasPlayingBeforeScrubbing) {
            [self playVideo];
        }
    }];
}

- (void)rateSegmentedControlChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.playbackRate = 0.5f;
            break;
        case 1:
            self.playbackRate = 0.75f;
            break;
        case 2:
        default:
            self.playbackRate = 1.0f;
            break;
    }

    if (self.player.timeControlStatus != AVPlayerTimeControlStatusPaused) {
        [self playVideo];
    }
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
