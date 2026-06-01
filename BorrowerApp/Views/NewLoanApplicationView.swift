import SwiftUI

struct NewLoanApplicationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = LoanApplicationViewModel()
    @State private var showDocSheet = false
    @State private var showConfirm = false
    @FocusState private var amountFocused: Bool

    @State private var calcRate: Double = 8.50
    @State private var calcLoanType: LoanType = .home
    @State private var amountText: String = "2500000"

    private let products: [(type: LoanType, name: String, rate: Double, icon: String)] = [
        (.home,      "Home",      8.50, "house.fill"),
        (.personal,  "Personal", 10.50, "person.fill"),
        (.vehicle,   "Auto",      9.25, "car.fill"),
        (.business,  "Business", 11.00, "briefcase.fill"),
        (.education, "Education", 7.80, "book.closed.fill")
    ]

    private var amountPresets: [Double] {
        switch calcLoanType {
        case .home:      return [1_500_000, 2_500_000, 5_000_000, 7_500_000]
        case .personal:  return [100_000, 300_000, 500_000, 1_000_000]
        case .vehicle:   return [400_000, 600_000, 1_000_000, 1_500_000]
        case .business:  return [500_000, 1_000_000, 2_500_000, 5_000_000]
        case .education: return [200_000, 500_000, 1_000_000, 2_000_000]
        }
    }

    private var tenurePresets: [Int] {
        switch calcLoanType {
        case .home:      return [120, 180, 240, 300]
        case .personal:  return [12, 24, 36, 60]
        case .vehicle:   return [24, 36, 48, 60]
        case .business:  return [24, 48, 60, 84]
        case .education: return [36, 60, 84, 120]
        }
    }

    private var amountBounds: ClosedRange<Double> {
        switch calcLoanType {
        case .home:      return 500_000...20_000_000
        case .personal:  return 50_000...2_500_000
        case .vehicle:   return 100_000...5_000_000
        case .business:  return 100_000...10_000_000
        case .education: return 100_000...5_000_000
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.ml) {
                productPicker
                amountCard
                tenureCard
                rateCard
                resultCard
                documentsCard
                submitButton
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.lmsBackground.ignoresSafeArea())
        .navigationTitle("New Application")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { keyboardToolbar }
        .sheet(isPresented: $showDocSheet) { documentsSheet }
        .alert("Application Submitted", isPresented: $showConfirm, actions: {
            Button("OK") { dismiss() }
        }, message: {
            Text("Your \(calcLoanType.rawValue.capitalized) Loan for \(Formatting.currency(Decimal(viewModel.requestedAmount))) is under review.")
        })
        .onAppear(perform: applyDefaults)
        .onChange(of: calcLoanType) { _, _ in
            clampAmountToBounds()
            clampTenureToPresets()
        }
    }

    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") { amountFocused = false }
        }
    }

    private var documentsSheet: some View {
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

    private func applyDefaults() {
        if viewModel.requestedAmount < amountBounds.lowerBound {
            viewModel.requestedAmount = 2_500_000
        }
        if !tenurePresets.contains(viewModel.tenureMonths) {
            viewModel.tenureMonths = 240
        }
        syncAmountText()
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

    // MARK: - Amount Card
    private var amountCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Loan Amount")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("₹")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .focused($amountFocused)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .onChange(of: amountText) { _, newValue in
                        let digits = newValue.filter(\.isNumber)
                        if digits != newValue { amountText = digits }
                        if let value = Double(digits) {
                            viewModel.requestedAmount = value
                        } else if digits.isEmpty {
                            viewModel.requestedAmount = 0
                        }
                    }
                    .onSubmit { clampAmountToBounds() }
            }

            HStack {
                Text(Formatting.currency(Decimal(viewModel.requestedAmount)))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Spacer()
                Stepper("", value: Binding(
                    get: { viewModel.requestedAmount },
                    set: { newVal in
                        viewModel.requestedAmount = min(max(newVal, amountBounds.lowerBound), amountBounds.upperBound)
                        syncAmountText()
                    }
                ), in: amountBounds, step: stepSize)
                .labelsHidden()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(amountPresets, id: \.self) { preset in
                        chip(
                            title: shortAmount(preset),
                            isSelected: viewModel.requestedAmount == preset
                        ) {
                            viewModel.requestedAmount = preset
                            syncAmountText()
                            amountFocused = false
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private var stepSize: Double {
        switch calcLoanType {
        case .home, .business: return 100_000
        case .vehicle: return 50_000
        case .personal, .education: return 25_000
        }
    }

    // MARK: - Tenure Card
    private var tenureCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Tenure")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker(selection: $viewModel.tenureMonths) {
                    ForEach(allTenureOptions, id: \.self) { months in
                        Text(tenureLabel(months)).tag(months)
                    }
                } label: {
                    Text(tenureLabel(viewModel.tenureMonths))
                }
                .pickerStyle(.menu)
                .tint(.primary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(tenurePresets, id: \.self) { months in
                        chip(
                            title: tenureShort(months),
                            isSelected: viewModel.tenureMonths == months
                        ) {
                            viewModel.tenureMonths = months
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    private var allTenureOptions: [Int] {
        let maxMonths = calcLoanType == .home ? 360 : (calcLoanType == .business ? 120 : 84)
        return Array(stride(from: 6, through: maxMonths, by: 6))
    }

    // MARK: - Rate Card
    private var rateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Interest Rate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Fixed rate for \(calcLoanType.rawValue.capitalized) loans")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(String(format: "%.2f%%", calcRate))
                .font(.title3.weight(.semibold))
                .foregroundStyle(.tint)
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
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
                let success = await viewModel.submit(
                    loanService: env.loans,
                    borrowerID: userID,
                    loanType: calcLoanType,
                    interestRate: calcRate
                )
                if success { showConfirm = true }
            }
        }
    }

    // MARK: - Chip
    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.s)
                .background(
                    isSelected ? Color.accentColor : Color.lmsFill,
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private func syncAmountText() {
        let intVal = Int(viewModel.requestedAmount)
        amountText = String(intVal)
    }

    private func clampAmountToBounds() {
        viewModel.requestedAmount = min(max(viewModel.requestedAmount, amountBounds.lowerBound), amountBounds.upperBound)
        syncAmountText()
    }

    private func clampTenureToPresets() {
        if !tenurePresets.contains(viewModel.tenureMonths) {
            viewModel.tenureMonths = tenurePresets[tenurePresets.count / 2]
        }
    }

    private func shortAmount(_ value: Double) -> String {
        if value >= 10_000_000 {
            return String(format: "₹%.1f Cr", value / 10_000_000)
        } else if value >= 100_000 {
            let lakhs = value / 100_000
            return lakhs.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "₹%.0f L", lakhs)
                : String(format: "₹%.1f L", lakhs)
        } else if value >= 1_000 {
            return String(format: "₹%.0fK", value / 1_000)
        }
        return "₹\(Int(value))"
    }

    private func tenureShort(_ months: Int) -> String {
        if months % 12 == 0 { return "\(months / 12)y" }
        return "\(months)m"
    }

    private func tenureLabel(_ months: Int) -> String {
        if months % 12 == 0 {
            let years = months / 12
            return "\(years) year\(years == 1 ? "" : "s")"
        }
        return "\(months) months"
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
