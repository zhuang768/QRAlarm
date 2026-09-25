import SwiftUI

@main
struct QRAlarmApp: App {
    @StateObject private var alarmStore = AlarmStore()
    @StateObject private var purchaseManager: PurchaseManager

    init() {
        _purchaseManager = StateObject(
            wrappedValue: PurchaseManager(isConfigured: RevenueCatConfiguration.isConfigured)
        )
        _ = AlarmManagerService.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmStore)
                .environmentObject(purchaseManager)
        }
    }
}
