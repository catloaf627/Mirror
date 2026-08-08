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
        .padding(.horizontal, 16)
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
        switch pulseColorType(from: colorType) {
        case 1:
            return Color(red: 170 / 255, green: 117 / 255, blue: 120 / 255)
        case 3:
            return Color(red: 160 / 255, green: 106 / 255, blue: 80 / 255)
        case 5:
            return Color(red: 168 / 255, green: 132 / 255, blue: 98 / 255)
        case 7:
            return Color(red: 103 / 255, green: 119 / 255, blue: 91 / 255)
        case 9:
            return Color(red: 62 / 255, green: 130 / 255, blue: 141 / 255)
        case 11:
            return Color(red: 104 / 255, green: 120 / 255, blue: 137 / 255)
        case 13:
            return Color(red: 105 / 255, green: 100 / 255, blue: 123 / 255)
        case 15:
            return Color(red: 104 / 255, green: 104 / 255, blue: 104 / 255)
        default:
            return Color(red: 104 / 255, green: 120 / 255, blue: 137 / 255)
        }
    }

    private static func pulseColorType(from colorType: Int) -> Int {
        colorType % 2 == 0 ? colorType + 1 : colorType
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
