import Foundation

enum OfficerFormat {
    static func timeAgo(_ date: Date) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: .now)
    }
}

struct OfficerSeedBorrower: Identifiable, Hashable {
    var id: UUID { user.id }

    let user: User
    let profile: BorrowerProfile
    let employer: String
    let existingLiabilities: Double
    let purpose: String
    let fraudFlag: Bool
}

struct OfficerApplication: Identifiable, Hashable {
    let application: LoanApplication
    let borrower: User
    let profile: BorrowerProfile
    let employer: String
    let existingLiabilities: Double
    let purpose: String
    let fraudFlag: Bool

    var id: UUID { application.id }
    var borrowerName: String { borrower.fullName }
    var borrowerInitials: String {
        borrower.fullName
            .split(separator: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }
    var loanType: LoanType { application.loanType }
    var loanTypeLabel: String { application.loanType.rawValue.capitalized + " Loan" }
    var status: ApplicationStatus { application.status }
    var employmentType: String { profile.employmentType?.rawValue.capitalized ?? "Not specified" }
    var riskLevel: RiskLevel {
        let score = creditScore
        switch score {
        case ..<600: return .critical
        case 600..<680: return .high
        case 680..<740: return .medium
        default: return .low
        }
    }
    var creditScore: Int { profile.creditScore ?? 720 }
    var loanAmount: Double { NSDecimalNumber(decimal: application.requestedAmount).doubleValue }
    var monthlyIncome: Double { NSDecimalNumber(decimal: profile.monthlyIncome ?? 0).doubleValue }
    var emiAmount: Double { loanAmount / Double(max(tenure, 1)) }
    var eligibilityScore: Int {
        let score = creditScore
        switch score {
        case ..<600: return 42
        case 600..<680: return 61
        case 680..<740: return 78
        default: return 91
        }
    }
    var debtToIncomeRatio: Double {
        let income = max(monthlyIncome, 1)
        return existingLiabilities / income
    }
    var tenure: Int { application.tenureMonths }
}

struct OfficerNotification: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let message: String
    let timestamp: Date
    let type: NotificationType
    let priority: Int
    var isRead: Bool
}

extension MockOfficerData {
    static let seedBorrowers: [OfficerSeedBorrower] = [
        OfficerSeedBorrower(
            user: User(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                fullName: "Priya Sharma",
                email: "priya.sharma@example.com",
                phone: "+91 98765 43210",
                role: .borrower
            ),
            profile: BorrowerProfile(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -32, to: .now)!,
                address: PostalAddress(
                    line1: "14 Lake View Road",
                    line2: nil,
                    city: "Mumbai",
                    state: "Maharashtra",
                    pinCode: 400001,
                    country: "India"
                ),
                panNumber: "ABCDE1234F",
                aadhaarLast4: "1122",
                employmentType: .salaried,
                monthlyIncome: 180_000,
                kycStatus: .verified,
                creditScore: 782
            ),
            employer: "Nexa Technologies",
            existingLiabilities: 240_000,
            purpose: "Home purchase",
            fraudFlag: false
        ),
        OfficerSeedBorrower(
            user: User(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                fullName: "Arjun Mehta",
                email: "arjun.mehta@example.com",
                phone: "+91 98765 43211",
                role: .borrower
            ),
            profile: BorrowerProfile(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -28, to: .now)!,
                address: PostalAddress(
                    line1: "88 Residency Street",
                    line2: "Apt 21",
                    city: "Pune",
                    state: "Maharashtra",
                    pinCode: 411001,
                    country: "India"
                ),
                panNumber: "ABCDE2234G",
                aadhaarLast4: "3344",
                employmentType: .selfEmployed,
                monthlyIncome: 95_000,
                kycStatus: .pending,
                creditScore: 668
            ),
            employer: "Mehta Trading Co.",
            existingLiabilities: 180_000,
            purpose: "Business expansion",
            fraudFlag: false
        ),
        OfficerSeedBorrower(
            user: User(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                fullName: "Anita Desai",
                email: "anita.desai@example.com",
                phone: "+91 98765 43212",
                role: .borrower
            ),
            profile: BorrowerProfile(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -24, to: .now)!,
                address: PostalAddress(
                    line1: "5 Park Avenue",
                    line2: nil,
                    city: "Bengaluru",
                    state: "Karnataka",
                    pinCode: 560001,
                    country: "India"
                ),
                panNumber: "ABCDE3234H",
                aadhaarLast4: "5566",
                employmentType: .business,
                monthlyIncome: 140_000,
                kycStatus: .rejected,
                creditScore: 612
            ),
            employer: "Desai Foods",
            existingLiabilities: 310_000,
            purpose: "Working capital",
            fraudFlag: true
        ),
        OfficerSeedBorrower(
            user: User(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                fullName: "Rahul Sharma",
                email: "rahul.sharma@example.com",
                phone: "+91 98765 43213",
                role: .borrower
            ),
            profile: BorrowerProfile(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -21, to: .now)!,
                address: PostalAddress(
                    line1: "21 River Bend",
                    line2: nil,
                    city: "Delhi",
                    state: "Delhi",
                    pinCode: 110001,
                    country: "India"
                ),
                panNumber: "ABCDE4234J",
                aadhaarLast4: "7788",
                employmentType: .salaried,
                monthlyIncome: 72_000,
                kycStatus: .pending,
                creditScore: 705
            ),
            employer: "Orbit Logistics",
            existingLiabilities: 160_000,
            purpose: "Education loan",
            fraudFlag: false
        )
    ]

    static func assignedApplications() -> [LoanApplication] {
        [
            LoanApplication(
                id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
                borrowerID: seedBorrowers[0].user.id,
                assignedOfficerID: officerUserID,
                loanType: .home,
                requestedAmount: 2_500_000,
                tenureMonths: 240,
                interestRate: 8.5,
                status: .disbursed,
                documentIDs: [],
                createdAt: Calendar.current.date(byAdding: .month, value: -4, to: .now)!,
                updatedAt: Calendar.current.date(byAdding: .month, value: -3, to: .now)!
            ),
            LoanApplication(
                id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
                borrowerID: seedBorrowers[1].user.id,
                assignedOfficerID: officerUserID,
                loanType: .personal,
                requestedAmount: 300_000,
                tenureMonths: 36,
                interestRate: 10.5,
                status: .underReview,
                documentIDs: [],
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: .now)!,
                updatedAt: .now
            ),
            LoanApplication(
                id: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd")!,
                borrowerID: seedBorrowers[2].user.id,
                assignedOfficerID: officerUserID,
                loanType: .business,
                requestedAmount: 1_200_000,
                tenureMonths: 60,
                interestRate: 12.0,
                status: .submitted,
                documentIDs: [],
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
                updatedAt: .now
            ),
            LoanApplication(
                id: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee")!,
                borrowerID: seedBorrowers[3].user.id,
                assignedOfficerID: officerUserID,
                loanType: .education,
                requestedAmount: 520_000,
                tenureMonths: 48,
                interestRate: 9.0,
                status: .escalated,
                documentIDs: [],
                createdAt: Calendar.current.date(byAdding: .day, value: -8, to: .now)!,
                updatedAt: .now
            )
        ]
    }
}
