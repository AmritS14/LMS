//
//  DistributionDetailsView.swift
//  LMS(GU)
//
//  Created by Antigravity on 22/05/26.
//
//

import SwiftUI

struct DistributionDetailsView: View {
    @Bindable var viewModel: DashboardViewModel
    @Bindable var userVM: UserManagementViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Content removed based on requirement to move reports to User Profile
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Distribution Details")
        .navigationBarTitleDisplayMode(.inline)
    }




    // Row Helpers

    private func statRow(title: String, count: Int, systemImage: String) -> some View {
        HStack(spacing: Spacing.s) {
            Text(title)
                .font(.lmsSubheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.lmsHeadline)
                .foregroundStyle(.secondary)
        }
    }
}

