import Foundation

struct OfficerProfileSummary: Hashable {
    let name: String
    let employeeID: String
    let branch: String
    var avatarInitials: String {
        name.split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }
}

enum MockOfficerData {
    static let officerUserID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    static let officerProfile = OfficerProfileSummary(
        name: "Sarah Mehta",
        employeeID: "LO-2041",
        branch: "Bengaluru — MG Road"
    )
}
