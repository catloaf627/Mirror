//
//  MirrorDebugAlert.m
//  Mirror
//

#import "MirrorDebugAlert.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "MirrorMacro.h"
#import "MirrorStorage.h"
#import "MirrorTimeText.h"

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
                                                                             message:@"\n\n"
                                                                      preferredStyle:UIAlertControllerStyleAlert];

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

    [debugSwitchContainer addSubview:debugSwitchLabel];
    [debugSwitchContainer addSubview:debugSwitch];
    [alertController.view addSubview:debugSwitchContainer];

    [NSLayoutConstraint activateConstraints:@[
        [debugSwitchContainer.leadingAnchor constraintEqualToAnchor:alertController.view.leadingAnchor constant:24],
        [debugSwitchContainer.trailingAnchor constraintEqualToAnchor:alertController.view.trailingAnchor constant:-24],
        [debugSwitchContainer.topAnchor constraintEqualToAnchor:alertController.view.topAnchor constant:60],
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
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [viewController presentViewController:alertController animated:YES completion:nil];
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
