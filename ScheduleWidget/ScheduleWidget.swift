//
//  ScheduleWidget.swift
//  ScheduleWidget
//
//  Created by 郭家駿 on 2026/9/9.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> ClassEntry {
        ClassEntry(date: .now, current: nil, next: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClassEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClassEntry>) -> Void) {
        let schedule: [Period] = SchedulePeriod(schedule: ScheduleHelper.loadItems()).periods
        let calendar = Calendar.current
        let now = Date()

        let systemWeekday = calendar.component(.weekday, from: now)
        let today = (systemWeekday + 5) % 7 + 1

        let todayPeriod = schedule
            .filter { $0.day == today }
            .sorted { $0.range.lowerBound < $1.range.lowerBound }

        struct Block { let start: Date; let end: Date; let period: Period }
        var blocks: [Block] = []
        for p in todayPeriod {
            let s = ScheduleLayout.periodTimes[p.range.lowerBound - 1]
            let e = ScheduleLayout.periodTimes[p.range.upperBound - 1]

            guard let start = calendar.date(bySettingHour: s.start.hour, minute: s.start.minute, second: 0, of: now), let end = calendar.date(bySettingHour: e.end.hour, minute: e.end.minute, second: 0, of: now) else { continue }
            blocks.append(Block(start: start, end: end, period: p))
        }

        var entries: [ClassEntry] = []
        entries.append(ClassEntry(date: calendar.startOfDay(for: now), current: nil, next: blocks.first?.period))

        for (i, b) in blocks.enumerated() {
            let nextPeriod = (i + 1 < blocks.count) ? blocks[i + 1].period : nil
            let nextStart = (i + 1 < blocks.count) ? blocks[i + 1].start : nil

            entries.append(ClassEntry(date: b.start, current: b.period, next: nextPeriod))

            if let ns = nextStart {
                if ns > b.end {
                    entries.append(ClassEntry(date: b.end, current: nil, next: nextPeriod))
                }
            } else {
                entries.append(ClassEntry(date: b.end, current: nil, next: nil))
            }

        }

        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)

        completion(Timeline(entries: entries, policy: .after(tomorrow)))
    }
}



class ScheduleHelper {
    static func loadItems() -> [ScheduleData] {
        guard let shared = UserDefaults(suiteName: "group.com.allen.NCHU-Unofficial"),
              let json = shared.string(forKey: "scheduleList"),
              let data = json.data(using: .utf8),
              let items = try? JSONDecoder().decode([ScheduleData].self, from: data)
        else { return [] }
        return items
    }
}

extension Period {
    /// The class time formatted as "HH:mm - HH:mm", derived from the period range.
    var timeText: String {
        let s = ScheduleLayout.periodTimes[range.lowerBound - 1].start
        let e = ScheduleLayout.periodTimes[range.upperBound - 1].end
        return String(format: "%02d:%02d - %02d:%02d", s.hour, s.minute, e.hour, e.minute)
    }
}

struct ClassEntry: TimelineEntry {
    let date: Date
    let current: Period?
    let next: Period?
}

struct ScheduleWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let current = entry.current {
                    Text(current.info.name ?? "—")
                        .font(.headline)
                        .lineLimit(1)
                    Text(current.timeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let teacher = current.info.teacher {
                        Text(teacher)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let location = current.info.location {
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No Class")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity,alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text("Next")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let next = entry.next {
                    Text(next.info.name ?? "—")
                        .font(.headline)
                        .lineLimit(1)
                    Text(next.timeText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let teacher = next.info.teacher {
                        Text(teacher)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let location = next.info.location {
                        Text(location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("No Class")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct ScheduleWidget: Widget {
    let kind: String = "ScheduleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ScheduleWidgetEntryView(entry: entry)
                .containerBackground(.ultraThinMaterial.tertiary, for: .widget)
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Schedule")
        .description("Show your current and next class")
    }
}

#Preview(as: .systemSmall) {
    ScheduleWidget()
} timeline: {
    ClassEntry(date: .now, current: nil, next: nil)
    ClassEntry(date: .now, current: Period(day: 1, range: 3...4, info: ScheduleData(text: "計算機組織 (3259) 蘇淮安AT242")), next: Period(day: 1, range: 5...6, info: ScheduleData(text: "資訊安全導論 (1234) 林詠章SC112")))
}
