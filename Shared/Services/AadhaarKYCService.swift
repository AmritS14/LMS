import Foundation

protocol AadhaarKYCService: Sendable {
    func verify(zipData: Data, sharePhrase: String, applicationID: UUID?) async throws -> AadhaarVerificationReport
    func report(documentID: UUID) async throws -> AadhaarVerificationReport?
}
