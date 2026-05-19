import Foundation

public protocol KeychainService: Sendable {
    func set(_ value: Data, for key: String) throws
    func get(_ key: String) throws -> Data?
    func remove(_ key: String) throws
}
