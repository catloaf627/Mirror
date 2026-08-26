//
//  MirrorSupportManualAlert.m
//  Mirror
//

#import "MirrorSupportManualAlert.h"
#import "MirrorLanguage.h"
#import "MirrorManualVideoViewController.h"

static NSString * const kMirrorSupportAuthorMailAddress = @"yuqingwang.dev@gmail.com";
static NSString * const kMirrorRecordTimeCannotOverlapVideoName = @"record_time_cannot_overlap";
static NSString * const kMirrorLongPressToEditMergeDeleteTaskVideoName = @"long_press_to_edit_merge_delete_a_task";
static NSString * const kMirrorLongPressToEditDeleteDragRecordVideoName = @"long_press_to_edit_delete_drag_a_record";
static NSString * const kMirrorTapToAdjustStartEndTimeVideoName = @"tap_to_adjust_start_end_time";
static NSString * const kMirrorTapEmptySpaceToAddNewRecordVideoName = @"tap_empty_space_to_add_a_new_record";
static NSString * const kMirrorSwipeOrUseCalendarToSwitchDatesVideoName = @"swipe_left_right_or_use_calendar_to_switch_dates";
static NSString * const kMirrorTapTopLeftToOpenSpecialDaysVideoName = @"tap_top_left_to_open_speical_days_long_press_to_edit_delete";
static NSString * const kMirrorLongPressDragAcrossDatesVideoName = @"long_press_and_drag_to_view_records_across_multiple_dates";
static NSString * const kMirrorTapDayToViewRecordsVideoName = @"tap_a_day_to_view_that_days_records";
static NSString * const kMirrorTapRecordToOpenTaskRecordsVideoName = @"tap_a_record_to_open_all_records_for_that_task_long_press_to_edit_delete";
static NSString * const kMirrorTapTaskInLegendToHideShowVideoName = @"tap_a_task_in_a_legend_to_hide_show_it";
static NSString * const kMirrorTapTopLeftFirstDayTopRightHeatmapVideoName = @"tap_top_left_to_switch_the_first_day_of_week_tap_top_right_to_switch_heatmap";
static NSString * const kMirrorManualVideoURLScheme = @"mirror-manual-video";
static NSString * const kMirrorManualVideoItemTitleKey = @"title";
static NSString * const kMirrorManualVideoItemURLKey = @"url";

@interface MirrorManualVideoTouchDownGestureRecognizer : UIGestureRecognizer

@end

@implementation MirrorManualVideoTouchDownGestureRecognizer

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateBegan;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateChanged;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateCancelled;
}

@end

@interface MirrorSupportManualAlert () <UIGestureRecognizerDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIImpactFeedbackGenerator *videoLinkFeedbackGenerator;

@end

@implementation MirrorSupportManualAlert

+ (void)presentFromViewController:(UIViewController *)viewController
{
    if (!viewController) {
        return;
    }

    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
    [[self sharedLinkDelegate] prepareVideoLinkFeedback];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"support_manual_title"]
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController setValue:[self attributedTitle] forKey:@"attributedTitle"];
    [alertController setValue:[self manualContentViewController] forKey:@"contentViewController"];

    UIAlertAction *contactAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"contact_author"] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self openAuthorMailFromViewController:viewController];
    }];
    UIAlertAction *gotchaAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"gotcha"] style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:contactAction];
    [alertController addAction:gotchaAction];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

+ (NSAttributedString *)attributedTitle
{
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    return [[NSAttributedString alloc] initWithString:[MirrorLanguage mirror_stringWithKey:@"support_manual_title"] attributes:@{
        NSFontAttributeName: [UIFont boldSystemFontOfSize:17],
        NSParagraphStyleAttributeName: paragraphStyle
    }];
}

+ (UIViewController *)manualContentViewController
{
    UIViewController *contentViewController = [UIViewController new];
    contentViewController.preferredContentSize = CGSizeMake(270, 360);

    UITextView *textView = [UITextView new];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.attributedText = [self attributedMessageWithVideoLink];
    textView.backgroundColor = UIColor.clearColor;
    textView.editable = NO;
    textView.selectable = YES;
    MirrorSupportManualAlert *linkDelegate = [self sharedLinkDelegate];
    textView.delegate = linkDelegate;
    MirrorManualVideoTouchDownGestureRecognizer *videoLinkPressRecognizer = [[MirrorManualVideoTouchDownGestureRecognizer alloc] initWithTarget:linkDelegate action:@selector(videoLinkPressBegan:)];
    videoLinkPressRecognizer.cancelsTouchesInView = NO;
    videoLinkPressRecognizer.delegate = linkDelegate;
    [textView addGestureRecognizer:videoLinkPressRecognizer];
    textView.scrollEnabled = YES;
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.textContainer.lineFragmentPadding = 0;
    textView.showsVerticalScrollIndicator = YES;
    textView.linkTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.systemGrayColor
    };
    [contentViewController.view addSubview:textView];

    [NSLayoutConstraint activateConstraints:@[
        [textView.topAnchor constraintEqualToAnchor:contentViewController.view.topAnchor],
        [textView.leadingAnchor constraintEqualToAnchor:contentViewController.view.leadingAnchor],
        [textView.trailingAnchor constraintEqualToAnchor:contentViewController.view.trailingAnchor],
        [textView.bottomAnchor constraintEqualToAnchor:contentViewController.view.bottomAnchor]
    ]];

    return contentViewController;
}

+ (NSString *)sectionTitleWithTabKey:(NSString *)tabKey
{
    return [[MirrorLanguage mirror_stringWithKey:tabKey] stringByAppendingString:[MirrorLanguage mirror_stringWithKey:@"manual_page_suffix"]];
}

+ (NSAttributedString *)attributedMessageWithVideoLink
{
    NSArray<NSString *> *sectionTitles = @[
        [self sectionTitleWithTabKey:@"start"],
        [self sectionTitleWithTabKey:@"today"],
        [self sectionTitleWithTabKey:@"record"]
    ];
    NSArray<NSArray<NSString *> *> *sectionItemKeys = @[
        @[@"manual_no_overlap", @"manual_start_edit_task", @"manual_start_task_limit"],
        @[@"manual_today_edit_record", @"manual_today_adjust_time", @"manual_today_add_record", @"manual_today_switch_date", @"manual_today_special_days"],
        @[@"manual_record_drag_dates", @"manual_record_view_day", @"manual_record_task_list", @"manual_record_legend_task_visibility", @"manual_record_options"]
    ];

    NSMutableString *message = [NSMutableString new];
    unichar objectReplacementCharacter = 0xFFFC;
    NSString *videoIconPlaceholder = [NSString stringWithCharacters:&objectReplacementCharacter length:1];
    NSMutableDictionary<NSString *, NSValue *> *videoLinkRangesByKey = [NSMutableDictionary new];

    NSMutableArray<NSValue *> *sectionRanges = [NSMutableArray new];
    for (NSInteger sectionIndex = 0; sectionIndex < sectionTitles.count; sectionIndex++) {
        NSString *sectionTitle = sectionTitles[sectionIndex];
        if (message.length > 0) {
            [message appendString:@"\n\n"];
        }
        NSRange sectionRange = NSMakeRange(message.length, sectionTitle.length);
        [message appendString:sectionTitle];
        [sectionRanges addObject:[NSValue valueWithRange:sectionRange]];
        for (NSString *itemKey in sectionItemKeys[sectionIndex]) {
            [message appendFormat:@"\n• %@", [MirrorLanguage mirror_stringWithKey:itemKey]];
            [self appendVideoIconPlaceholder:videoIconPlaceholder forManualKey:itemKey toMessage:message rangesByKey:videoLinkRangesByKey];
        }
    }

    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentLeft;
    paragraphStyle.lineSpacing = 1;
    NSMutableAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithString:message attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:13],
        NSForegroundColorAttributeName: UIColor.labelColor,
        NSParagraphStyleAttributeName: paragraphStyle
    }];
    CGFloat iconSize = 13;
    UIImageSymbolConfiguration *symbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:iconSize weight:UIImageSymbolWeightSemibold];
    UIImage *playImage = [[UIImage systemImageNamed:@"play.circle.fill" withConfiguration:symbolConfiguration] imageWithTintColor:UIColor.systemGrayColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    [videoLinkRangesByKey enumerateKeysAndObjectsUsingBlock:^(NSString *manualKey, NSValue *rangeValue, BOOL *stop) {
        [self addVideoLinkForManualKey:manualKey range:rangeValue.rangeValue playImage:playImage iconSize:iconSize toAttributedMessage:attributedMessage];
    }];
    for (NSValue *rangeValue in sectionRanges) {
        [attributedMessage addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13] range:rangeValue.rangeValue];
    }
    return attributedMessage;
}

+ (void)appendVideoIconPlaceholder:(NSString *)videoIconPlaceholder forManualKey:(NSString *)manualKey toMessage:(NSMutableString *)message rangesByKey:(NSMutableDictionary<NSString *, NSValue *> *)rangesByKey
{
    if (![self videoURLForManualKey:manualKey]) {
        return;
    }

    [message appendString:@"\u00A0"];
    NSRange videoLinkRange = NSMakeRange(message.length, 1);
    [message appendString:videoIconPlaceholder];
    rangesByKey[manualKey] = [NSValue valueWithRange:videoLinkRange];
}

+ (void)addVideoLinkForManualKey:(NSString *)manualKey range:(NSRange)range playImage:(UIImage *)playImage iconSize:(CGFloat)iconSize toAttributedMessage:(NSMutableAttributedString *)attributedMessage
{
    NSURL *videoURL = [self videoURLForManualKey:manualKey];
    if (!videoURL || range.location == NSNotFound) {
        return;
    }

    NSTextAttachment *playAttachment = [NSTextAttachment new];
    playAttachment.image = playImage;
    playAttachment.bounds = CGRectMake(0, -1.5, iconSize, iconSize);
    NSURL *manualVideoURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", kMirrorManualVideoURLScheme, manualKey]];
    [attributedMessage addAttributes:@{
        NSAttachmentAttributeName: playAttachment,
        NSLinkAttributeName: manualVideoURL
    } range:range];
}

+ (NSArray<NSString *> *)videoManualKeys
{
    return @[
        @"manual_no_overlap",
        @"manual_start_edit_task",
        @"manual_today_edit_record",
        @"manual_today_adjust_time",
        @"manual_today_add_record",
        @"manual_today_switch_date",
        @"manual_today_special_days",
        @"manual_record_drag_dates",
        @"manual_record_view_day",
        @"manual_record_task_list",
        @"manual_record_legend_task_visibility",
        @"manual_record_options"
    ];
}

+ (NSArray<NSDictionary<NSString *, id> *> *)videoItems
{
    NSMutableArray<NSDictionary<NSString *, id> *> *videoItems = [NSMutableArray new];
    for (NSString *manualKey in [self videoManualKeys]) {
        NSURL *videoURL = [self videoURLForManualKey:manualKey];
        if (!videoURL) {
            continue;
        }
        [videoItems addObject:@{
            kMirrorManualVideoItemTitleKey: [MirrorLanguage mirror_stringWithKey:manualKey],
            kMirrorManualVideoItemURLKey: videoURL
        }];
    }
    return [videoItems copy];
}

+ (NSInteger)videoIndexForManualKey:(NSString *)manualKey
{
    NSInteger availableVideoIndex = 0;
    for (NSString *candidateKey in [self videoManualKeys]) {
        if (![self videoURLForManualKey:candidateKey]) {
            continue;
        }
        if ([candidateKey isEqualToString:manualKey]) {
            return availableVideoIndex;
        }
        availableVideoIndex++;
    }
    return 0;
}

+ (NSURL *)videoURLForManualKey:(NSString *)manualKey
{
    NSDictionary<NSString *, NSString *> *videoNames = @{
        @"manual_no_overlap": kMirrorRecordTimeCannotOverlapVideoName,
        @"manual_start_edit_task": kMirrorLongPressToEditMergeDeleteTaskVideoName,
        @"manual_today_edit_record": kMirrorLongPressToEditDeleteDragRecordVideoName,
        @"manual_today_adjust_time": kMirrorTapToAdjustStartEndTimeVideoName,
        @"manual_today_add_record": kMirrorTapEmptySpaceToAddNewRecordVideoName,
        @"manual_today_switch_date": kMirrorSwipeOrUseCalendarToSwitchDatesVideoName,
        @"manual_today_special_days": kMirrorTapTopLeftToOpenSpecialDaysVideoName,
        @"manual_record_drag_dates": kMirrorLongPressDragAcrossDatesVideoName,
        @"manual_record_view_day": kMirrorTapDayToViewRecordsVideoName,
        @"manual_record_task_list": kMirrorTapRecordToOpenTaskRecordsVideoName,
        @"manual_record_legend_task_visibility": kMirrorTapTaskInLegendToHideShowVideoName,
        @"manual_record_options": kMirrorTapTopLeftFirstDayTopRightHeatmapVideoName
    };
    NSString *videoName = videoNames[manualKey];
    if (videoName.length == 0) {
        return nil;
    }

    for (NSString *extension in @[@"mp4", @"mov"]) {
        NSURL *videoURL = [NSBundle.mainBundle URLForResource:videoName withExtension:extension subdirectory:@"Manual_videos"];
        if (videoURL) {
            return videoURL;
        }
    }

    for (NSString *extension in @[@"mp4", @"mov"]) {
        NSURL *videoURL = [NSBundle.mainBundle URLForResource:videoName withExtension:extension];
        if (videoURL) {
            return videoURL;
        }
    }

    return nil;
}

+ (instancetype)sharedLinkDelegate
{
    static MirrorSupportManualAlert *delegate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        delegate = [MirrorSupportManualAlert new];
    });
    return delegate;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    if (![URL.scheme isEqualToString:kMirrorManualVideoURLScheme]) {
        return YES;
    }

    [self presentVideoForManualKey:URL.host fromView:textView];
    return NO;
}

- (void)videoLinkPressBegan:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }

    if (![recognizer.view isKindOfClass:UITextView.class]) {
        return;
    }

    UITextView *textView = (UITextView *)recognizer.view;
    NSURL *URL = [self manualVideoURLAtPoint:[recognizer locationInView:textView] textView:textView];
    if ([URL.scheme isEqualToString:kMirrorManualVideoURLScheme]) {
        [self playVideoLinkFeedback];
    }
}

- (NSURL *)manualVideoURLAtPoint:(CGPoint)point textView:(UITextView *)textView
{
    NSLayoutManager *layoutManager = textView.layoutManager;
    NSTextContainer *textContainer = textView.textContainer;
    CGPoint location = CGPointMake(
        point.x - textView.textContainerInset.left + textView.contentOffset.x,
        point.y - textView.textContainerInset.top + textView.contentOffset.y
    );
    NSUInteger characterIndex = [layoutManager characterIndexForPoint:location inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:nil];
    if (characterIndex >= textView.attributedText.length) {
        return nil;
    }

    id linkValue = [textView.attributedText attribute:NSLinkAttributeName atIndex:characterIndex effectiveRange:nil];
    return [linkValue isKindOfClass:NSURL.class] ? linkValue : nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)prepareVideoLinkFeedback
{
    self.videoLinkFeedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [self.videoLinkFeedbackGenerator prepare];
}

- (void)playVideoLinkFeedback
{
    if (!self.videoLinkFeedbackGenerator) {
        [self prepareVideoLinkFeedback];
    }
    [self.videoLinkFeedbackGenerator impactOccurred];
    [self.videoLinkFeedbackGenerator prepare];
}

- (void)presentVideoForManualKey:(NSString *)manualKey fromView:(UIView *)view
{
    NSArray<NSDictionary<NSString *, id> *> *videoItems = [MirrorSupportManualAlert videoItems];
    if (videoItems.count == 0) {
        return;
    }

    UIViewController *presentingViewController = [self topViewControllerFromRootViewController:view.window.rootViewController];
    if (!presentingViewController) {
        return;
    }

    NSInteger currentIndex = [MirrorSupportManualAlert videoIndexForManualKey:manualKey];
    MirrorManualVideoViewController *playerViewController = [[MirrorManualVideoViewController alloc] initWithVideoItems:videoItems currentIndex:currentIndex];
    [presentingViewController presentViewController:playerViewController animated:YES completion:nil];
}

- (UIViewController *)topViewControllerFromRootViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController) {
        return [self topViewControllerFromRootViewController:rootViewController.presentedViewController];
    }
    if ([rootViewController isKindOfClass:UINavigationController.class]) {
        return [self topViewControllerFromRootViewController:((UINavigationController *)rootViewController).visibleViewController];
    }
    if ([rootViewController isKindOfClass:UITabBarController.class]) {
        return [self topViewControllerFromRootViewController:((UITabBarController *)rootViewController).selectedViewController];
    }
    return rootViewController;
}

+ (void)openAuthorMailFromViewController:(UIViewController *)viewController
{
    NSURL *mailURL = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", kMirrorSupportAuthorMailAddress]];
    if (!mailURL) {
        return;
    }

    UIApplication *application = UIApplication.sharedApplication;
    if (![application canOpenURL:mailURL]) {
        [self presentMailUnavailableAlertFromViewController:viewController];
        return;
    }
    [application openURL:mailURL options:@{} completionHandler:nil];
}

+ (void)presentMailUnavailableAlertFromViewController:(UIViewController *)viewController
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[MirrorLanguage mirror_stringWithKey:@"mail_unavailable"] message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:[MirrorLanguage mirror_stringWithKey:@"ok"] style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
