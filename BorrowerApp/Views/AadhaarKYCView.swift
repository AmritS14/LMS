import SwiftUI
import UniformTypeIdentifiers

struct AadhaarKYCView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    var applicationID: UUID? = nil

    @State private var selectedZipURL: URL? = nil
    @State private var selectedZipData: Data? = nil
    @State private var sharePhrase: String = ""
    @State private var consentGiven: Bool = false
    @State private var showFilePicker = false
    @State private var isSubmitting = false
    @State private var result: AadhaarVerificationReport? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l) {
                    if let report = result {
                        resultCard(report)
                    } else {
                        step1
                        step2
                        step3
                        consentRow
                        submitButton
                    }
                }
                .padding(Spacing.m)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Aadhaar XML Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) { Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(.primary).padding(8).background(Color(uiColor: .systemGray5), in: Circle()) }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType.zip],
                allowsMultipleSelection: false
            ) { res in
                switch res {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    selectedZipURL = url
                    selectedZipData = try? Data(contentsOf: url)
                case .failure:
                    break
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    VStack(spacing: Spacing.s) {
                        ProgressView()
                        Text("Verifying with UIDAI…").font(.subheadline)
                    }
                    .padding(Spacing.l)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                }
            }
        }
    }

    // MARK: - Steps

    private var step1: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            stepHeader(number: "1", title: "Download Your Aadhaar XML")
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Visit the UIDAI portal, log in, and download your Paperless Offline e-KYC ZIP. You'll also receive a 4-character Share Phrase.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Link("Open UIDAI portal →", destination: URL(string: "https://myaadhaar.uidai.gov.in/offline-ekyc")!)
                    .font(.subheadline.weight(.medium))
            }
        }
        .padding(Spacing.m)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var step2: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            stepHeader(number: "2", title: "Upload the ZIP File")
            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: selectedZipURL != nil ? "checkmark.circle.fill" : "doc.zipper")
                        .foregroundStyle(selectedZipURL != nil ? Color.lmsSuccess : .secondary)
                    Text(selectedZipURL?.lastPathComponent ?? "Select .zip file")
                        .font(.subheadline)
                        .foregroundStyle(selectedZipURL != nil ? .primary : .secondary)
                    Spacer()
                    Image(systemName: "folder")
                        .foregroundStyle(.tint)
                }
                .padding(Spacing.m)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selectedZipURL != nil ? Color.lmsSuccess : Color(.separator), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(Spacing.m)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var step3: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            stepHeader(number: "3", title: "Enter Share Phrase")
            SecureField("4-character share phrase from UIDAI", text: $sharePhrase)
                .padding(Spacing.m)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
        }
        .padding(Spacing.m)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var consentRow: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Button {
                consentGiven.toggle()
            } label: {
                Image(systemName: consentGiven ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundStyle(consentGiven ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)
            Text("I authorise Infosys LMS to verify my Aadhaar Paperless Offline e-KYC document with UIDAI for identity verification purposes.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.m)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    private var submitButton: some View {
        VStack(spacing: Spacing.s) {
            if let err = errorMessage {
                Label(err, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.lmsDanger)
                    .multilineTextAlignment(.center)
            }
            Button {
                Task { await submit() }
            } label: {
                Text("Verify with UIDAI")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.m)
                    .background(
                        canSubmit ? Color.accentColor : Color.secondary,
                        in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
        }
    }

    // MARK: - Result Card

    private func resultCard(_ report: AadhaarVerificationReport) -> some View {
        let banner = decisionBannerContent(report)
        return VStack(spacing: Spacing.m) {
            // Decision banner
            HStack(spacing: Spacing.sm) {
                Image(systemName: banner.icon)
                    .font(.title2.weight(.bold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(banner.title).font(.headline.weight(.bold))
                    Text(banner.subtitle).font(.caption).opacity(0.8)
                }
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(Spacing.m)
            .background(banner.color, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))

            // Demographics
            if let name = report.demographics.name {
                infoRow(icon: "person.fill", label: "Name", value: name)
            }
            if let dob = report.demographics.dob {
                infoRow(icon: "calendar", label: "Date of Birth", value: dob)
            }
            if let gender = report.demographics.gender {
                infoRow(icon: "person.text.rectangle", label: "Gender", value: genderLabel(gender))
            }
            if let city = report.demographics.address?["city"] {
                infoRow(icon: "location.fill", label: "City", value: city)
            }

            // UIDAI verification note
            HStack(spacing: Spacing.xs) {
                Image(systemName: "shield.checkered")
                    .font(.caption)
                    .foregroundStyle(Color.lmsSuccess)
                Text("Verified by UIDAI Paperless Offline e-KYC")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
        }
        .padding(Spacing.m)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
    }

    // MARK: - Helpers

    private var canSubmit: Bool {
        selectedZipData != nil && !sharePhrase.isEmpty && consentGiven
    }

    private func submit() async {
        guard let zipData = selectedZipData, let env else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            let report = try await env.aadhaarKYC.verify(
                zipData: zipData,
                sharePhrase: sharePhrase,
                applicationID: applicationID
            )
            result = report
            
            // Save to DB
            var updatedProfile = session.borrowerProfile ?? BorrowerProfile(
                id: session.currentUser?.id ?? UUID(),
                dateOfBirth: Date()
            )
            updatedProfile.kycStatus = .verified
            updatedProfile.aadhaarLast4 = String(report.referenceId.prefix(4))
            
            if let addressDict = report.demographics.address {
                updatedProfile.address = PostalAddress(
                    line1: [addressDict["house"], addressDict["street"], addressDict["locality"]].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", "),
                    line2: addressDict["vtc"],
                    city: addressDict["city"] ?? addressDict["district"] ?? "",
                    state: addressDict["state"] ?? "",
                    pinCode: Int(addressDict["pinCode"] ?? "") ?? 0,
                    country: "India"
                )
            }
            
            try await env.auth.saveBorrowerProfile(updatedProfile)
            session.borrowerProfile = updatedProfile
        } catch {
            let msg = error.localizedDescription
            if msg.contains("wrong_share_phrase") || msg.contains("Wrong share phrase") {
                errorMessage = "Wrong share phrase. Please check the code from UIDAI and try again."
            } else {
                errorMessage = msg
            }
        }
        isSubmitting = false
        sharePhrase = "" // clear after attempt — never retain in memory
    }

    private func stepHeader(number: String, title: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: Circle())
            Text(title).font(.subheadline.weight(.semibold))
        }
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).foregroundStyle(.secondary)
                Text(value).font(.subheadline)
            }
        }
    }

    private func genderLabel(_ raw: String) -> String {
        switch raw.uppercased() {
        case "M": return "Male"
        case "F": return "Female"
        case "T": return "Transgender"
        default: return raw
        }
    }

    private struct BannerInfo { let color: Color; let icon: String; let title: String; let subtitle: String }
    private func decisionBannerContent(_ report: AadhaarVerificationReport) -> BannerInfo {
        switch report.autoDecision {
        case .auto_verified:
            return BannerInfo(color: .lmsSuccess, icon: "checkmark.seal.fill", title: "Identity Verified", subtitle: "Aadhaar XML signature valid")
        case .needs_review:
            return BannerInfo(color: .orange, icon: "clock.badge.exclamationmark.fill", title: "Submitted for Review", subtitle: "An officer will verify your document shortly")
        case .auto_rejected:
            return BannerInfo(color: .lmsDanger, icon: "xmark.seal.fill", title: "Verification Failed", subtitle: report.rejectionReason ?? "The file could not be verified")
        }
    }
}

#Preview {
    AadhaarKYCView()
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
