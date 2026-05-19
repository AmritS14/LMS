import Foundation

public protocol PersistenceController: Sendable {
    func save<T: Codable & Sendable>(_ value: T, for key: String) async throws
    func load<T: Codable & Sendable>(_ type: T.Type, for key: String) async throws -> T?
    func delete(_ key: String) async throws
}
