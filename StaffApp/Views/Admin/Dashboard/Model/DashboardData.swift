//
//  DashboardData.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import Foundation
import SwiftUI

// MARK: - Distribution Stats Model

struct DistributionStats {
    let totalAmount: String
    let totalUser: Int
    let activeLoans: Int
    let applications: Int
}

// MARK: - Recent Application Model

struct RecentApplication: Identifiable {
    let id = UUID()
    let name: String
    let loanType: LoanType
    let amount: String
    let status: ApplicationStatus
    let date: String
    
    var statusColor: Color {
        switch status {
        case .approved, .disbursed, .recommended: return .green
        case .submitted, .underReview, .additionalInfoRequired: return .orange
        case .rejected, .closed: return .red
        case .draft: return .gray
        }
    }
}

// MARK: - Dashboard Snapshot

struct DashboardSnapshot {
    let stats: DistributionStats
    let recentApplications: [RecentApplication]
}

// MARK: - Sample Data

extension DashboardSnapshot {
    static let sample = DashboardSnapshot(
        stats: DistributionStats(
            totalAmount: "₹82.20 L",
            totalUser: 8,
            activeLoans: 6,
            applications: 6
        ),
        recentApplications: [
            RecentApplication(name: "Aarav Mehta", loanType: .home, amount: "₹45.00L", status: .approved, date: "19 May 2026"),
            RecentApplication(name: "Priya Sharma", loanType: .business, amount: "₹12.50L", status: .submitted, date: "15 May 2026"),
            RecentApplication(name: "Rohan Verma", loanType: .vehicle, amount: "₹8.20L", status: .approved, date: "12 May 2026"),
            RecentApplication(name: "Sneha Patel", loanType: .personal, amount: "₹5.00L", status: .approved, date: "10 May 2026"),
            RecentApplication(name: "Vikram Singh", loanType: .business, amount: "₹8.00L", status: .submitted, date: "8 May 2026"),
            RecentApplication(name: "Ananya Reddy", loanType: .personal, amount: "₹3.50L", status: .approved, date: "1 May 2026")
        ]
    )
}
