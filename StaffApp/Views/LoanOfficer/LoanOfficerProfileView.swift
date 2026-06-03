import SwiftUI

struct LoanOfficerProfileView: View {
    @Environment(AppViewModel.self) var viewModel
    
    // Settings state
    @State private var enableNotifications = true
    @State private var enableBiometrics = false
    @State private var syncOnCellular = true
    
    // Collapsible branch section state
    @State private var isBranchExpanded = false
    

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Header Profile Info
                ProfileHeaderView()
                
                // KPI Performance Grid
                PerformanceGridView()
                
                // Collapsible Branch details
                BranchDetailsSection(isExpanded: $isBranchExpanded)
                
                // App settings & Preferences
                SettingsSection(
                    enableNotifications: $enableNotifications,
                    enableBiometrics: $enableBiometrics,
                    syncOnCellular: $syncOnCellular
                )
                

                Spacer(minLength: 40)
            }
            .padding(.bottom, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Officer Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    @Environment(AppViewModel.self) var viewModel
    
    var body: some View {
        VStack(spacing: 16) {
            LOAvatarView(
                initials: viewModel.officerProfile.avatarInitials,
                size: 96,
                colors: [
                    Color(red: 0.1, green: 0.4, blue: 0.9),
                    Color(red: 0.3, green: 0.6, blue: 1.0)
                ]
            )
            .shadow(color: Color.blue.opacity(0.2), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 4) {
                Text(viewModel.officerProfile.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text(viewModel.officerProfile.designation)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    LOStatusBadge(text: viewModel.officerProfile.employeeId, color: .blue, size: .small)
                    LOStatusBadge(text: viewModel.selectedBranch, color: .green, size: .small)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Performance Grid View
struct PerformanceGridView: View {
    @Environment(AppViewModel.self) var viewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LOSectionHeader(
                title: "Performance Metrics",
                subtitle: "Updated in real-time"
            )
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                // Total Approved
                MetricCard(
                    title: "Total Approved",
                    value: "\(viewModel.kpiData.count > 1 ? viewModel.kpiData[1].value : 0)",
                    icon: "checkmark.seal.fill",
                    color: .green,
                    subtitle: "Applications approved"
                )
                
                // Approval Rate
                MetricCard(
                    title: "Approval Rate",
                    value: String(format: "%.1f%%", viewModel.officerProfile.approvalRate),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    subtitle: "Industry avg: 65%"
                )
                
                // Active Tasks
                MetricCard(
                    title: "Pending Cases",
                    value: "\(viewModel.kpiData.count > 0 ? viewModel.kpiData[0].value : 0)",
                    icon: "doc.plaintext.fill",
                    color: .orange,
                    subtitle: "Awaiting review"
                )
                
                // Disbursed Volume
                MetricCard(
                    title: "Disbursed Value",
                    value: viewModel.kpiData.count > 1 ? AppFormatters.formatCurrency(Double(viewModel.kpiData[1].value) * 100000) : "—",
                    icon: "indianrupeesign.circle.fill",
                    color: .purple,
                    subtitle: "Approved loans"
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.8))
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 0.5)
        )
    }
}

// MARK: - Branch Details Section
struct BranchDetailsSection: View {
    @Environment(AppViewModel.self) var viewModel
    @Binding var isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Branch Details")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(viewModel.selectedBranch.isEmpty ? "Branch not assigned" : viewModel.selectedBranch)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(18)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            
            if isExpanded {
                VStack(spacing: 0) {
                    LODetailRow(icon: "building.2.fill", title: "Branch", value: viewModel.selectedBranch.isEmpty ? "Not assigned" : viewModel.selectedBranch)
                    Divider().padding(.vertical, 8)
                    LODetailRow(icon: "person.fill", title: "Employee ID", value: viewModel.officerProfile.employeeId.isEmpty ? "—" : viewModel.officerProfile.employeeId)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(18)
                .padding(.horizontal, 20)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Settings Section
struct SettingsSection: View {
    @Binding var enableNotifications: Bool
    @Binding var enableBiometrics: Bool
    @Binding var syncOnCellular: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LOSectionHeader(
                title: "Preferences & Security",
                subtitle: "App settings"
            )
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                Toggle(isOn: $enableNotifications) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Real-time Alerts")
                                .font(.system(size: 15, weight: .medium))
                            Text("Notify on document upload & approvals")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(.orange)
                    }
                }
                
                Divider()
                
                Toggle(isOn: $enableBiometrics) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Biometric Security")
                                .font(.system(size: 15, weight: .medium))
                            Text("Use Face ID or Touch ID to authorize decisions")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "faceid")
                            .foregroundStyle(.blue)
                    }
                }
                
                Divider()
                
                Toggle(isOn: $syncOnCellular) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cellular Data Sync")
                                .font(.system(size: 15, weight: .medium))
                            Text("Sync records when off Wi-Fi networks")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(18)
            .padding(.horizontal, 20)
        }
    }
}

