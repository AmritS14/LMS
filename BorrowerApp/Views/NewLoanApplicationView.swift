import SwiftUI

struct NewLoanApplicationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss
    
    @State private var viewModel = LoanApplicationViewModel()
    @State private var showDocSheet = false
    @State private var showConfirm = false
    
    // Default rate based on type
    @State private var calcRate: Double = 8.50
    @State private var calcLoanType: LoanType = .home

    private let products: [(type: LoanType, name: String, rate: Double, icon: String)] = [
        (.home,      "Home Loan",       8.50, "house.fill"),
        (.personal,  "Personal Loan",  10.50, "person.fill"),
        (.vehicle,      "Auto Loan",       9.25, "car.fill"),
        (.business,  "Business Loan",  11.00, "briefcase.fill"),
        (.education, "Education Loan",  7.80, "book.closed.fill")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.lmsBackground.ignoresSafeArea()

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
            }
            .navigationTitle("EMI Calculator")
            .sheet(isPresented: $showDocSheet) {
                // In LMS we use KYCView to upload docs
                NavigationStack {
                    KYCView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") { showDocSheet = false }
                            }
                        }
                }
            }
            .alert("Application Submitted", isPresented: $showConfirm) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your \(calcLoanType.rawValue.capitalized) for \(Formatting.currency(Decimal(viewModel.requestedAmount))) is under review.")
            }
        }
    }

    // MARK: - Product Picker
    var productPicker: some View {
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
                                    .fill(calcLoanType == p.type ? Color.lmsAccent : Color.lmsFill)
                                    .frame(width: 48, height: 48)
                                Image(systemName: p.icon)
                                    .foregroundStyle(calcLoanType == p.type ? .white : .secondary)
                                    .font(.title3)
                            }
                            Text(p.name.replacingOccurrences(of: " Loan", with: ""))
                                .font(.lmsCaption).bold()
                                .foregroundStyle(calcLoanType == p.type ? Color.lmsAccent : .secondary)
                        }
                        .frame(width: 72)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, Spacing.s)
        }
    }

    // MARK: - Sliders Card
    var sliderCard: some View {
        SectionCard {
            VStack(spacing: Spacing.ml) {
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
                    Text(String(format: "%.2f%% p.a.", calcRate)).bold()
                }
                .font(.lmsSubheadline)
            }
        }
    }

    func sliderRow(label: String, value: String, slider: some View) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text(label).font(.lmsSubheadline).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.lmsSubheadline).bold()
            }
            slider.tint(Color.lmsAccent)
        }
    }

    // MARK: - Result Card
    var resultCard: some View {
        let emiResult = EMICalculator.calculate(
            principal: Decimal(viewModel.requestedAmount),
            annualInterestRate: calcRate,
            tenureMonths: viewModel.tenureMonths,
            startDate: .now
        )
        
        return VStack(spacing: 0) {
            VStack(spacing: Spacing.xs) {
                Text("Monthly EMI")
                    .font(.lmsSubheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Text(Formatting.currency(emiResult.monthlyInstallment))
                    .font(.lmsHeroAmount)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.l)
            .background(Color.lmsAccent)

            HStack {
                resultStat("Principal", Formatting.currency(Decimal(viewModel.requestedAmount)))
                Divider().frame(height: 40)
                resultStat("Interest", Formatting.currency(emiResult.totalInterest))
                Divider().frame(height: 40)
                resultStat("Total", Formatting.currency(emiResult.totalPayable))
            }
            .padding(.vertical, Spacing.sm)
            .background(Color.lmsSurface)
        }
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    func resultStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(value).font(.lmsFootnote).bold()
            Text(label).font(.lmsCaption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Documents Card
    var documentsCard: some View {
        SectionCard(title: "Documents") {
            Button {
                showDocSheet = true
            } label: {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "arrow.up.doc.fill").foregroundStyle(Color.lmsAccent)
                    Text("Upload KYC & Collateral Papers")
                        .foregroundStyle(Color.lmsAccent)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.sm)
                .background(Color.lmsAccent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
            }
        }
    }

    // MARK: - Submit Button
    var submitButton: some View {
        PrimaryButton("Submit Application", isLoading: viewModel.isSubmitting) {
            Task {
                guard let env = env, let userID = session.currentUser?.id else { return }
                let success = await viewModel.submit(loanService: env.loans, borrowerID: userID)
                if success {
                    showConfirm = true
                }
            }
        }
    }
}

#Preview {
    NewLoanApplicationView()
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
