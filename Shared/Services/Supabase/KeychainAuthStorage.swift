import Foundation
import Supabase

struct KeychainAuthStorage: AuthLocalStorage {
    let key = "supabase.auth.token"
    
    func store(key: String, value: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.key,
            kSecValueData as String: value
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func retrieve(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == noErr {
            return item as? Data
        }
        return nil
    }
    
    func remove(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
