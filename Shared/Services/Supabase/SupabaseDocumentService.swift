import Foundation
import Supabase

actor SupabaseDocumentService: DocumentService {
    private let client: SupabaseClient
    private let apiBase = "https://arshitsinghal-lms-backend.hf.space"
    
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
        let uploaded_at: Date?
        let created_at: Date?
    }
    
    // Mappers
    private func mapKind(_ raw: String) -> DocumentKind {
        switch raw.lowercased() {
        case "identityproof", "identity_proof": return .identityProof
        case "addressproof", "address_proof": return .addressProof
        case "incomeproof", "income_proof": return .incomeProof
        case "bankstatement", "bank_statement": return .bankStatement
        case "collateral": return .collateral
        default: return .other
        }
    }
    
    private func mapDBKind(_ kind: DocumentKind) -> String {
        // Use camelCase to match backend DTO enum values
        switch kind {
        case .identityProof: return "identityProof"
        case .addressProof: return "addressProof"
        case .incomeProof: return "incomeProof"
        case .bankStatement: return "bankStatement"
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
            mimeType: "application/octet-stream",
            remoteURL: remoteURL,
            status: mapStatus(dbDoc.status),
            uploadedAt: dbDoc.uploaded_at ?? dbDoc.created_at ?? .now
        )
    }
    
    func upload(_ data: Data, fileName: String, mimeType: String, kind: DocumentKind, ownerID: UUID) async throws -> LoanDocument {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to upload documents"])
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        let url = URL(string: "\(apiBase)/documents/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var bodyData = Data()
        
        // Add 'kind' field
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"kind\"\r\n\r\n".data(using: .utf8)!)
        bodyData.append("\(mapDBKind(kind))\r\n".data(using: .utf8)!)
        
        // Add 'file' field
        bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
        bodyData.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        bodyData.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        bodyData.append(data)
        bodyData.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = bodyData
        
        let (responseData, httpResponse) = try await URLSession.shared.data(for: request)
        
        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let errorStr = String(data: responseData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: "Upload failed: \(errorStr)"])
        }
        
        let dbDoc = try SupabaseManager.shared.decoder.decode(DBLoanDocument.self, from: responseData)
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

    func documents(forApplication applicationID: UUID) async throws -> [LoanDocument] {
        // Join the application⇄document link table to the documents themselves.
        // RLS lets the assigned officer / managing manager read these rows.
        struct LinkRow: Decodable { let loan_documents: DBLoanDocument? }
        let response = try await client
            .from("loan_application_documents")
            .select("loan_documents(*)")
            .eq("application_id", value: applicationID)
            .execute()

        let rows = try SupabaseManager.shared.decoder.decode([LinkRow].self, from: response.data)
        return rows.compactMap { $0.loan_documents }.map(toDomainDocument)
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
            _ = try? await client.storage.from("loan_documents").remove(paths: ["\(ownerPrefix)/\(path)"])
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

    // MARK: - Staff document review (via backend)

    func signedURL(documentID: UUID) async throws -> URL {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let url = URL(string: "\(apiBase)/documents/\(documentID.uuidString)/url")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: errorStr])
        }

        struct SignedURLResponse: Decodable {
            let signedUrl: String?
            let signedURL: String?
        }
        let decoded = try JSONDecoder().decode(SignedURLResponse.self, from: data)
        guard let urlStr = decoded.signedUrl ?? decoded.signedURL, let signed = URL(string: urlStr) else {
            throw NSError(domain: "API", code: 500, userInfo: [NSLocalizedDescriptionKey: "Missing signed URL in response"])
        }
        return signed
    }

    func verifyDocument(documentID: UUID, remark: String?) async throws {
        var body: [String: Any]? = nil
        if let remark { body = ["remark": remark] }
        try await postDocumentAction(documentID: documentID, action: "verify", body: body)
    }

    func rejectDocument(documentID: UUID, reason: String) async throws {
        try await postDocumentAction(documentID: documentID, action: "reject", body: ["reason": reason])
    }

    private func postDocumentAction(documentID: UUID, action: String, body: [String: Any]?) async throws {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let url = URL(string: "\(apiBase)/documents/\(documentID.uuidString)/\(action)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body ?? [:])

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let errorStr = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(action) failed: \(errorStr)"])
        }
    }
}
