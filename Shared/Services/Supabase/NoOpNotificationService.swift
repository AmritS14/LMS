import Foundation
import UserNotifications

/// Production notification service stub. APNs device registration and push
/// history are not yet backed by a server endpoint. Authorization is requested
/// from the OS so the system permission dialog works correctly.
actor NoOpNotificationService: NotificationService {

    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    func registerDeviceToken(_ token: Data) async throws { }
    func subscribe(to topic: NotificationTopic) async throws { }
    func unsubscribe(from topic: NotificationTopic) async throws { }
    func fetchHistory(limit: Int) async throws -> [PushNotification] { [] }
}
