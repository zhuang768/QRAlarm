import AppIntents
import Foundation
import WidgetKit

struct ToggleAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "切換鬧鐘狀態"

    @Parameter(title: "Alarm ID")
    var alarmID: String

    @Parameter(title: "Enable Status")
    var isEnabled: Bool

    init() {}

    init(alarmID: String, isEnabled: Bool) {
        self.alarmID = alarmID
        self.isEnabled = isEnabled
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: alarmID),
              let defaults = UserDefaults(suiteName: "group.com.qralarm.app"),
              let data = defaults.data(forKey: "com.qralarm.alarms"),
              var alarms = try? JSONDecoder().decode([AlarmItem].self, from: data) else {
            return .result()
        }

        if let index = alarms.firstIndex(where: { $0.id == uuid }) {
            alarms[index].isEnabled = isEnabled

            if let updatedData = try? JSONEncoder().encode(alarms) {
                defaults.set(updatedData, forKey: "com.qralarm.alarms")
                // TODO: Update real AlarmManagerService (AlarmKit) here via some shared logic
            }
        }

        return .result()
    }
}
