import ActivityKit
import Foundation

struct MirrorLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let startDate: Date
    }

    let taskName: String
    let colorType: Int
}

@objcMembers
@objc(MirrorLiveActivityManager)
final class MirrorLiveActivityManager: NSObject {
    @objc(startWithTaskName:startTimestamp:colorType:)
    static func start(taskName: String, startTimestamp: TimeInterval, colorType: Int) {
        guard #available(iOS 16.1, *), ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        Task {
            let startDate = Date(timeIntervalSince1970: startTimestamp)
            let attributes = MirrorLiveActivityAttributes(taskName: taskName, colorType: colorType)
            let state = MirrorLiveActivityAttributes.ContentState(startDate: startDate)
            guard !hasMatchingActivity(taskName: taskName, startDate: startDate, colorType: colorType) else {
                return
            }

            await endActiveActivities()

            do {
                if #available(iOS 16.2, *) {
                    let content = ActivityContent(state: state, staleDate: nil)
                    _ = try Activity<MirrorLiveActivityAttributes>.request(
                        attributes: attributes,
                        content: content,
                        pushType: nil
                    )
                } else {
                    _ = try Activity<MirrorLiveActivityAttributes>.request(
                        attributes: attributes,
                        contentState: state,
                        pushType: nil
                    )
                }
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
        for activity in Activity<MirrorLiveActivityAttributes>.activities {
            if #available(iOS 16.2, *) {
                let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
                await activity.end(finalContent, dismissalPolicy: .immediate)
            } else {
                await activity.end(using: activity.contentState, dismissalPolicy: .immediate)
            }
        }
    }

    @available(iOS 16.1, *)
    private static func hasMatchingActivity(taskName: String, startDate: Date, colorType: Int) -> Bool {
        Activity<MirrorLiveActivityAttributes>.activities.contains { activity in
            guard activity.attributes.taskName == taskName,
                  activity.attributes.colorType == colorType else {
                return false
            }

            let activityStartDate: Date
            if #available(iOS 16.2, *) {
                activityStartDate = activity.content.state.startDate
            } else {
                activityStartDate = activity.contentState.startDate
            }
            return abs(activityStartDate.timeIntervalSince(startDate)) < 1
        }
    }
}
