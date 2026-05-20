//
//  LoanProduct.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import Foundation

// MARK: - Loan Product Model

/// Represents a configurable loan product in the system.
/// Each product defines the constraints (amount range, rate, tenure)
/// that loan officers must follow when issuing loans of this type.
struct LoanProduct: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var minAmount: Double
    var maxAmount: Double
    var interestRate: Double
    var maxTenure: Int // in months

    init(
        id: UUID = UUID(),
        name: String,
        minAmount: Double,
        maxAmount: Double,
        interestRate: Double,
        maxTenure: Int
    ) {
        self.id = id
        self.name = name
        self.minAmount = minAmount
        self.maxAmount = maxAmount
        self.interestRate = interestRate
        self.maxTenure = maxTenure
    }
}

// MARK: - Loan Category

/// Groups loan products by category for organized display in the form.
enum LoanCategory: String, CaseIterable, Identifiable {
    case personal = "Personal Loans"
    case home = "Home Loans"
    case vehicle = "Vehicle Loans"
    case business = "Business Loans"

    var id: String { rawValue }

    /// SF Symbol icon for each loan category.
    var systemImage: String {
        switch self {
        case .personal: "person.fill"
        case .home: "house.fill"
        case .vehicle: "car.fill"
        case .business: "building.2.fill"
        }
    }
}

// MARK: - Sample Data

extension LoanProduct {
    /// Mock loan products organized by category for previews.
    static let sampleProducts: [LoanCategory: [LoanProduct]] = [
        .personal: [
            LoanProduct(
                name: "Personal Loan – Standard",
                minAmount: 50_000,
                maxAmount: 10_00_000,
                interestRate: 10.5,
                maxTenure: 60
            ),
            LoanProduct(
                name: "Personal Loan – Premium",
                minAmount: 1_00_000,
                maxAmount: 25_00_000,
                interestRate: 9.75,
                maxTenure: 84
            ),
        ],
        .home: [
            LoanProduct(
                name: "Home Loan – Fixed Rate",
                minAmount: 5_00_000,
                maxAmount: 1_00_00_000,
                interestRate: 8.5,
                maxTenure: 360
            ),
            LoanProduct(
                name: "Home Loan – Floating Rate",
                minAmount: 5_00_000,
                maxAmount: 1_50_00_000,
                interestRate: 8.25,
                maxTenure: 360
            ),
        ],
        .vehicle: [
            LoanProduct(
                name: "Car Loan",
                minAmount: 1_00_000,
                maxAmount: 50_00_000,
                interestRate: 9.0,
                maxTenure: 84
            ),
            LoanProduct(
                name: "Two-Wheeler Loan",
                minAmount: 20_000,
                maxAmount: 5_00_000,
                interestRate: 11.0,
                maxTenure: 48
            ),
        ],
        .business: [
            LoanProduct(
                name: "SME Business Loan",
                minAmount: 2_00_000,
                maxAmount: 50_00_000,
                interestRate: 12.0,
                maxTenure: 120
            ),
        ],
    ]
}
