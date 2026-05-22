import SwiftUI

struct NewLoanApplicationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = LoanApplicationViewModel()
    @State private var showDocSheet = false
    @State private var showConfirm = false

    @State private var calcRate: Double = 8.50
    @State private var calcLoanType: LoanType = .home

    private let products: [(type: LoanType, name: String, rate: Double, icon: String)] = [
        (.home,      "Home",      8.50, "house.fill"),
        (.personal,  "Personal", 10.50, "person.fill"),
        (.vehicle,   "Auto",      9.25, "car.fill"),
        (.business,  "Business", 11.00, "briefcase.fill"),
        (.education, "Education", 7.80, "book.closed.fill")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.ml) {
                productPicker
                sliderCard
                resultCard
                documentsCard
                submitButton
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .background(Color.lmsBackground.ignoresSafeArea())
        .navigationTitle("New Application")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showDocSheet) {
            NavigationStack {
                KYCView()
                    .navigationTitle("Upload Documents")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showDocSheet = false }
                        }
                    }
            }
            .presentationDetents([.large])
        }
        .alert("Application Submitted", isPresented: $showConfirm) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your \(calcLoanType.rawValue.capitalized) Loan for \(Formatting.currency(Decimal(viewModel.requestedAmount))) is under review.")
        }
    }

    // MARK: - Product Picker
    private var productPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(products, id: \.type) { p in
                    Button {
                        calcLoanType = p.type
                        calcRate = p.rate
                    } label: {
                        VStack(spacing: Spacing.s) {
                            ZStack {
                                Circle()
                                    .fill(calcLoanType == p.type ? Color.accentColor : Color.lmsFill)
                                    .frame(width: 52, height: 52)
                                Image(systemName: p.icon)
                                    .foregroundStyle(calcLoanType == p.type ? .white : .secondary)
                                    .font(.title3)
                            }
                            Text(p.name)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(calcLoanType == p.type ? .primary : .secondary)
                        }
                        .frame(width: 72)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Spacing.s)
            .padding(.horizontal, Spacing.xs)
        }
    }

    // MARK: - Sliders Card
    private var sliderCard: some View {
        VStack(spacing: Spacing.l) {
            sliderRow(
                label: "Principal Amount",
                value: Formatting.currency(Decimal(viewModel.requestedAmount)),
                slider: Slider(
                    value: $viewModel.requestedAmount,
                    in: 50_000...10_000_000, step: 50_000
                )
            )
            Divider()
            sliderRow(
                label: "Tenure",
                value: "\(viewModel.tenureMonths) months",
                slider: Slider(
                    value: Binding(
                        get: { Double(viewModel.tenureMonths) },
                        set: { viewModel.tenureMonths = Int($0) }
                    ),
                    in: 6...360, step: 6
                )
            )
            Divider()
            HStack {
                Text("Interest Rate").foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2f%% p.a.", calcRate))
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private func sliderRow(label: String, value: String, slider: some View) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text(label).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.subheadline.weight(.semibold))
            }
            slider.tint(.accentColor)
        }
    }

    // MARK: - Result Card
    private var resultCard: some View {
        let emiResult = EMICalculator.calculate(
            principal: Decimal(viewModel.requestedAmount),
            annualInterestRate: calcRate,
            tenureMonths: viewModel.tenureMonths,
            startDate: .now
        )

        return VStack(spacing: 0) {
            VStack(spacing: Spacing.xs) {
                Text("Monthly EMI")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text(Formatting.currency(emiResult.monthlyInstallment))
                    .font(.lmsHeroAmount)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
            .background(Color.accentColor)

            HStack {
                resultStat("Principal", Formatting.currency(Decimal(viewModel.requestedAmount)))
                Divider().frame(height: 36)
                resultStat("Interest", Formatting.currency(emiResult.totalInterest))
                Divider().frame(height: 36)
                resultStat("Total", Formatting.currency(emiResult.totalPayable))
            }
            .padding(.vertical, Spacing.sm)
            .background(Color.lmsSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private func resultStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(value).font(.footnote.weight(.semibold))
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Documents Card
    private var documentsCard: some View {
        Button {
            showDocSheet = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "arrow.up.doc.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Upload Documents")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("KYC & collateral papers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.m)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        PrimaryButton("Submit Application", isLoading: viewModel.isSubmitting) {
            Task {
                guard let env, let userID = session.currentUser?.id else { return }
                let success = await viewModel.submit(loanService: env.loans, borrowerID: userID)
                if success { showConfirm = true }
            }
        }
    }
}

#Preview {
    NavigationStack { NewLoanApplicationView() }
        .environment(SessionStore(
            currentUser: MockAuthService.seedBorrower,
            borrowerProfile: MockAuthService.seedBorrowerProfile
        ))
        .environment(\.appEnvironment, AppEnvironment(
            auth: MockAuthService(),
            loans: MockLoanService(),
            documents: MockDocumentService(),
            notifications: MockNotificationService(),
            messaging: MockMessagingService(),
            keychain: MockKeychainService()
        ))
}
