import SwiftUI

struct LoanReviewView: View {
    @Environment(LoanOfficerStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let applicationID: UUID

    @State private var officerRemarks: String = ""
    @State private var showApproveConfirmation = false
    @State private var showRejectConfirmation = false
    @State private var showEscalateSheet = false
    @State private var showDocumentRequestSheet = false
    @State private var escalationNotes: String = ""
    @State private var requestedDocumentName: String = ""
    @State private var requestedDocumentNote: String = ""

    private var application: OfficerApplication? {
        store.application(id: applicationID)
    }

    var body: some View {
        Group {
            if let app = application {
                content(for: app)
            } else {
                ContentUnavailableView(
                    "Application not found",
                    systemImage: "questionmark.folder",
                    description: Text("The selected application is no longer available.")
                )
            }
        }
        .navigationTitle("Loan Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(for app: OfficerApplication) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: Spacing.m) {
                    borrowerSection(app)
                    loanDetailsSection(app)
                    documentsSection
                    collateralSection
                    recommendationSection(app)
                }
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, 120)
            }
            .background(Color.lmsBackground)

            actionBar(for: app)
        }
        .confirmationDialog("Approve Application",
                            isPresented: $showApproveConfirmation,
                            titleVisibility: .visible) {
            Button("Approve") { store.approveApplication(app); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Approve \(app.borrowerName)'s \(app.loanTypeLabel) of \(OfficerFormat.currency(app.loanAmount))?")
        }
        .confirmationDialog("Reject Application",
                            isPresented: $showRejectConfirmation,
                            titleVisibility: .visible) {
            Button("Reject", role: .destructive) { store.rejectApplication(app); dismiss() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will notify \(app.borrowerName).")
        }
        .sheet(isPresented: $showEscalateSheet) { escalateSheet(for: app) }
        .sheet(isPresented: $showDocumentRequestSheet) { requestDocumentSheet }
    }

    // MARK: Sections

    private func borrowerSection(_ app: OfficerApplication) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: Spacing.m) {
                AvatarView(initials: app.borrowerInitials,
                           size: 72,
                           colors: app.riskLevel.gradient)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(app.borrowerName)
                        .font(.lmsTitle2)
                    StatusBadge(app.status.displayLabel, tone: app.status.tone,
                                icon: app.status.icon)
                }
                Spacer()
            }

            HStack {
                Spacer()
                CircularProgress(progress: Double(app.creditScore) / 900.0,
                                 color: creditScoreColor(app.creditScore),
                                 lineWidth: 10,
                                 size: 96)
                Spacer()
            }

            Divider()
            DetailRow(icon: "building.2.fill", title: "Employer", value: app.employer)
            DetailRow(icon: "indianrupeesign.circle.fill", title: "Monthly Income",
                      value: OfficerFormat.currency(app.monthlyIncome),
                      valueColor: .lmsSuccess)
            DetailRow(icon: "chart.line.downtrend.xyaxis", title: "Existing Liabilities",
                      value: OfficerFormat.currency(app.existingLiabilities),
                      valueColor: app.existingLiabilities > 0 ? .lmsWarning : .lmsSuccess)
            DetailRow(icon: "star.fill", title: "Eligibility Score",
                      value: "\(app.eligibilityScore)/100",
                      valueColor: eligibilityColor(app.eligibilityScore))
            Divider()
            HStack(spacing: Spacing.m) {
                contactButton(icon: "phone.fill", label: app.phoneNumber, color: .lmsSuccess)
                contactButton(icon: "envelope.fill", label: app.email, color: .lmsInfo)
            }
        }
        .padding(Spacing.m)
        .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private func loanDetailsSection(_ app: OfficerApplication) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Loan Details", icon: "banknote.fill")
            VStack(spacing: 0) {
                DetailRow(icon: "doc.text.fill", title: "Loan Type", value: app.loanTypeLabel)
                DetailRow(icon: "indianrupeesign.circle", title: "Requested",
                          value: OfficerFormat.currency(app.loanAmount))
                DetailRow(icon: "calendar.badge.clock", title: "EMI",
                          value: OfficerFormat.currency(app.emiAmount),
                          valueColor: .lmsAccent)
                DetailRow(icon: "percent", title: "Interest Rate",
                          value: String(format: "%.2f%%", app.interestRate))
                DetailRow(icon: "clock.fill", title: "Tenure",
                          value: "\(app.tenure) months")
                DetailRow(icon: "text.quote", title: "Purpose", value: app.purpose)

                Divider().padding(.vertical, Spacing.xs)
                repaymentRow(app)
                Divider().padding(.vertical, Spacing.xs)
                riskBar(app)
            }
            .padding(Spacing.m)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    private func repaymentRow(_ app: OfficerApplication) -> some View {
        HStack {
            repaymentColumn(label: "Principal",
                            value: OfficerFormat.currency(app.loanAmount),
                            color: .lmsAccent)
            Spacer()
            repaymentColumn(label: "Interest",
                            value: OfficerFormat.currency(app.totalInterest),
                            color: .lmsWarning)
            Spacer()
            repaymentColumn(label: "Total Payable",
                            value: OfficerFormat.currency(app.totalPayable),
                            color: .lmsSuccess)
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.s)
        .background(Color.lmsTertiarySurface, in: RoundedRectangle(cornerRadius: CornerRadius.small))
    }

    private func repaymentColumn(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
        }
    }

    private func riskBar(_ app: OfficerApplication) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Text("Risk Analysis").font(.subheadline.weight(.semibold))
                Spacer()
                StatusBadge(app.riskLevel.rawValue, tone: app.riskLevel.tone,
                            icon: app.riskLevel.icon)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.lmsGray5).frame(height: 10)
                    Capsule()
                        .fill(toneColor(app.riskLevel.tone))
                        .frame(width: geo.size.width * app.riskLevel.progress, height: 10)
                }
            }
            .frame(height: 10)
            HStack {
                Text("Low").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Critical").font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(
                title: "Documents & KYC",
                subtitle: "\(store.reviewDocuments.filter { $0.status == .verified }.count)/\(store.reviewDocuments.count) verified",
                icon: "doc.text.fill"
            )
            VStack(spacing: 0) {
                ForEach(store.reviewDocuments) { doc in
                    documentRow(doc)
                    if doc.id != store.reviewDocuments.last?.id { Divider() }
                }
            }
            .padding(Spacing.m)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    private func documentRow(_ doc: ReviewDocument) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: doc.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(toneColor(doc.status.tone))
                .frame(width: 36, height: 36)
                .background(toneColor(doc.status.tone).opacity(0.12),
                            in: RoundedRectangle(cornerRadius: CornerRadius.small))
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.name).font(.subheadline.weight(.semibold))
                Text(doc.type).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if doc.ocrVerified {
                Text("OCR")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.lmsSuccess)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Color.lmsSuccess.opacity(0.12), in: Capsule())
            }
            StatusBadge(doc.status.rawValue, tone: doc.status.tone,
                        icon: doc.status.icon, size: .small)
        }
        .padding(.vertical, Spacing.xs)
    }

    private var collateralSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Collateral", icon: "building.2.fill")
            VStack(spacing: 0) {
                DetailRow(icon: "house.fill", title: "Property Type",
                          value: store.collateral.propertyType)
                DetailRow(icon: "mappin.circle.fill", title: "Address",
                          value: store.collateral.address)
                DetailRow(icon: "indianrupeesign.circle.fill", title: "Current Valuation",
                          value: OfficerFormat.currency(store.collateral.currentValuation),
                          valueColor: .lmsSuccess)
                DetailRow(icon: "calendar", title: "Last Valuation",
                          value: OfficerFormat.date(store.collateral.lastValuationDate))

                Divider().padding(.vertical, Spacing.xs)

                HStack(spacing: Spacing.m) {
                    CircularProgress(progress: min(store.collateral.coverageRatio / 2.0, 1.0),
                                     color: coverageColor(store.collateral.coverageRatio),
                                     size: 72)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coverage Ratio").font(.subheadline.weight(.semibold))
                        Text(String(format: "%.2fx", store.collateral.coverageRatio))
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(coverageColor(store.collateral.coverageRatio))
                        Text(store.collateral.coverageRatio >= 1.5 ? "Adequate" : "Marginal")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Divider().padding(.vertical, Spacing.xs)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Revaluation History").font(.subheadline.weight(.semibold))
                    ForEach(Array(store.collateral.revaluationHistory.enumerated()), id: \.offset) { idx, entry in
                        HStack {
                            Circle()
                                .fill(idx == store.collateral.revaluationHistory.count - 1
                                      ? Color.lmsSuccess : Color.lmsGray4)
                                .frame(width: 8, height: 8)
                            Text(OfficerFormat.date(entry.date))
                                .font(.footnote).foregroundStyle(.secondary)
                            Spacer()
                            Text(OfficerFormat.currency(entry.value))
                                .font(.footnote.weight(.semibold).monospacedDigit())
                        }
                    }
                }
            }
            .padding(Spacing.m)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    private func recommendationSection(_ app: OfficerApplication) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Recommendation", icon: "text.bubble.fill")
            VStack(alignment: .leading, spacing: Spacing.sm) {
                riskSummary(app)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Officer Remarks").font(.subheadline.weight(.semibold))
                    TextEditor(text: $officerRemarks)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(Spacing.s)
                        .background(Color.lmsTertiarySurface,
                                    in: RoundedRectangle(cornerRadius: CornerRadius.medium))
                }
                PrimaryButton("Submit Recommendation") {
                    store.recommendApplication(app)
                    dismiss()
                }
            }
            .padding(Spacing.m)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card))
        }
    }

    private func riskSummary(_ app: OfficerApplication) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack {
                Image(systemName: app.riskLevel.icon)
                    .foregroundStyle(toneColor(app.riskLevel.tone))
                Text("Risk Summary").font(.subheadline.weight(.semibold))
                Spacer()
                StatusBadge(app.riskLevel.rawValue, tone: app.riskLevel.tone,
                            icon: app.riskLevel.icon)
            }
            riskFactor(label: "Credit Score",
                       detail: "\(app.creditScore)/900",
                       isPositive: app.creditScore >= 650)
            riskFactor(label: "Debt-to-Income",
                       detail: String(format: "%.1f%%", app.debtToIncomeRatio * 100),
                       isPositive: app.debtToIncomeRatio < 0.5)
            riskFactor(label: "KYC",
                       detail: app.kycStatus.displayLabel,
                       isPositive: app.kycStatus == .verified)
            riskFactor(label: "Fraud Flag",
                       detail: app.fraudFlag ? "Detected" : "Clear",
                       isPositive: !app.fraudFlag)
            riskFactor(label: "Collateral",
                       detail: String(format: "%.2fx", store.collateral.coverageRatio),
                       isPositive: store.collateral.coverageRatio >= 1.5)
        }
        .padding(Spacing.m)
        .background(toneColor(app.riskLevel.tone).opacity(0.06),
                    in: RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    private func riskFactor(label: String, detail: String, isPositive: Bool) -> some View {
        HStack {
            Image(systemName: isPositive ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isPositive ? Color.lmsSuccess : Color.lmsWarning)
                .font(.caption)
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(detail).font(.caption.weight(.semibold))
                .foregroundStyle(isPositive ? Color.lmsSuccess : Color.lmsWarning)
        }
    }

    // MARK: Action Bar

    private func actionBar(for app: OfficerApplication) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.s) {
                actionPill("Approve", icon: "checkmark.circle.fill", tint: .lmsSuccess) {
                    showApproveConfirmation = true
                }
                actionPill("Reject", icon: "xmark.circle.fill", tint: .lmsDanger) {
                    showRejectConfirmation = true
                }
                actionPill("Escalate", icon: "arrow.up.circle.fill", tint: .lmsAccent) {
                    showEscalateSheet = true
                }
                actionPill("Request Docs", icon: "doc.badge.plus", tint: .lmsInfo) {
                    showDocumentRequestSheet = true
                }
                actionPill("Send Back", icon: "arrow.uturn.backward", tint: .lmsWarning) {
                    store.requestAdditionalInfo(for: app)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
        }
        .background(.ultraThinMaterial)
    }

    private func actionPill(_ title: String, icon: String, tint: Color,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.s)
                .background(tint, in: Capsule())
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: Sheets

    private func escalateSheet(for app: OfficerApplication) -> some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    TextEditor(text: $escalationNotes)
                        .frame(minHeight: 120)
                }
                Section("Escalation Level") {
                    Picker("Level", selection: .constant("Senior Officer")) {
                        Text("Senior Officer").tag("Senior Officer")
                        Text("Branch Manager").tag("Branch Manager")
                        Text("Regional Head").tag("Regional Head")
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Escalate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showEscalateSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        showEscalateSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var requestDocumentSheet: some View {
        NavigationStack {
            Form {
                Section("Document Name") {
                    TextField("e.g. Bank Statement (6 months)", text: $requestedDocumentName)
                }
                Section("Note to Borrower") {
                    TextEditor(text: $requestedDocumentNote).frame(minHeight: 100)
                }
                Section("Quick Select") {
                    quickDocOption("Bank Statement", icon: "building.columns.fill")
                    quickDocOption("Salary Slip", icon: "doc.text.fill")
                    quickDocOption("IT Returns", icon: "doc.on.doc.fill")
                    quickDocOption("Property Documents", icon: "house.fill")
                }
            }
            .navigationTitle("Request Documents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDocumentRequestSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { showDocumentRequestSheet = false }
                        .disabled(requestedDocumentName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func quickDocOption(_ name: String, icon: String) -> some View {
        Button {
            requestedDocumentName = name
        } label: {
            HStack {
                Image(systemName: icon).foregroundStyle(Color.lmsAccent)
                Text(name).foregroundStyle(.primary)
                Spacer()
                if requestedDocumentName == name {
                    Image(systemName: "checkmark").foregroundStyle(Color.lmsAccent)
                }
            }
        }
    }

    // MARK: Helpers

    private func contactButton(icon: String, label: String, color: Color) -> some View {
        Button {} label: {
            HStack(spacing: Spacing.s) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.12), in: Circle())
                Text(label).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    private func toneColor(_ tone: StatusBadge.Tone) -> Color {
        switch tone {
        case .neutral: .primary
        case .info: .lmsInfo
        case .success: .lmsSuccess
        case .warning: .lmsWarning
        case .danger: .lmsDanger
        }
    }

    private func creditScoreColor(_ score: Int) -> Color {
        if score >= 750 { return .lmsSuccess }
        if score >= 650 { return .lmsInfo }
        if score >= 550 { return .lmsWarning }
        return .lmsDanger
    }

    private func eligibilityColor(_ score: Int) -> Color {
        if score >= 70 { return .lmsSuccess }
        if score >= 50 { return .lmsWarning }
        return .lmsDanger
    }

    private func coverageColor(_ ratio: Double) -> Color {
        if ratio >= 1.5 { return .lmsSuccess }
        if ratio >= 1.0 { return .lmsWarning }
        return .lmsDanger
    }
}
