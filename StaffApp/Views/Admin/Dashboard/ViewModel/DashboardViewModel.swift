//
//  DashboardViewModel.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI
import Observation

// MARK: - Dashboard ViewModel

/// Manages the state for the Admin Dashboard.
/// Loads a DashboardSnapshot and handles refresh operations.
@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - State

    /// The current dashboard data snapshot.
    var snapshot: DashboardSnapshot

    /// Whether a data refresh is in progress.
    var isRefreshing: Bool = false

    // MARK: - Initialization

    init(snapshot: DashboardSnapshot = .sample) {
        self.snapshot = snapshot
    }

    // MARK: - Actions

    /// Simulates refreshing dashboard data from backend.
    func refreshDashboard() async {
        isRefreshing = true
        defer { isRefreshing = false }

        // Simulate network delay
        try? await Task.sleep(for: .seconds(1.2))

        // Simply re-assign the sample or updated data
        snapshot = .sample
    }
}
