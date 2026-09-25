import SwiftUI

// MARK: - AddAlarmView（完整設定表單）

enum AddAlarmMode {
    case add
    case edit(AlarmItem)
}

struct AddAlarmView: View {
    let mode: AddAlarmMode
    let onSave: (AlarmItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @State private var selectedTime: Date
    @State private var label: String
    @State private var repeatDays: WeekdaySet
    @State private var requiresQRCode: Bool
    @State private var qrCodeContent: String?
    @State private var showPaywall = false
    @State private var showQRSetupScanner = false

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    private var originalID: UUID? {
        if case .edit(let a) = mode { return a.id }
        return nil
    }
    private var originalIsEnabled: Bool {
        if case .edit(let alarm) = mode { return alarm.isEnabled }
        return true
    }

    private let daySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    private let dayFullNames = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    init(mode: AddAlarmMode, onSave: @escaping (AlarmItem) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            var c = Calendar.current.dateComponents([.hour, .minute], from: Date())
            let m = c.minute ?? 0
            c.minute = ((m / 5) + 1) * 5 % 60
            _selectedTime = State(initialValue: Calendar.current.date(from: c) ?? Date())
            _label = State(initialValue: "")
            _repeatDays = State(initialValue: [])
            _requiresQRCode = State(initialValue: false)
            _qrCodeContent = State(initialValue: nil)
        case .edit(let alarm):
            var c = DateComponents()
            c.hour = alarm.hour; c.minute = alarm.minute
            _selectedTime = State(initialValue: Calendar.current.date(from: c) ?? Date())
            _label = State(initialValue: alarm.label == "鬧鐘" ? "" : alarm.label)
            _repeatDays = State(initialValue: alarm.repeatDays)
            _requiresQRCode = State(initialValue: alarm.requiresQRCode)
            _qrCodeContent = State(initialValue: alarm.qrCodeContent)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        timePicker
                        settingsSection
                    }
                    .padding(.horizontal, DS.Spacing.sidePadding)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("CANCEL") { dismiss() }
                        .font(DS.Font.tag)
                        .foregroundStyle(DS.Color.secondary)
                        .tracking(1)
                }
                ToolbarItem(placement: .principal) {
                    Text(isEditing ? "EDIT" : "NEW ALARM")
                        .font(DS.Font.tag)
                        .foregroundStyle(DS.Color.primary)
                        .tracking(2)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("SAVE") { saveAlarm() }
                        .font(DS.Font.tag)
                        .foregroundStyle(DS.Color.accent)
                        .tracking(1)
                }
            }
            .sheet(isPresented: $showPaywall) {
                ProPaywallView()
            }
            .fullScreenCover(isPresented: $showQRSetupScanner) {
                qrSetupScanner
            }
        }
    }

    // MARK: Time Picker

    private var timePicker: some View {
        VStack(spacing: 0) {
            DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(DS.Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(DS.Color.cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            // 標籤
            settingsRow {
                HStack {
                    Text("LABEL")
                        .font(DS.Font.tag)
                        .foregroundStyle(DS.Color.secondary)
                        .tracking(1)
                    Spacer()
                    TextField("鬧鐘", text: $label)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(DS.Color.primary)
                        .font(DS.Font.body)
                }
            }

            rowDivider

            // 重複星期
            VStack(alignment: .leading, spacing: 14) {
                Text("REPEAT")
                    .font(DS.Font.tag)
                    .foregroundStyle(DS.Color.secondary)
                    .tracking(1)

                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        let bit = WeekdaySet(rawValue: 1 << i)
                        let isSelected = repeatDays.contains(bit)
                        Button {
                            if isSelected {
                                repeatDays.remove(bit)
                            } else {
                                repeatDays.insert(bit)
                            }
                        } label: {
                            Text(daySymbols[i])
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(isSelected ? .white : DS.Color.secondary)
                                .frame(width: 36, height: 36)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(isSelected ? DS.Color.accent : DS.Color.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(DS.Color.cardBorder, lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !repeatDays.isEmpty {
                    Text(repeatDays.shortEnglishText)
                        .font(DS.Font.tag)
                        .foregroundStyle(DS.Color.accent)
                        .tracking(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.Spacing.cardPadding)
            .padding(.vertical, 16)

            rowDivider

            // QR Code 開關
            settingsRow {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("QR CODE UNLOCK")
                            .font(DS.Font.tag)
                            .foregroundStyle(DS.Color.secondary)
                            .tracking(1)
                        if requiresQRCode {
                            Text(qrCodeContent == nil ? "SCAN A TARGET QR CODE" : "TARGET QR SAVED")
                                .font(.system(size: 11))
                                .foregroundStyle(DS.Color.accent)
                        } else if !purchaseManager.isPro {
                            Text("PRO FEATURE")
                                .font(.system(size: 11))
                                .foregroundStyle(DS.Color.accent)
                        }
                    }
                    Spacer()
                    DSToggle(isOn: requiresQRCode) {
                        if purchaseManager.isPro {
                            if requiresQRCode {
                                requiresQRCode = false
                                qrCodeContent = nil
                            } else {
                                showQRSetupScanner = true
                            }
                        } else {
                            showPaywall = true
                        }
                    }
                }
            }

            if requiresQRCode {
                rowDivider
                settingsRow {
                    Button("CHANGE TARGET QR CODE") {
                        showQRSetupScanner = true
                    }
                    .font(DS.Font.tag)
                    .foregroundStyle(DS.Color.accent)
                    .tracking(1)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(DS.Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(DS.Color.cardBorder, lineWidth: 1)
                )
        )
    }

    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, DS.Spacing.cardPadding)
            .padding(.vertical, 16)
    }

    private var rowDivider: some View {
        DS.Color.cardBorder
            .frame(height: 1)
            .padding(.horizontal, DS.Spacing.cardPadding)
    }

    private var qrSetupScanner: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()

            if QRScannerView.isSupported {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SAVE TARGET QR")
                                .font(DS.Font.tag)
                                .foregroundStyle(.white)
                                .tracking(2)
                            Text("Choose a code away from your bed.")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        Spacer()
                        Button("CANCEL") { showQRSetupScanner = false }
                            .font(DS.Font.tag)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding()

                    QRScannerView(isScanning: $showQRSetupScanner) { payload in
                        qrCodeContent = payload
                        requiresQRCode = true
                        showQRSetupScanner = false
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(DS.Color.accent)
                    Text("A camera-enabled iPhone is required to save a target QR code.")
                        .font(DS.Font.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Button("CLOSE") { showQRSetupScanner = false }
                        .font(DS.Font.button)
                        .foregroundStyle(.white)
                        .frame(width: 160, height: 48)
                        .background(RoundedRectangle(cornerRadius: 4).fill(DS.Color.accent))
                }
                .padding(32)
            }
        }
    }

    // MARK: Save

    private func saveAlarm() {
        let c = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
        let alarm = AlarmItem(
            id: originalID ?? UUID(),
            hour: c.hour ?? 7,
            minute: c.minute ?? 0,
            label: label.isEmpty ? "鬧鐘" : label,
            repeatDays: repeatDays,
            isEnabled: originalIsEnabled,
            requiresQRCode: requiresQRCode && qrCodeContent != nil,
            qrCodeContent: qrCodeContent
        )
        onSave(alarm)
        dismiss()
    }
}
