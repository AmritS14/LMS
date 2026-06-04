import SwiftUI

// MARK: - Loan Policy Edit Sheet

struct LoanPolicyEditSheet: View {
    @State var policy: LoanPolicyConfig
    var onSave: (LoanPolicyConfig) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmation = false
    @State private var isSaving = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
                
                // MARK: Loan Type Header

                Section {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: typeIcon)
                            .font(.title2)
                            .foregroundStyle(typeColor)
                            .frame(width: 44, height: 44)
                            .background(typeColor.opacity(0.12),
                                         in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(policy.loanType.rawValue.capitalized + " Loan")
                                .font(.lmsTitle3)
                            Text("Policy Configuration")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // MARK: Interest Rate

                Section("Interest Rate") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        HStack {
                            Text("Minimum")
                            Spacer()
                            Text("\(String(format: "%.1f", policy.interestRateMin))%")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }
                        Slider(value: $policy.interestRateMin, in: 5...20, step: 0.5)
                            .tint(typeColor)
                    }

                    VStack(alignment: .leading, spacing: Spacing.s) {
                        HStack {
                            Text("Maximum")
                            Spacer()
                            Text("\(String(format: "%.1f", policy.interestRateMax))%")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }
                        Slider(value: $policy.interestRateMax, in: 5...25, step: 0.5)
                            .tint(typeColor)
                    }
                }

                // MARK: Loan Limits

                Section("Loan Limits") {
                    LabeledContent("Max Amount") {
                        Text(policy.maxAmountText)
                            .font(.subheadline.weight(.semibold))
                    }

                    Stepper("Max Tenure: \(policy.maxTenureText)",
                            value: $policy.maxTenureMonths,
                            in: 12...360, step: 12)
                }

                // MARK: Status

                Section {
                    Toggle(isOn: $policy.isActive) {
                        Label("Active", systemImage: policy.isActive ? "checkmark.circle.fill" : "xmark.circle")
                    }
                    .tint(typeColor)
                }
            }
            .navigationTitle("Edit Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) { Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.primary).padding(8).background(Color(uiColor: .systemGray5), in: Circle()) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            showConfirmation = true
                        }
                        .font(.headline)
                        .disabled(isSaving)
                    }
                }
            }
            .confirmationDialog("Save Changes", isPresented: $showConfirmation,
                                titleVisibility: .visible) {
                Button("Save Policy") {
                    Task {
                        isSaving = true
                        errorMessage = nil
                        do {
                            try await onSave(policy)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isSaving = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will update the \(policy.loanType.rawValue.capitalized) Loan policy. Changes take effect immediately.")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .disabled(isSaving)
    }

    // MARK: Helpers

    private var typeIcon: String {
        switch policy.loanType {
        case .home: "house"
        case .personal: "person"
        case .business: "building.2"
        case .vehicle: "car"
        case .education: "graduationcap"
        }
    }

    private var typeColor: Color {
        switch policy.loanType {
        case .home: .lmsAccent
        case .personal: .lmsInfo
        case .business: .lmsWarning
        case .vehicle: .lmsSuccess
        case .education: .lmsDanger
        }
    }
}

#Preview {
    Text("Preview")
        .sheet(isPresented: .constant(true)) {
            LoanPolicyEditSheet(
                policy: LoanPolicyConfig(
                    id: UUID(),
                    loanType: .home,
                    interestRateMin: 7.5, interestRateMax: 9.5,
                    maxTenureMonths: 360, maxAmount: 10_000_000,
                    minCreditScore: 700, maxDTIRatio: 0.50,
                    isActive: true
                ),
                onSave: { _ in }
            )
        }
}
