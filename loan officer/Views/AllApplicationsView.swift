//
//  AllApplicationsView.swift
//  loan officer
//
//  Created by Aadya Tiwari on 22/05/26.
//


//
//  AllApplicationsView.swift
//  loan officer
//
//  Created by Aadya Tiwari on 22/05/26.
//

import SwiftUI

struct AllApplicationsView: View {

    @EnvironmentObject var viewModel: AppViewModel

    @State private var searchText = ""
    @State private var selectedFilter: LoanStatus? = nil

    private var filteredApplications: [LoanApplication] {

        viewModel.filteredApplications.filter { application in

            let matchesSearch =
                searchText.isEmpty
                || application.borrowerName.localizedCaseInsensitiveContains(searchText)
                || application.loanType.localizedCaseInsensitiveContains(searchText)

            let matchesFilter =
                selectedFilter == nil
                || application.status == selectedFilter

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {

        ScrollView(.vertical, showsIndicators: false) {

            VStack(spacing: 20) {

                searchSection

                filterSection

                applicationsSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Applications")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Search Section

extension AllApplicationsView {

    private var searchSection: some View {

        HStack(spacing: 10) {

            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(
                "Search borrower or loan type",
                text: $searchText
            )
            .textInputAutocapitalization(.words)
            .disableAutocorrection(true)

            if !searchText.isEmpty {

                Button {

                    searchText = ""

                } label: {

                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Filter Section

extension AllApplicationsView {

    private var filterSection: some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 10) {

                filterChip(
                    title: "All",
                    isSelected: selectedFilter == nil
                ) {

                    selectedFilter = nil
                }

                ForEach(LoanStatus.allCases, id: \.self) { status in

                    filterChip(
                        title: status.rawValue,
                        isSelected: selectedFilter == status
                    ) {

                        selectedFilter = status
                    }
                }
            }
        }
    }

    private func filterChip(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {

        Button {
                action()

        } label: {

            Text(title)
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    isSelected
                    ? .white
                    : .primary
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            isSelected
                            ? Color.blue
                            : Color(.tertiarySystemGroupedBackground)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Applications Section

extension AllApplicationsView {
    
    private var applicationsSection: some View {
        
        VStack(spacing: 14) {
            
            if filteredApplications.isEmpty {
                
                emptyStateView
                
            } else {
                
                ForEach(filteredApplications) { application in
                    
                    Button {
                        
                        viewModel.selectedApplication = application
                        
                        viewModel.navigationPath.append(
                            AppDestination.loanReview
                        )
                        
                    } label: {
                        
                        applicationCard(application)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: Application Card
    
    private func applicationCard(
        _ application: LoanApplication
    ) -> some View {
        
        PremiumCard {
            
            VStack(alignment: .leading, spacing: 14) {
                
                HStack(alignment: .top, spacing: 12) {
                    
                    AvatarView(
                        initials: application.borrowerInitials,
                        size: 48,
                        colors:
                            application.riskLevel == .critical
                        ? [.red, .pink]
                        : [.blue, .cyan]
                    )
                    
                    
                    VStack(alignment: .leading, spacing: 4) {
                        
                        HStack(spacing: 6) {
                            
                            Text(application.borrowerName)
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .semibold
                                    )
                                )
                            
                            if application.fraudFlag {
                                
                                Image(systemName: "exclamationmark.shield.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        Text(application.loanType)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        
                        Text(
                            AppFormatters.formatCurrency(
                                application.loanAmount
                            )
                        )
                        .font(
                            .system(
                                size: 14,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                    }
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 6)
                    {
                        Image(systemName: "chevron.right")
                            .font(
                                .system(
                                    size: 12,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.tertiary)
                    }
                }
                HStack(spacing: 8) {
                    
                    StatusBadge(
                        text: application.status.rawValue,
                        color: application.status.color,
                        icon: application.status.icon,
                        size: .small
                    )
                    
//                    StatusBadge(
//                        text: application.riskLevel.rawValue,
//                        color: application.riskLevel.color,
//                        icon: application.riskLevel.icon,
//                        size: .small
//                    )
                    
                    Spacer()
                    
                }
    
            }
            
        }
    }
    
    // MARK: Empty State
    
    private var emptyStateView: some View {
        
        VStack(spacing: 14) {
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 4) {
                
                Text("No Applications Found")
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
                    )
                
                Text("Try changing your filters")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
}
// MARK: - Preview

#Preview {

    NavigationStack {

        AllApplicationsView()
            .environmentObject(AppViewModel())
    }
}
