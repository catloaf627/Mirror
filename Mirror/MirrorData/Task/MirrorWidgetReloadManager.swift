//
//  MirrorWidgetReloadManager.swift
//  Mirror
//

import WidgetKit

@objcMembers
@objc(MirrorWidgetReloadManager)
final class MirrorWidgetReloadManager: NSObject {
    @objc
    static func reloadScheduleWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "MirrorTodayWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "MirrorScheduleWidget")
    }
}
