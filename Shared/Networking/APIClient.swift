import Foundation

enum HTTPMethod: String, Sendable {
    case get = "GET", post = "POST", put = "PUT", patch = "PATCH", delete = "DELETE"
}

struct APIRequest: Sendable {
    var path: String
    var method: HTTPMethod
    var query: [String: String]
    var headers: [String: String]
    var body: Data?

    init(
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

enum APIError: Error, Sendable {
    case invalidResponse
    case status(Int, Data?)
    case decoding(Error)
    case transport(Error)
    case unauthorized
}

protocol APIClient: Sendable {
    func send<T: Decodable & Sendable>(_ request: APIRequest, as type: T.Type) async throws -> T
    func sendVoid(_ request: APIRequest) async throws
}
