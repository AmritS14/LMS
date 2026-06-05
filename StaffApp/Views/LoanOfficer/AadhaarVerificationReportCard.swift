import SwiftUI

struct AadhaarVerificationReportCard: View {
    let report: AadhaarVerificationReport

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                Text("UIDAI Verification Report")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                autoDecisionBadge
            }

            Divider()

            // Signature
            verificationRow(
                icon: "lock.shield.fill",
                label: "UIDAI Signature",
                value: report.signatureValid ? "Valid" : "Invalid",
                valueColor: report.signatureValid ? .green : .red,
                detail: report.signerCert?.subject
            )

            // Mobile hash
            hashRow(
                icon: "phone.fill",
                label: "Mobile Hash",
                result: report.mobileHashMatch
            )

            // Email hash
            hashRow(
                icon: "envelope.fill",
                label: "Email Hash",
                result: report.emailHashMatch
            )

            Divider()

            // Demographics
            if let name = report.demographics.name {
                infoRow(label: "Name", value: name)
            }
            if let dob = report.demographics.dob {
                infoRow(label: "Date of Birth", value: dob)
            }
            if let gender = report.demographics.gender {
                infoRow(label: "Gender", value: genderLabel(gender))
            }
            if let state = report.demographics.address?["state"] {
                infoRow(label: "State", value: state)
            }

            Divider()

            // XML age
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("XML generated:")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text(formattedDate(report.xmlGeneratedAt))
                    .font(.system(size: 11, weight: .medium))
                if report.xmlAgeDays > 180 {
                    Label("\(report.xmlAgeDays)d old", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(5)
                }
            }

            if let reason = report.rejectionReason {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                    Text(reason)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(autoDecisionBorderColor, lineWidth: 1)
        )
    }

    // MARK: - Sub-views

    private var autoDecisionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: decisionIcon)
            Text(decisionLabel)
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(decisionColor)
        .cornerRadius(8)
    }

    private func verificationRow(icon: String, label: String, value: String, valueColor: Color, detail: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(valueColor)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(label)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(valueColor)
                }
                if let detail {
                    Text(detail)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func hashRow(icon: String, label: String, result: HashMatchResult) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(hashColor(result))
                .frame(width: 18)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: hashIcon(result))
                    .font(.system(size: 10))
                Text(hashLabel(result))
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(hashColor(result))
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: 0) {
            Text("\(label): ")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .medium))
        }
    }

    // MARK: - Computed helpers

    private var decisionIcon: String {
        switch report.autoDecision {
        case .auto_verified: return "checkmark.seal.fill"
        case .needs_review: return "clock.badge.exclamationmark.fill"
        case .auto_rejected: return "xmark.seal.fill"
        }
    }

    private var decisionLabel: String {
        switch report.autoDecision {
        case .auto_verified: return "Auto-Verified"
        case .needs_review: return "Needs Review"
        case .auto_rejected: return "Auto-Rejected"
        }
    }

    private var decisionColor: Color {
        switch report.autoDecision {
        case .auto_verified: return .green
        case .needs_review: return .orange
        case .auto_rejected: return .red
        }
    }

    private var autoDecisionBorderColor: Color {
        switch report.autoDecision {
        case .auto_verified: return .green.opacity(0.3)
        case .needs_review: return .orange.opacity(0.3)
        case .auto_rejected: return .red.opacity(0.3)
        }
    }

    private func hashColor(_ result: HashMatchResult) -> Color {
        switch result {
        case .match: return .green
        case .mismatch: return .red
        case .no_profile_value: return .secondary
        }
    }

    private func hashIcon(_ result: HashMatchResult) -> String {
        switch result {
        case .match: return "checkmark.circle.fill"
        case .mismatch: return "xmark.circle.fill"
        case .no_profile_value: return "minus.circle.fill"
        }
    }

    private func hashLabel(_ result: HashMatchResult) -> String {
        switch result {
        case .match: return "Match"
        case .mismatch: return "Mismatch"
        case .no_profile_value: return "No profile value"
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

    private func formattedDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            let out = DateFormatter()
            out.dateStyle = .medium
            return out.string(from: date)
        }
        return isoString
    }
}

#Preview {
    AadhaarVerificationReportCard(report: AadhaarVerificationReport(
        documentId: UUID().uuidString,
        signatureValid: true,
        signerCert: AadhaarSignerCert(
            subject: "CN=UIDAI, O=UIDAI, C=IN",
            signingTime: ISO8601DateFormatter().string(from: .now)
        ),
        mobileHashMatch: .match,
        emailHashMatch: .no_profile_value,
        referenceId: "1202501151234567890",
        xmlGeneratedAt: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400 * 30)),
        xmlAgeDays: 30,
        demographics: AadhaarDemographics(
            name: "Ravi Kumar",
            dob: "1990-06-15",
            gender: "M",
            careOf: "Sh. Ramesh Kumar",
            address: ["state": "Karnataka", "city": "Bengaluru"]
        ),
        photoUrl: nil,
        autoDecision: .auto_verified,
        rejectionReason: nil
    ))
    .padding()
}
