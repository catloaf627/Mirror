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
            await endActiveActivities()

            let startDate = Date(timeIntervalSince1970: startTimestamp)
            let attributes = MirrorLiveActivityAttributes(taskName: taskName, colorType: colorType)
            let state = MirrorLiveActivityAttributes.ContentState(startDate: startDate)

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
}
