import SwiftUI

// MARK: - Reusable Report UI Components

struct ReportSectionCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, Spacing.m)
                .padding(.top, Spacing.m)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.lmsSurface)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
            .padding(.horizontal, Spacing.m)
        }
    }
}

struct ReportDetailRow: View {
    let title: String
    let value: String
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .padding(Spacing.m)

            if !isLast {
                Divider()
                    .padding(.leading, Spacing.m)
            }
        }
    }
}

struct ReportKPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .padding(8)
                    .background(color.opacity(0.12), in: Circle())
                Spacer()
            }
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lmsSurface)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }
}

struct OverdueCustomerRow: View {
    let customer: OverdueCustomer
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(customer.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Text("\(customer.daysLate) Days Late")
                        .font(.caption)
                        .foregroundStyle(Color.lmsDanger)
                }
                Spacer()
                Text(Formatting.currency(customer.pendingAmount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(Spacing.m)

            if !isLast {
                Divider()
                    .padding(.leading, Spacing.m)
            }
        }
    }
}
