import Foundation

public protocol NotificationService: Sendable {
    func registerDeviceToken(_ token: Data) async throws
    func requestAuthorization() async throws -> Bool
    func subscribe(to topic: NotificationTopic) async throws
    func unsubscribe(from topic: NotificationTopic) async throws
    func fetchHistory(limit: Int) async throws -> [PushNotification]
}
