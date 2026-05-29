import Foundation
import Supabase

actor SupabaseAadhaarKYCService: AadhaarKYCService {
    private let client: SupabaseClient
    private let apiBase = "http://localhost:3000"

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    func verify(zipData: Data, sharePhrase: String, applicationID: UUID?) async throws -> AadhaarVerificationReport {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        let url = URL(string: "\(apiBase)/kyc/aadhaar/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // sharePhrase field — never log this value
        appendField("sharePhrase", sharePhrase)

        if let appID = applicationID {
            appendField("applicationId", appID.uuidString)
        }

        // zip file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"zip\"; filename=\"aadhaar_offline_kyc.zip\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/zip\r\n\r\n".data(using: .utf8)!)
        body.append(zipData)
        body.append("\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        if let httpRes = httpResponse as? HTTPURLResponse, !(200...299).contains(httpRes.statusCode) {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "API", code: httpRes.statusCode, userInfo: [NSLocalizedDescriptionKey: parseErrorMessage(msg)])
        }

        return try SupabaseManager.shared.decoder.decode(AadhaarVerificationReport.self, from: data)
    }

    func report(documentID: UUID) async throws -> AadhaarVerificationReport? {
        guard let session = try? await client.auth.session else {
            throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])
        }

        let url = URL(string: "\(apiBase)/kyc/aadhaar/report/\(documentID.uuidString)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        guard let httpRes = httpResponse as? HTTPURLResponse else { return nil }
        if httpRes.statusCode == 404 { return nil }
        if !(200...299).contains(httpRes.statusCode) { return nil }

        return try? SupabaseManager.shared.decoder.decode(AadhaarVerificationReport.self, from: data)
    }

    private func parseErrorMessage(_ raw: String) -> String {
        if raw.contains("wrong_share_phrase") { return "Wrong share phrase. Please check the 4-character code from UIDAI." }
        if raw.contains("no_xml_in_zip") { return "No Aadhaar XML found in the zip. Please download the file again from UIDAI." }
        return raw
    }
}
