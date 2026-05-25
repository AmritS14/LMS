import SwiftUI

struct NewLoanApplicationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = LoanApplicationViewModel()
    @State private var showDocSheet = false
    @State private var showConfirm = false
    @FocusState private var amountFocused: Bool

    @State private var amountText: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.ml) {
                if viewModel.isLoadingProducts {
                    ProgressView("Loading loan products…")
                        .padding(.top, Spacing.xl)
                } else if viewModel.loanProducts.isEmpty {
                    ContentUnavailableView(
                        "No Products Available",
                        systemImage: "exclamationmark.triangle",
                        description: Text(viewModel.errorMessage ?? "Could not load loan products.")
                    )
                } else {
                    productPicker
                    amountCard
                    tenureCard
                    rateCard
                    resultCard
                    documentsCard
                    
                    if let errorMsg = viewModel.errorMessage {
                        Text(errorMsg)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, Spacing.m)
                    }
                    
                    submitButton
                }
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
            Text("Your loan application for \(Formatting.currency(Decimal(viewModel.requestedAmount))) has been submitted and is under review.")
        })
        .task {
            if let env {
                await viewModel.loadProducts(loanService: env.loans)
                syncAmountText()
            }
        }
    }

    // MARK: - Computed from selected product
    
    private var selectedProduct: LoanProduct? { viewModel.selectedProduct }

    private var amountBounds: ClosedRange<Double> {
        guard let p = selectedProduct else { return 10_000...1_000_000 }
        return NSDecimalNumber(decimal: p.minimumAmount).doubleValue...NSDecimalNumber(decimal: p.maximumAmount).doubleValue
    }

    private var displayRate: Double {
        selectedProduct?.displayRate ?? 10.0
    }

    private var amountPresets: [Double] {
        guard let p = selectedProduct else { return [] }
        let min = NSDecimalNumber(decimal: p.minimumAmount).doubleValue
        let max = NSDecimalNumber(decimal: p.maximumAmount).doubleValue
        let step = (max - min) / 4.0
        return [min, min + step, min + step * 2, min + step * 3].map { $0.rounded() }
    }

    private var tenurePresets: [Int] {
        guard let p = selectedProduct else { return [12, 24, 36, 60] }
        let min = p.minimumTenureMonths
        let max = p.maximumTenureMonths
        let step = Swift.max((max - min) / 4, 1)
        var presets: [Int] = []
        var v = min
        while v <= max && presets.count < 5 {
            presets.append(v)
            v += step
        }
        if !presets.contains(max) { presets.append(max) }
        return presets
    }

    private var stepSize: Double {
        let range = amountBounds.upperBound - amountBounds.lowerBound
        if range > 5_000_000 { return 100_000 }
        if range > 1_000_000 { return 50_000 }
        return 25_000
    }

    // MARK: - Toolbar

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

    // MARK: - Product Picker
    private var productPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.loanProducts) { product in
                    Button {
                        viewModel.selectedProduct = product
                        // Reset amount and tenure to product defaults
                        viewModel.requestedAmount = NSDecimalNumber(decimal: product.minimumAmount).doubleValue
                        viewModel.tenureMonths = product.minimumTenureMonths
                        syncAmountText()
                    } label: {
                        VStack(spacing: Spacing.s) {
                            ZStack {
                                Circle()
                                    .fill(selectedProduct?.id == product.id ? Color.accentColor : Color.lmsFill)
                                    .frame(width: 52, height: 52)
                                Image(systemName: product.icon)
                                    .foregroundStyle(selectedProduct?.id == product.id ? .white : .secondary)
                                    .font(.title3)
                            }
                            Text(product.name.replacingOccurrences(of: " Loan", with: ""))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(selectedProduct?.id == product.id ? .primary : .secondary)
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

    // MARK: - Tenure Card
    private var tenureCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Tenure")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if let p = selectedProduct {
                    Picker(selection: $viewModel.tenureMonths) {
                        ForEach(allTenureOptions(for: p), id: \.self) { months in
                            Text(tenureLabel(months)).tag(months)
                        }
                    } label: {
                        Text(tenureLabel(viewModel.tenureMonths))
                    }
                    .pickerStyle(.menu)
                    .tint(.primary)
                }
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

    private func allTenureOptions(for product: LoanProduct) -> [Int] {
        Array(stride(from: product.minimumTenureMonths, through: product.maximumTenureMonths, by: 6))
    }

    // MARK: - Rate Card
    private var rateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Interest Rate")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let p = selectedProduct {
                    Text("\(String(format: "%.1f", p.minimumInterestRate))% – \(String(format: "%.1f", p.maximumInterestRate))%")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Text(String(format: "%.2f%%", displayRate))
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
            annualInterestRate: displayRate,
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
                    borrowerID: userID
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
