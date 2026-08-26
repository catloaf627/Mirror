//
//  MirrorSupportManualAlert.m
//  Mirror
//

#import "MirrorSupportManualAlert.h"
#import "MirrorLanguage.h"

static NSString * const kMirrorSupportAuthorMailAddress = @"yuqingwang.dev@gmail.com";
static NSString * const kMirrorRecordTimeCannotOverlapVideoURLString = @"https://yuqingwang.dev/mirrorly/mirrorly_videos/record_time_cannot_overlap_english.mov";

@implementation MirrorSupportManualAlert

+ (void)presentFromViewController:(UIViewController *)viewController
{
    if (!viewController) {
        return;
    }

    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
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
    textView.scrollEnabled = YES;
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.textContainer.lineFragmentPadding = 0;
    textView.showsVerticalScrollIndicator = YES;
    textView.linkTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.systemBlueColor
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
        @[@"manual_start_edit_task", @"manual_start_count", @"manual_start_task_limit", @"manual_start_language"],
        @[@"manual_today_edit_record", @"manual_today_adjust_time", @"manual_today_add_record", @"manual_today_switch_date", @"manual_today_special_days"],
        @[@"manual_record_drag_dates", @"manual_record_view_day", @"manual_record_task_list", @"manual_record_legend_task_visibility", @"manual_record_hide_tasks", @"manual_record_options"]
    ];

    NSMutableString *message = [[NSMutableString alloc] initWithString:[MirrorLanguage mirror_stringWithKey:@"manual_no_overlap"]];
    [message appendString:@"\u00A0"];
    NSRange videoLinkRange = NSMakeRange(message.length, 1);
    unichar objectReplacementCharacter = 0xFFFC;
    NSString *videoIconPlaceholder = [NSString stringWithCharacters:&objectReplacementCharacter length:1];
    [message appendString:videoIconPlaceholder];

    NSMutableArray<NSValue *> *sectionRanges = [NSMutableArray new];
    for (NSInteger sectionIndex = 0; sectionIndex < sectionTitles.count; sectionIndex++) {
        NSString *sectionTitle = sectionTitles[sectionIndex];
        [message appendString:@"\n\n"];
        NSRange sectionRange = NSMakeRange(message.length, sectionTitle.length);
        [message appendString:sectionTitle];
        [sectionRanges addObject:[NSValue valueWithRange:sectionRange]];
        for (NSString *itemKey in sectionItemKeys[sectionIndex]) {
            [message appendFormat:@"\n• %@", [MirrorLanguage mirror_stringWithKey:itemKey]];
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
    UIImage *playImage = [[UIImage systemImageNamed:@"play.circle.fill" withConfiguration:symbolConfiguration] imageWithTintColor:UIColor.systemBlueColor renderingMode:UIImageRenderingModeAlwaysOriginal];
    NSTextAttachment *playAttachment = [NSTextAttachment new];
    playAttachment.image = playImage;
    playAttachment.bounds = CGRectMake(0, -1.5, iconSize, iconSize);
    [attributedMessage addAttributes:@{
        NSAttachmentAttributeName: playAttachment,
        NSLinkAttributeName: kMirrorRecordTimeCannotOverlapVideoURLString
    } range:videoLinkRange];
    for (NSValue *rangeValue in sectionRanges) {
        [attributedMessage addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13] range:rangeValue.rangeValue];
    }
    return attributedMessage;
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
