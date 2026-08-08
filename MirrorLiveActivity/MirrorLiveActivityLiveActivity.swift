//
//  MirrorLiveActivityLiveActivity.swift
//  MirrorLiveActivity
//
//  Created by Yuqing Wang on 8/7/26.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct MirrorLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let startDate: Date
    }

    let taskName: String
    let colorType: Int
}

struct MirrorLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MirrorLiveActivityAttributes.self) { context in
            MirrorLockScreenLiveActivityView(context: context)
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(MirrorActivityColor.color(for: context.attributes.colorType))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        MirrorColorDot(color: MirrorActivityColor.color(for: context.attributes.colorType), size: 14)

                        Text(context.attributes.taskName)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startDate, style: .timer)
                        .font(.headline)
                        .monospacedDigit()
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        Capsule()
                            .fill(MirrorActivityColor.color(for: context.attributes.colorType))
                            .frame(width: 36, height: 5)

                        Text(context.state.startDate, style: .timer)
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                }
            } compactLeading: {
                MirrorColorDot(color: MirrorActivityColor.color(for: context.attributes.colorType), size: 13)
            } compactTrailing: {
                Text(context.state.startDate, style: .timer)
                    .font(.caption2)
                    .monospacedDigit()
                    .frame(maxWidth: 56)
            } minimal: {
                MirrorColorDot(color: MirrorActivityColor.color(for: context.attributes.colorType), size: 12)
            }
            .keylineTint(MirrorActivityColor.color(for: context.attributes.colorType))
        }
    }
}

private struct MirrorLockScreenLiveActivityView: View {
    let context: ActivityViewContext<MirrorLiveActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            MirrorColorDot(color: MirrorActivityColor.color(for: context.attributes.colorType), size: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.taskName)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(.white)

                Text("Counting")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Spacer()

            Text(context.state.startDate, style: .timer)
                .font(.title3)
                .monospacedDigit()
                .foregroundStyle(.white)
        }
        .padding(.vertical, 4)
    }
}

private struct MirrorColorDot: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.65), lineWidth: 1)
            )
    }
}

private enum MirrorActivityColor {
    static func color(for colorType: Int) -> Color {
        switch baseColorType(from: colorType) {
        case 0:
            return Color(red: 224 / 255, green: 205 / 255, blue: 207 / 255)
        case 2:
            return Color(red: 233 / 255, green: 217 / 255, blue: 209 / 255)
        case 4:
            return Color(red: 243 / 255, green: 230 / 255, blue: 211 / 255)
        case 6:
            return Color(red: 224 / 255, green: 235 / 255, blue: 223 / 255)
        case 8:
            return Color(red: 212 / 255, green: 231 / 255, blue: 234 / 255)
        case 10:
            return Color(red: 198 / 255, green: 208 / 255, blue: 220 / 255)
        case 12:
            return Color(red: 216 / 255, green: 207 / 255, blue: 226 / 255)
        case 14:
            return Color(red: 218 / 255, green: 218 / 255, blue: 218 / 255)
        default:
            return Color(red: 198 / 255, green: 208 / 255, blue: 220 / 255)
        }
    }

    private static func baseColorType(from colorType: Int) -> Int {
        colorType % 2 == 0 ? colorType : colorType - 1
    }
}

extension MirrorLiveActivityAttributes {
    fileprivate static var preview: MirrorLiveActivityAttributes {
        MirrorLiveActivityAttributes(taskName: "Workout", colorType: 6)
    }
}

extension MirrorLiveActivityAttributes.ContentState {
    fileprivate static var preview: MirrorLiveActivityAttributes.ContentState {
        MirrorLiveActivityAttributes.ContentState(startDate: .now.addingTimeInterval(-1800))
    }
}

#Preview("Notification", as: .content, using: MirrorLiveActivityAttributes.preview) {
    MirrorLiveActivityLiveActivity()
} contentStates: {
    MirrorLiveActivityAttributes.ContentState.preview
}
