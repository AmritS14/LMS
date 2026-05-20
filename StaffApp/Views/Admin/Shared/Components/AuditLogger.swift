//
//  AuditLogger.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import Foundation

// MARK: - Audit Logger

/// A simulated audit logging service to satisfy compliance requirements
/// across the Admin Module (US-39, US-40, US-41, US-43).
struct AuditLogger {
    /// Logs an admin action with a timestamp.
    /// In a real application, this would persist securely to a backend database.
    static func log(action: String, details: String = "") {
        let timestamp = Date().formatted(.iso8601)
        let logEntry = "[\(timestamp)] AUDIT: \(action)" + (details.isEmpty ? "" : " - \(details)")
        
        // Simulating secure storage by printing to console
        print(logEntry)
        
        // TODO: Persist to secure audit backend
    }
}
