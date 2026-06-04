import SwiftUI

struct ReportsDashboardView: View {
    var preselectedBorrowerName: String? = nil
    @State private var viewModel = ReportsViewModel()
    
    @State private var selectedType: String? = nil
    @State private var selectedStatus: String? = nil
    @State private var selectedDateRange: DateRangeOption = .all

    // Export Flow States
    @State private var isExporting = false
    @State private var exportURL: URL? = nil

    // Expanded Detailed Rows
    @State private var expandedRowIDs: Set<UUID> = []

    private let loanTypes = ["Personal", "Vehicle", "Home", "Education"]
    private let statuses = ["Active", "Closed", "Defaulted"]

    enum DateRangeOption: String, CaseIterable, Identifiable {
        case all = "All Dates"
        case lastWeek = "Last 7 Days"
        case lastMonth = "Last 30 Days"
        var id: String { self.rawValue }
    }

    // MARK: - Computed Properties
    private var filteredData: [ReportsViewModel.ReportItem] {
        viewModel.items.filter { item in
            if let preselected = preselectedBorrowerName, item.borrowerName != preselected { return false }
            if let type = selectedType, item.loanType != type { return false }
            if let status = selectedStatus, item.status != status { return false }

            let daysAgo = Calendar.current.dateComponents([.day], from: item.date, to: Date()).day ?? 0
            switch selectedDateRange {
            case .all: break
            case .lastWeek: if daysAgo > 7 { return false }
            case .lastMonth: if daysAgo > 30 { return false }
            }
            return true
        }
    }

    var body: some View {
        List {
            if viewModel.isAccessRestricted {
                ContentUnavailableView("Access Restricted", systemImage: "lock.shield", description: Text("You do not have permissions to view institutional reports. Admins only."))
            } else if viewModel.hasError {
                ContentUnavailableView("Failed to Load", systemImage: "exclamationmark.triangle", description: Text("A database or network error occurred. Please try again."))
            } else {
                if viewModel.isLoading {
                    Section {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                } else {
                    // Detailed Breakdown Section
                    if filteredData.isEmpty {
                        ContentUnavailableView("No Reports Found", systemImage: "doc.text.magnifyingglass", description: Text("No matching database records for the selected filters."))
                    } else {
                        Section {
                            ForEach(Array(filteredData.enumerated()), id: \.element.id) { index, item in
                                reportRow(for: item)
                            }
                        } header: {
                            Text("Detailed Breakdown (\(filteredData.count) Records)")
                                .font(.adminSectionHeader)
                                .foregroundStyle(Color.secondary)
                                .textCase(.uppercase)
                                .padding(.leading, 8)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadReportData()
        }
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Generating Export...")
                            .font(.headline)
                    }
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
        .toolbar {
            reportsToolbar
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var reportsToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                Section("Date Range") {
                    ForEach(DateRangeOption.allCases) { opt in
                        Button {
                            selectedDateRange = opt
                        } label: {
                            HStack {
                                Text(opt.rawValue)
                                if selectedDateRange == opt {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }



                Section("Type") {
                    Button {
                        selectedType = nil
                    } label: {
                        HStack {
                            Text("All Types")
                            if selectedType == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    ForEach(loanTypes, id: \.self) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack {
                                Text(type)
                                if selectedType == type {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section("Status") {
                    Button {
                        selectedStatus = nil
                    } label: {
                        HStack {
                            Text("All Statuses")
                            if selectedStatus == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    ForEach(statuses, id: \.self) { status in
                        Button {
                            selectedStatus = status
                        } label: {
                            HStack {
                                Text(status)
                                if selectedStatus == status {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Divider()
                Button(role: .destructive) {
                    resetFilters()
                } label: {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .symbolVariant((selectedType != nil || selectedStatus != nil || selectedDateRange != .all) ? .fill : .none)
            }
        }
    }

    // MARK: - Helpers

    private func expandedRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "Active": return .green
        case "Closed": return .gray
        case "Defaulted": return .red
        default: return .orange
        }
    }

    private func resetFilters() {
        withAnimation {
            selectedType = nil
            selectedStatus = nil
            selectedDateRange = .all
        }
    }
    
    @ViewBuilder
    private func reportRow(for item: ReportsViewModel.ReportItem) -> some View {
        let isExpanded = expandedRowIDs.contains(item.id)
        
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation {
                    if isExpanded {
                        expandedRowIDs.remove(item.id)
                    } else {
                        expandedRowIDs.insert(item.id)
                    }
                }
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.borrowerName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(item.branch) Branch • \(item.loanType)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(item.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(Formatting.currency(item.disbursedAmount))
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        
                        Text(item.status)
                            .font(.caption.bold())
                            .foregroundStyle(statusColor(item.status))
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 8) {
                    Divider().padding(.vertical, 4)
                    expandedRow(label: "Outstanding Principal", value: Formatting.currency(item.outstandingPrincipal))
                    expandedRow(label: "Avg Loan Tenure", value: "\(item.averageTenure) Months")
                    expandedRow(label: "Branch Division", value: "\(item.branch) Region")
                    expandedRow(label: "Product Type", value: "\(item.loanType) Credit")
                    expandedRow(label: "Audit ID", value: String(item.id.uuidString.prefix(8)).uppercased())
                }
                .padding(.leading, 12)
                .padding(.bottom, 4)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReportsDashboardView()
    }
}
