import Foundation

protocol DocumentService: Sendable {
    func upload(_ data: Data, fileName: String, mimeType: String, kind: DocumentKind, ownerID: UUID) async throws -> LoanDocument
    func list(ownerID: UUID) async throws -> [LoanDocument]
    /// Documents linked to a specific application (staff-facing review).
    func documents(forApplication applicationID: UUID) async throws -> [LoanDocument]
    func delete(documentID: UUID) async throws
    func updateStatus(documentID: UUID, status: DocumentVerificationStatus) async throws

    // Staff document review (routed through backend for audit trail)
    func signedURL(documentID: UUID) async throws -> URL
    func verifyDocument(documentID: UUID, remark: String?) async throws
    func rejectDocument(documentID: UUID, reason: String) async throws
}
