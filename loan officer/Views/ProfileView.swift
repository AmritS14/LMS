import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    // Settings state
    @State private var enableNotifications = true
    @State private var enableBiometrics = false
    @State private var syncOnCellular = true
    
    // Collapsible branch section state
    @State private var isBranchExpanded = false
    
    // Interactive Signature Pad state
    @State private var currentLine = [CGPoint]()
    @State private var lines = [[CGPoint]]()
    @State private var isSignatureSaved = false
    
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
                
                // Premium Interactive Digital Signature Pad
                SignaturePadSection(
                    currentLine: $currentLine,
                    lines: $lines,
                    isSignatureSaved: $isSignatureSaved
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
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            AvatarView(
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
                    StatusBadge(text: viewModel.officerProfile.employeeId, color: .blue, size: .small)
                    StatusBadge(text: viewModel.selectedBranch, color: .green, size: .small)
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
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Performance Metrics",
                subtitle: "Updated in real-time"
            )
            .padding(.horizontal, 20)
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                // Total Approved
                MetricCard(
                    title: "Total Approved",
                    value: "\(viewModel.kpiData[1].value)",
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
                    value: "\(viewModel.kpiData[0].value)",
                    icon: "doc.plaintext.fill",
                    color: .orange,
                    subtitle: "Awaiting review"
                )
                
                // Disbursed Volume
                MetricCard(
                    title: "Disbursed Value",
                    value: "₹45.8 Cr",
                    icon: "indianrupeesign.circle.fill",
                    color: .purple,
                    subtitle: "FY 2025-26"
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
                        Text("Mumbai Central office information")
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
                    DetailRow(icon: "tag.fill", title: "Branch Code", value: "BR-MUM-01")
                    Divider().padding(.vertical, 8)
                    DetailRow(icon: "globe.asia.australia.fill", title: "Region", value: "Western India")
                    Divider().padding(.vertical, 8)
                    DetailRow(icon: "person.badge.key.fill", title: "Branch Manager", value: "Anil Deshmukh")
                    Divider().padding(.vertical, 8)
                    DetailRow(icon: "phone.fill", title: "Contact Desk", value: "+91 22 6678 9100")
                    Divider().padding(.vertical, 8)
                    DetailRow(icon: "mappin.and.ellipse", title: "Address", value: "BKC Capital Towers, G Block, Bandra East, Mumbai, 400051")
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
            SectionHeader(
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

// MARK: - Signature Pad Section
struct SignaturePadSection: View {
    @Binding var currentLine: [CGPoint]
    @Binding var lines: [[CGPoint]]
    @Binding var isSignatureSaved: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Digital Signature",
                subtitle: "Used to sign sanction letters"
            )
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                // Drawing Canvas
                ZStack {
                    Color(.systemBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.separator).opacity(0.4), lineWidth: 1)
                        )
                    
                    // Guide Line
                    Path { path in
                        path.move(to: CGPoint(x: 20, y: 110))
                        path.addLine(to: CGPoint(x: 320, y: 110))
                    }
                    .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [5]))
                    
                    // Existing lines
                    ForEach(0..<lines.count, id: \.self) { index in
                        DrawingLine(points: lines[index])
                            .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    
                    // Current drawing line
                    DrawingLine(points: currentLine)
                        .stroke(Color.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    if lines.isEmpty && currentLine.isEmpty {
                        Text("Sign here on the screen")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
                .frame(height: 150)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newPoint = value.location
                            // Limit drawing within canvas bounds
                            if newPoint.y >= 0 && newPoint.y <= 150 {
                                currentLine.append(newPoint)
                            }
                        }
                        .onEnded { _ in
                            if !currentLine.isEmpty {
                                lines.append(currentLine)
                                currentLine = []
                            }
                        }
                )
                
                // Controls
                HStack(spacing: 12) {
                    Button(action: {
                        lines.removeAll()
                        currentLine.removeAll()
                        isSignatureSaved = false
                    }) {
                        Label("Clear", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if !lines.isEmpty {
                            withAnimation {
                                isSignatureSaved = true
                            }
                        }
                    }) {
                        Label(isSignatureSaved ? "Signature Saved" : "Save Signature", systemImage: isSignatureSaved ? "checkmark" : "square.and.arrow.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(lines.isEmpty ? Color.gray : (isSignatureSaved ? Color.green : Color.blue))
                            .cornerRadius(10)
                    }
                    .disabled(lines.isEmpty)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(18)
            .padding(.horizontal, 20)
        }
    }
}

// Helper view to draw line path from points
struct DrawingLine: Shape {
    var points: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard let firstPoint = points.first else { return path }
        path.move(to: firstPoint)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}
