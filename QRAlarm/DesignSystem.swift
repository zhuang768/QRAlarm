import SwiftUI

// MARK: - Design System

/// QRAlarm 全域設計常數
/// 整個 App 只使用這一套色彩，禁止在其他地方硬寫 Color hex。
enum DS {

    // MARK: Colors

    enum Color {
        /// 主背景（深色模式 #0A0A0A，淺色模式 #FAFAF8）
        static let background = SwiftUI.Color("DSBackground")

        /// 卡片背景（比主背景略淺/深一階）
        static let cardBackground = SwiftUI.Color("DSCardBackground")

        /// 卡片邊框（1px，帶透明度）
        static let cardBorder = SwiftUI.Color("DSCardBorder")

        /// 唯一強調色 #FF5C2B
        static let accent = SwiftUI.Color(hex: "#FF5C2B")

        /// 主文字（系統自動深/淺）
        static let primary = SwiftUI.Color("DSPrimary")

        /// 次要文字（深 #8E8E93 / 淺 #6B6B6B）
        static let secondary = SwiftUI.Color("DSSecondary")

        /// 禁用/關閉狀態文字
        static let disabled = SwiftUI.Color("DSDisabled")
    }

    // MARK: Font

    enum Font {
        /// 鬧鐘列表時間大字 — 48pt Rounded Bold
        static let alarmTime = SwiftUI.Font.system(size: 48, weight: .bold, design: .rounded)

        /// 響鈴畫面超大時間 — 96pt Rounded UltraLight
        static let ringingTime = SwiftUI.Font.system(size: 96, weight: .ultraLight, design: .rounded)

        /// AM/PM 標籤 — 18pt Rounded Regular
        static let period = SwiftUI.Font.system(size: 18, weight: .regular, design: .rounded)

        /// 星期/標籤 小字全大寫 — 11pt Mono Semibold
        static let tag = SwiftUI.Font.system(size: 11, weight: .semibold, design: .monospaced)

        /// 導覽列標題 — 22pt Rounded Bold
        static let navTitle = SwiftUI.Font.system(size: 22, weight: .bold, design: .rounded)

        /// 一般內文
        static let body = SwiftUI.Font.system(size: 15, weight: .regular)

        /// 按鈕文字
        static let button = SwiftUI.Font.system(size: 16, weight: .semibold, design: .rounded)
    }

    // MARK: Spacing

    enum Spacing {
        static let cardPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 16
        static let sidePadding: CGFloat = 20
    }
}

// MARK: - Color Hex Extension

extension SwiftUI.Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - WeekdaySet English Display

extension WeekdaySet {
    var shortEnglishText: String {
        if self == .everyday { return "EVERY DAY" }
        if self == .weekdays { return "MON — FRI" }
        if self == .weekends { return "SAT — SUN" }
        if self.isEmpty { return "ONCE" }
        let syms = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
        return (0..<7)
            .compactMap { contains(WeekdaySet(rawValue: 1 << $0)) ? syms[$0] : nil }
            .joined(separator: " ")
    }
}
