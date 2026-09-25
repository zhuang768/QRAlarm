import Foundation
import RevenueCat

enum RevenueCatConfiguration {
    static let isConfigured: Bool = {
#if DEBUG
        guard
            let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
            apiKey.hasPrefix("test_"),
            !apiKey.contains("REPLACE")
        else {
            return false
        }

#if DEBUG
        Purchases.logLevel = .debug
#endif
        Purchases.configure(withAPIKey: apiKey)
        return true
#else
        // Test Store keys must never configure a production/App Store build.
        return false
#endif
    }()
}

@MainActor
final class PurchaseManager: ObservableObject {
    static let proEntitlementID = "qralarm_pro"

    @Published private(set) var isPro = false
    @Published private(set) var currentPackage: Package?
    @Published private(set) var isWorking = false
    @Published private(set) var statusMessage: String?

    let isConfigured: Bool

    init(isConfigured: Bool) {
        self.isConfigured = isConfigured
        if !isConfigured {
            statusMessage = "Add your RevenueCat Test Store API key to run purchases."
        }
    }

    var priceText: String {
        currentPackage?.storeProduct.localizedPriceString ?? "TEST STORE"
    }

    func prepare() async {
        guard isConfigured else { return }
        await refreshCustomerInfo()
        await loadOffering()
    }

    func refreshCustomerInfo() async {
        guard isConfigured else { return }
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            apply(customerInfo)
        } catch {
            statusMessage = "Could not refresh access: \(error.localizedDescription)"
        }
    }

    func loadOffering() async {
        guard isConfigured else { return }
        do {
            let offerings = try await Purchases.shared.offerings()
            currentPackage = offerings.current?.monthly
                ?? offerings.current?.availablePackages.first
            if currentPackage == nil {
                statusMessage = "No package is available in the current Offering."
            }
        } catch {
            statusMessage = "Could not load the Test Store offering: \(error.localizedDescription)"
        }
    }

    func purchase() async {
        guard isConfigured else {
            statusMessage = "RevenueCat Test Store is not configured yet."
            return
        }
        guard let currentPackage else {
            await loadOffering()
            if self.currentPackage == nil { return }
            await purchase()
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            let result = try await Purchases.shared.purchase(package: currentPackage)
            if result.userCancelled {
                statusMessage = "Purchase cancelled — Pro remains locked."
            } else {
                apply(result.customerInfo)
                statusMessage = isPro
                    ? "QRAlarm Pro unlocked."
                    : "Purchase completed, but the qralarm_pro entitlement is not active."
            }
        } catch {
            statusMessage = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restore() async {
        guard isConfigured else {
            statusMessage = "RevenueCat Test Store is not configured yet."
            return
        }

        isWorking = true
        defer { isWorking = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            apply(customerInfo)
            statusMessage = isPro
                ? "Purchases restored — Pro is active."
                : "No active Pro purchase was found."
        } catch {
            statusMessage = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func apply(_ customerInfo: CustomerInfo) {
        isPro = customerInfo.entitlements.all[Self.proEntitlementID]?.isActive == true
    }
}
