import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct NewLoanApplicationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    /// Called when the user completes (or skips) the application flow.
    /// When embedded in a tab, this switches back to the Home tab.
    var onComplete: (() -> Void)? = nil

    @State private var viewModel = LoanApplicationViewModel()

    // Flow state: form → submitted → upload docs → done
    enum FlowStep {
        case form
        case uploadDocuments
        case complete
    }
    @State private var flowStep: FlowStep = .form
    @State private var showProductComparison = false

    // Amount input
    @State private var amountText: String = ""
    @FocusState private var amountFocused: Bool

    // Tenure input
    enum TenureUnit: String, CaseIterable {
        case months = "Months"
        case years = "Years"
    }
    @State private var tenureUnit: TenureUnit = .months
    @State private var tenureDisplayValue: Double = 12
    @State private var tenureText: String = "12"
    @FocusState private var tenureFocused: Bool

    // Document upload state
    @State private var isUploadingDoc = false
    @State private var uploadMessage: String?
    @State private var uploadDidFail = false
    @State private var activeDocumentKind: DocumentKind?
    @State private var showSourcePicker = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var uploadedKinds: Set<DocumentKind> = []

    var body: some View {
        Group {
            switch flowStep {
            case .form:
                formView
            case .uploadDocuments:
                documentUploadView
            case .complete:
                completionView
            }
        }
        .background(Color.lmsBackground.ignoresSafeArea())
        .navigationTitle(flowStep == .form ? "New Application" : flowStep == .uploadDocuments ? "Upload Documents" : "Success")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if flowStep == .form && !viewModel.loanProducts.isEmpty {
                    Button {
                        showProductComparison = true
                    } label: {
                        Image(systemName: "rectangle.split.2x1")
                            .font(.title3.weight(.semibold))
                    }
                }
            }
        }
        .toolbar { keyboardToolbar }
        .sheet(isPresented: $showProductComparison) {
            ProductComparisonView(
                products: viewModel.loanProducts,
                selectedProductID: selectedProduct?.id
            ) { selectedProd in
                viewModel.selectedProduct = selectedProd
                viewModel.requestedAmount = NSDecimalNumber(decimal: selectedProd.minimumAmount).doubleValue
                viewModel.tenureMonths = selectedProd.minimumTenureMonths
                syncAmountText()
                syncTenureFromViewModel()
            }
        }
        .task {
            if let env {
                await viewModel.loadProducts(loanService: env.loans)
                syncAmountText()
                syncTenureFromViewModel()
            }
        }
    }

    // MARK: - Form View

    private var formView: some View {
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
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Select Loan Product")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, Spacing.xs)
                        
                        productPicker
                    }
                    
                    amountCard
                    tenureCard
                    rateCard
                    resultCard

                    if let errorMsg = viewModel.errorMessage {
                        Text(errorMsg)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, Spacing.m)
                    }

                    if !isEligibleToApply {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.subheadline)
                                Text("Incomplete Profile Requirements")
                                    .font(.subheadline.weight(.semibold))
                            }
                            
                            Text("Before submitting a loan application, you must complete the following setup requirements in your profile settings:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.bottom, 4)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                requirementsRow(
                                    title: "KYC Verification Status",
                                    isDone: session.borrowerProfile?.kycStatus == .verified
                                )
                                requirementsRow(
                                    title: "Employment Status",
                                    isDone: session.borrowerProfile?.employmentType != nil
                                )
                                requirementsRow(
                                    title: "Monthly Salary / Income details",
                                    isDone: (session.borrowerProfile?.monthlyIncome ?? 0) > 0
                                )
                            }
                        }
                        .padding(Spacing.m)
                        .background(Color.lmsWarning.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous)
                                .stroke(Color.lmsWarning.opacity(0.3), lineWidth: 1)
                        )
                    }

                    submitButton
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Document Upload View (post-submission)

    private var documentUploadView: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                // Status header
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.lmsSuccess)
                    Text("Application Submitted!")
                        .font(.title3.weight(.semibold))
                    Text("Now upload your KYC documents to speed up processing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.l)
                .padding(.horizontal, Spacing.m)

                // Document rows
                VStack(spacing: 0) {
                    docUploadRow(kind: .incomeProof, title: "Salary Slips", icon: "doc.text.fill", iconColor: .orange)
                    Divider().padding(.leading, 56)
                    docUploadRow(kind: .bankStatement, title: "Bank Statement", icon: "building.columns.fill", iconColor: .indigo)
                }
                .padding(Spacing.m)
                .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .padding(.horizontal, Spacing.m)

                if !viewModel.uploadedDocumentIDs.isEmpty {
                    Text("\(viewModel.uploadedDocumentIDs.count) document\(viewModel.uploadedDocumentIDs.count > 1 ? "s" : "") uploaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMsg = viewModel.errorMessage {
                    Label(errorMsg, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.lmsDanger)
                        .padding(.horizontal, Spacing.m)
                }

                VStack(spacing: Spacing.sm) {
                    // Finish with documents
                    if !viewModel.uploadedDocumentIDs.isEmpty {
                        PrimaryButton(
                            "Submit Documents & Finish",
                            isLoading: viewModel.isLinkingDocuments
                        ) {
                            Task {
                                guard let env else { return }
                                let success = await viewModel.linkDocuments(loanService: env.loans)
                                if success {
                                    withAnimation { flowStep = .complete }
                                }
                            }
                        }
                        .padding(.horizontal, Spacing.m)
                    }

                    // Skip for now
                    Button {
                        withAnimation { flowStep = .complete }
                    } label: {
                        Text(viewModel.uploadedDocumentIDs.isEmpty ? "Skip for Now" : "Skip Remaining")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, Spacing.l)
            }
        }
        .scrollIndicators(.hidden)
        .disabled(isUploadingDoc)
        .overlay {
            if isUploadingDoc {
                VStack(spacing: Spacing.s) {
                    ProgressView()
                    Text("Uploading…").font(.subheadline)
                }
                .padding(Spacing.l)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            }
        }
        .overlay(alignment: .bottom) {
            if let msg = uploadMessage {
                Label(msg, systemImage: uploadDidFail ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.m)
                    .padding(.vertical, Spacing.sm)
                    .background(uploadDidFail ? Color.lmsDanger : Color.lmsSuccess, in: Capsule())
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    .padding(.bottom, Spacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: uploadMessage)
        .confirmationDialog("Choose File Source", isPresented: $showSourcePicker, titleVisibility: .visible) {
            Button { showPhotoPicker = true } label: {
                Label("Photo Library", systemImage: "photo.on.rectangle")
            }
            Button { showFilePicker = true } label: {
                Label("Browse Files", systemImage: "folder")
            }
            Button("Cancel", role: .cancel) { activeDocumentKind = nil }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem, let kind = activeDocumentKind else { return }
            selectedPhotoItem = nil
            Task {
                await handlePhotoPickerResult(item: newItem, kind: kind)
                activeDocumentKind = nil
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.pdf, .jpeg, .png], allowsMultipleSelection: false) { result in
            guard let kind = activeDocumentKind else { return }
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    Task {
                        await handleFileImporterResult(url: url, kind: kind)
                        activeDocumentKind = nil
                    }
                }
            case .failure(let error):
                uploadDidFail = true
                uploadMessage = error.localizedDescription
                activeDocumentKind = nil
            }
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.lmsSuccess.opacity(0.15))
                    .frame(width: 96, height: 96)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.lmsSuccess)
            }
            VStack(spacing: Spacing.xs) {
                Text("Application Complete")
                    .font(.title2.weight(.semibold))
                Text("Your loan application for \(Formatting.currency(Decimal(viewModel.requestedAmount))) has been submitted and is under review.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.l)
                if !viewModel.uploadedDocumentIDs.isEmpty {
                    Text("\(viewModel.uploadedDocumentIDs.count) document\(viewModel.uploadedDocumentIDs.count > 1 ? "s" : "") attached")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            PrimaryButton("Done") {
                viewModel.reset()
                uploadedKinds = []
                syncAmountText()
                syncTenureFromViewModel()
                withAnimation {
                    flowStep = .form
                }
                if let onComplete {
                    onComplete()
                } else {
                    dismiss()
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.m)
        }
    }

    // MARK: - Computed

    private var selectedProduct: LoanProduct? { viewModel.selectedProduct }

    private var amountBounds: ClosedRange<Double> {
        guard let p = selectedProduct else { return 10_000...1_000_000 }
        return NSDecimalNumber(decimal: p.minimumAmount).doubleValue...NSDecimalNumber(decimal: p.maximumAmount).doubleValue
    }

    private var displayRate: Double {
        selectedProduct?.displayRate ?? 10.0
    }

    private var stepSize: Double {
        let range = amountBounds.upperBound - amountBounds.lowerBound
        if range > 5_000_000 { return 100_000 }
        if range > 1_000_000 { return 50_000 }
        if range > 100_000 { return 10_000 }
        return 5_000
    }

    private var tenureMonthsBounds: ClosedRange<Int> {
        guard let p = selectedProduct else { return 6...360 }
        return p.minimumTenureMonths...p.maximumTenureMonths
    }

    private var tenureDisplayBounds: ClosedRange<Double> {
        let minM = Double(tenureMonthsBounds.lowerBound)
        let maxM = Double(tenureMonthsBounds.upperBound)
        switch tenureUnit {
        case .months: return minM...maxM
        case .years: return (minM / 12.0)...(maxM / 12.0)
        }
    }

    private var tenureSliderStep: Double {
        tenureUnit == .months ? 1 : 0.5
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                amountFocused = false
                tenureFocused = false
                clampAmountToBounds()
                clampTenureToBounds()
            }
        }
    }

    // MARK: - Product Picker

    private var productPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(viewModel.loanProducts) { product in
                    Button {
                        viewModel.selectedProduct = product
                        viewModel.requestedAmount = NSDecimalNumber(decimal: product.minimumAmount).doubleValue
                        viewModel.tenureMonths = product.minimumTenureMonths
                        syncAmountText()
                        syncTenureFromViewModel()
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
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("₹")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("0", text: $amountText)
                    .keyboardType(.numberPad)
                    .focused($amountFocused)
                    .font(.system(.title, design: .rounded).weight(.bold))
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

            Slider(
                value: Binding(
                    get: { viewModel.requestedAmount },
                    set: { newVal in
                        viewModel.requestedAmount = newVal
                        syncAmountText()
                    }
                ),
                in: amountBounds,
                step: stepSize
            )
            .tint(.accentColor)

            HStack {
                Text(shortAmount(amountBounds.lowerBound))
                    .font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text(shortAmount(amountBounds.upperBound))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            .padding(.top, -Spacing.s)
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    // MARK: - Tenure Card

    private var tenureCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Tenure")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Picker("Unit", selection: $tenureUnit) {
                ForEach(TenureUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: tenureUnit) { _, _ in syncTenureFromViewModel() }

            HStack(alignment: .firstTextBaseline, spacing: Spacing.s) {
                TextField("0", text: $tenureText)
                    .keyboardType(tenureUnit == .years ? .decimalPad : .numberPad)
                    .focused($tenureFocused)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .frame(maxWidth: 80)
                    .onChange(of: tenureText) { _, newValue in applyTenureText(newValue) }
                    .onSubmit { clampTenureToBounds() }
                Text(tenureUnit.rawValue.lowercased())
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if tenureUnit == .years {
                    Text("= \(viewModel.tenureMonths) mo")
                        .font(.caption)
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.lmsFill, in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }

            Slider(value: $tenureDisplayValue, in: tenureDisplayBounds, step: tenureSliderStep)
                .tint(.accentColor)
                .onChange(of: tenureDisplayValue) { _, newVal in
                    syncViewModelFromTenureDisplay(newVal)
                    tenureText = formatTenureDisplay(newVal)
                }

            HStack {
                Text(tenureRangeLabel(tenureDisplayBounds.lowerBound))
                    .font(.caption2).foregroundStyle(.tertiary)
                Spacer()
                Text(tenureRangeLabel(tenureDisplayBounds.upperBound))
                    .font(.caption2).foregroundStyle(.tertiary)
            }
            .padding(.top, -Spacing.s)
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
    }

    // MARK: - Rate Card

    private var rateCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Interest Rate")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                if let p = selectedProduct {
                    Text("\(String(format: "%.1f", p.minimumInterestRate))% – \(String(format: "%.1f", p.maximumInterestRate))%")
                        .font(.caption).foregroundStyle(.tertiary)
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

    // MARK: - Submit Button

    private var isEligibleToApply: Bool {
        let hasSalary = (session.borrowerProfile?.monthlyIncome ?? 0) > 0
        let hasEmployment = session.borrowerProfile?.employmentType != nil
        let hasKYC = session.borrowerProfile?.kycStatus == .verified
        return hasSalary && hasEmployment && hasKYC
    }

    private func requirementsRow(title: String, isDone: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(isDone ? Color.lmsSuccess : Color.lmsDanger)
                .font(.footnote)
            Text(title)
                .font(.footnote)
                .foregroundStyle(isDone ? .primary : .secondary)
        }
    }

    private var submitButton: some View {
        PrimaryButton(
            isEligibleToApply ? "Submit Application" : "Submit Application (Incomplete Profile)",
            isLoading: viewModel.isSubmitting
        ) {
            Task {
                guard let env, let userID = session.currentUser?.id else { return }
                let success = await viewModel.submit(
                    loanService: env.loans,
                    borrowerID: userID
                )
                if success {
                    withAnimation { flowStep = .uploadDocuments }
                }
            }
        }
        .disabled(!isEligibleToApply || viewModel.isSubmitting)
    }

    // MARK: - Document Upload Row

    @ViewBuilder
    private func docUploadRow(kind: DocumentKind, title: String, icon: String, iconColor: Color) -> some View {
        let isUploaded = uploadedKinds.contains(kind)
        Button {
            activeDocumentKind = kind
            showSourcePicker = true
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
                    .frame(width: 30, height: 30)
                    .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                if isUploaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.lmsSuccess)
                } else {
                    Text("Upload")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photo Picker Handler

    private func handlePhotoPickerResult(item: PhotosPickerItem, kind: DocumentKind) async {
        guard let env, let userID = session.currentUser?.id else { return }
        isUploadingDoc = true
        uploadMessage = nil

        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                throw NSError(domain: "KYC", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not load selected photo"])
            }

            let mimeType: String
            let ext: String
            if imageData.prefix(4) == Data([0x89, 0x50, 0x4E, 0x47]) {
                mimeType = "image/png"; ext = "png"
            } else {
                mimeType = "image/jpeg"; ext = "jpg"
            }

            let fileName = "\(kind.rawValue)_\(UUID().uuidString.prefix(8)).\(ext)"
            let doc = try await env.documents.upload(imageData, fileName: fileName, mimeType: mimeType, kind: kind, ownerID: userID)
            viewModel.addUploadedDocumentID(doc.id)
            uploadedKinds.insert(kind)
            uploadDidFail = false
            uploadMessage = "\(displayName(for: kind)) uploaded"
        } catch {
            uploadDidFail = true
            uploadMessage = error.localizedDescription
        }
        isUploadingDoc = false
        try? await Task.sleep(for: .seconds(3))
        if !isUploadingDoc { uploadMessage = nil }
    }

    // MARK: - File Importer Handler

    private func handleFileImporterResult(url: URL, kind: DocumentKind) async {
        guard let env, let userID = session.currentUser?.id else { return }
        isUploadingDoc = true
        uploadMessage = nil

        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let fileData = try Data(contentsOf: url)
            let fileName = url.lastPathComponent
            let ext = url.pathExtension.lowercased()
            let mimeType: String
            switch ext {
            case "pdf": mimeType = "application/pdf"
            case "png": mimeType = "image/png"
            case "jpg", "jpeg": mimeType = "image/jpeg"
            default: mimeType = "application/octet-stream"
            }

            let doc = try await env.documents.upload(fileData, fileName: fileName, mimeType: mimeType, kind: kind, ownerID: userID)
            viewModel.addUploadedDocumentID(doc.id)
            uploadedKinds.insert(kind)
            uploadDidFail = false
            uploadMessage = "\(displayName(for: kind)) uploaded"
        } catch {
            uploadDidFail = true
            uploadMessage = error.localizedDescription
        }
        isUploadingDoc = false
        try? await Task.sleep(for: .seconds(3))
        if !isUploadingDoc { uploadMessage = nil }
    }

    private func displayName(for kind: DocumentKind) -> String {
        switch kind {
        case .identityProof: return "ID Proof"
        case .addressProof: return "Address Proof"
        case .incomeProof: return "Salary Slip"
        case .bankStatement: return "Bank Statement"
        case .collateral: return "Collateral"
        case .other: return "Document"
        }
    }

    // MARK: - Amount Helpers

    private func syncAmountText() {
        amountText = String(Int(viewModel.requestedAmount))
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

    // MARK: - Tenure Helpers

    private func syncTenureFromViewModel() {
        let months = Double(viewModel.tenureMonths)
        switch tenureUnit {
        case .months:
            tenureDisplayValue = months
            tenureText = "\(viewModel.tenureMonths)"
        case .years:
            let years = months / 12.0
            tenureDisplayValue = years
            tenureText = formatTenureDisplay(years)
        }
    }

    private func syncViewModelFromTenureDisplay(_ displayVal: Double) {
        switch tenureUnit {
        case .months:
            viewModel.tenureMonths = max(Int(displayVal.rounded()), tenureMonthsBounds.lowerBound)
        case .years:
            let months = Int((displayVal * 12).rounded())
            viewModel.tenureMonths = min(max(months, tenureMonthsBounds.lowerBound), tenureMonthsBounds.upperBound)
        }
    }

    private func applyTenureText(_ text: String) {
        let cleaned = text.filter { $0.isNumber || $0 == "." }
        guard let value = Double(cleaned) else { return }
        switch tenureUnit {
        case .months:
            let months = Int(value.rounded())
            viewModel.tenureMonths = min(max(months, tenureMonthsBounds.lowerBound), tenureMonthsBounds.upperBound)
            tenureDisplayValue = Double(viewModel.tenureMonths)
        case .years:
            let months = Int((value * 12).rounded())
            viewModel.tenureMonths = min(max(months, tenureMonthsBounds.lowerBound), tenureMonthsBounds.upperBound)
            tenureDisplayValue = value
        }
    }

    private func clampTenureToBounds() {
        viewModel.tenureMonths = min(max(viewModel.tenureMonths, tenureMonthsBounds.lowerBound), tenureMonthsBounds.upperBound)
        syncTenureFromViewModel()
    }

    private func formatTenureDisplay(_ value: Double) -> String {
        if tenureUnit == .years {
            return value == value.rounded() ? "\(Int(value))" : String(format: "%.1f", value)
        }
        return "\(Int(value))"
    }

    private func tenureRangeLabel(_ value: Double) -> String {
        if tenureUnit == .years {
            return value == value.rounded() ? "\(Int(value)) yr" : String(format: "%.1f yr", value)
        }
        return "\(Int(value)) mo"
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
