import SwiftUI

struct DashboardView: View {
    @Environment(LoanOfficerStore.self) private var store
    @State private var expandedApplicationID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                header
                branchCard
                kpiGrid
                recentApplications
                recoveryShortcut
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.m)
        }
        .background(Color.lmsBackground)
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: OfficerRoute.notifications) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.title3)
                        if store.unreadNotificationCount > 0 {
                            CountBadge(count: store.unreadNotificationCount)
                                .offset(x: 8, y: -6)
                        }
                    }
                }
                .accessibilityLabel("Notifications")
            }
        }
        .task { await store.refreshAll() }
    }

    // MARK: Header
    private var header: some View {
        HStack(spacing: Spacing.sm) {
            AvatarView(initials: store.officerProfile.avatarInitials, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.greetingText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(store.officerProfile.name)
                    .font(.lmsTitle3)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
    }

    // MARK: Branch
    private var branchCard: some View {
        HStack(spacing: Spacing.s) {
            Image(systemName: "building.2.fill")
                .foregroundStyle(Color.lmsAccent)
            Text(store.officerProfile.branch)
                .font(.subheadline)
            Spacer()
            Text("EMP: \(store.officerProfile.employeeID)")
                .font(.lmsMono)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.m)
        .padding(.vertical, Spacing.sm)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    // MARK: KPI Grid
    private var kpiGrid: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Today", subtitle: "Performance overview",
                          icon: "chart.bar.fill")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.sm),
                                GridItem(.flexible(), spacing: Spacing.sm)],
                      spacing: Spacing.sm) {
                ForEach(store.kpiTiles) { kpi in
                    kpiTile(kpi)
                }
            }
        }
    }

    private func kpiTile(_ kpi: OfficerKPI) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Image(systemName: kpi.icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(kpi.tint)
                .frame(width: 36, height: 36)
                .background(kpi.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.small))
            Text(kpi.value)
                .font(.system(.title, design: .rounded).weight(.bold))
            Text(kpi.title)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2, reservesSpace: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    // MARK: Recent Applications
    private var recentApplications: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                SectionHeader(
                    title: "Recent Applications",
                    subtitle: "\(store.applications.count) total"
                )
                NavigationLink("View All", value: OfficerRoute.allApplications)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.lmsAccent)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(store.applications.prefix(3)) { app in
                    applicationCard(app)
                }
            }
        }
    }

    private func applicationCard(_ app: OfficerApplication) -> some View {
        let isExpanded = expandedApplicationID == app.id
        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                AvatarView(initials: app.borrowerInitials,
                           size: 44,
                           colors: app.riskLevel.gradient)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(app.borrowerName)
                            .font(.headline)
                        if app.fraudFlag {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundStyle(.red)
                                .font(.footnote)
                        }
                    }
                    Text("\(app.loanTypeLabel) • \(OfficerFormat.currency(app.loanAmount))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: Spacing.s) {
                StatusBadge(app.status.displayLabel, tone: app.status.tone,
                            icon: app.status.icon, size: .small)
                StatusBadge(app.riskLevel.rawValue, tone: app.riskLevel.tone,
                            icon: app.riskLevel.icon, size: .small)
            }

            if isExpanded {
                Divider()
                VStack(spacing: 0) {
                    DetailRow(icon: app.kycStatus.icon, title: "KYC",
                              value: app.kycStatus.displayLabel,
                              valueColor: tone(app.kycStatus.tone))
                    DetailRow(icon: "gauge.medium", title: "Eligibility",
                              value: "\(app.eligibilityScore)/100",
                              valueColor: eligibilityColor(app.eligibilityScore))
                    DetailRow(icon: "indianrupeesign.circle.fill", title: "EMI",
                              value: OfficerFormat.currency(app.emiAmount))
                    DetailRow(icon: "calendar", title: "Applied",
                              value: OfficerFormat.date(app.applicationDate))
                }

                NavigationLink(value: OfficerRoute.review(app.id)) {
                    Label("View Full Details", systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, Spacing.xs)
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                expandedApplicationID = isExpanded ? nil : app.id
            }
        }
    }

    // MARK: Recovery Shortcut
    private var recoveryShortcut: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Recovery",
                          subtitle: "Overdue accounts needing attention")
            NavigationLink(value: OfficerRoute.recovery) {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.lmsWarning)
                        .frame(width: 44, height: 44)
                        .background(Color.lmsWarning.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recovery Management")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(store.overdueBorrowers.count) overdue accounts")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(Spacing.m)
                .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
            }
            .buttonStyle(.plain)
        }
    }

    private func tone(_ tone: StatusBadge.Tone) -> Color {
        switch tone {
        case .neutral: .primary
        case .info: .lmsInfo
        case .success: .lmsSuccess
        case .warning: .lmsWarning
        case .danger: .lmsDanger
        }
    }

    private func eligibilityColor(_ score: Int) -> Color {
        if score >= 70 { return .lmsSuccess }
        if score >= 50 { return .lmsWarning }
        return .lmsDanger
    }
}

#Preview {
    DashboardView()
        .environment(LoanOfficerStore())
}
