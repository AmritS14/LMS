import SwiftUI

// MARK: - Help & FAQ View

//struct HelpAndFAQView: View {
//    var body: some View {
//        List {
//            // MARK: Getting Started
//            Section("Getting Started") {
//                FAQItem(
//                    question: "How do I review a loan application?",
//                    answer: "Navigate to the Applications tab, select a pending application, and review the borrower details, credit score, and supporting documents. You can then approve, reject, or send back the application with remarks."
//                )
//                FAQItem(
//                    question: "How do I view officer performance?",
//                    answer: "Go to the Dashboard tab and scroll to the Officer Performance section. Tap on any officer to see their detailed metrics including approval rates, average decision time, and loan portfolio."
//                )
//                FAQItem(
//                    question: "How do I generate reports?",
//                    answer: "Open the Reports tab and choose from Daily, Weekly, Monthly, or NPA report types. You can preview the report on-screen and export it as a PDF to share with stakeholders."
//                )
//            }
//
//            // MARK: Loan Management
//            Section("Loan Management") {
//                FAQItem(
//                    question: "What does the NPA ratio indicate?",
//                    answer: "The Non-Performing Asset (NPA) ratio shows the percentage of loans where borrowers have stopped making payments for 90 days or more. A lower NPA ratio indicates better portfolio health."
//                )
//                FAQItem(
//                    question: "How is collection efficiency calculated?",
//                    answer: "Collection efficiency is the ratio of actual collections received versus the total demand (expected EMI payments) for a given period. It measures how effectively your branch recovers dues."
//                )
//                FAQItem(
//                    question: "What are risk alerts?",
//                    answer: "Risk alerts notify you when a loan shows early warning signs such as missed payments, deteriorating credit scores, or unusual activity. You can configure alert thresholds in Profile → Alert Thresholds."
//                )
//            }
//
//            // MARK: Account & Security
//            Section("Account & Security") {
//                FAQItem(
//                    question: "How do I change my password?",
//                    answer: "For security purposes, password changes must be initiated through your organisation's IT department or the admin portal. Contact your system administrator for assistance."
//                )
//                FAQItem(
//                    question: "Why was I signed out automatically?",
//                    answer: "For security, sessions expire after a period of inactivity. If you are signed out unexpectedly, simply log in again with your credentials. Contact support if you continue to experience issues."
//                )
//            }
//
//            // MARK: Troubleshooting
//            Section("Troubleshooting") {
//                FAQItem(
//                    question: "Data is not loading or looks outdated",
//                    answer: "Pull down on any screen to refresh the data. Ensure you have a stable internet connection. If the problem persists, try signing out and signing back in, or contact support."
//                )
//                FAQItem(
//                    question: "I cannot approve or reject applications",
//                    answer: "Verify that you have the Branch Manager role assigned. Only users with appropriate permissions can take action on loan applications. Contact your administrator if your role is incorrect."
//                )
//            }
//
//            // MARK: App Info
//            Section {
//                LabeledContent("App Version", value: appVersion)
//                LabeledContent("Build", value: buildNumber)
//            } footer: {
//                Text("© 2026 LMS. All rights reserved.")
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding(.top, Spacing.m)
//            }
//        }
//        .listStyle(.insetGrouped)
//        .navigationTitle("Help & FAQ")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//
//    private var appVersion: String {
//        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
//    }
//
//    private var buildNumber: String {
//        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
//    }
//}
//
//// MARK: - FAQ Disclosure Item
//
//private struct FAQItem: View {
//    let question: String
//    let answer: String
//    @State private var isExpanded = false
//
//    var body: some View {
//        DisclosureGroup(isExpanded: $isExpanded) {
//            Text(answer)
//                .font(.subheadline)
//                .foregroundStyle(.secondary)
//                .padding(.top, Spacing.xs)
//        } label: {
//            Text(question)
//                .font(.subheadline.weight(.medium))
//        }
//    }
//}

// MARK: - Contact Support View

struct ContactSupportView: View {
    @Environment(\.openURL) private var openURL

    private let supportEmail = "support@lmsapp.com"
    private let supportPhone = "+91 1800-123-4567"
    private let supportHours = "Mon – Fri, 9:00 AM – 6:00 PM IST"

    var body: some View {
        List {
            // MARK: Contact Options
            Section {
                // Email
                Button {
                    if let url = URL(string: "mailto:\(supportEmail)?subject=LMS%20Manager%20Support%20Request") {
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        contactIcon(systemName: "envelope.fill", color: .lmsAccent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email Support")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(supportEmail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }

                // Phone
                Button {
                    let digits = supportPhone.filter { $0.isNumber || $0 == "+" }
                    if let url = URL(string: "tel:\(digits)") {
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        contactIcon(systemName: "phone.fill", color: .lmsSuccess)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Call Support")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(supportPhone)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("Get in Touch")
            } footer: {
                Text("Our support team typically responds within 24 hours on business days.")
            }

            // MARK: Support Hours
            Section("Support Hours") {
                HStack(spacing: Spacing.sm) {
                    contactIcon(systemName: "clock.fill", color: .lmsInfo)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Business Hours")
                            .font(.subheadline.weight(.medium))
                        Text(supportHours)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: Spacing.sm) {
                    contactIcon(systemName: "exclamationmark.bubble.fill", color: .lmsWarning)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Critical Issues")
                            .font(.subheadline.weight(.medium))
                        Text("For urgent matters outside business hours, email with \"URGENT\" in the subject line.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // MARK: Before You Contact
            Section {
                VStack(alignment: .leading, spacing: Spacing.s) {
                    infoRow(icon: "1.circle.fill", text: "Check the Help & FAQ section for common questions")
                    infoRow(icon: "2.circle.fill", text: "Note your Employee ID and branch name")
                    infoRow(icon: "3.circle.fill", text: "Describe the issue with steps to reproduce")
                    infoRow(icon: "4.circle.fill", text: "Include screenshots if applicable")
                }
                .padding(.vertical, Spacing.xs)
            } header: {
                Text("Before You Contact Us")
            } footer: {
                Text("Providing detailed information helps us resolve your issue faster.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Helpers

    private func contactIcon(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.body.weight(.medium))
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
            .background(color.opacity(0.12),
                         in: RoundedRectangle(cornerRadius: CornerRadius.small))
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Color.lmsAccent)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

//#Preview("Help & FAQ") {
//    NavigationStack {
//        HelpAndFAQView()
//    }
//}

#Preview("Contact Support") {
    NavigationStack {
        ContactSupportView()
    }
}
