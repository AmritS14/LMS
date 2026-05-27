import SwiftUI

// MARK: - Reports Models
struct ReportItem: Identifiable, Hashable {
    let id = UUID()
    let branch: String
    let loanType: String
    let disbursedAmount: Decimal
    let averageTenure: Int
    let status: String
    let date: Date
}

struct MonthlyTrend: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double // in Lakhs
    let changePercent: Double
}

// MARK: - Reports Dashboard View
struct ReportsDashboardView: View {
    @State private var viewMode: ViewMode = .summary
    @State private var selectedBranch: String? = nil
    @State private var selectedType: String? = nil
    @State private var selectedStatus: String? = nil
    @State private var selectedDateRange: DateRangeOption = .all
    
    // States for simulations
    @State private var isLoading = false
    @State private var hasError = false
    @State private var isAccessRestricted = false
    
    // Export Flow States
    @State private var isExporting = false
    @State private var exportProgressText = ""
    @State private var showExportShareSheet = false
    @State private var exportURL: URL? = nil
    
    // Expanded Detailed Rows
    @State private var expandedRowIDs: Set<UUID> = []
    
    // Sample Data
    private let branches = ["Main", "North", "South", "West"]
    private let loanTypes = ["Personal", "Vehicle", "Home", "Education"]
    private let statuses = ["Disbursed", "Active", "Closed", "Defaulted"]
    
    private let monthlyTrends = [
        MonthlyTrend(month: "Jan", amount: 45.0, changePercent: -2.1),
        MonthlyTrend(month: "Feb", amount: 62.5, changePercent: 38.8),
        MonthlyTrend(month: "Mar", amount: 78.0, changePercent: 24.8),
        MonthlyTrend(month: "Apr", amount: 95.2, changePercent: 22.0),
        MonthlyTrend(month: "May", amount: 128.5, changePercent: 35.0)
    ]
    
    private let reportData = [
        ReportItem(branch: "Main", loanType: "Personal", disbursedAmount: 1200000, averageTenure: 12, status: "Disbursed", date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
        ReportItem(branch: "Main", loanType: "Vehicle", disbursedAmount: 2500000, averageTenure: 36, status: "Active", date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!),
        ReportItem(branch: "North", loanType: "Home", disbursedAmount: 8500000, averageTenure: 120, status: "Closed", date: Calendar.current.date(byAdding: .day, value: -12, to: Date())!),
        ReportItem(branch: "South", loanType: "Education", disbursedAmount: 1800000, averageTenure: 48, status: "Defaulted", date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!),
        ReportItem(branch: "West", loanType: "Vehicle", disbursedAmount: 3200000, averageTenure: 60, status: "Disbursed", date: Calendar.current.date(byAdding: .day, value: -25, to: Date())!),
        ReportItem(branch: "North", loanType: "Personal", disbursedAmount: 900000, averageTenure: 18, status: "Active", date: Calendar.current.date(byAdding: .day, value: -35, to: Date())!),
        ReportItem(branch: "South", loanType: "Home", disbursedAmount: 11000000, averageTenure: 180, status: "Active", date: Calendar.current.date(byAdding: .day, value: -45, to: Date())!)
    ]
    
    enum ViewMode: String, CaseIterable, Identifiable {
        case summary = "Summary"
        case detailed = "Detailed"
        var id: String { self.rawValue }
    }
    
    enum DateRangeOption: String, CaseIterable, Identifiable {
        case all = "All"
        case lastWeek = "Last 7 Days"
        case lastMonth = "Last 30 Days"
        var id: String { self.rawValue }
    }
    
    // MARK: - Computed Properties
    private var filteredData: [ReportItem] {
        reportData.filter { item in
            if let branch = selectedBranch, item.branch != branch { return false }
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
    
    private var totalDisbursed: Decimal {
        filteredData.reduce(0) { $0 + $1.disbursedAmount }
    }
    
    private var averageInterest: Double {
        // Return structured mock averages
        switch selectedType {
        case "Home": return 8.75
        case "Vehicle": return 10.50
        case "Education": return 9.25
        case "Personal": return 12.00
        default: return 10.12
        }
    }
    
    private var defaultRatio: Double {
        let total = filteredData.count
        if total == 0 { return 0 }
        let defaults = filteredData.filter { $0.status == "Defaulted" }.count
        return (Double(defaults) / Double(total)) * 100
    }
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            if isAccessRestricted {
                accessRestrictedView
            } else if hasError {
                errorStateView
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Demo controller toggles (helps review loading, error and restricted UI states)
                        demoControlBar
                        
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(ViewMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Filter Section (Applicable to both view modes but primarily detailed)
                        filterPanel
                        
                        if isLoading {
                            skeletonLoadingView
                        } else if filteredData.isEmpty {
                            emptyStateView
                        } else {
                            if viewMode == .summary {
                                summaryView
                            } else {
                                detailedView
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            
            if isExporting {
                exportProgressOverlay
            }
        }
        .navigationTitle("Reports")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { startExport(format: "PDF") }) {
                        Label("Export PDF", systemImage: "doc.plaintext")
                    }
                    
                    Button(action: { startExport(format: "Excel") }) {
                        Label("Export Excel", systemImage: "tablecells")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(isLoading || isAccessRestricted || hasError)
            }
        }
        .sheet(isPresented: $showExportShareSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    // MARK: - Dashboard Subviews
    
    private var summaryView: some View {
        VStack(spacing: 16) {
            // KPI Grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                kpiCard(title: "TOTAL DISBURSED", value: compactRupee(totalDisbursed), icon: "indianrupeesign.circle.fill", color: .blue, trend: "+8.4% MoM")
                kpiCard(title: "AVG INTEREST", value: String(format: "%.2f%%", averageInterest), icon: "percent", color: .orange, trend: "-0.25% MoM")
                kpiCard(title: "DEFAULT RATIO", value: String(format: "%.1f%%", defaultRatio), icon: "exclamationmark.octagon.fill", color: .red, trend: "-1.2% MoM")
                kpiCard(title: "ACTIVE APPS", value: "\(filteredData.count)", icon: "doc.text.fill", color: .green, trend: "+4 Apps")
            }
            .padding(.horizontal)
            
            // Trends Charts Visualization
            trendsCard
        }
    }
    
    private var detailedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(filteredData) { item in
                    let isExpanded = expandedRowIDs.contains(item.id)
                    VStack(spacing: 0) {
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                if isExpanded {
                                    expandedRowIDs.remove(item.id)
                                } else {
                                    expandedRowIDs.insert(item.id)
                                }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(item.branch) Branch • \(item.loanType)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Text(item.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(Formatting.currency(item.disbursedAmount))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                    statusBadge(item.status)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                                    .padding(.leading, 4)
                            }
                            .padding()
                        }
                        
                        if isExpanded {
                            Divider().padding(.horizontal)
                            VStack(spacing: 8) {
                                detailRow(label: "Average Loan Tenure", value: "\(item.averageTenure) Months")
                                detailRow(label: "Branch Division", value: "\(item.branch) Region")
                                detailRow(label: "Product Classification", value: "\(item.loanType) Credit")
                                detailRow(label: "Audit ID Hash", value: item.id.uuidString.prefix(8).uppercased())
                            }
                            .padding()
                            .background(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.5))
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var filterPanel: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Date picker chip
                    Menu {
                        ForEach(DateRangeOption.allCases) { opt in
                            Button(opt.rawValue) { selectedDateRange = opt }
                        }
                    } label: {
                        filterChip(title: "Date: \(selectedDateRange.rawValue)", isSelected: selectedDateRange != .all)
                    }
                    
                    // Branch chip
                    Menu {
                        Button("All Branches") { selectedBranch = nil }
                        ForEach(branches, id: \.self) { branch in
                            Button(branch) { selectedBranch = branch }
                        }
                    } label: {
                        filterChip(title: selectedBranch ?? "Branch", isSelected: selectedBranch != nil)
                    }
                    
                    // Loan Type chip
                    Menu {
                        Button("All Types") { selectedType = nil }
                        ForEach(loanTypes, id: \.self) { t in
                            Button(t) { selectedType = t }
                        }
                    } label: {
                        filterChip(title: selectedType ?? "Loan Type", isSelected: selectedType != nil)
                    }
                    
                    // Status chip
                    Menu {
                        Button("All Statuses") { selectedStatus = nil }
                        ForEach(statuses, id: \.self) { st in
                            Button(st) { selectedStatus = st }
                        }
                    } label: {
                        filterChip(title: selectedStatus ?? "Status", isSelected: selectedStatus != nil)
                    }
                }
                .padding(.horizontal)
            }
            
            // Clear Filters Button
            if selectedBranch != nil || selectedType != nil || selectedStatus != nil || selectedDateRange != .all {
                Button(action: resetFilters) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear Filters")
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
                }
                .padding(.horizontal)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func filterChip(title: String, isSelected: Bool) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            Image(systemName: "chevron.down")
                .font(.system(size: 8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.blue.opacity(0.12) : Color(uiColor: .secondarySystemGroupedBackground), in: Capsule())
        .overlay(Capsule().stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1))
        .foregroundStyle(isSelected ? .blue : .primary)
    }
    
    private func kpiCard(title: String, value: String, icon: String, color: Color, trend: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Spacer()
                Text(trend)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(trend.contains("-") ? .red : .green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var trendsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Disbursement Trends")
                        .font(.headline)
                    Text("Total volume in Lakhs (INR)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.green)
                    Text("+35% Max")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.1), in: Capsule())
            }
            
            // Visual chart representation using shape blocks (completely compiler safe)
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(monthlyTrends) { trend in
                    VStack(spacing: 8) {
                        Spacer()
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.gradient)
                            .frame(width: 24, height: CGFloat(trend.amount * 1.2))
                        
                        Text(trend.month)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 180)
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private func statusBadge(_ status: String) -> some View {
        let color: Color = switch status {
        case "Disbursed": .blue
        case "Active": .green
        case "Closed": .secondary
        case "Defaulted": .red
        default: .orange
        }
        
        return Text(status)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }
    
    private func detailRow(label: String, value: String) -> some View {
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
    
    // MARK: - Simulation Control Bar (Testing helper)
    private var demoControlBar: some View {
        HStack(spacing: 12) {
            Button {
                isLoading = true
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    isLoading = false
                }
            } label: {
                Label("Sim Loading", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .buttonStyle(.bordered)
            
            Button {
                hasError.toggle()
            } label: {
                Label(hasError ? "Clear Error" : "Sim Error", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .buttonStyle(.bordered)
            .tint(hasError ? .green : .red)
            
            Button {
                isAccessRestricted.toggle()
            } label: {
                Label(isAccessRestricted ? "Unlock" : "Lock Access", systemImage: isAccessRestricted ? "lock.open" : "lock")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
            .buttonStyle(.bordered)
            .tint(isAccessRestricted ? .green : .orange)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Simulation States views
    
    private var accessRestrictedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 72))
                .foregroundStyle(.red)
            Text("Access Restricted")
                .font(.title2)
                .fontWeight(.bold)
            Text("You do not have permissions to view institutional summaries.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Request Access") {
                // UI simulated only
            }
            .buttonStyle(.borderedProminent)
            
            Button("Reset State") {
                isAccessRestricted = false
            }
            .font(.caption)
            .padding(.top, 12)
            Spacer()
        }
    }
    
    private var errorStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            Text("Failed to Load Reports")
                .font(.title3)
                .fontWeight(.bold)
            Text("A network connection problem was detected. Please check your credentials and try again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Retry") {
                hasError = false
                isLoading = true
                Task {
                    try? await Task.sleep(for: .seconds(1.2))
                    isLoading = false
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .padding(.top, 36)
            Text("No Reports Available")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("No matching records found for active filters.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
    
    private var skeletonLoadingView: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(0..<4) { _ in
                    VStack(alignment: .leading, spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 32, height: 32)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 24)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 12)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal)
            
            VStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 160)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Export Process Overlay (HUD)
    private var exportProgressOverlay: some View {
        Color.black.opacity(0.4)
            .ignoresSafeArea()
            .overlay {
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(.white)
                    Text(exportProgressText)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(Color.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
            }
    }
    
    // MARK: - Helper Methods
    private func resetFilters() {
        withAnimation {
            selectedBranch = nil
            selectedType = nil
            selectedStatus = nil
            selectedDateRange = .all
        }
    }
    
    private func compactRupee(_ amount: Decimal) -> String {
        let d = amount as NSDecimalNumber
        let lakh = 100_000.0
        let crore = 10_000_000.0
        let val = d.doubleValue
        
        if val >= crore {
            return String(format: "₹%.2fCr", val / crore)
        } else if val >= lakh {
            return String(format: "₹%.1fL", val / lakh)
        } else {
            return Formatting.currency(amount)
        }
    }
    
    private func startExport(format: String) {
        isExporting = true
        exportProgressText = "Preparing Report..."
        
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run {
                exportProgressText = "Report Ready"
            }
            try? await Task.sleep(for: .seconds(0.6))
            
            // Create a fake report file locally
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "LMS_Institutional_Report_\(Int.random(in: 1000...9999)).\(format.lowercased() == "pdf" ? "pdf" : "xlsx")"
            let fileURL = tempDir.appendingPathComponent(fileName)
            try? "LMS Mock Report Content for \(format)".write(to: fileURL, atomically: true, encoding: .utf8)
            
            await MainActor.run {
                isExporting = false
                exportURL = fileURL
                showExportShareSheet = true
            }
        }
    }
}

// MARK: - UIActivityViewController Bridge for iOS Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ReportsDashboardView()
    }
}
