import Foundation

public protocol DocumentService: Sendable {
    func upload(_ data: Data, fileName: String, mimeType: String, kind: DocumentKind, ownerID: UUID) async throws -> LoanDocument
    func list(ownerID: UUID) async throws -> [LoanDocument]
    func delete(documentID: UUID) async throws
    func updateStatus(documentID: UUID, status: DocumentVerificationStatus) async throws
}
