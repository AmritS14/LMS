import Foundation
import Security

/// A native implementation of KeychainService using Apple's Security framework.
/// This ensures session tokens and critical credentials are saved securely and survive app termination.
final class SecureKeychainService: KeychainService, @unchecked Sendable {
    private let serviceName = "com.antigravity.lms"

    func set(_ value: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: value
        ]

        // Delete any existing item first to avoid conflict errors
        SecItemDelete(query as CFDictionary)

        // Write the new item to the keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(
                domain: "KeychainService",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Failed to save item to keychain. SecStatus: \(status)"]
            )
        }
    }

    func get(_ key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var resultRef: AnyObject? = nil
        let status = SecItemCopyMatching(query as CFDictionary, &resultRef)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw NSError(
                domain: "KeychainService",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve item from keychain. SecStatus: \(status)"]
            )
        }

        return resultRef as? Data
    }

    func remove(_ key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(
                domain: "KeychainService",
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: "Failed to remove item from keychain. SecStatus: \(status)"]
            )
        }
    }
}
