import SwiftUI

public struct ManagerDashboardView: View {
    @State private var navigateToApps = false
    @State private var navigateToReview = false
    @State private var navigateToProfile = false
    @State private var navigateToNotifications = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: Spacing.l) {

                    // MARK: - Subtitle Row
                    subtitleRow

                    // MARK: - Section 1: Priority Actions
                    priorityActionsSection

                    // MARK: - Section 2: Today's Summary
                    todaySummarySection

                    // MARK: - Section 3: Primary CTA
                    PrimaryButton("Review Applications") {
                        navigateToApps = true
                    }
                    .padding(.horizontal, Spacing.m)

                    // MARK: - Section 4: Branch Performance
                    branchPerformanceSection

                    // MARK: - Section 5: Recent Actions
                    recentActionsSection

                    // MARK: - Section 6: Smart Insights
                    smartInsightsSection

                    Spacer().frame(height: Spacing.xxl)
                }
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.lmsSurface.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { navigateToNotifications = true }) {
                        Image(systemName: "bell")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.lmsText)
                    }
                    Button(action: { navigateToProfile = true }) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.lmsSecondaryText)
                    }
                }
            }
            .navigationDestination(isPresented: $navigateToApps) {
                ManagerApplicationsView()
            }
            .navigationDestination(isPresented: $navigateToReview) {
                ApplicationReviewView()
            }
            .sheet(isPresented: $navigateToProfile) {
                StaffProfileView()
            }
            .navigationDestination(isPresented: $navigateToNotifications) {
                LONotificationsView()
            }
        }
    }

    // MARK: - Subtitle Row

    private var subtitleRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(currentDateString)
                    .font(.lmsSubheadline)
                    .foregroundColor(.lmsSecondaryText)
                Text("Branch: Bangalore Branch")
                    .font(.lmsCaption)
                    .foregroundColor(.lmsSecondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: - Section 1: Priority Actions

    private var priorityActionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Applications")
                .font(.lmsTitle3)
                .foregroundColor(.lmsText)
                .padding(.horizontal, Spacing.m)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.m) {
                    priorityCard(
                        icon: "clock.badge.exclamationmark",
                        count: "23",
                        title: "Pending Review",
                        subtitle: "Needs attention",
                        accentColor: .lmsNavyBlue
                    ) {}

                    priorityCard(
                        icon: "arrow.uturn.backward.circle",
                        count: "5",
                        title: "Sent Back",
                        subtitle: "Awaiting correction",
                        accentColor: .lmsWarning
                    ) {}

                    priorityCard(
                        icon: "exclamationmark.triangle",
                        count: "3",
                        title: "High Risk",
                        subtitle: "Escalated",
                        accentColor: .lmsDanger
                    ) {}
                }
                .padding(.horizontal, Spacing.m)
            }
        }
    }

    // MARK: - Section 2: Today's Summary

    private var todaySummarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text("Today's Summary")
                .font(.lmsTitle3)
                .foregroundColor(.lmsText)
                .padding(.horizontal, Spacing.m)

            HStack(spacing: Spacing.m) {
                summaryCard(
                    count: "13",
                    title: "Approved Today",
                    trend: "↑ 3 vs yesterday",
                    trendColor: .lmsSuccess,
                    accentColor: .lmsSuccess
                ) { navigateToApps = true }

                summaryCard(
                    count: "2",
                    title: "Rejected Today",
                    trend: "Same as yesterday",
                    trendColor: .lmsSecondaryText,
                    accentColor: .lmsDanger
                ) { navigateToApps = true }
            }
            .padding(.horizontal, Spacing.m)
        }
    }

    // MARK: - Section 4: Branch Performance

    private var branchPerformanceSection: some View {
        SectionCard(title: "Branch Performance") {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: Spacing.m), GridItem(.flexible(), spacing: Spacing.m)], spacing: Spacing.m) {

                // Approval Rate
                metricCard(
                    title: "Approval Rate",
                    value: "84%",
                    indicator: { approvalRateBar }
                )

                // Avg Decision Time
                metricCard(
                    title: "Avg Decision Time",
                    value: "4.1h",
                    indicator: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 9, weight: .bold))
                            Text("14% faster")
                                .font(.lmsCaption2)
                        }
                        .foregroundColor(.lmsSuccess)
                    }
                )

            }
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: - Section 5: Recent Actions

    private var recentActionsSection: some View {
        SectionCard {
            VStack(spacing: 0) {
                // Header with View All
                HStack {
                    Text("Recent Actions")
                        .font(.lmsTitle3)
                        .foregroundColor(.lmsText)
                    Spacer()
                    Button(action: { navigateToApps = true }) {
                        Text("View All")
                            .font(.lmsSubheadline)
                            .foregroundColor(.lmsNavyBlue)
                            .padding(.vertical, Spacing.s)
                            .padding(.leading, Spacing.m)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.bottom, Spacing.m)

                VStack(spacing: Spacing.s) {
                    recentActionRow(
                        symbol: "checkmark.circle.fill",
                        action: "Approved",
                        name: "Sarah Jenkins",
                        amount: "₹4,50,000",
                        time: "Just now",
                        color: .lmsSuccess,
                        isLatest: true
                    ) { navigateToReview = true }

                    recentActionRow(
                        symbol: "checkmark.circle.fill",
                        action: "Approved",
                        name: "Jonathan Aris",
                        amount: "₹2,10,000",
                        time: "10:45 AM",
                        color: .lmsSuccess,
                        isLatest: false
                    ) { navigateToReview = true }

                    recentActionRow(
                        symbol: "xmark.circle.fill",
                        action: "Rejected",
                        name: "LN88432",
                        amount: "₹1,25,000",
                        time: "09:12 AM",
                        color: .lmsDanger,
                        isLatest: false
                    ) { navigateToReview = true }

                    recentActionRow(
                        symbol: "arrow.uturn.backward.circle.fill",
                        action: "Returned",
                        name: "LN88456",
                        amount: "₹5,00,000",
                        time: "Yesterday",
                        color: .lmsWarning,
                        isLatest: false
                    ) { navigateToReview = true }
                }
            }
        }
        .padding(.horizontal, Spacing.m)
    }

    // MARK: - Section 6: Smart Insights

    private var smartInsightsSection: some View {
        Button(action: { navigateToApps = true }) {
            HStack(spacing: Spacing.m) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.lmsWarning)
                    .frame(width: 40, height: 40)
                    .background(Color.lmsWarning.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Approval rate increased 2.5% this week")
                        .font(.lmsSubheadline)
                        .foregroundColor(.lmsText)
                    Text("3 applications need urgent review")
                        .font(.lmsCaption)
                        .foregroundColor(.lmsSecondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.lmsSecondaryText.opacity(0.5))
            }
            .padding(Spacing.m)
            .background(Color.lmsWarning.opacity(0.05))
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(Color.lmsWarning.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, Spacing.m)
    }

    // MARK: - Component: Priority Card

    private func priorityCard(icon: String, count: String, title: String, subtitle: String, accentColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                // Accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(height: 3)
                    .padding(.horizontal, -Spacing.m)
                    .padding(.top, -Spacing.m)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
                    .padding(.top, Spacing.xs)

                Text(count)
                    .font(.system(size: 32, weight: .bold, design: .default))
                    .foregroundColor(.lmsText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.lmsSubheadline)
                        .foregroundColor(.lmsText)
                    Text(subtitle)
                        .font(.lmsCaption)
                        .foregroundColor(.lmsSecondaryText)
                }
            }
            .padding(Spacing.m)
            .frame(width: 160)
            .background(Color.lmsCardBackground)
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(Color.gray.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Component: Summary Card

    private func summaryCard(count: String, title: String, trend: String, trendColor: Color, accentColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.s) {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .fill(accentColor)
                            .frame(width: 10, height: 10)
                    )

                Text(count)
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundColor(.lmsText)

                Text(title)
                    .font(.lmsSubheadline)
                    .foregroundColor(.lmsSecondaryText)

                Text(trend)
                    .font(.lmsCaption)
                    .foregroundColor(trendColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.m)
            .background(Color.lmsCardBackground)
            .cornerRadius(CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(Color.gray.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Component: Metric Card

    private func metricCard<Indicator: View>(title: String, value: String, @ViewBuilder indicator: () -> Indicator) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            Text(title)
                .font(.lmsCaption)
                .foregroundColor(.lmsSecondaryText)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.lmsText)

            indicator()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(Color.lmsSurface.opacity(0.6))
        .cornerRadius(CornerRadius.medium)
    }

    // MARK: - Component: Approval Rate Bar

    private var approvalRateBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.lmsNavyBlue.opacity(0.12))
                    .frame(height: 6)
                Capsule()
                    .fill(Color.lmsNavyBlue)
                    .frame(width: geometry.size.width * 0.84, height: 6)
            }
        }
        .frame(height: 6)
    }

    // MARK: - Component: Progress Ring

    private func progressRing(progress: Double, color: Color) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 24, height: 24)
    }

    // MARK: - Component: Recent Action Row

    private func recentActionRow(symbol: String, action: String, name: String, amount: String, time: String, color: Color, isLatest: Bool, tapAction: @escaping () -> Void) -> some View {
        Button(action: tapAction) {
            HStack(spacing: Spacing.m) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: Spacing.xs) {
                        Text(action)
                            .font(.lmsSubheadline)
                            .foregroundColor(color)
                        Text("·")
                            .foregroundColor(.lmsSecondaryText)
                        Text(name)
                            .font(.lmsSubheadline)
                            .foregroundColor(.lmsText)
                    }

                    HStack(spacing: Spacing.xs) {
                        Text(amount)
                            .font(.lmsCaption)
                            .foregroundColor(.lmsSecondaryText)
                        Text("·")
                            .foregroundColor(.lmsSecondaryText.opacity(0.5))
                        Text(time)
                            .font(.lmsCaption)
                            .foregroundColor(.lmsSecondaryText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.lmsSecondaryText.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.s)
            .padding(.vertical, Spacing.xs)
            .contentShape(Rectangle())
            .background(isLatest ? color.opacity(0.04) : Color.clear)
            .cornerRadius(CornerRadius.small)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Helpers

    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        let date = formatter.string(from: Date())
        return "Today, \(date)"
    }
}

// MARK: - Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

// MARK: - Previews

struct ManagerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ManagerDashboardView()
            .environment(SessionStore())
    }
}
