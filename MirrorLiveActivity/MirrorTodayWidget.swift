//
//  MirrorTodayWidget.swift
//  MirrorLiveActivity
//

import Foundation
import SwiftUI
import UIKit
import WidgetKit

private let mirrorTodayAppGroupIdentifier = "group.com.yuqingwang.dev.Mirror"
private let mirrorTodayJSONFileName = "mirror.json"

struct MirrorTodayWidgetEntry: TimelineEntry {
    let date: Date
    let tasks: [MirrorTodayTaskSlice]
    let totalSeconds: TimeInterval
    let unavailableMessage: String?
}

struct MirrorTodayTaskSlice: Identifiable, Hashable {
    let id: String
    let name: String
    let seconds: TimeInterval
    let color: Color
}

struct MirrorTodayWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MirrorTodayWidgetEntry {
        MirrorTodayWidgetEntry(date: .now,
                               tasks: previewTasks,
                               totalSeconds: previewTasks.reduce(0) { $0 + $1.seconds },
                               unavailableMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MirrorTodayWidgetEntry) -> Void) {
        let result = MirrorTodayStore.loadTodayTasks()
        completion(MirrorTodayWidgetEntry(date: .now,
                                          tasks: result.tasks,
                                          totalSeconds: result.totalSeconds,
                                          unavailableMessage: result.unavailableMessage))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MirrorTodayWidgetEntry>) -> Void) {
        let now = Date.now
        let result = MirrorTodayStore.loadTodayTasks()
        let entry = MirrorTodayWidgetEntry(date: now,
                                           tasks: result.tasks,
                                           totalSeconds: result.totalSeconds,
                                           unavailableMessage: result.unavailableMessage)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: now) ?? Calendar.current.startOfNextDay(after: now)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private var previewTasks: [MirrorTodayTaskSlice] {
        [
            MirrorTodayTaskSlice(id: "preview-focus", name: "Focus", seconds: 3.5 * 60 * 60, color: MirrorTodayColor.color(for: 10)),
            MirrorTodayTaskSlice(id: "preview-design", name: "Design", seconds: 2.25 * 60 * 60, color: MirrorTodayColor.color(for: 0)),
            MirrorTodayTaskSlice(id: "preview-study", name: "Study", seconds: 1.5 * 60 * 60, color: MirrorTodayColor.color(for: 6))
        ]
    }
}

struct MirrorTodayWidget: Widget {
    private let kind = "MirrorTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MirrorTodayWidgetProvider()) { entry in
            MirrorTodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Mirror Today")
        .description("Shows today's tracked time.")
        .supportedFamilies([.systemSmall])
    }
}

private struct MirrorTodayWidgetView: View {
    let entry: MirrorTodayWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            if let unavailableMessage = entry.unavailableMessage {
                MirrorTodayEmptyView(text: unavailableMessage)
            } else if entry.tasks.isEmpty {
                MirrorTodayEmptyView(text: String(localized: "No time today"))
            } else {
                ZStack(alignment: .topTrailing) {
                    MirrorTodayPieChart(tasks: entry.tasks.prefix(5).map { $0 })


                    Text(formattedDuration(entry.totalSeconds))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 60 * 60 ? [.hour, .minute] : [.minute]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll

        return formatter.string(from: max(seconds, 60)) ?? "0"
    }
}

private struct MirrorTodayPieChart: View {
    let tasks: [MirrorTodayTaskSlice]

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let rect = CGRect(x: (proxy.size.width - side) / 2,
                              y: (proxy.size.height - side) / 2,
                              width: side,
                              height: side)

            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: side, height: side)
                    .position(x: rect.midX, y: rect.midY)

                ForEach(segments) { segment in
                    MirrorTodayPieSegment(startAngle: segment.startAngle, endAngle: segment.endAngle)
                        .fill(segment.color)
                        .frame(width: side, height: side)
                        .position(x: rect.midX, y: rect.midY)
                }

                MirrorTodayPieSeparatorLines(angles: segments.map(\.startAngle))
                    .stroke(Color(.systemBackground), style: StrokeStyle(lineWidth: 1, lineCap: .butt))
                    .frame(width: side, height: side)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
    }

    private var segments: [MirrorTodayPieSegmentModel] {
        let total = tasks.reduce(0) { $0 + $1.seconds }
        guard total > 0 else { return [] }

        var start = Angle.degrees(-90)
        return tasks.map { task in
            let sweep = Angle.degrees(360 * task.seconds / total)
            let segment = MirrorTodayPieSegmentModel(id: task.id,
                                                     startAngle: start,
                                                     endAngle: start + sweep,
                                                     color: task.color)
            start += sweep
            return segment
        }
    }

}

private struct MirrorTodayPieSegmentModel: Identifiable {
    let id: String
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
}

private struct MirrorTodayPieSegment: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

private struct MirrorTodayPieSeparatorLines: Shape {
    let angles: [Angle]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        for angle in angles {
            let xUnit = cos(angle.radians)
            let yUnit = sin(angle.radians)
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + xUnit * radius,
                                     y: center.y + yUnit * radius))
        }

        return path
    }
}

private struct MirrorTodayEmptyView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private enum MirrorTodayStore {
    struct LoadResult {
        let tasks: [MirrorTodayTaskSlice]
        let totalSeconds: TimeInterval
        let unavailableMessage: String?
    }

    static func loadTodayTasks() -> LoadResult {
        guard let fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: mirrorTodayAppGroupIdentifier)?.appendingPathComponent(mirrorTodayJSONFileName) else {
            return LoadResult(tasks: [], totalSeconds: 0, unavailableMessage: String(localized: "Shared data unavailable"))
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            return LoadResult(tasks: [], totalSeconds: 0, unavailableMessage: String(localized: "Open Mirror.ly to sync data"))
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let jsonDictionary = jsonObject as? [String: Any],
              let jsonRecords = jsonDictionary["records"] as? [[String: Any]],
              let jsonTasks = jsonDictionary["tasks"] as? [[String: Any]] else {
            return LoadResult(tasks: [], totalSeconds: 0, unavailableMessage: String(localized: "Time data unavailable"))
        }

        let tasksByName = taskMetadataByName(from: jsonTasks)
        let calendar = Calendar.current
        let now = Date.now
        let todayStart = calendar.startOfDay(for: now)
        let todayEnd = calendar.startOfNextDay(after: now)
        var secondsByName: [String: TimeInterval] = [:]

        for record in jsonRecords {
            guard let taskName = record["task_name"] as? String,
                  !taskName.isEmpty,
                  tasksByName[taskName]?.isHidden != true,
                  let startTimestamp = timestampValue(from: record["start_time"]),
                  let endTimestamp = timestampValue(from: record["end_time"]),
                  endTimestamp > startTimestamp else {
                continue
            }

            let startDate = Date(timeIntervalSince1970: startTimestamp)
            let endDate = Date(timeIntervalSince1970: endTimestamp)
            let clippedStart = max(startDate, todayStart)
            let clippedEnd = min(endDate, todayEnd)
            guard clippedEnd > clippedStart else { continue }

            secondsByName[taskName, default: 0] += clippedEnd.timeIntervalSince(clippedStart)
        }

        let slices = secondsByName.map { taskName, seconds in
            let colorType = tasksByName[taskName]?.colorType ?? 14
            return MirrorTodayTaskSlice(id: taskName,
                                        name: taskName,
                                        seconds: seconds,
                                        color: MirrorTodayColor.color(for: colorType))
        }
        .sorted { lhs, rhs in
            let lhsOrder = tasksByName[lhs.name]?.order ?? Int.max
            let rhsOrder = tasksByName[rhs.name]?.order ?? Int.max
            if lhsOrder == rhsOrder {
                return lhs.name < rhs.name
            }
            return lhsOrder < rhsOrder
        }

        return LoadResult(tasks: slices,
                          totalSeconds: slices.reduce(0) { $0 + $1.seconds },
                          unavailableMessage: nil)
    }

    private static func taskMetadataByName(from jsonTasks: [[String: Any]]) -> [String: MirrorTodayTaskMetadata] {
        var metadata: [String: MirrorTodayTaskMetadata] = [:]
        for (index, task) in jsonTasks.enumerated() {
            guard let taskName = task["task_name"] as? String, !taskName.isEmpty else { continue }
            let colorType = intValue(from: task["color"]) ?? 14
            let isHidden = boolValue(from: task["is_hidden"])
            metadata[taskName] = MirrorTodayTaskMetadata(colorType: colorType, isHidden: isHidden, order: index)
        }
        return metadata
    }

    private static func timestampValue(from value: Any?) -> TimeInterval? {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let double = value as? Double {
            return double
        }
        if let int = value as? Int {
            return TimeInterval(int)
        }
        return nil
    }

    private static func intValue(from value: Any?) -> Int? {
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let int = value as? Int {
            return int
        }
        return nil
    }

    private static func boolValue(from value: Any?) -> Bool {
        if let number = value as? NSNumber {
            return number.boolValue
        }
        if let bool = value as? Bool {
            return bool
        }
        return false
    }
}

private struct MirrorTodayTaskMetadata {
    let colorType: Int
    let isHidden: Bool
    let order: Int
}

private extension Calendar {
    func startOfNextDay(after date: Date) -> Date {
        self.date(byAdding: .day, value: 1, to: startOfDay(for: date)) ?? date.addingTimeInterval(24 * 60 * 60)
    }
}

private enum MirrorTodayColor {
    static func color(for colorType: Int) -> Color {
        Color(UIColor { traitCollection in
            uiColor(for: colorType, darkMode: traitCollection.userInterfaceStyle == .dark)
        })
    }

    private static func uiColor(for colorType: Int, darkMode: Bool) -> UIColor {
        switch colorType {
        case 0:
            return darkMode ? uiColor(red: 90, green: 48, blue: 53) : uiColor(red: 226, green: 207, blue: 210)
        case 1:
            return darkMode ? uiColor(red: 226, green: 207, blue: 210) : uiColor(red: 90, green: 48, blue: 53)
        case 2:
            return darkMode ? uiColor(red: 90, green: 52, blue: 36) : uiColor(red: 228, green: 212, blue: 204)
        case 3:
            return darkMode ? uiColor(red: 228, green: 212, blue: 204) : uiColor(red: 90, green: 52, blue: 36)
        case 4:
            return darkMode ? uiColor(red: 93, green: 69, blue: 42) : uiColor(red: 229, green: 218, blue: 200)
        case 5:
            return darkMode ? uiColor(red: 229, green: 218, blue: 200) : uiColor(red: 93, green: 69, blue: 42)
        case 6:
            return darkMode ? uiColor(red: 51, green: 64, blue: 45) : uiColor(red: 213, green: 225, blue: 211)
        case 7:
            return darkMode ? uiColor(red: 213, green: 225, blue: 211) : uiColor(red: 51, green: 64, blue: 45)
        case 8:
            return darkMode ? uiColor(red: 33, green: 74, blue: 80) : uiColor(red: 205, green: 222, blue: 225)
        case 9:
            return darkMode ? uiColor(red: 205, green: 222, blue: 225) : uiColor(red: 33, green: 74, blue: 80)
        case 10:
            return darkMode ? uiColor(red: 53, green: 64, blue: 76) : uiColor(red: 206, green: 216, blue: 228)
        case 11:
            return darkMode ? uiColor(red: 206, green: 216, blue: 228) : uiColor(red: 53, green: 64, blue: 76)
        case 12:
            return darkMode ? uiColor(red: 57, green: 54, blue: 74) : uiColor(red: 220, green: 211, blue: 228)
        case 13:
            return darkMode ? uiColor(red: 220, green: 211, blue: 228) : uiColor(red: 57, green: 54, blue: 74)
        case 14:
            return darkMode ? uiColor(red: 61, green: 61, blue: 61) : uiColor(red: 218, green: 218, blue: 218)
        case 15:
            return darkMode ? uiColor(red: 218, green: 218, blue: 218) : uiColor(red: 61, green: 61, blue: 61)
        default:
            return .clear
        }
    }

    private static func uiColor(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }
}

#Preview(as: .systemSmall) {
    MirrorTodayWidget()
} timeline: {
    MirrorTodayWidgetEntry(date: .now,
                           tasks: [
                               MirrorTodayTaskSlice(id: "focus", name: "Focus", seconds: 4 * 60 * 60, color: MirrorTodayColor.color(for: 10)),
                               MirrorTodayTaskSlice(id: "study", name: "Study", seconds: 2 * 60 * 60, color: MirrorTodayColor.color(for: 6)),
                               MirrorTodayTaskSlice(id: "design", name: "Design", seconds: 2.5 * 60 * 60, color: MirrorTodayColor.color(for: 0))
                           ],
                           totalSeconds: 8.5 * 60 * 60,
                           unavailableMessage: nil)
}
