import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), alarm: mockAlarm())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        completion(SimpleEntry(date: Date(), alarm: fetchNextAlarm()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(date: Date(), alarm: fetchNextAlarm())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func fetchNextAlarm() -> AlarmItem? {
        guard let data = UserDefaults(suiteName: "group.com.qralarm.app")?.data(forKey: "com.qralarm.alarms"),
              let alarms = try? JSONDecoder().decode([AlarmItem].self, from: data) else {
            return nil
        }
        return alarms.sorted {
            if $0.hour != $1.hour { return $0.hour < $1.hour }
            return $0.minute < $1.minute
        }.first
    }

    private func mockAlarm() -> AlarmItem {
        AlarmItem(hour: 7, minute: 30, label: "起床囉", isEnabled: true)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let alarm: AlarmItem?
}

struct QRAlarmWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            if let alarm = entry.alarm {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(alarm.label)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)

                        Text(String(format: "%d:%02d", alarm.hour12, alarm.minute))
                            .font(.system(size: 36, weight: .light, design: .rounded))
                            .foregroundStyle(alarm.isEnabled ? .primary : .secondary)
                    }

                    Spacer()

                    Button(intent: ToggleAlarmIntent(alarmID: alarm.id.uuidString, isEnabled: !alarm.isEnabled)) {
                        Image(systemName: alarm.isEnabled ? "bell.fill" : "bell.slash")
                            .font(.title2)
                            .foregroundStyle(alarm.isEnabled ? .white : .gray)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(alarm.isEnabled ? Color.accentColor : Color(.quaternarySystemFill))
                            )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("尚未設定鬧鐘")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct QRAlarmWidget: Widget {
    let kind: String = "QRAlarmWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QRAlarmWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("最近的鬧鐘")
        .description("在桌面上快速查看並開關下一個鬧鐘。")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
