import SwiftUI

// MARK: - AlarmListView

struct AlarmListView: View {
    @EnvironmentObject private var store: AlarmStore
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var showAddAlarm = false
    @State private var showQuickAdd = false
    @State private var editingAlarm: AlarmItem? = nil
    @State private var ringingAlarm: AlarmItem? = nil
    @State private var addButtonPressed = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.background
                    .ignoresSafeArea()

                if store.alarms.isEmpty {
                    EmptyAlarmView()
                } else {
                    alarmList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
            }
            .sheet(isPresented: $showAddAlarm) {
                AddAlarmView(mode: .add) { scheduleAndAdd($0) }
            }
            .sheet(isPresented: $showQuickAdd) {
                QuickAddView { scheduleAndAdd($0) }
                    .presentationDetents([.height(340)])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $editingAlarm) { alarm in
                AddAlarmView(mode: .edit(alarm)) { scheduleAndUpdate($0) }
            }
            .fullScreenCover(item: $ringingAlarm) { alarm in
                RingingView(alarm: alarm) { ringingAlarm = nil }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .alarmRinging)) { note in
            guard let id = note.userInfo?["id"] as? UUID,
                  let item = store.alarms.first(where: { $0.id == id }) else { return }
            ringingAlarm = item
        }
        .onReceive(NotificationCenter.default.publisher(for: .alarmStopped)) { _ in
            ringingAlarm = nil
        }
    }

    // MARK: Alarm List

    private var alarmList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DS.Spacing.cardSpacing) {
                Spacer().frame(height: 8)
                if purchaseManager.isPro,
                   let mission = sortedAlarms.first(where: { $0.requiresQRCode }) {
                    Button {
                        ringingAlarm = mission
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("TEST QR WAKE-UP")
                            Spacer()
                            Text("PRO")
                        }
                        .font(DS.Font.tag)
                        .foregroundStyle(DS.Color.accent)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(DS.Color.cardBackground)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(DS.Color.accent.opacity(0.5)))
                        )
                    }
                    .buttonStyle(.plain)
                }
                ForEach(sortedAlarms) { alarm in
                    AlarmCard(alarm: alarm) {
                        editingAlarm = alarm
                    } onToggle: {
                        toggleAlarm(alarm)
                    } onDelete: {
                        deleteAlarm(alarm)
                    }
                }
                Spacer().frame(height: 32)
            }
            .padding(.horizontal, DS.Spacing.sidePadding)
        }
    }

    private var sortedAlarms: [AlarmItem] {
        store.alarms.sorted {
            if $0.hour != $1.hour { return $0.hour < $1.hour }
            return $0.minute < $1.minute
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Text("ALARM")
                .font(DS.Font.navTitle)
                .foregroundStyle(DS.Color.primary)
                .tracking(2)
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                showPaywall = true
            } label: {
                Text(purchaseManager.isPro ? "PRO ✓" : "GO PRO")
                    .font(DS.Font.tag)
                    .foregroundStyle(DS.Color.accent)
                    .tracking(1)
            }
            addButton
        }
    }

    private var addButton: some View {
        ZStack {
            // 短按 → 完整新增表單
            // 長按 → 快速設定彈出
            Circle()
                .fill(DS.Color.accent)
                .frame(width: 34, height: 34)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                )
                .scaleEffect(addButtonPressed ? 0.88 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: addButtonPressed)
        }
        .onTapGesture {
            showAddAlarm = true
        }
        .onLongPressGesture(minimumDuration: 0.4, pressing: { pressing in
            addButtonPressed = pressing
        }, perform: {
            showQuickAdd = true
        })
    }

    // MARK: Actions

    private func scheduleAndAdd(_ alarm: AlarmItem) {
        Task {
            _ = try? await AlarmManagerService.shared.schedule(alarm)
            store.add(alarm)
        }
    }

    private func scheduleAndUpdate(_ alarm: AlarmItem) {
        Task {
            try? await AlarmManagerService.shared.cancel(id: alarm.id)
            if alarm.isEnabled { _ = try? await AlarmManagerService.shared.schedule(alarm) }
            store.update(alarm)
        }
    }

    private func toggleAlarm(_ alarm: AlarmItem) {
        var updated = alarm
        updated.isEnabled.toggle()
        Task {
            if updated.isEnabled {
                _ = try? await AlarmManagerService.shared.schedule(updated)
            } else {
                try? await AlarmManagerService.shared.cancel(id: updated.id)
            }
            store.update(updated)
        }
    }

    private func deleteAlarm(_ alarm: AlarmItem) {
        Task {
            try? await AlarmManagerService.shared.cancel(id: alarm.id)
            store.delete(id: alarm.id)
        }
    }
}

// MARK: - AlarmCard

struct AlarmCard: View {
    let alarm: AlarmItem
    let onTap: () -> Void
    let onToggle: () -> Void
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showDeleteButton = false

    private let swipeThreshold: CGFloat = -60

    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button revealed on swipe
            if showDeleteButton {
                Button(action: onDelete) {
                    Text("DELETE")
                        .font(DS.Font.tag)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 92)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.red)
                        )
                }
                .transition(.move(edge: .trailing))
            }

            // Card
            cardContent
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 {
                                offset = max(value.translation.width, swipeThreshold * 1.5)
                            } else if showDeleteButton {
                                offset = min(0, value.translation.width - 60)
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if value.translation.width < swipeThreshold {
                                    offset = swipeThreshold
                                    showDeleteButton = true
                                } else {
                                    offset = 0
                                    showDeleteButton = false
                                }
                            }
                        }
                )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showDeleteButton)
    }

    private var cardContent: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    // 時間顯示
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(String(format: "%d:%02d", alarm.hour12, alarm.minute))
                            .font(DS.Font.alarmTime)
                            .foregroundStyle(alarm.isEnabled ? DS.Color.primary : DS.Color.disabled)

                        Text(alarm.displayPeriod)
                            .font(DS.Font.period)
                            .foregroundStyle(alarm.isEnabled ? DS.Color.secondary : DS.Color.disabled)
                    }

                    // 標籤行
                    HStack(spacing: 10) {
                        if alarm.label != "鬧鐘" && !alarm.label.isEmpty {
                            Text(alarm.label.uppercased())
                                .font(DS.Font.tag)
                                .foregroundStyle(alarm.isEnabled ? DS.Color.secondary : DS.Color.disabled)
                        }

                        Text(alarm.repeatDays.shortEnglishText)
                            .font(DS.Font.tag)
                            .foregroundStyle(alarm.isEnabled ? DS.Color.secondary : DS.Color.disabled)

                        if alarm.requiresQRCode {
                            Text("QR")
                                .font(DS.Font.tag)
                                .foregroundStyle(DS.Color.accent.opacity(alarm.isEnabled ? 1 : 0.4))
                        }
                    }
                }

                Spacer()

                // 開關（使用強調色）
                DSToggle(isOn: alarm.isEnabled) {
                    onToggle()
                }
            }
            .padding(.horizontal, DS.Spacing.cardPadding)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(DS.Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(DS.Color.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DSToggle（自訂開關，使用強調色）

struct DSToggle: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Capsule()
                .fill(isOn ? DS.Color.accent : DS.Color.cardBorder)
                .frame(width: 44, height: 26)
                .overlay(
                    Circle()
                        .fill(.white)
                        .frame(width: 20, height: 20)
                        .offset(x: isOn ? 9 : -9)
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isOn)
                )
                .overlay(
                    Capsule()
                        .stroke(DS.Color.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - EmptyAlarmView（Path 手繪時鐘）

struct EmptyAlarmView: View {
    var body: some View {
        VStack(spacing: 24) {
            HandDrawnClock()
                .stroke(DS.Color.secondary, lineWidth: 1.5)
                .frame(width: 72, height: 72)

            VStack(spacing: 6) {
                Text("NO ALARMS")
                    .font(DS.Font.tag)
                    .foregroundStyle(DS.Color.secondary)
                    .tracking(3)

                Text("還沒有任何鬧鐘")
                    .font(DS.Font.body)
                    .foregroundStyle(DS.Color.disabled)

                Text("長按右上角 + 快速新增")
                    .font(DS.Font.tag)
                    .foregroundStyle(DS.Color.accent)
                    .tracking(1)
                    .padding(.top, 4)
            }
        }
    }
}

// MARK: - HandDrawnClock（SwiftUI Path 手繪時鐘）

struct HandDrawnClock: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        // 外圓
        p.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius,
                                width: radius * 2, height: radius * 2))

        // 刻度（12、3、6、9點）
        for i in 0..<12 {
            let angle = CGFloat(i) * .pi / 6 - .pi / 2
            let outerR = radius * 0.88
            let innerR = radius * (i % 3 == 0 ? 0.72 : 0.80)
            p.move(to: CGPoint(x: center.x + outerR * cos(angle),
                               y: center.y + outerR * sin(angle)))
            p.addLine(to: CGPoint(x: center.x + innerR * cos(angle),
                                  y: center.y + innerR * sin(angle)))
        }

        // 時針（指向7:30）
        let hourAngle: CGFloat = (.pi * 2 * 7.5 / 12) - .pi / 2
        p.move(to: center)
        p.addLine(to: CGPoint(x: center.x + radius * 0.50 * cos(hourAngle),
                               y: center.y + radius * 0.50 * sin(hourAngle)))

        // 分針（指向7:30，即9點方向）
        let minAngle: CGFloat = (.pi * 2 * 30 / 60) - .pi / 2
        p.move(to: center)
        p.addLine(to: CGPoint(x: center.x + radius * 0.68 * cos(minAngle),
                               y: center.y + radius * 0.68 * sin(minAngle)))

        // 圓心點
        p.addEllipse(in: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5))

        // 鬧鐘小鈴（上方兩個半圓型的「耳朵」）
        let bellOffset = radius * 0.30
        p.addArc(center: CGPoint(x: center.x - bellOffset, y: center.y - radius + 2),
                 radius: 6, startAngle: .degrees(220), endAngle: .degrees(360), clockwise: false)
        p.addArc(center: CGPoint(x: center.x + bellOffset, y: center.y - radius + 2),
                 radius: 6, startAngle: .degrees(180), endAngle: .degrees(320), clockwise: false)

        return p
    }
}

// MARK: - QuickAddView（長按快速新增）

struct QuickAddView: View {
    let onSave: (AlarmItem) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTime: Date = {
        var comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        comps.minute = ((comps.minute ?? 0) / 5 + 1) * 5 % 60
        comps.hour = (comps.minute == 0 ? ((comps.hour ?? 0) + 1) : (comps.hour ?? 0)) % 24
        return Calendar.current.date(from: comps) ?? Date()
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("QUICK ADD")
                    .font(DS.Font.tag)
                    .foregroundStyle(DS.Color.secondary)
                    .tracking(3)
                Spacer()
                Button("取消") { dismiss() }
                    .font(DS.Font.body)
                    .foregroundStyle(DS.Color.secondary)
            }
            .padding(.horizontal, DS.Spacing.sidePadding)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // 時間滾輪
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: 160)

            // 確認按鈕
            Button {
                let comps = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                let alarm = AlarmItem(
                    hour: comps.hour ?? 7,
                    minute: comps.minute ?? 0,
                    label: "鬧鐘",
                    repeatDays: [],
                    isEnabled: true
                )
                onSave(alarm)
                dismiss()
            } label: {
                Text("設定鬧鐘")
                    .font(DS.Font.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.Color.accent)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DS.Spacing.sidePadding)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .background(DS.Color.background)
    }
}
