//
//  EmptyStateView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Reusable Empty State

/// A full-screen placeholder shown when a list or section has no data.
/// Uses ContentUnavailableView styling for HIG compliance.
struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(subtitle)
        }
    }
}

#Preview {
    EmptyStateView(
        title: "No Users Found",
        subtitle: "Try adjusting your search or add a new user.",
        systemImage: "person.slash"
    )
}
