//
//  NotificationTemplate.swift
//  LMS(GU)
//
//  Created by Shailesh on 19/05/26.
//

import Foundation

// MARK: - Notification Channels

/// Represents the medium through which a notification is sent.
enum NotificationChannel: String, CaseIterable, Identifiable, Codable {
    case email = "Email"
    case sms = "SMS"
    case inApp = "In-App"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .email: "envelope.fill"
        case .sms: "message.fill"
        case .inApp: "bell.badge.fill"
        }
    }
}

// MARK: - Trigger Event Enum

/// Represents the system event that triggers a notification.
enum TriggerEvent: String, CaseIterable, Identifiable, Codable {
    case loanApproved = "Loan Approved"
    case loanRejected = "Loan Rejected"
    case paymentDue = "Payment Due"
    case paymentReceived = "Payment Received"
    case paymentOverdue = "Payment Overdue"
    case documentRequired = "Document Required"
    case accountActivated = "Account Activated"
    case accountDeactivated = "Account Deactivated"

    var id: String { rawValue }

    /// SF Symbol icon for each trigger event.
    var systemImage: String {
        switch self {
        case .loanApproved: "checkmark.seal.fill"
        case .loanRejected: "xmark.seal.fill"
        case .paymentDue: "bell.badge.fill"
        case .paymentReceived: "indianrupeesign.circle.fill"
        case .paymentOverdue: "exclamationmark.triangle.fill"
        case .documentRequired: "doc.badge.plus"
        case .accountActivated: "person.badge.checkmark"
        case .accountDeactivated: "person.badge.minus"
        }
    }

    /// Color associated with each trigger event category.
    var tintColor: String {
        switch self {
        case .loanApproved, .paymentReceived, .accountActivated: "green"
        case .loanRejected, .paymentOverdue, .accountDeactivated: "red"
        case .paymentDue, .documentRequired: "orange"
        }
    }
}

// MARK: - Notification Template Model

/// Represents a notification template that the admin can customize.
/// Templates define the content sent to borrowers on trigger events.
struct NotificationTemplate: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var triggerEvent: TriggerEvent
    var bodyText: String
    var channels: Set<NotificationChannel>

    init(
        id: UUID = UUID(),
        title: String,
        triggerEvent: TriggerEvent,
        bodyText: String,
        channels: Set<NotificationChannel> = [.email, .inApp]
    ) {
        self.id = id
        self.title = title
        self.triggerEvent = triggerEvent
        self.bodyText = bodyText
        self.channels = channels
    }
}

// MARK: - Sample Data

extension NotificationTemplate {
    /// Mock templates for preview and development use.
    static let sampleTemplates: [NotificationTemplate] = [
        NotificationTemplate(
            title: "Loan Approval Notice",
            triggerEvent: .loanApproved,
            bodyText: "Dear {{borrower_name}},\n\nCongratulations! Your loan application (ID: {{loan_id}}) for ₹{{loan_amount}} has been approved.\n\nPlease log in to your account to review the terms and complete the disbursement process.\n\nBest regards,\nLMS Team"
        ),
        NotificationTemplate(
            title: "Loan Rejection Notice",
            triggerEvent: .loanRejected,
            bodyText: "Dear {{borrower_name}},\n\nWe regret to inform you that your loan application (ID: {{loan_id}}) could not be approved at this time.\n\nPlease contact your branch manager for further assistance.\n\nRegards,\nLMS Team"
        ),
        NotificationTemplate(
            title: "Payment Due Reminder",
            triggerEvent: .paymentDue,
            bodyText: "Dear {{borrower_name}},\n\nThis is a reminder that your EMI payment of ₹{{emi_amount}} for Loan ID: {{loan_id}} is due on {{due_date}}.\n\nPlease ensure timely payment to avoid late fees.\n\nThank you,\nLMS Team"
        ),
        NotificationTemplate(
            title: "Payment Received Confirmation",
            triggerEvent: .paymentReceived,
            bodyText: "Dear {{borrower_name}},\n\nWe have successfully received your payment of ₹{{payment_amount}} for Loan ID: {{loan_id}}.\n\nYour remaining balance is ₹{{remaining_balance}}.\n\nThank you,\nLMS Team"
        ),
        NotificationTemplate(
            title: "Overdue Payment Alert",
            triggerEvent: .paymentOverdue,
            bodyText: "Dear {{borrower_name}},\n\n⚠️ Your EMI payment for Loan ID: {{loan_id}} is now overdue by {{days_overdue}} days. A late fee of ₹{{late_fee}} has been applied.\n\nPlease make the payment immediately to avoid further penalties.\n\nUrgent,\nLMS Team"
        ),
        NotificationTemplate(
            title: "Document Upload Request",
            triggerEvent: .documentRequired,
            bodyText: "Dear {{borrower_name}},\n\nTo proceed with your loan application (ID: {{loan_id}}), we require the following documents:\n\n{{document_list}}\n\nPlease upload them through your account portal within 7 business days.\n\nRegards,\nLMS Team"
        ),
        NotificationTemplate(
            title: "Account Activation",
            triggerEvent: .accountActivated,
            bodyText: "Dear {{borrower_name}},\n\nYour LMS account has been successfully activated. You can now access all loan services through the portal.\n\nWelcome aboard!\nLMS Team"
        ),
        NotificationTemplate(
            title: "Account Deactivation Notice",
            triggerEvent: .accountDeactivated,
            bodyText: "Dear {{borrower_name}},\n\nYour LMS account has been deactivated. If you believe this was done in error, please contact your branch administrator.\n\nRegards,\nLMS Team"
        ),
    ]
}
