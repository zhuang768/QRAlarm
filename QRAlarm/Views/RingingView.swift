import SwiftUI

// MARK: - RingingView

struct RingingView: View {
    let alarm: AlarmItem
    let onDismiss: () -> Void

    @State private var isStopConfirming = false
    @State private var stopHoldProgress: CGFloat = 0.0
    @State private var stopHoldTimer: Timer?
    @State private var currentTime = Date()
    @State private var clockTimer: Timer?
    @State private var breathScale: CGFloat = 1.0
    @State private var showQRScanner = false
    @State private var scanMessage: String?

    private let holdDuration: TimeInterval = 2.0

    var body: some View {
        ZStack {
            // 純黑背景（不用漸層，遵守設計規範）
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                timeBlock
                Spacer()
                labelBlock
                Spacer(minLength: 48)
                actionButtons
                    .padding(.bottom, 52)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startClockTimer()
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                breathScale = 1.04
            }
        }
        .onDisappear {
            clockTimer?.invalidate()
            stopHoldTimer?.invalidate()
        }
        .fullScreenCover(isPresented: $showQRScanner) {
            qrScannerSheet
        }
    }

    // MARK: - Time Block

    private var timeBlock: some View {
        let hour = Calendar.current.component(.hour, from: currentTime)
        let minute = Calendar.current.component(.minute, from: currentTime)
        let h12: Int = { let h = hour % 12; return h == 0 ? 12 : h }()
        let period = hour < 12 ? "AM" : "PM"

        return VStack(spacing: 4) {
            Text(String(format: "%d:%02d", h12, minute))
                .font(DS.Font.ringingTime)
                .foregroundStyle(.white)
                .scaleEffect(breathScale)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: breathScale)

            Text(period)
                .font(DS.Font.tag)
                .foregroundStyle(.white.opacity(0.4))
                .tracking(4)
        }
    }

    // MARK: - Label

    private var labelBlock: some View {
        VStack(spacing: 8) {
            // 強調色細線
            Rectangle()
                .fill(DS.Color.accent)
                .frame(width: 24, height: 2)

            Text(alarm.label.uppercased())
                .font(DS.Font.tag)
                .foregroundStyle(.white.opacity(0.5))
                .tracking(3)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // QR Code 解鎖（若有設定）
            if alarm.requiresQRCode {
                Button {
                    showQRScanner = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 18))
                        Text("SCAN QR CODE TO UNLOCK")
                            .font(DS.Font.tag)
                            .tracking(1)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.Color.accent)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DS.Spacing.sidePadding)

                if let scanMessage {
                    Text(scanMessage)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(DS.Color.accent)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.sidePadding)
                }
            }

            HStack(spacing: 12) {
                // 貪睡
                Button { snoozeAlarm() } label: {
                    VStack(spacing: 6) {
                        Text("ZZ")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                        Text("SNOOZE")
                            .font(DS.Font.tag)
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(2)
                        Text("9 MIN")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // QR missions require the saved code. Standard alarms use hold-to-stop.
                if !alarm.requiresQRCode || !QRScannerView.isSupported {
                    ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )

                    if isStopConfirming {
                        // 進度條覆蓋（底部到頂部方向填滿）
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                Rectangle()
                                    .fill(DS.Color.accent.opacity(0.25))
                                    .frame(height: geo.size.height * stopHoldProgress)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .animation(.linear(duration: 0.05), value: stopHoldProgress)
                    }

                    VStack(spacing: 6) {
                        Image(systemName: isStopConfirming ? "stop.fill" : "stop")
                            .font(.system(size: 22))
                            .foregroundStyle(isStopConfirming ? DS.Color.accent : .white.opacity(0.7))
                        Text("STOP")
                            .font(DS.Font.tag)
                            .foregroundStyle(.white.opacity(0.4))
                            .tracking(2)
                        Text("HOLD 2S")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in if !isStopConfirming { startHoldTimer() } }
                            .onEnded { _ in cancelHoldTimer() }
                    )
                }
            }
            .padding(.horizontal, DS.Spacing.sidePadding)
        }
    }

    // MARK: - QR Scanner Sheet

    private var qrScannerSheet: some View {
        ZStack {
            Color(hex: "#0A0A0A").ignoresSafeArea()
            Group {
                if QRScannerView.isSupported {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Button("CANCEL") { showQRScanner = false }
                                .font(DS.Font.tag)
                                .foregroundStyle(DS.Color.secondary)
                                .tracking(1)
                                .padding()
                        }

                        QRScannerView(isScanning: $showQRScanner) { payload in
                            if payload == alarm.qrCodeContent {
                                scanMessage = nil
                                showQRScanner = false
                                stopAlarm()
                            } else {
                                scanMessage = "THAT ISN'T YOUR SAVED QR CODE — TRY AGAIN"
                                showQRScanner = true
                            }
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("CAMERA NOT AVAILABLE")
                            .font(DS.Font.tag)
                            .foregroundStyle(DS.Color.secondary)
                        Button {
                            showQRScanner = false
                        } label: {
                            Text("CLOSE")
                                .font(DS.Font.button)
                                .foregroundStyle(.white)
                                .frame(width: 160, height: 48)
                                .background(RoundedRectangle(cornerRadius: 4).fill(DS.Color.accent))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func startClockTimer() {
        currentTime = Date()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            currentTime = Date()
        }
    }

    private func snoozeAlarm() {
        Task {
            try? await AlarmManagerService.shared.snooze(id: alarm.id)
            onDismiss()
        }
    }

    private func startHoldTimer() {
        isStopConfirming = true
        stopHoldProgress = 0
        stopHoldTimer?.invalidate()
        let start = Date()
        stopHoldTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(start)
            DispatchQueue.main.async {
                stopHoldProgress = min(CGFloat(elapsed / holdDuration), 1.0)
                if elapsed >= holdDuration {
                    timer.invalidate()
                    stopAlarm()
                }
            }
        }
    }

    private func cancelHoldTimer() {
        stopHoldTimer?.invalidate()
        isStopConfirming = false
        stopHoldProgress = 0
    }

    private func stopAlarm() {
        Task {
            try? await AlarmManagerService.shared.stopRinging(id: alarm.id)
            onDismiss()
        }
    }
}
