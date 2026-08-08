import ActivityKit
import Foundation

struct MirrorTimeActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let startDate: Date
    }

    let taskName: String
    let colorType: Int
}
