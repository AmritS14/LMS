import Foundation

// Officer-only seed data that the shared mock services don't yet model
// (employer, fraud flag, collateral, overdue accounts, generated docs).
// The store uses this alongside real LoanService / MessagingService
// responses to hydrate the officer screens.
enum MockOfficerData {
    static let officerUserID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

    static let officerProfile = OfficerProfileSummary(
        name: "Sarah Mehta",
        employeeID: "LO-2041",
        branch: "Bengaluru — MG Road"
    )

    // MARK: Borrowers used for assigned applications

    struct SeedBorrower {
        let user: User
        let profile: BorrowerProfile
        let employer: String
        let existingLiabilities: Decimal
        let purpose: String
        let fraudFlag: Bool
    }

    static let seedBorrowers: [SeedBorrower] = [
        SeedBorrower(
            user: User(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                fullName: "Naman Gupta",
                email: "naman@example.com",
                phone: "+91 98765 43210",
                role: .borrower
            ),
            profile: BorrowerProfile(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                dateOfBirth: date("1998-06-15"),
                address: PostalAddress(
                    line1: "42 MG Road", line2: "Sector 14",
                    city: "Gurugram", state: "Haryana",
                    pinCode: 122001, country: "India"
                ),
                panNumber: "ABCDE1234F",
                aadhaarLast4: "6789",
                employmentType: .salaried,
                monthlyIncome: 120_000,
                kycStatus: .verified,
                creditScore: 780
            ),
            employer: "Infosys Ltd.",
            existingLiabilities: 8_500,
            purpose: "Home renovation",
            fraudFlag: false
        ),
        SeedBorrower(
            user: User(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                fullName: "Priya Krishnan",
                email: "priya.k@example.com",
                phone: "+91 98123 45678",
                role: .borrower
            ),
            profile: BorrowerProfile(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                dateOfBirth: date("1992-03-22"),
                address: nil,
                panNumber: "PQRSX2233A",
                aadhaarLast4: "1234",
                employmentType: .salaried,
                monthlyIncome: 85_000,
                kycStatus: .verified,
                creditScore: 705
            ),
            employer: "TCS",
            existingLiabilities: 12_000,
            purpose: "Vehicle purchase",
            fraudFlag: false
        ),
        SeedBorrower(
            user: User(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                fullName: "Rahul Sharma",
                email: "rahul.s@example.com",
                phone: "+91 99887 12345",
                role: .borrower
            ),
            profile: BorrowerProfile(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                dateOfBirth: date("1988-11-05"),
                address: nil,
                panNumber: "ZXCVB5566Y",
                aadhaarLast4: "5544",
                employmentType: .selfEmployed,
                monthlyIncome: 145_000,
                kycStatus: .submitted,
                creditScore: 620
            ),
            employer: "Sharma Trading Co.",
            existingLiabilities: 35_000,
            purpose: "Business expansion",
            fraudFlag: false
        ),
        SeedBorrower(
            user: User(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                fullName: "Anita Desai",
                email: "anita.d@example.com",
                phone: "+91 97654 32109",
                role: .borrower
            ),
            profile: BorrowerProfile(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                dateOfBirth: date("2000-09-12"),
                address: nil,
                panNumber: "JKLMN1199Z",
                aadhaarLast4: "9921",
                employmentType: .salaried,
                monthlyIncome: 65_000,
                kycStatus: .pending,
                creditScore: 540
            ),
            employer: "Wipro",
            existingLiabilities: 22_000,
            purpose: "Higher education",
            fraudFlag: true
        ),
        SeedBorrower(
            user: User(
                id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
                fullName: "Vikram Iyer",
                email: "vikram@example.com",
                phone: "+91 90909 88776",
                role: .borrower
            ),
            profile: BorrowerProfile(
                id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
                dateOfBirth: date("1985-02-28"),
                address: nil,
                panNumber: "BNMQR4477X",
                aadhaarLast4: "7766",
                employmentType: .business,
                monthlyIncome: 220_000,
                kycStatus: .verified,
                creditScore: 815
            ),
            employer: "Iyer Consulting",
            existingLiabilities: 15_000,
            purpose: "Real estate investment",
            fraudFlag: false
        )
    ]

    // MARK: Applications assigned to the officer

    static func assignedApplications() -> [LoanApplication] {
        let officer = officerUserID
        let now = Date.now
        let calendar = Calendar.current

        return [
            LoanApplication(
                id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
                borrowerID: seedBorrowers[0].user.id,
                assignedOfficerID: officer,
                loanType: .personal,
                requestedAmount: 300_000,
                tenureMonths: 36,
                interestRate: 10.5,
                status: .underReview,
                createdAt: calendar.date(byAdding: .day, value: -5, to: now)!,
                updatedAt: now
            ),
            LoanApplication(
                id: UUID(),
                borrowerID: seedBorrowers[1].user.id,
                assignedOfficerID: officer,
                loanType: .vehicle,
                requestedAmount: 750_000,
                tenureMonths: 60,
                interestRate: 9.25,
                status: .submitted,
                createdAt: calendar.date(byAdding: .day, value: -2, to: now)!,
                updatedAt: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            LoanApplication(
                id: UUID(),
                borrowerID: seedBorrowers[2].user.id,
                assignedOfficerID: officer,
                loanType: .business,
                requestedAmount: 1_500_000,
                tenureMonths: 84,
                interestRate: 12.0,
                status: .escalated,
                createdAt: calendar.date(byAdding: .day, value: -9, to: now)!,
                updatedAt: calendar.date(byAdding: .day, value: -3, to: now)!
            ),
            LoanApplication(
                id: UUID(),
                borrowerID: seedBorrowers[3].user.id,
                assignedOfficerID: officer,
                loanType: .education,
                requestedAmount: 500_000,
                tenureMonths: 60,
                interestRate: 11.0,
                status: .underReview,
                createdAt: calendar.date(byAdding: .day, value: -12, to: now)!,
                updatedAt: calendar.date(byAdding: .day, value: -1, to: now)!
            ),
            LoanApplication(
                id: UUID(),
                borrowerID: seedBorrowers[4].user.id,
                assignedOfficerID: officer,
                loanType: .home,
                requestedAmount: 4_500_000,
                tenureMonths: 240,
                interestRate: 8.4,
                status: .recommended,
                createdAt: calendar.date(byAdding: .day, value: -20, to: now)!,
                updatedAt: calendar.date(byAdding: .day, value: -4, to: now)!
            )
        ]
    }

    // MARK: Documents shown in Loan Review

    static func reviewDocuments() -> [ReviewDocument] {
        let now = Date.now
        return [
            ReviewDocument(name: "PAN Card", type: "Identity Proof",
                           icon: "person.text.rectangle.fill",
                           status: .verified, ocrVerified: true,
                           uploadDate: Calendar.current.date(byAdding: .day, value: -8, to: now)),
            ReviewDocument(name: "Aadhaar Card", type: "Address Proof",
                           icon: "creditcard.fill",
                           status: .verified, ocrVerified: true,
                           uploadDate: Calendar.current.date(byAdding: .day, value: -8, to: now)),
            ReviewDocument(name: "Salary Slip — March", type: "Income Proof",
                           icon: "doc.text.fill",
                           status: .pending, ocrVerified: false,
                           uploadDate: Calendar.current.date(byAdding: .day, value: -2, to: now)),
            ReviewDocument(name: "Bank Statement (6 months)", type: "Financial",
                           icon: "building.columns.fill",
                           status: .duplicate, ocrVerified: true,
                           uploadDate: Calendar.current.date(byAdding: .day, value: -3, to: now)),
            ReviewDocument(name: "ITR FY 2024", type: "Income Proof",
                           icon: "doc.on.doc.fill",
                           status: .missing, ocrVerified: false,
                           uploadDate: nil)
        ]
    }

    static func collateral() -> LoanCollateral {
        let now = Date.now
        let cal = Calendar.current
        return LoanCollateral(
            propertyType: "Residential Apartment, 3BHK",
            address: "Plot 12, Whitefield, Bengaluru 560066",
            currentValuation: 6_200_000,
            lastValuationDate: cal.date(byAdding: .month, value: -2, to: now)!,
            revaluationHistory: [
                CollateralValuation(date: cal.date(byAdding: .year, value: -2, to: now)!, value: 5_400_000),
                CollateralValuation(date: cal.date(byAdding: .year, value: -1, to: now)!, value: 5_800_000),
                CollateralValuation(date: cal.date(byAdding: .month, value: -2, to: now)!, value: 6_200_000)
            ],
            coverageRatio: 1.65
        )
    }

    // MARK: Officer notifications feed

    static func notifications() -> [OfficerNotification] {
        let now = Date.now
        return [
            OfficerNotification(
                title: "Fraud signal on Anita Desai",
                message: "Document forensics flagged tampering on bank statement.",
                timestamp: now.addingTimeInterval(-60 * 18),
                type: .fraudAlert,
                priority: 1,
                isRead: false
            ),
            OfficerNotification(
                title: "3 applications awaiting review",
                message: "Personal loan recommendations are due before EOD today.",
                timestamp: now.addingTimeInterval(-60 * 45),
                type: .pendingApproval,
                priority: 1,
                isRead: false
            ),
            OfficerNotification(
                title: "New assignment — Vikram Iyer",
                message: "Home loan of ₹45,00,000 was routed to your queue.",
                timestamp: now.addingTimeInterval(-60 * 60 * 2),
                type: .assignedApplication,
                priority: 2,
                isRead: false
            ),
            OfficerNotification(
                title: "EMI overdue — Loan LN-1042",
                message: "DPD has crossed 30 days. Schedule a recovery call.",
                timestamp: now.addingTimeInterval(-60 * 60 * 5),
                type: .overdueReminder,
                priority: 1,
                isRead: true
            ),
            OfficerNotification(
                title: "Branch manager escalation",
                message: "Manager requested status update on Rahul Sharma's file.",
                timestamp: now.addingTimeInterval(-60 * 60 * 24),
                type: .escalation,
                priority: 2,
                isRead: true
            ),
            OfficerNotification(
                title: "System maintenance window",
                message: "Sanction letter PDF generation will be offline 02:00–02:30.",
                timestamp: now.addingTimeInterval(-60 * 60 * 36),
                type: .system,
                priority: 2,
                isRead: true
            )
        ]
    }

    // MARK: Generated documents

    static func generatedDocuments() -> [GeneratedDocument] {
        let now = Date.now
        let cal = Calendar.current
        return [
            GeneratedDocument(
                title: "Sanction Letter — Naman Gupta",
                category: .sanctionLetter,
                fileSize: "184 KB",
                generatedDate: cal.date(byAdding: .day, value: -1, to: now)!,
                isSigned: true,
                borrowerAcknowledged: true
            ),
            GeneratedDocument(
                title: "Sanction Letter — Vikram Iyer",
                category: .sanctionLetter,
                fileSize: "210 KB",
                generatedDate: cal.date(byAdding: .day, value: -4, to: now)!,
                isSigned: true,
                borrowerAcknowledged: false
            ),
            GeneratedDocument(
                title: "Branch Performance — April",
                category: .report,
                fileSize: "1.2 MB",
                generatedDate: cal.date(byAdding: .day, value: -10, to: now)!,
                isSigned: false,
                borrowerAcknowledged: false
            ),
            GeneratedDocument(
                title: "Risk Heatmap Report",
                category: .report,
                fileSize: "820 KB",
                generatedDate: cal.date(byAdding: .day, value: -7, to: now)!,
                isSigned: false,
                borrowerAcknowledged: false
            ),
            GeneratedDocument(
                title: "Credit Policy v3.2",
                category: .policy,
                fileSize: "340 KB",
                generatedDate: cal.date(byAdding: .month, value: -1, to: now)!,
                isSigned: false,
                borrowerAcknowledged: false
            ),
            GeneratedDocument(
                title: "KYC Verification Policy",
                category: .policy,
                fileSize: "256 KB",
                generatedDate: cal.date(byAdding: .month, value: -3, to: now)!,
                isSigned: false,
                borrowerAcknowledged: false
            )
        ]
    }

    // MARK: Overdue borrowers (recovery)

    static func overdueBorrowers() -> [OverdueBorrower] {
        [
            OverdueBorrower(
                id: UUID(),
                borrowerName: "Anita Desai",
                loanID: "LN-1042",
                phoneNumber: "+91 97654 32109",
                dpdDays: 47,
                outstandingEMI: 18_750,
                totalOutstanding: 412_500,
                priority: .urgent,
                collectionEfficiency: 38,
                contacted: false
            ),
            OverdueBorrower(
                id: UUID(),
                borrowerName: "Rahul Sharma",
                loanID: "LN-2188",
                phoneNumber: "+91 99887 12345",
                dpdDays: 28,
                outstandingEMI: 24_320,
                totalOutstanding: 286_400,
                priority: .high,
                collectionEfficiency: 55,
                contacted: false
            ),
            OverdueBorrower(
                id: UUID(),
                borrowerName: "Priya Krishnan",
                loanID: "LN-3301",
                phoneNumber: "+91 98123 45678",
                dpdDays: 12,
                outstandingEMI: 15_540,
                totalOutstanding: 78_200,
                priority: .normal,
                collectionEfficiency: 72,
                contacted: true
            ),
            OverdueBorrower(
                id: UUID(),
                borrowerName: "Karan Patel",
                loanID: "LN-4422",
                phoneNumber: "+91 91234 56789",
                dpdDays: 5,
                outstandingEMI: 9_800,
                totalOutstanding: 19_600,
                priority: .low,
                collectionEfficiency: 85,
                contacted: false
            )
        ]
    }

    // MARK: helpers

    private static func date(_ iso: String) -> Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: iso) ?? .now
    }
}
