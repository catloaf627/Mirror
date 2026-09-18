//
//  MirrorDebugAlert.m
//  Mirror
//

#import "MirrorDebugAlert.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "MirrorMacro.h"
#import "MirrorStorage.h"
#import "MirrorTimeText.h"
#import "MirrorFakeDataSeeder.h"

@interface MirrorDebugAlert () <UIDocumentPickerDelegate>

@property (nonatomic, weak) UIViewController *presentingViewController;

@end

@implementation MirrorDebugAlert

+ (instancetype)sharedInstance
{
    static MirrorDebugAlert *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [MirrorDebugAlert new];
    });
    return sharedInstance;
}

+ (void)presentFromViewController:(UIViewController *)viewController
{
    [[MirrorDebugAlert sharedInstance] presentFromViewController:viewController];
}

- (void)presentFromViewController:(UIViewController *)viewController
{
    self.presentingViewController = viewController;

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"DEBUG"
                                                                             message:@"\n\n\n\n\n\n\n\n\n"
                                                                      preferredStyle:UIAlertControllerStyleAlert];

    UIView *tapDotSwitchContainer = [UIView new];
    tapDotSwitchContainer.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *recordSwitchLabel = [UILabel new];
    recordSwitchLabel.translatesAutoresizingMaskIntoConstraints = NO;
    recordSwitchLabel.text = @"is_record";
    recordSwitchLabel.font = [UIFont systemFontOfSize:17];
    recordSwitchLabel.textColor = UIColor.labelColor;

    UISwitch *recordSwitch = [UISwitch new];
    recordSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    recordSwitch.on = is_record;
    [recordSwitch addTarget:self action:@selector(recordSwitchChanged:) forControlEvents:UIControlEventValueChanged];

    UIButton *copyTimeOnButton = [UIButton buttonWithType:UIButtonTypeSystem];
    copyTimeOnButton.translatesAutoresizingMaskIntoConstraints = NO;
    [copyTimeOnButton setTitle:@"sudo systemsetup -setusingnetworktime off" forState:UIControlStateNormal];
    copyTimeOnButton.titleLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium];
    copyTimeOnButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    copyTimeOnButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [copyTimeOnButton addTarget:self action:@selector(copyRecordNetworkTimeOffCommand) forControlEvents:UIControlEventTouchUpInside];

    UIButton *copyDateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    copyDateButton.translatesAutoresizingMaskIntoConstraints = NO;
    [copyDateButton setTitle:[self recordNoonDateCommand] forState:UIControlStateNormal];
    copyDateButton.titleLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium];
    copyDateButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    copyDateButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [copyDateButton addTarget:self action:@selector(copyRecordDateCommand) forControlEvents:UIControlEventTouchUpInside];

    UIButton *copyTimeOffButton = [UIButton buttonWithType:UIButtonTypeSystem];
    copyTimeOffButton.translatesAutoresizingMaskIntoConstraints = NO;
    [copyTimeOffButton setTitle:@"sudo systemsetup -setusingnetworktime on" forState:UIControlStateNormal];
    copyTimeOffButton.titleLabel.font = [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium];
    copyTimeOffButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    copyTimeOffButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [copyTimeOffButton addTarget:self action:@selector(copyRecordTimeOffCommand) forControlEvents:UIControlEventTouchUpInside];

    UIView *debugSwitchContainer = [UIView new];
    debugSwitchContainer.translatesAutoresizingMaskIntoConstraints = NO;

    UILabel *debugSwitchLabel = [UILabel new];
    debugSwitchLabel.translatesAutoresizingMaskIntoConstraints = NO;
    debugSwitchLabel.text = @"is_debug";
    debugSwitchLabel.font = [UIFont systemFontOfSize:17];
    debugSwitchLabel.textColor = UIColor.labelColor;

    UISwitch *debugSwitch = [UISwitch new];
    debugSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    debugSwitch.on = is_debug;
    [debugSwitch addTarget:self action:@selector(debugSwitchChanged:) forControlEvents:UIControlEventValueChanged];

    [tapDotSwitchContainer addSubview:recordSwitchLabel];
    [tapDotSwitchContainer addSubview:recordSwitch];
    [tapDotSwitchContainer addSubview:copyTimeOnButton];
    [tapDotSwitchContainer addSubview:copyDateButton];
    [tapDotSwitchContainer addSubview:copyTimeOffButton];
    [debugSwitchContainer addSubview:debugSwitchLabel];
    [debugSwitchContainer addSubview:debugSwitch];
    [alertController.view addSubview:tapDotSwitchContainer];
    [alertController.view addSubview:debugSwitchContainer];

    [NSLayoutConstraint activateConstraints:@[
        [tapDotSwitchContainer.leadingAnchor constraintEqualToAnchor:alertController.view.leadingAnchor constant:24],
        [tapDotSwitchContainer.trailingAnchor constraintEqualToAnchor:alertController.view.trailingAnchor constant:-24],
        [tapDotSwitchContainer.topAnchor constraintEqualToAnchor:alertController.view.topAnchor constant:60],
        [tapDotSwitchContainer.heightAnchor constraintEqualToConstant:124],

        [recordSwitchLabel.leadingAnchor constraintEqualToAnchor:tapDotSwitchContainer.leadingAnchor],
        [recordSwitchLabel.topAnchor constraintEqualToAnchor:tapDotSwitchContainer.topAnchor],

        [recordSwitch.trailingAnchor constraintEqualToAnchor:tapDotSwitchContainer.trailingAnchor],
        [recordSwitch.centerYAnchor constraintEqualToAnchor:recordSwitchLabel.centerYAnchor],

        [copyTimeOnButton.leadingAnchor constraintEqualToAnchor:tapDotSwitchContainer.leadingAnchor],
        [copyTimeOnButton.trailingAnchor constraintEqualToAnchor:tapDotSwitchContainer.trailingAnchor],
        [copyTimeOnButton.topAnchor constraintEqualToAnchor:recordSwitchLabel.bottomAnchor constant:8],
        [copyTimeOnButton.heightAnchor constraintEqualToConstant:26],

        [copyDateButton.leadingAnchor constraintEqualToAnchor:tapDotSwitchContainer.leadingAnchor],
        [copyDateButton.trailingAnchor constraintEqualToAnchor:tapDotSwitchContainer.trailingAnchor],
        [copyDateButton.topAnchor constraintEqualToAnchor:copyTimeOnButton.bottomAnchor constant:4],
        [copyDateButton.heightAnchor constraintEqualToConstant:26],

        [copyTimeOffButton.leadingAnchor constraintEqualToAnchor:tapDotSwitchContainer.leadingAnchor],
        [copyTimeOffButton.trailingAnchor constraintEqualToAnchor:tapDotSwitchContainer.trailingAnchor],
        [copyTimeOffButton.topAnchor constraintEqualToAnchor:copyDateButton.bottomAnchor constant:4],
        [copyTimeOffButton.heightAnchor constraintEqualToConstant:26],

        [debugSwitchContainer.leadingAnchor constraintEqualToAnchor:alertController.view.leadingAnchor constant:24],
        [debugSwitchContainer.trailingAnchor constraintEqualToAnchor:alertController.view.trailingAnchor constant:-24],
        [debugSwitchContainer.topAnchor constraintEqualToAnchor:tapDotSwitchContainer.bottomAnchor constant:4],
        [debugSwitchContainer.heightAnchor constraintEqualToConstant:36],

        [debugSwitchLabel.leadingAnchor constraintEqualToAnchor:debugSwitchContainer.leadingAnchor],
        [debugSwitchLabel.centerYAnchor constraintEqualToAnchor:debugSwitchContainer.centerYAnchor],

        [debugSwitch.trailingAnchor constraintEqualToAnchor:debugSwitchContainer.trailingAnchor],
        [debugSwitch.centerYAnchor constraintEqualToAnchor:debugSwitchContainer.centerYAnchor]
    ]];

    [alertController addAction:[UIAlertAction actionWithTitle:@"Export JSON" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self exportJSONData];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Import JSON" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self showJSONDocumentPicker];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Seed Fake Data" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self presentSeedFakeDataConfirmation];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"For My Web" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self exportJSONDataForMyWeb];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [viewController presentViewController:alertController animated:YES completion:nil];
}

- (void)recordSwitchChanged:(UISwitch *)recordSwitch
{
    [[NSUserDefaults standardUserDefaults] setBool:recordSwitch.isOn forKey:@"is_record"];
}

- (void)copyRecordNetworkTimeOffCommand
{
    UIPasteboard.generalPasteboard.string = @"sudo systemsetup -setusingnetworktime off";
}

- (void)copyRecordDateCommand
{
    UIPasteboard.generalPasteboard.string = [self recordNoonDateCommand];
}

- (NSString *)recordNoonDateCommand
{
    return @"sudo date 0903000026";
}

- (void)copyRecordTimeOffCommand
{
    UIPasteboard.generalPasteboard.string = @"sudo systemsetup -setusingnetworktime on";
}

- (void)debugSwitchChanged:(UISwitch *)debugSwitch
{
    [[NSUserDefaults standardUserDefaults] setBool:debugSwitch.isOn forKey:@"is_debug"];
}

- (void)exportJSONData
{
    NSData *data = [MirrorStorage exportJSONData];
    if (!data) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"No Data" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }

    NSString *filename = [[@"Mirror" stringByAppendingString:[MirrorTimeText getPreciseTimeString]] stringByAppendingString:@".json"];
    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:filename]];
    [data writeToURL:url atomically:NO];

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[];
    activityViewController.popoverPresentationController.sourceView = self.presentingViewController.view;
    activityViewController.popoverPresentationController.sourceRect = CGRectMake(self.presentingViewController.view.bounds.size.width / 2, 0, 1, 1);
    [self.presentingViewController presentViewController:activityViewController animated:YES completion:nil];
}

- (void)exportJSONDataForMyWeb
{
    NSData *data = [MirrorStorage exportJSONData];
    if (!data) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"No Data" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }

    NSError *jsonError = nil;
    NSMutableDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
    NSMutableArray *records = jsonDictionary[RECORDS];
    NSMutableArray *days = jsonDictionary[DAYS];
    if (jsonError || ![jsonDictionary isKindOfClass:NSDictionary.class] || ![records isKindOfClass:NSArray.class] || ![days isKindOfClass:NSArray.class]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Invalid JSON Data" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }

    NSUInteger itemCount = MAX(records.count, days.count);
    for (NSUInteger index = 0; index < itemCount; index++) {
        if (index < records.count && [records[index] isKindOfClass:NSMutableDictionary.class]) {
            records[index][@"note"] = @"";
        }
        if (index < days.count && [days[index] isKindOfClass:NSMutableDictionary.class]) {
            days[index][@"info"] = @"";
        }
    }

    NSData *webData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:NSJSONWritingPrettyPrinted error:nil];
    if (!webData) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Export Failed" message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }

    NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingString:@"me.json"]];
    [webData writeToURL:url atomically:NO];

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    activityViewController.excludedActivityTypes = @[];
    activityViewController.popoverPresentationController.sourceView = self.presentingViewController.view;
    activityViewController.popoverPresentationController.sourceRect = CGRectMake(self.presentingViewController.view.bounds.size.width / 2, 0, 1, 1);
    [self.presentingViewController presentViewController:activityViewController animated:YES completion:nil];
}

- (void)presentSeedFakeDataConfirmation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *viewController = self.presentingViewController;
        if (!viewController) {
            return;
        }

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Seed Fake Data?"
                                                                                 message:@"This will overwrite current tasks, records, and special days."
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Seed" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [MirrorFakeDataSeeder seedFakeData];
            [[NSNotificationCenter defaultCenter] postNotificationName:MirrorImportDataNotificaiton object:nil];
        }]];
        [viewController presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)showJSONDocumentPicker
{
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:@[UTTypeData]];
    documentPicker.delegate = self;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [self.presentingViewController presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    NSURL *url = urls.firstObject;
    if (!url) {
        return;
    }

    BOOL fileUrlAuthorized = [url startAccessingSecurityScopedResource];
    if (!fileUrlAuthorized) {
        return;
    }

    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    NSError *coordinateError = nil;
    [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&coordinateError byAccessor:^(NSURL *newURL) {
        NSError *readError = nil;
        NSData *data = [NSData dataWithContentsOfURL:newURL options:NSDataReadingMappedIfSafe error:&readError];
        if (readError || ![MirrorStorage importJSONData:data]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Invalid JSON Data" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self.presentingViewController presentViewController:alertController animated:YES completion:nil];
            return;
        }

        [MirrorStorage saveSecondsFromGMT:@([NSTimeZone systemTimeZone].secondsFromGMT)];
        [[NSNotificationCenter defaultCenter] postNotificationName:MirrorImportDataNotificaiton object:nil];
    }];
    [url stopAccessingSecurityScopedResource];
}

@end
