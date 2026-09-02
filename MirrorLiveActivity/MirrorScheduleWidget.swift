//
//  MirrorScheduleWidget.swift
//  MirrorLiveActivity
//

import SwiftUI
import WidgetKit

private let mirrorAppGroupIdentifier = "group.com.yuqingwang.dev.Mirror"
private let mirrorJSONFileName = "mirror.json"

struct MirrorScheduleWidgetEntry: TimelineEntry {
    let date: Date
    let schedules: [MirrorWidgetSchedule]
    let unavailableMessage: String?
}

struct MirrorWidgetSchedule: Identifiable, Hashable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
}

private struct MirrorScheduleSection: Identifiable {
    let date: Date
    let schedules: [MirrorWidgetSchedule]

    var id: TimeInterval {
        date.timeIntervalSince1970
    }
}

struct MirrorScheduleWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MirrorScheduleWidgetEntry {
        let now = Date.now
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(24 * 60 * 60)
        let later = Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now.addingTimeInterval(3 * 24 * 60 * 60)
        return MirrorScheduleWidgetEntry(date: now, schedules: [
            MirrorWidgetSchedule(id: "preview-1", title: "Tennis", startDate: tomorrowAt(hour: 9, minute: 0, from: tomorrow), endDate: tomorrowAt(hour: 10, minute: 30, from: tomorrow)),
            MirrorWidgetSchedule(id: "preview-2", title: "Ajah", startDate: tomorrowAt(hour: 9, minute: 0, from: later), endDate: tomorrowAt(hour: 10, minute: 0, from: later))
        ], unavailableMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MirrorScheduleWidgetEntry) -> Void) {
        let now = Date.now
        let result = MirrorScheduleStore.loadSchedules()
        completion(MirrorScheduleWidgetEntry(date: now, schedules: result.schedules, unavailableMessage: result.unavailableMessage))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MirrorScheduleWidgetEntry>) -> Void) {
        let now = Date.now
        let result = MirrorScheduleStore.loadSchedules()
        let entry = MirrorScheduleWidgetEntry(date: now, schedules: result.schedules, unavailableMessage: result.unavailableMessage)
        let nextRefresh = result.schedules.first { $0.endDate > now }?.endDate ?? Calendar.current.startOfNextDay(after: now)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func tomorrowAt(hour: Int, minute: Int, from date: Date) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
}

struct MirrorScheduleWidget: Widget {
    private let kind = "MirrorScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MirrorScheduleWidgetProvider()) { entry in
            MirrorScheduleWidgetView(entry: entry)
        }
        .configurationDisplayName("Mirror Schedules")
        .description("Shows your upcoming schedules.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

private struct MirrorScheduleWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MirrorScheduleWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            MirrorDateHeaderView(date: entry.date, isToday: true)

            if let unavailableMessage = entry.unavailableMessage {
                MirrorEmptyScheduleView(text: unavailableMessage)
            } else {
                agendaContent
            }
        }
        .padding(widgetPadding)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    @ViewBuilder
    private var agendaContent: some View {
        let todaySchedules = schedulesForToday()
        let futureSections = futureScheduleSections()

        if todaySchedules.isEmpty {
            MirrorEmptyScheduleView(text: String(localized: "No schedules today"))
        } else {
            ForEach(todaySchedules.prefix(maxTodayRows)) { schedule in
                MirrorScheduleRow(schedule: schedule, compact: family == .systemSmall)
            }
        }

        if family != .systemSmall {
            ForEach(futureSections.prefix(maxFutureSections)) { section in
                MirrorDateHeaderView(date: section.date, isToday: false)
                ForEach(section.schedules.prefix(rowsPerFutureSection)) { schedule in
                    MirrorScheduleRow(schedule: schedule, compact: false)
                }
            }
        }

        Spacer(minLength: 0)
    }

    private var verticalSpacing: CGFloat {
        family == .systemSmall ? 3 : 4
    }

    private var widgetPadding: EdgeInsets {
        switch family {
        case .systemSmall:
            return EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)
        case .systemMedium:
            return EdgeInsets(top: 3, leading: 0, bottom: 3, trailing: 0)
        default:
            return EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0)
        }
    }

    private var maxTodayRows: Int {
        switch family {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 2
        default:
            return 3
        }
    }

    private var maxFutureSections: Int {
        family == .systemLarge ? 3 : 1
    }

    private var rowsPerFutureSection: Int {
        family == .systemLarge ? 2 : 1
    }

    private func schedulesForToday() -> [MirrorWidgetSchedule] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: entry.date)
        let todayEnd = calendar.startOfNextDay(after: entry.date)
        return entry.schedules.compactMap { schedule in
            guard schedule.startDate < todayEnd, schedule.endDate > todayStart else {
                return nil
            }
            return MirrorWidgetSchedule(id: schedule.id,
                                        title: schedule.title,
                                        startDate: max(schedule.startDate, todayStart),
                                        endDate: min(schedule.endDate, todayEnd))
        }
    }

    private func futureScheduleSections() -> [MirrorScheduleSection] {
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: entry.date)
        let futureSchedules = entry.schedules.filter { schedule in
            calendar.startOfDay(for: schedule.startDate) > todayStart
        }
        let groupedSchedules = Dictionary(grouping: futureSchedules) { schedule in
            calendar.startOfDay(for: schedule.startDate)
        }
        return groupedSchedules.keys.sorted().map { date in
            MirrorScheduleSection(date: date, schedules: groupedSchedules[date] ?? [])
        }
    }
}

private struct MirrorDateHeaderView: View {
    let date: Date
    let isToday: Bool

    var body: some View {
        Text(displayText)
            .font(.system(size: isToday ? 14 : 13, weight: .bold))
            .foregroundStyle(isToday ? Color.red : Color.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var displayText: String {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date.now) ?? Date.now

        if calendar.isDate(date, inSameDayAs: tomorrow) {
            let weekday = date.formatted(.dateTime.weekday(.wide))
            return "\(String(localized: "Tomorrow")) \(weekday)"
        }

        return date.formatted(.dateTime.month(.abbreviated).day().weekday(.wide))
    }
}

private struct MirrorEmptyScheduleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MirrorScheduleRow: View {
    let schedule: MirrorWidgetSchedule
    let compact: Bool

    var body: some View {
        HStack(spacing: 7) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.32))
                .frame(width: 3, height: compact ? 24 : 28)

            Text(schedule.title)
                .font(.system(size: compact ? 12 : 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 0) {
                Text(schedule.startDate.formatted(date: .omitted, time: .shortened))
                    .foregroundStyle(.secondary)

                Text(schedule.endDate.formatted(date: .omitted, time: .shortened))
                    .foregroundStyle(.secondary.opacity(0.45))
            }
            .font(.system(size: compact ? 11 : 12, weight: .regular))
            .monospacedDigit()
            .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, compact ? 2 : 3)
        .frame(minHeight: compact ? 30 : 34)
        .background(Color(.secondarySystemBackground).opacity(0.42), in: RoundedRectangle(cornerRadius: 5))
    }
}

private enum MirrorScheduleStore {
    struct LoadResult {
        let schedules: [MirrorWidgetSchedule]
        let unavailableMessage: String?
    }

    static func loadSchedules() -> LoadResult {
        guard let fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: mirrorAppGroupIdentifier)?.appendingPathComponent(mirrorJSONFileName) else {
            return LoadResult(schedules: [], unavailableMessage: String(localized: "Shared data unavailable"))
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            return LoadResult(schedules: [], unavailableMessage: String(localized: "Open Mirror.ly to sync schedules"))
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let jsonDictionary = jsonObject as? [String: Any],
              let jsonSchedules = jsonDictionary["schedules"] as? [[String: Any]] else {
            return LoadResult(schedules: [], unavailableMessage: String(localized: "Schedule data unavailable"))
        }

        let now = Date.now.timeIntervalSince1970
        let schedules: [MirrorWidgetSchedule] = jsonSchedules.compactMap { dictionary -> MirrorWidgetSchedule? in
            guard let startTimestamp = timestampValue(from: dictionary["start_time"]),
                  let endTimestamp = timestampValue(from: dictionary["end_time"]),
                  endTimestamp > startTimestamp,
                  endTimestamp >= now else {
                return nil
            }

            let title = dictionary["schedule_info"] as? String ?? ""
            return MirrorWidgetSchedule(id: "\(startTimestamp)-\(endTimestamp)-\(title)",
                                        title: title,
                                        startDate: Date(timeIntervalSince1970: startTimestamp),
                                        endDate: Date(timeIntervalSince1970: endTimestamp))
        }
        .sorted { lhs, rhs in
            lhs.startDate < rhs.startDate
        }

        return LoadResult(schedules: schedules, unavailableMessage: nil)
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
}

private extension Calendar {
    func startOfNextDay(after date: Date) -> Date {
        self.date(byAdding: .day, value: 1, to: startOfDay(for: date)) ?? date.addingTimeInterval(24 * 60 * 60)
    }
}

#Preview(as: .systemLarge) {
    MirrorScheduleWidget()
} timeline: {
    MirrorScheduleWidgetEntry(date: .now, schedules: [
        MirrorWidgetSchedule(id: "1", title: "Tennis", startDate: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now, endDate: Calendar.current.date(byAdding: .day, value: 1, to: .now.addingTimeInterval(5400)) ?? .now.addingTimeInterval(5400)),
        MirrorWidgetSchedule(id: "2", title: "Ajah", startDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now, endDate: Calendar.current.date(byAdding: .day, value: 3, to: .now.addingTimeInterval(3600)) ?? .now.addingTimeInterval(3600))
    ], unavailableMessage: nil)
}
