import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE"
}

public struct APIRequest: Sendable {
    public var path: String
    public var method: HTTPMethod
    public var query: [String: String]
    public var headers: [String: String]
    public var body: Data?

    public init(
        path: String,
        method: HTTPMethod = .get,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.body = body
    }
}

public enum APIError: Error, Sendable {
    case invalidResponse
    case status(Int, Data?)
    case decoding(Error)
    case transport(Error)
    case unauthorized
}

public protocol APIClient: Sendable {
    func send<T: Decodable & Sendable>(_ request: APIRequest, as type: T.Type) async throws -> T
    func sendVoid(_ request: APIRequest) async throws
}
