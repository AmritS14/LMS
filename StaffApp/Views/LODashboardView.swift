import SwiftUI

struct LODashboardView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.l) {
                    // KPI Widget Row
                    HStack(spacing: Spacing.m) {
                        KPIWidget(title: "Assigned", value: "12", icon: "tray.full", color: .lmsNavyBlue)
                        KPIWidget(title: "Pending", value: "5", icon: "clock", color: .lmsWarning)
                        KPIWidget(title: "Awaiting", value: "3", icon: "person.text.rectangle", color: .lmsPrimary)
                    }
                    .padding(.horizontal, Spacing.m)
                    
                    // Priority Queue
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("Priority Queue")
                            .font(.lmsTitle2)
                            .padding(.horizontal, Spacing.m)
                        
                        ForEach(0..<3, id: \.self) { _ in
                            NavigationLink {
                                LOApplicationDetailView()
                            } label: {
                                PriorityQueueCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, Spacing.m)
            }
            .navigationTitle("Dashboard")
            .background(Color.lmsSurface.ignoresSafeArea())
        }
    }
}

struct KPIWidget: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
            Text(title)
                .font(.lmsCaption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.lmsSurface)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct PriorityQueueCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Jane Doe")
                    .font(.lmsHeadline)
                Text("Home Loan • $350k")
                    .font(.lmsSubheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Spacing.xs) {
                StatusBadge("Review Needed", tone: .warning)
                Text("2 hrs ago")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.lmsSurface)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, Spacing.m)
    }
}

#Preview {
    LODashboardView()
}
