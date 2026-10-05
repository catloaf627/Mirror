//
//  MirrorSupportManualAlert.m
//  Mirror
//

#import "MirrorSupportManualAlert.h"
#import "MirrorLanguage.h"
#import "MirrorManualVideoViewController.h"

static NSString * const kMirrorRecordTimeCannotOverlapVideoName = @"0_no_overlap";
static NSString * const kMirrorLongPressToSwitchTaskPositionVideoName = @"1_reorder";
static NSString * const kMirrorLongPressToEditTaskVideoName = @"1_edit";
static NSString * const kMirrorLongPressToMergeTaskVideoName = @"1_merge";
static NSString * const kMirrorSwipeOrUseCalendarToSwitchDatesVideoName = @"2_switch_dates";
static NSString * const kMirrorTapToAdjustStartEndTimeVideoName = @"2_tap_edit";
static NSString * const kMirrorTapEmptySpaceToAddNewRecordVideoName = @"2_add";
static NSString * const kMirrorLongPressToEditRecordVideoName = @"2_edit";
static NSString * const kMirrorFutureTodoWidgetVideoName = @"2_future_todo";
static NSString * const kMirrorLongPressToEditSpecialDayVideoName = @"2_special_edit";
static NSString * const kMirrorTapTaskInLegendToHideShowVideoName = @"3_legend";
static NSString * const kMirrorLongPressDragAcrossDatesVideoName = @"3_select_multiple";
static NSString * const kMirrorTapToSwitchRecordDataStyleVideoName = @"3_four_styles";
static NSString * const kMirrorLongPressToEditTaskRecordVideoName = @"3_one_edit";
static NSString * const kMirrorManualVideoItemTitleKey = @"title";
static NSString * const kMirrorManualVideoItemURLKey = @"url";
static NSString * const kMirrorManualVideoDefinitionLanguageKey = @"languageKey";
static NSString * const kMirrorManualVideoDefinitionNameKey = @"name";

@implementation MirrorSupportManualAlert

+ (void)presentFromViewController:(UIViewController *)viewController
{
    if (!viewController) {
        return;
    }

    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];

    NSArray<NSDictionary<NSString *, id> *> *videoItems = [self videoItems];
    if (videoItems.count == 0) {
        return;
    }

    UIViewController *presentingViewController = [self topViewControllerFromRootViewController:viewController];
    if (!presentingViewController) {
        return;
    }

    NSInteger lastWatchedVideoIndex = [[NSUserDefaults standardUserDefaults] integerForKey:kMirrorManualLastWatchedVideoIndexKey];
    NSInteger currentIndex = lastWatchedVideoIndex >= 0 && lastWatchedVideoIndex < videoItems.count ? lastWatchedVideoIndex : 0;
    MirrorManualVideoViewController *playerViewController = [[MirrorManualVideoViewController alloc] initWithVideoItems:videoItems currentIndex:currentIndex];
    [presentingViewController presentViewController:playerViewController animated:YES completion:nil];
}

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)videoDefinitions
{
    return @[
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_no_overlap", kMirrorManualVideoDefinitionNameKey: kMirrorRecordTimeCannotOverlapVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_start_switch_task_position", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressToSwitchTaskPositionVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_start_edit_task", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressToEditTaskVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_start_merge_task", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressToMergeTaskVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_today_switch_date", kMirrorManualVideoDefinitionNameKey: kMirrorSwipeOrUseCalendarToSwitchDatesVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_today_adjust_time", kMirrorManualVideoDefinitionNameKey: kMirrorTapToAdjustStartEndTimeVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_today_add_record", kMirrorManualVideoDefinitionNameKey: kMirrorTapEmptySpaceToAddNewRecordVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_today_edit_record", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressToEditRecordVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_future_todo_widget", kMirrorManualVideoDefinitionNameKey: kMirrorFutureTodoWidgetVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_special_day_edit", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressToEditSpecialDayVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_record_legend_task_visibility", kMirrorManualVideoDefinitionNameKey: kMirrorTapTaskInLegendToHideShowVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_record_drag_dates", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressDragAcrossDatesVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_record_data_styles", kMirrorManualVideoDefinitionNameKey: kMirrorTapToSwitchRecordDataStyleVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_record_task_record_edit", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressToEditTaskRecordVideoName}
    ];
}

+ (NSArray<NSDictionary<NSString *, id> *> *)videoItems
{
    NSMutableArray<NSDictionary<NSString *, id> *> *videoItems = [NSMutableArray new];
    for (NSDictionary<NSString *, NSString *> *definition in [self videoDefinitions]) {
        NSURL *videoURL = [self videoURLForName:definition[kMirrorManualVideoDefinitionNameKey]];
        if (!videoURL) {
            continue;
        }
        [videoItems addObject:@{
            kMirrorManualVideoItemTitleKey: [MirrorLanguage mirror_stringWithKey:definition[kMirrorManualVideoDefinitionLanguageKey]],
            kMirrorManualVideoItemURLKey: videoURL
        }];
    }
    return [videoItems copy];
}

+ (NSURL *)videoURLForName:(NSString *)videoName
{
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

+ (UIViewController *)topViewControllerFromRootViewController:(UIViewController *)rootViewController
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

@end
