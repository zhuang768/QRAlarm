import Foundation
import UserNotifications

// MARK: - AlarmManagerService
// Local notifications keep QRAlarm functional on iOS 17 and later without
// requiring the iOS 26-only AlarmKit framework.

enum AlarmManagerError: Error {
    case notAuthorized
    case scheduleFailed
}

final class AlarmManagerService: NSObject, UNUserNotificationCenterDelegate {

    static let shared = AlarmManagerService()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let categoryIdentifier = "QRALARM_WAKE_UP"

    private override init() {
        super.init()
        notificationCenter.delegate = self
        notificationCenter.setNotificationCategories([
            UNNotificationCategory(
                identifier: categoryIdentifier,
                actions: [],
                intentIdentifiers: [],
                options: [.customDismissAction]
            )
        ])
    }

    private(set) var isAuthorized = false

    // MARK: - Authorization

    func requestAuthorization() async throws {
        let settings = await notificationCenter.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isAuthorized = true
        case .notDetermined:
            isAuthorized = try await notificationCenter.requestAuthorization(options: [.alert, .sound])
        case .denied:
            isAuthorized = false
            throw AlarmManagerError.notAuthorized
        @unknown default:
            isAuthorized = false
            throw AlarmManagerError.notAuthorized
        }

        guard isAuthorized else { throw AlarmManagerError.notAuthorized }
    }

    // MARK: - Schedule

    @discardableResult
    func schedule(_ item: AlarmItem) async throws -> UUID {
        guard isAuthorized else { throw AlarmManagerError.notAuthorized }

        await cancelPendingRequests(for: item.id)

        let content = UNMutableNotificationContent()
        content.title = item.label
        content.body = item.requiresQRCode
            ? "Open QRAlarm and scan a QR code to stop this alarm."
            : "Your alarm is ringing."
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = ["alarmID": item.id.uuidString]

        if item.repeatDays.isEmpty {
            let fireDate = item.nextFireDate()
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let request = UNNotificationRequest(
                identifier: requestIdentifier(for: item.id, suffix: "once"),
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            try await notificationCenter.add(request)
        } else {
            for weekday in item.repeatDays.alarmKitWeekdays {
                var components = DateComponents()
                components.weekday = weekday
                components.hour = item.hour
                components.minute = item.minute

                let request = UNNotificationRequest(
                    identifier: requestIdentifier(for: item.id, suffix: "weekday-\(weekday)"),
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                )
                try await notificationCenter.add(request)
            }
        }

        return item.id
    }

    func cancel(id: UUID) async throws {
        await cancelPendingRequests(for: id)
    }

    func stopRinging(id: UUID) async throws {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .alarmStopped,
                object: nil,
                userInfo: ["id": id]
            )
        }
    }

    func snooze(id: UUID, minutes: Int = 9) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Snoozed alarm"
        content.body = "Your QRAlarm is ringing again."
        content.sound = .default
        content.categoryIdentifier = categoryIdentifier
        content.userInfo = ["alarmID": id.uuidString]

        let request = UNNotificationRequest(
            identifier: requestIdentifier(for: id, suffix: "snooze"),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(max(minutes, 1) * 60),
                repeats: false
            )
        )
        try await notificationCenter.add(request)
        try await stopRinging(id: id)
    }

    // MARK: - Sync

    func syncAll(alarms: [AlarmItem]) async {
        for item in alarms {
            do {
                if item.isEnabled {
                    try await schedule(item)
                } else {
                    try await cancel(id: item.id)
                }
            } catch {
                print("[AlarmManagerService] sync error: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Notification handling

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        presentAlarm(from: notification.request.content.userInfo)
        return [.banner, .sound]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        presentAlarm(from: response.notification.request.content.userInfo)
    }

    private func presentAlarm(from userInfo: [AnyHashable: Any]) {
        guard
            let rawID = userInfo["alarmID"] as? String,
            let id = UUID(uuidString: rawID)
        else { return }

        Task { @MainActor in
            NotificationCenter.default.post(
                name: .alarmRinging,
                object: nil,
                userInfo: ["id": id]
            )
        }
    }

    private func requestIdentifier(for id: UUID, suffix: String) -> String {
        "qralarm.\(id.uuidString).\(suffix)"
    }

    private func cancelPendingRequests(for id: UUID) async {
        let prefix = "qralarm.\(id.uuidString)."
        let identifiers = await notificationCenter.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        notificationCenter.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let alarmStopped = Notification.Name("com.qralarm.alarmStopped")
    static let alarmRinging = Notification.Name("com.qralarm.alarmRinging")
}
