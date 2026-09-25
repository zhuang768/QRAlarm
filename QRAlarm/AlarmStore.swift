import Foundation
import Combine

// MARK: - AlarmStore

@MainActor
final class AlarmStore: ObservableObject {
    @Published private(set) var alarms: [AlarmItem] = []

    private let saveKey = "com.qralarm.alarms"
    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    func add(_ alarm: AlarmItem) {
        alarms.append(alarm)
        save()
    }

    func update(_ alarm: AlarmItem) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index] = alarm
        save()
    }

    func delete(at offsets: IndexSet) {
        alarms.remove(atOffsets: offsets)
        save()
    }

    func delete(id: UUID) {
        alarms.removeAll { $0.id == id }
        save()
    }

    func toggle(id: UUID) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].isEnabled.toggle()
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(alarms) {
            defaults.set(data, forKey: saveKey)
        }
    }

    private func load() {
        // Read the old App Group location once so existing local data is preserved.
        let legacyData = UserDefaults(suiteName: "group.com.qralarm.app")?.data(forKey: saveKey)
        guard
            let data = defaults.data(forKey: saveKey) ?? legacyData,
            let decoded = try? JSONDecoder().decode([AlarmItem].self, from: data)
        else { return }
        alarms = decoded
        if defaults.data(forKey: saveKey) == nil {
            defaults.set(data, forKey: saveKey)
        }
    }
}
