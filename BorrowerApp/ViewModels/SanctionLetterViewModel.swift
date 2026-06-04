import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class SanctionLetterViewModel {
    var pdfURL: URL? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    func loadPDF(applicationID: UUID, customPath: String? = nil) async {
        isLoading = true
        errorMessage = nil
        pdfURL = nil

        let uuidUpper = applicationID.uuidString
        let uuidLower = applicationID.uuidString.lowercased()
        
        let buckets = ["loan_documents", "documents"]
        let paths: [String]
        if let customPath {
            paths = [customPath, "sanction_letters/\(uuidLower).pdf", "sanction_letters/\(uuidUpper).pdf"]
        } else {
            paths = [
                "sanction_letters/\(uuidLower).pdf",
                "sanction_letters/\(uuidUpper).pdf"
            ]
        }
        
        var success = false
        var lastError: Error? = nil
        
        for bucket in buckets {
            for path in paths {
                do {
                    print("Attempting to load sanction letter from bucket: \(bucket), path: \(path)")
                    
                    // 1. Try Supabase Storage signed URL (1-hour expiry)
                    let signedURL = try await SupabaseManager.shared.client.storage
                        .from(bucket)
                        .createSignedURL(path: path, expiresIn: 3600)
                    
                    // Download data
                    let (data, response) = try await URLSession.shared.data(from: signedURL)
                    if let httpRes = response as? HTTPURLResponse, (200...299).contains(httpRes.statusCode) {
                        let tempDirectory = FileManager.default.temporaryDirectory
                        let tempFileURL = tempDirectory.appendingPathComponent("\(applicationID.uuidString.lowercased()).pdf")
                        try data.write(to: tempFileURL, options: .atomic)
                        self.pdfURL = tempFileURL
                        success = true
                        break
                    } else {
                        throw NSError(domain: "SanctionLetter", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid status code during download"])
                    }
                } catch {
                    print("Signed URL method failed for \(bucket)/\(path): \(error). Trying direct download...")
                    
                    // 2. Fallback: Download data directly from Supabase Storage using current session credentials
                    do {
                        let data = try await SupabaseManager.shared.client.storage
                            .from(bucket)
                            .download(path: path)
                        
                        let tempDirectory = FileManager.default.temporaryDirectory
                        let tempFileURL = tempDirectory.appendingPathComponent("\(applicationID.uuidString.lowercased()).pdf")
                        try data.write(to: tempFileURL, options: .atomic)
                        self.pdfURL = tempFileURL
                        success = true
                        break
                    } catch {
                        lastError = error
                    }
                }
            }
            if success { break }
        }
        
        if !success {
            self.errorMessage = "Failed to load sanction letter: \(lastError?.localizedDescription ?? "Object not found")"
        }
        
        isLoading = false
    }
}
