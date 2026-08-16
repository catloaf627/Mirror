//
//  MirrorSupportManualAlert.m
//  Mirror
//

#import "MirrorSupportManualAlert.h"
#import "MirrorLanguage.h"

static NSString * const kMirrorSupportAuthorMailAddress = @"yuqingwang.dev@gmail.com";

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
    [alertController setValue:[self attributedMessage] forKey:@"attributedMessage"];

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

+ (NSString *)sectionTitleWithTabKey:(NSString *)tabKey
{
    return [[MirrorLanguage mirror_stringWithKey:tabKey] stringByAppendingString:[MirrorLanguage mirror_stringWithKey:@"manual_page_suffix"]];
}

+ (NSAttributedString *)attributedMessage
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

    NSMutableString *message = [[MirrorLanguage mirror_stringWithKey:@"manual_no_overlap"] mutableCopy];
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
        NSParagraphStyleAttributeName: paragraphStyle
    }];
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
