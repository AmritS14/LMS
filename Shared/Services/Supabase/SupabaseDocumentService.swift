import Foundation
import Supabase

actor SupabaseDocumentService: DocumentService {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    // DB Models
    private struct DBLoanDocument: Decodable {
        let id: UUID
        let owner_id: UUID
        let kind: String
        let file_name: String
        let remote_url: String?
        let status: String
        let uploaded_at: Date
    }
    
    // Mappers
    private func mapKind(_ raw: String) -> DocumentKind {
        switch raw.lowercased() {
        case "identity_proof": return .identityProof
        case "address_proof": return .addressProof
        case "income_proof": return .incomeProof
        case "bank_statement": return .bankStatement
        case "collateral": return .collateral
        default: return .other
        }
    }
    
    private func mapDBKind(_ kind: DocumentKind) -> String {
        switch kind {
        case .identityProof: return "identity_proof"
        case .addressProof: return "address_proof"
        case .incomeProof: return "income_proof"
        case .bankStatement: return "bank_statement"
        case .collateral: return "collateral"
        case .other: return "other"
        }
    }
    
    private func mapStatus(_ raw: String) -> DocumentVerificationStatus {
        switch raw.lowercased() {
        case "verified": return .verified
        case "rejected": return .rejected
        default: return .pending
        }
    }
    
    private func mapDBStatus(_ status: DocumentVerificationStatus) -> String {
        switch status {
        case .pending: return "pending"
        case .verified: return "verified"
        case .rejected: return "rejected"
        }
    }
    
    private func toDomainDocument(_ dbDoc: DBLoanDocument) -> LoanDocument {
        var remoteURL: URL? = nil
        if let remoteStr = dbDoc.remote_url {
            remoteURL = URL(string: remoteStr)
        }
        
        return LoanDocument(
            id: dbDoc.id,
            ownerID: dbDoc.owner_id,
            kind: mapKind(dbDoc.kind),
            fileName: dbDoc.file_name,
            mimeType: "application/octet-stream", // Fallback, normally store in db
            remoteURL: remoteURL,
            status: mapStatus(dbDoc.status),
            uploadedAt: dbDoc.uploaded_at
        )
    }
    
    func upload(_ data: Data, fileName: String, mimeType: String, kind: DocumentKind, ownerID: UUID) async throws -> LoanDocument {
        let fileExt = (fileName as NSString).pathExtension
        let storagePath = "\(ownerID.uuidString)/\(UUID().uuidString).\(fileExt)"
        
        // Upload to Supabase Storage
        _ = try await client.storage
            .from("documents")
            .upload(
                path: storagePath,
                file: data,
                options: FileOptions(contentType: mimeType)
            )
            
        // Get public URL or authenticated URL
        let remoteURLString = try client.storage.from("documents").getPublicURL(path: storagePath).absoluteString
        
        // Insert metadata into loan_documents table
        let insertData: [String: AnyJSON] = [
            "owner_id": .string(ownerID.uuidString),
            "kind": .string(mapDBKind(kind)),
            "file_name": .string(fileName),
            "remote_url": .string(remoteURLString),
            "status": .string("pending")
        ]
        
        let response = try await client
            .from("loan_documents")
            .insert(insertData)
            .select()
            .single()
            .execute()
            
        let dbDoc = try SupabaseManager.shared.decoder.decode(DBLoanDocument.self, from: response.data)
        return toDomainDocument(dbDoc)
    }
    
    func list(ownerID: UUID) async throws -> [LoanDocument] {
        let response = try await client
            .from("loan_documents")
            .select()
            .eq("owner_id", value: ownerID)
            .order("uploaded_at", ascending: false)
            .execute()
            
        let dbDocs = try SupabaseManager.shared.decoder.decode([DBLoanDocument].self, from: response.data)
        return dbDocs.map(toDomainDocument)
    }
    
    func delete(documentID: UUID) async throws {
        // Find document first to get remote_url
        let response = try await client
            .from("loan_documents")
            .select()
            .eq("id", value: documentID)
            .single()
            .execute()
            
        let dbDoc = try SupabaseManager.shared.decoder.decode(DBLoanDocument.self, from: response.data)
        
        if let urlStr = dbDoc.remote_url, let url = URL(string: urlStr) {
            let path = url.lastPathComponent
            let ownerPrefix = dbDoc.owner_id.uuidString
            // Delete from storage
            _ = try? await client.storage.from("documents").remove(paths: ["\(ownerPrefix)/\(path)"])
        }
        
        // Delete from database
        _ = try await client
            .from("loan_documents")
            .delete()
            .eq("id", value: documentID)
            .execute()
    }
    
    func updateStatus(documentID: UUID, status: DocumentVerificationStatus) async throws {
        let updateData: [String: AnyJSON] = [
            "status": .string(mapDBStatus(status))
        ]
        
        _ = try await client
            .from("loan_documents")
            .update(updateData)
            .eq("id", value: documentID)
            .execute()
    }
}
