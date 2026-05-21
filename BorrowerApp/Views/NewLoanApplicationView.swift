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
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        productPicker
                        sliderCard
                        resultCard
                        documentsCard
                        submitButton
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
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
            HStack(spacing: 12) {
                ForEach(products, id: \.type) { p in
                    Button {
                        calcLoanType = p.type
                        calcRate = p.rate
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(calcLoanType == p.type ? Color.blue : Color(.systemFill))
                                    .frame(width: 48, height: 48)
                                Image(systemName: p.icon)
                                    .foregroundStyle(calcLoanType == p.type ? .white : .secondary)
                                    .font(.title3)
                            }
                            Text(p.name.replacingOccurrences(of: " Loan", with: ""))
                                .font(.caption).bold()
                                .foregroundStyle(calcLoanType == p.type ? .blue : .secondary)
                        }
                        .frame(width: 72)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Sliders Card
    var sliderCard: some View {
        VStack(spacing: 20) {
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
            .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    func sliderRow(label: String, value: String, slider: some View) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(label).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                Text(value).font(.subheadline).bold()
            }
            slider.tint(.blue)
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
            VStack(spacing: 4) {
                Text("Monthly EMI")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Text(Formatting.currency(emiResult.monthlyInstallment))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.blue)

            HStack {
                resultStat("Principal", Formatting.currency(Decimal(viewModel.requestedAmount)))
                Divider().frame(height: 40)
                resultStat("Interest", Formatting.currency(emiResult.totalInterest))
                Divider().frame(height: 40)
                resultStat("Total", Formatting.currency(emiResult.totalPayable))
            }
            .padding(.vertical, 14)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }

    func resultStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.footnote).bold()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Documents Card
    var documentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Documents").font(.headline)
                Spacer()
            }

            Button {
                showDocSheet = true
            } label: {
                HStack {
                    Image(systemName: "arrow.up.doc.fill").foregroundStyle(.blue)
                    Text("Upload KYC & Collateral Papers")
                        .foregroundStyle(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    // MARK: - Submit Button
    var submitButton: some View {
        Button {
            Task {
                guard let env = env, let userID = session.currentUser?.id else { return }
                let success = await viewModel.submit(loanService: env.loans, borrowerID: userID)
                if success {
                    showConfirm = true
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(viewModel.isSubmitting ? Color.blue.opacity(0.4) : Color.blue)
                    .frame(height: 52)
                if viewModel.isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Submit Application").font(.headline).foregroundStyle(.white)
                }
            }
        }
        .disabled(viewModel.isSubmitting)
    }
}
