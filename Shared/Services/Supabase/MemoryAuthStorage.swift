import Foundation
import Supabase

class MemoryAuthStorage: AuthStorage, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    
    func store(key: String, value: Data) throws { storage[key] = value }
    func retrieve(key: String) throws -> Data? { return storage[key] }
    func remove(key: String) throws { storage.removeValue(forKey: key) }
}
