//
//  MirrorSupportManualAlert.m
//  Mirror
//

#import "MirrorSupportManualAlert.h"
#import "MirrorLanguage.h"
#import "MirrorManualVideoViewController.h"

static NSString * const kMirrorRecordTimeCannotOverlapVideoName = @"no_overlap";
static NSString * const kMirrorLongPressToEditMergeDeleteTaskVideoName = @"start_longpress_edit_merge_delete";
static NSString * const kMirrorLongPressToEditDeleteDragRecordVideoName = @"today_longpress_edit_delete";
static NSString * const kMirrorTapToAdjustStartEndTimeVideoName = @"today_tap_drag_edit";
static NSString * const kMirrorTapEmptySpaceToAddNewRecordVideoName = @"today_tap_empty_add_record";
static NSString * const kMirrorSwipeOrUseCalendarToSwitchDatesVideoName = @"swipe_or_calendar_switch_dates";
static NSString * const kMirrorTapTopLeftToOpenSpecialDaysVideoName = @"special_days";
static NSString * const kMirrorLongPressDragAcrossDatesVideoName = @"records_longdrag_to_see_multiple";
static NSString * const kMirrorTapDayToViewRecordsVideoName = @"records_tap_to_see_one_day";
static NSString * const kMirrorTapRecordToOpenTaskRecordsVideoName = @"records_tap_a_record_to_see_all_records_of_a_task_longpress_to";
static NSString * const kMirrorTapTaskInLegendToHideShowVideoName = @"records_click_legend";
static NSString * const kMirrorTapTopLeftFirstDayTopRightHeatmapVideoName = @"records_lefttop_righttop";
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

    MirrorManualVideoViewController *playerViewController = [[MirrorManualVideoViewController alloc] initWithVideoItems:videoItems currentIndex:0];
    [presentingViewController presentViewController:playerViewController animated:YES completion:nil];
}

+ (NSArray<NSDictionary<NSString *, NSString *> *> *)videoDefinitions
{
    return @[
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_no_overlap", kMirrorManualVideoDefinitionNameKey: kMirrorRecordTimeCannotOverlapVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_start_edit_task", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressToEditMergeDeleteTaskVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_today_adjust_time", kMirrorManualVideoDefinitionNameKey: kMirrorTapToAdjustStartEndTimeVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_today_edit_record", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressToEditDeleteDragRecordVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_today_add_record", kMirrorManualVideoDefinitionNameKey: kMirrorTapEmptySpaceToAddNewRecordVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_today_switch_date", kMirrorManualVideoDefinitionNameKey: kMirrorSwipeOrUseCalendarToSwitchDatesVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_today_special_days", kMirrorManualVideoDefinitionNameKey: kMirrorTapTopLeftToOpenSpecialDaysVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_record_drag_dates", kMirrorManualVideoDefinitionNameKey: kMirrorLongPressDragAcrossDatesVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_record_view_day", kMirrorManualVideoDefinitionNameKey: kMirrorTapDayToViewRecordsVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_record_task_list", kMirrorManualVideoDefinitionNameKey: kMirrorTapRecordToOpenTaskRecordsVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_record_legend_task_visibility", kMirrorManualVideoDefinitionNameKey: kMirrorTapTaskInLegendToHideShowVideoName},
        @{kMirrorManualVideoDefinitionLanguageKey: @"manual_record_options", kMirrorManualVideoDefinitionNameKey: kMirrorTapTopLeftFirstDayTopRightHeatmapVideoName}
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
