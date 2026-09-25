import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AlarmStore
    @EnvironmentObject private var purchaseManager: PurchaseManager

    var body: some View {
        AlarmListView()
            .task {
                await purchaseManager.prepare()
                do {
                    try await AlarmManagerService.shared.requestAuthorization()
                    await AlarmManagerService.shared.syncAll(alarms: store.alarms)
                } catch {
                    print("[ContentView] error: \(error)")
                }
            }
    }
}
