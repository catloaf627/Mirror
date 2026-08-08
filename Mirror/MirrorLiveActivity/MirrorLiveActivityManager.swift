import ActivityKit
import Foundation

@objcMembers
@objc(MirrorLiveActivityManager)
final class MirrorLiveActivityManager: NSObject {
    @objc(startWithTaskName:startTimestamp:colorType:)
    static func start(taskName: String, startTimestamp: TimeInterval, colorType: Int) {
        guard #available(iOS 16.1, *), ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        Task {
            await endActiveActivities()

            let startDate = Date(timeIntervalSince1970: startTimestamp)
            let attributes = MirrorTimeActivityAttributes(taskName: taskName, colorType: colorType)
            let state = MirrorTimeActivityAttributes.ContentState(startDate: startDate)
            let content = ActivityContent(state: state, staleDate: nil)

            do {
                _ = try Activity<MirrorTimeActivityAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                print("Failed to start Mirror live activity: \(error)")
            }
        }
    }

    @objc
    static func end() {
        guard #available(iOS 16.1, *) else {
            return
        }

        Task {
            await endActiveActivities()
        }
    }

    @available(iOS 16.1, *)
    private static func endActiveActivities() async {
        for activity in Activity<MirrorTimeActivityAttributes>.activities {
            let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
    }
}
