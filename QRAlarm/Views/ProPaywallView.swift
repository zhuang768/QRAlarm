import SwiftUI

struct ProPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        hero
                        featureList
                        purchaseSection
                    }
                    .padding(DS.Spacing.sidePadding)
                }
            }
            .navigationTitle("QRALARM PRO")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("CLOSE") { dismiss() }
                        .font(DS.Font.tag)
                        .foregroundStyle(DS.Color.secondary)
                }
            }
        }
        .task { await purchaseManager.prepare() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: purchaseManager.isPro ? "checkmark.seal.fill" : "qrcode.viewfinder")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(DS.Color.accent)

            Text(purchaseManager.isPro ? "PRO IS ACTIVE" : "WAKE UP ON PURPOSE")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(DS.Color.primary)

            Text("Turn a QR code across the room into a wake-up mission. The alarm only stops after you get up and scan it.")
                .font(DS.Font.body)
                .foregroundStyle(DS.Color.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            featureRow(icon: "qrcode", title: "QR wake-up missions", detail: "Scan any QR code to dismiss")
            divider
            featureRow(icon: "play.circle", title: "Instant demo mode", detail: "Test the full wake-up flow anytime")
            divider
            featureRow(icon: "arrow.clockwise", title: "Subscription restore", detail: "Access follows your RevenueCat customer")
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(DS.Color.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(DS.Color.cardBorder, lineWidth: 1))
        )
    }

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let message = purchaseManager.statusMessage {
                Text(message)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(DS.Color.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 4).fill(DS.Color.cardBackground))
            }

            if purchaseManager.isPro {
                Button("CONTINUE WITH PRO") { dismiss() }
                    .buttonStyle(ProButtonStyle())
            } else {
                Button {
                    Task { await purchaseManager.purchase() }
                } label: {
                    HStack {
                        Text(purchaseManager.isWorking ? "WORKING…" : "UNLOCK PRO")
                        Spacer()
                        Text(purchaseManager.priceText)
                    }
                }
                .buttonStyle(ProButtonStyle())
                .disabled(purchaseManager.isWorking || !purchaseManager.isConfigured)
            }

            Button("RESTORE PURCHASES") {
                Task { await purchaseManager.restore() }
            }
            .font(DS.Font.tag)
            .foregroundStyle(DS.Color.secondary)
            .disabled(purchaseManager.isWorking || !purchaseManager.isConfigured)

            Text("Test Store purchases are simulated by RevenueCat and do not charge real money.")
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.disabled)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(DS.Color.accent)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(DS.Font.button)
                    .foregroundStyle(DS.Color.primary)
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    private var divider: some View {
        DS.Color.cardBorder.frame(height: 1).padding(.leading, 60)
    }
}

private struct ProButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DS.Font.button)
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(DS.Color.accent.opacity(configuration.isPressed ? 0.75 : 1))
            )
    }
}
