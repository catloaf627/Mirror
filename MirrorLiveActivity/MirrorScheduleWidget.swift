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

private struct MirrorScheduleDisplayLine: Identifiable {
    enum Kind {
        case date(Date, isToday: Bool)
        case schedule(MirrorWidgetSchedule)
    }

    let id: String
    let kind: Kind
}

struct MirrorScheduleWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> MirrorScheduleWidgetEntry {
        let now = Date.now
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(24 * 60 * 60)
        let later = Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now.addingTimeInterval(3 * 24 * 60 * 60)
        return MirrorScheduleWidgetEntry(date: now, schedules: [
            MirrorWidgetSchedule(id: "preview-1", title: String(localized: "Sample todo"), startDate: tomorrowAt(hour: 9, minute: 0, from: tomorrow), endDate: tomorrowAt(hour: 10, minute: 30, from: tomorrow)),
            MirrorWidgetSchedule(id: "preview-2", title: String(localized: "Upcoming todo"), startDate: tomorrowAt(hour: 9, minute: 0, from: later), endDate: tomorrowAt(hour: 10, minute: 0, from: later))
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
        .configurationDisplayName("Mirror Todos")
        .description("Shows your upcoming todos.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
    }
}

private struct MirrorScheduleWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MirrorScheduleWidgetEntry

    var body: some View {
        widgetContent
            .containerBackground(for: .widget) {
                Color(.systemBackground)
            }
    }

    @ViewBuilder
    private var widgetContent: some View {
        switch family {
        case .accessoryInline:
            accessoryInlineView
        case .accessoryCircular:
            accessoryCircularView
        case .accessoryRectangular:
            accessoryRectangularView
        default:
            homeScreenWidgetView
        }
    }

    private var homeScreenWidgetView: some View {
        VStack(alignment: .leading, spacing: verticalSpacing) {
            if let unavailableMessage = entry.unavailableMessage {
                MirrorEmptyScheduleView(text: unavailableMessage)
            } else {
                agendaContent
            }
        }
        .padding(widgetPadding)
    }

    private var accessoryInlineView: some View {
        Label {
            Text(accessorySummaryText)
        } icon: {
            Image(systemName: accessorySymbolName)
        }
    }

    private var accessoryCircularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(spacing: 2) {
                Image(systemName: accessorySymbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .widgetAccentable()

                Text(accessoryCircularText)
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(4)
        }
    }

    private var accessoryRectangularView: some View {
        ZStack {
            AccessoryWidgetBackground()

            VStack(alignment: .leading, spacing: 2) {
                Label {
                    Text(accessoryHeadlineText)
                        .lineLimit(1)
                } icon: {
                    Image(systemName: accessorySymbolName)
                }
                .font(.system(size: 13, weight: .semibold))
                .widgetAccentable()

                Text(accessoryDetailText)
                    .font(.system(size: 12, weight: .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var agendaContent: some View {
        let displayLines = visibleDisplayLines()

        if displayLines.isEmpty {
            MirrorEmptyScheduleView(text: String(localized: "No upcoming todos"))
        } else {
            ForEach(displayLines) { line in
                switch line.kind {
                case let .date(date, isToday):
                    MirrorDateHeaderView(date: date, isToday: isToday)
                case let .schedule(schedule):
                    MirrorScheduleRow(schedule: schedule, compact: family == .systemSmall)
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

    private var maxLineCount: Int {
        switch family {
        case .systemSmall:
            return 3
        case .systemMedium:
            return 3
        default:
            return 7
        }
    }

    private var nextSchedule: MirrorWidgetSchedule? {
        entry.schedules.first { $0.endDate > entry.date }
    }

    private var accessorySymbolName: String {
        nextSchedule == nil ? "calendar" : "calendar.badge.clock"
    }

    private var accessorySummaryText: String {
        guard entry.unavailableMessage == nil else {
            return String(localized: "Open Mirror.ly")
        }

        guard let nextSchedule else {
            return String(localized: "No upcoming todos")
        }

        return "\(nextSchedule.title), \(accessoryTimeText(for: nextSchedule))"
    }

    private var accessoryHeadlineText: String {
        guard entry.unavailableMessage == nil else {
            return String(localized: "Mirror Todos")
        }

        return nextSchedule?.title ?? String(localized: "No upcoming todos")
    }

    private var accessoryDetailText: String {
        if let unavailableMessage = entry.unavailableMessage {
            return unavailableMessage
        }

        guard let nextSchedule else {
            return String(localized: "All clear")
        }

        return accessoryTimeText(for: nextSchedule)
    }

    private var accessoryCircularText: String {
        guard entry.unavailableMessage == nil else {
            return String(localized: "Open")
        }

        guard let nextSchedule else {
            return "0"
        }

        return nextSchedule.startDate.formatted(date: .omitted, time: .shortened)
    }

    private func accessoryTimeText(for schedule: MirrorWidgetSchedule) -> String {
        let calendar = Calendar.current
        let dayText: String

        if calendar.isDate(schedule.startDate, inSameDayAs: entry.date) {
            dayText = String(localized: "Today")
        } else if calendar.isDateInTomorrow(schedule.startDate) {
            dayText = String(localized: "Tomorrow")
        } else {
            dayText = schedule.startDate.formatted(.dateTime.weekday(.abbreviated))
        }

        return "\(dayText) \(schedule.startDate.formatted(date: .omitted, time: .shortened))"
    }

    private func visibleDisplayLines() -> [MirrorScheduleDisplayLine] {
        var remainingLineCount = maxLineCount
        var lines: [MirrorScheduleDisplayLine] = []

        for section in scheduleSections() {
            guard remainingLineCount >= 2 else {
                break
            }

            let visibleSchedules = Array(section.schedules.prefix(remainingLineCount - 1))
            guard !visibleSchedules.isEmpty else {
                continue
            }

            let isToday = Calendar.current.isDate(section.date, inSameDayAs: entry.date)
            lines.append(MirrorScheduleDisplayLine(id: "date-\(section.id)", kind: .date(section.date, isToday: isToday)))
            lines.append(contentsOf: visibleSchedules.map { schedule in
                MirrorScheduleDisplayLine(id: "schedule-\(schedule.id)", kind: .schedule(schedule))
            })
            remainingLineCount -= visibleSchedules.count + 1
        }

        return lines
    }

    private func scheduleSections() -> [MirrorScheduleSection] {
        let todaySchedules = schedulesForToday()
        let todaySection = todaySchedules.isEmpty ? [] : [MirrorScheduleSection(date: Calendar.current.startOfDay(for: entry.date),
                                                                                 schedules: todaySchedules)]
        return todaySection + futureScheduleSections()
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
            .foregroundStyle(isToday ? Color(.systemRed) : Color.secondary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var displayText: String {
        let calendar = Calendar.current

        if isToday {
            return String(localized: "Today")
        }

        if calendar.isDateInTomorrow(date) {
            return String(localized: "Tomorrow")
        }

        let weekday = date.formatted(.dateTime.weekday(.wide))
        let monthDay = date.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday), \(monthDay)"
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

private enum MirrorWidgetColor {
    static let scheduleText = Color(.secondaryLabel)
    static let scheduleBorder = Color(.separator)
}

private struct MirrorScheduleRow: View {
    let schedule: MirrorWidgetSchedule
    let compact: Bool

    var body: some View {
        HStack(spacing: 7) {
            Text(schedule.title)
                .font(.system(size: compact ? 12 : 13, weight: .semibold))
                .foregroundStyle(MirrorWidgetColor.scheduleText)
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
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(MirrorWidgetColor.scheduleBorder, style: StrokeStyle(lineWidth: 1.2, dash: [2, 3]))
        }
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
            return LoadResult(schedules: [], unavailableMessage: String(localized: "Open Mirror.ly to sync todos"))
        }

        guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let jsonDictionary = jsonObject as? [String: Any],
              let jsonSchedules = jsonDictionary["schedules"] as? [[String: Any]] else {
            return LoadResult(schedules: [], unavailableMessage: String(localized: "Todo data unavailable"))
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
        MirrorWidgetSchedule(id: "1", title: String(localized: "Sample todo"), startDate: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now, endDate: Calendar.current.date(byAdding: .day, value: 1, to: .now.addingTimeInterval(5400)) ?? .now.addingTimeInterval(5400)),
        MirrorWidgetSchedule(id: "2", title: String(localized: "Upcoming todo"), startDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now, endDate: Calendar.current.date(byAdding: .day, value: 3, to: .now.addingTimeInterval(3600)) ?? .now.addingTimeInterval(3600))
    ], unavailableMessage: nil)
}
