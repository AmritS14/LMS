//
//  SectionHeaderView.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import SwiftUI

// MARK: - Reusable Section Header

/// A consistent section header used in List/Form sections across
/// the Admin Module. Pairs an SF Symbol icon with a title string.
struct SectionHeaderView: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

#Preview {
    List {
        Section {
            Text("Row content")
        } header: {
            SectionHeaderView(title: "Personal Loans", systemImage: "banknote")
        }
    }
}
