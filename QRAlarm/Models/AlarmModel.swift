import Foundation
import Combine

// MARK: - Weekday

/// Bitmask 表示重複星期（1=週日, 2=週一, 4=週二, ... , 64=週六）
struct WeekdaySet: OptionSet, Codable, Hashable {
    let rawValue: Int

    static let sunday    = WeekdaySet(rawValue: 1 << 0)
    static let monday    = WeekdaySet(rawValue: 1 << 1)
    static let tuesday   = WeekdaySet(rawValue: 1 << 2)
    static let wednesday = WeekdaySet(rawValue: 1 << 3)
    static let thursday  = WeekdaySet(rawValue: 1 << 4)
    static let friday    = WeekdaySet(rawValue: 1 << 5)
    static let saturday  = WeekdaySet(rawValue: 1 << 6)

    static let weekdays: WeekdaySet = [.monday, .tuesday, .wednesday, .thursday, .friday]
    static let weekends: WeekdaySet = [.saturday, .sunday]
    static let everyday: WeekdaySet = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]

    var displayText: String {
        if self == .everyday { return "每天" }
        if self == .weekdays { return "週一至五" }
        if self == .weekends { return "週末" }
        if self.isEmpty { return "只響一次" }

        let days = ["日", "一", "二", "三", "四", "五", "六"]
        var result: [String] = []
        for i in 0..<7 {
            if self.contains(WeekdaySet(rawValue: 1 << i)) {
                result.append("週" + days[i])
            }
        }
        return result.joined(separator: "、")
    }

    var alarmKitWeekdays: [Int] {
        var result: [Int] = []
        for i in 0..<7 {
            if self.contains(WeekdaySet(rawValue: 1 << i)) {
                result.append(i + 1)
            }
        }
        return result
    }
}

// MARK: - AlarmItem

struct AlarmItem: Identifiable, Codable, Hashable {
    var id: UUID
    var hour: Int
    var minute: Int
    var label: String
    var repeatDays: WeekdaySet
    var isEnabled: Bool
    var requiresQRCode: Bool
    var qrCodeContent: String?

    init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        label: String = "鬧鐘",
        repeatDays: WeekdaySet = [],
        isEnabled: Bool = true,
        requiresQRCode: Bool = false,
        qrCodeContent: String? = nil
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
        self.repeatDays = repeatDays
        self.isEnabled = isEnabled
        self.requiresQRCode = requiresQRCode
        self.qrCodeContent = qrCodeContent
    }

    var timeString: String {
        String(format: "%02d:%02d", hour, minute)
    }

    var displayPeriod: String {
        hour < 12 ? "AM" : "PM"
    }

    var hour12: Int {
        let h = hour % 12
        return h == 0 ? 12 : h
    }

    func nextFireDate() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard var candidate = calendar.date(from: components) else { return Date() }

        if candidate <= Date() {
            candidate = calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
        }

        if !repeatDays.isEmpty {
            for dayOffset in 0..<8 {
                let check = calendar.date(byAdding: .day, value: dayOffset, to: candidate) ?? candidate
                let weekday = calendar.component(.weekday, from: check)
                let bit = WeekdaySet(rawValue: 1 << (weekday - 1))
                if repeatDays.contains(bit) {
                    return check
                }
            }
        }

        return candidate
    }
}
