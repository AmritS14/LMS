import Foundation
import SwiftUI
import Supabase

// Central data store for every Branch Manager screen. All data is fetched
// from Supabase / the backend on configure() and on each refreshAll() call.
// Mock seeds are preserved only in the DEBUG preview helper at the bottom.
@MainActor
@Observable
final class ManagerStore {

    // MARK: State — Identity

    var managerProfile: OfficerProfileSummary = OfficerProfileSummary(name: "Manager", employeeID: "—", branch: "Branch")
    var branchName: String = "Branch"

    // MARK: State — Applications

    var applications: [ManagerApplication] = []
    var recentActions: [ManagerRecentAction] = []
    var notifications: [OfficerNotification] = []

    var approvedToday: Int = 0
    var rejectedToday: Int = 0
    var approvalRate: Double = 0
    var avgDecisionTime: String = "—"

    var selectedApplicationID: UUID?

    // MARK: State — Portfolio

    var portfolioSummary: PortfolioSummaryData = PortfolioSummaryData(
        totalLoans: 0, totalDisbursement: 0, collectionEfficiency: 0,
        npaRatio: 0, activeLoans: 0, overdueLoans: 0,
        recoveryRate: 0, paidEMIPercent: 0
    )
    var loanCategories: [LoanCategoryBreakdown] = []
    var branchPerformanceItems: [BranchPerformanceItem] = []
    var atRiskPercent: Double = 0

    // MARK: State — Report Data

    var dailyReportData: DailyReportData = DailyReportData(
        loansApproved: 0, totalDisbursedToday: 0, activeLoans: 0,
        emiCollected: 0, pendingCollections: 0, newCustomers: 0, missedPayments: 0
    )
    var weeklyReportData: WeeklyReportData = WeeklyReportData(
        weeklyLoanGrowth: 0, totalRepaymentCollected: 0,
        numberOfDefaults: 0, recoveryPerformance: 0, topPayingCustomers: 0, overdueAccounts: []
    )
    var monthlyReportData: MonthlyReportData = MonthlyReportData(
        monthlyRevenue: 0, totalDistributed: 0, loanRecoveryRate: 0,
        totalProfit: 0, interestEarned: 0, penaltyCollected: 0, processingFees: 0,
        bestPerformingCategory: "—", loanTypeAnalytics: []
    )
    var npaReportData: NPAReportData = NPAReportData(
        totalNPALoans: 0, npaRatio: 0, totalNPAAmount: 0,
        totalOverdueEMIs: 0, overdueAmount: 0,
        criticalAccounts: 0, highRiskAccounts: 0, mediumRiskAccounts: 0
    )

    // MARK: State — Officers

    var officerPerformance: [OfficerPerformanceData] = []

    // MARK: State — Audit

    var auditLogs: [ManagerAuditLogEntry] = []

    // MARK: State — Report History

    var reportHistory: [ReportItem] = []

    // MARK: State — Risk Alerts

    var riskAlerts: [RiskAlert] = []

    // MARK: State — Loan Policies

    var loanPolicies: [LoanPolicyConfig] = []

    // MARK: Private

    private var environment: AppEnvironment?
    private var currentUserID: UUID?
    private var currentUserName: String = "Manager"

    private let supabase = SupabaseManager.shared.client
    private let decoder = SupabaseManager.shared.decoder

    // MARK: Bootstrap

    func configure(environment: AppEnvironment, session: SessionStore) {
        self.environment = environment
        self.currentUserID = session.currentUser?.id
        self.currentUserName = session.currentUser?.fullName ?? "Manager"

        // Set the name immediately; employee ID and branch are fetched in refreshAll()
        managerProfile = OfficerProfileSummary(
            name: currentUserName,
            employeeID: "—",
            branch: "—"
        )

        loadReportHistory()
        Task { await refreshAll() }
    }

    func refreshAll() async {
        guard let environment else { return }

        await loadManagerProfile()
        await loadApplications(environment: environment)
        await loadLoanPolicies(environment: environment)
        await loadRecentDecisions()
        await loadNotifications()
        await loadRiskAlerts()
        await loadOfficerPerformance()
        await loadAuditLogs()
        await loadPortfolioAndReports()
    }

    // MARK: Private — DB decode types

    private struct DBUser: Decodable {
        let id: UUID
        let full_name: String?
        let email: String?
    }

    private struct DBEvent: Decodable {
        let application_id: UUID
        let actor_id: UUID?
        let event_type: String
        let remark: String?
        let created_at: Date
    }

    private struct DBEventWithApp: Decodable {
        struct NestedApp: Decodable {
            struct NestedUser: Decodable { let full_name: String? }
            let id: UUID
            let requested_amount: Decimal?
            let borrower_id: UUID?
            let users: NestedUser?
        }
        let id: UUID
        let application_id: UUID
        let actor_id: UUID?
        let event_type: String
        let remark: String?
        let created_at: Date
        let loan_applications: NestedApp?
    }

    private struct DBLoan: Decodable {
        let id: UUID
        let borrower_id: UUID
        let principal: Decimal
        let outstanding_balance: Decimal
        let status: String
        let disbursement_date: Date?
    }

    private struct DBEMI: Decodable {
        let loan_id: UUID
        let total_amount: Decimal
        let principal_component: Decimal
        let interest_component: Decimal
        let status: String
        let paid_at: Date?
        let due_date: Date
    }

    private struct DBBorrower: Decodable {
        let id: UUID
        let created_at: Date
    }

    private struct DBEMIWithLoan: Decodable {
        struct NestedLoan: Decodable {
            struct NestedApp: Decodable {
                struct NestedUser: Decodable { let full_name: String? }
                let id: UUID
                let users: NestedUser?
            }
            let loan_applications: NestedApp?
        }
        let id: UUID
        let loan_id: UUID
        let total_amount: Decimal
        let due_date: Date
        let loans: NestedLoan?
    }

    private struct DBNotification: Decodable {
        let id: UUID
        let title: String
        let message: String?
        let type: String?
        let is_read: Bool?
        let created_at: Date
    }

    private struct DBStaffProfileRow: Decodable {
        let employee_id: String?
        let branch_id: UUID?
        let department: String?
    }

    private struct DBLoanWithProduct: Decodable {
        struct NestedApp: Decodable {
            struct NestedProduct: Decodable { let name: String? }
            let loan_products: NestedProduct?
        }
        let principal: Decimal
        let loan_applications: NestedApp?
    }

    // MARK: Private — Load: Manager Profile

    private func loadManagerProfile() async {
        guard let userID = currentUserID else { return }
        do {
            let resp = try await supabase
                .from("staff_profiles")
                .select("employee_id, branch_id, department")
                .eq("id", value: userID.uuidString)
                .limit(1)
                .execute()
            let profiles = try decoder.decode([DBStaffProfileRow].self, from: resp.data)
            guard let profile = profiles.first else { return }
            let employeeID = profile.employee_id ?? "—"
            let branch = profile.department ?? "—"
            branchName = branch
            managerProfile = OfficerProfileSummary(
                name: currentUserName,
                employeeID: employeeID,
                branch: branch
            )
        } catch { /* keep existing state */ }
    }

    // MARK: Private — Load: Applications

    private func loadApplications(environment: AppEnvironment) async {
        print("[ManagerStore] loadApplications: starting")
        do {
            let apps = try await environment.loans.fetchApplications(statuses: [
                "submitted", "assigned", "under_review", "document_pending",
                "manager_review",
                "approved", "rejected", "disbursed", "closed"
            ])
            print("[ManagerStore] loadApplications: got \(apps.count) apps")
            guard !apps.isEmpty else { applications = []; return }

            // Batch-fetch the most recent officer remark per application
            let appIDs = apps.map(\.id.uuidString)
            var evalNotes: [UUID: String] = [:]
            let evResp = try await supabase
                .from("loan_application_events")
                .select("application_id, remark, event_type, created_at")
                .in("application_id", values: appIDs)
                .in("event_type", values: ["sent_to_manager", "review_started", "submitted"])
                .order("created_at", ascending: false)
                .execute()
            let events = try decoder.decode([DBEvent].self, from: evResp.data)
            for event in events {
                if evalNotes[event.application_id] == nil,
                   let remark = event.remark, !remark.isEmpty {
                    evalNotes[event.application_id] = remark
                }
            }

            let defaultNote = "Application submitted for manager review."
            applications = apps.map { app in
                let officerName = app.assignedOfficerName ?? "Unassigned"
                let borrowerName = app.borrowerName ?? "Applicant"
                let note = evalNotes[app.id] ?? defaultNote
                return buildManagerApplication(
                    from: app,
                    borrowerName: borrowerName,
                    officerName: officerName,
                    evaluationNote: note
                )
            }
        } catch {
            print("[ManagerStore] loadApplications error: \(error)")
        }
    }

    private func buildManagerApplication(
        from app: LoanApplication,
        borrowerName: String,
        officerName: String,
        evaluationNote: String
    ) -> ManagerApplication {
        let borrowerUser = User(
            id: app.borrowerID,
            fullName: borrowerName,
            email: app.borrowerEmail ?? "",
            phone: "",
            role: .borrower
        )
        let profile = BorrowerProfile(id: app.borrowerID, dateOfBirth: Date(timeIntervalSince1970: 0))
        let officerApp = OfficerApplication(
            application: app,
            borrower: borrowerUser,
            profile: profile,
            employer: "—",
            existingLiabilities: 0,
            purpose: app.productName ?? "Loan application",
            fraudFlag: false
        )
        return ManagerApplication(
            base: officerApp,
            officerName: officerName,
            recommendation: .from(risk: officerApp.riskLevel),
            evaluationNote: evaluationNote
        )
    }

    // MARK: Private — Load: Loan Policies

    private func loadLoanPolicies(environment: AppEnvironment) async {
        do {
            let products = try await environment.loans.fetchLoanProducts()
            loanPolicies = products.map { p in
                LoanPolicyConfig(
                    loanType: p.loanType,
                    interestRateMin: p.minimumInterestRate,
                    interestRateMax: p.maximumInterestRate,
                    maxTenureMonths: p.maximumTenureMonths,
                    maxAmount: p.maximumAmount,
                    minCreditScore: defaultMinCreditScore(for: p.loanType),
                    maxDTIRatio: defaultMaxDTI(for: p.loanType),
                    isActive: p.isActive
                )
            }
        } catch { /* keep existing state */ }
    }

    private func defaultMinCreditScore(for type: LoanType) -> Int {
        switch type {
        case .home: 700; case .personal: 650; case .business: 680
        case .vehicle: 660; case .education: 600
        }
    }

    private func defaultMaxDTI(for type: LoanType) -> Double {
        switch type {
        case .home: 0.50; case .personal: 0.40; case .business: 0.55
        case .vehicle: 0.45; case .education: 0.60
        }
    }

    // MARK: Private — Load: Recent Decisions

    private func loadRecentDecisions() async {
        guard let managerID = currentUserID else { return }
        do {
            let resp = try await supabase
                .from("loan_application_events")
                .select("id, application_id, actor_id, event_type, remark, created_at, loan_applications(id, requested_amount, borrower_id, users:users!loan_applications_borrower_id_fkey(full_name))")
                .eq("actor_id", value: managerID.uuidString)
                .in("event_type", values: ["approved", "rejected", "sent_to_manager"])
                .order("created_at", ascending: false)
                .limit(20)
                .execute()

            let events = try decoder.decode([DBEventWithApp].self, from: resp.data)

            // Resolve borrower names (already embedded in the join)
            recentActions = events.compactMap { event -> ManagerRecentAction? in
                guard let kind = actionKind(from: event.event_type) else { return nil }
                let name = event.loan_applications?.users?.full_name ?? "Applicant"
                let amount = event.loan_applications?.requested_amount.map { Formatting.currency($0) } ?? "—"
                return ManagerRecentAction(
                    kind: kind, name: name, amount: amount,
                    date: event.created_at, applicationID: event.application_id
                )
            }

            let todayStart = Calendar.current.startOfDay(for: .now)
            approvedToday = recentActions.filter { $0.kind == .approve && $0.date >= todayStart }.count
            rejectedToday = recentActions.filter { $0.kind == .reject && $0.date >= todayStart }.count

            // Compute average time from sent_to_manager → manager decision
            let decidedEvents = events.filter { ["approved", "rejected"].contains($0.event_type) }
            if !decidedEvents.isEmpty {
                let decidedIDs = decidedEvents.map(\.application_id.uuidString)
                let stmResp = try? await supabase
                    .from("loan_application_events")
                    .select("application_id, created_at")
                    .in("application_id", values: decidedIDs)
                    .eq("event_type", value: "sent_to_manager")
                    .execute()
                if let data = stmResp?.data,
                   let stmEvents = try? decoder.decode([DBEvent].self, from: data) {
                    var sentAt: [UUID: Date] = [:]
                    for e in stmEvents { sentAt[e.application_id] = e.created_at }
                    let deltas: [Double] = decidedEvents.compactMap { event in
                        guard let sent = sentAt[event.application_id] else { return nil }
                        let hours = event.created_at.timeIntervalSince(sent) / 3600
                        return hours > 0 ? hours : nil
                    }
                    if !deltas.isEmpty {
                        let avg = deltas.reduce(0, +) / Double(deltas.count)
                        avgDecisionTime = avg < 24
                            ? String(format: "%.0fh", avg)
                            : String(format: "%.1f days", avg / 24)
                    }
                }
            }
        } catch { /* keep existing state */ }
    }

    private func actionKind(from eventType: String) -> ApplicationActionType? {
        switch eventType {
        case "approved": .approve
        case "rejected": .reject
        case "sent_back", "returned_to_officer": .sendBack
        default: nil
        }
    }

    // MARK: Private — Load: Notifications

    private func loadNotifications() async {
        guard let userID = currentUserID else { return }
        do {
            let resp = try await supabase
                .from("notifications")
                .select("id, title, message, type, is_read, created_at")
                .eq("user_id", value: userID.uuidString)
                .order("created_at", ascending: false)
                .limit(30)
                .execute()
            let dbNotifs = try decoder.decode([DBNotification].self, from: resp.data)
            notifications = dbNotifs.map { n in
                OfficerNotification(
                    title: n.title,
                    message: n.message ?? "",
                    timestamp: n.created_at,
                    type: notificationType(from: n.type),
                    priority: (n.type == "fraud_alert" || n.type == "pending_approval") ? 1 : 2,
                    isRead: n.is_read ?? false
                )
            }
        } catch { /* notifications table may not exist yet */ }
    }

    private func notificationType(from raw: String?) -> NotificationType {
        switch raw {
        case "fraud_alert": .fraudAlert
        case "pending_approval": .pendingApproval
        case "escalation": .escalation
        default: .system
        }
    }

    // MARK: Private — Load: Risk Alerts (derived from overdue EMIs)

    private func loadRiskAlerts() async {
        do {
            let resp = try await supabase
                .from("emis")
                .select("id, loan_id, total_amount, due_date, loans!inner(loan_applications!inner(id, users:users!loan_applications_borrower_id_fkey(full_name)))")
                .eq("status", value: "overdue")
                .order("due_date", ascending: true)
                .limit(10)
                .execute()
            let dbEMIs = try decoder.decode([DBEMIWithLoan].self, from: resp.data)
            riskAlerts = dbEMIs.map { emi in
                let borrowerName = emi.loans?.loan_applications?.users?.full_name ?? "Borrower"
                let appID = emi.loans?.loan_applications?.id
                let refCode = appID.map {
                    "LN-" + $0.uuidString.replacingOccurrences(of: "-", with: "").prefix(6).uppercased()
                } ?? "LN-UNKNOWN"
                let daysOverdue = Calendar.current.dateComponents([.day], from: emi.due_date, to: .now).day ?? 0
                let severity: RiskAlertSeverity = daysOverdue > 30 ? .critical : daysOverdue > 7 ? .high : .medium
                return RiskAlert(
                    title: "Overdue EMI — \(borrowerName)",
                    message: "EMI of \(Formatting.currency(emi.total_amount)) is \(daysOverdue) day(s) overdue.",
                    severity: severity, loanReferenceCode: refCode,
                    timestamp: emi.due_date, isRead: false
                )
            }
        } catch { /* keep existing state */ }
    }

    // MARK: Private — Load: Officer Performance

    private func loadOfficerPerformance() async {
        do {
            let userResp = try await supabase
                .from("users").select("id, full_name").eq("role", value: "loan_officer").execute()
            let officers = try decoder.decode([DBUser].self, from: userResp.data)
            guard !officers.isEmpty else { officerPerformance = []; return }

            let officerIDs = officers.map(\.id.uuidString)
            let evResp = try await supabase
                .from("loan_application_events")
                .select("id, application_id, actor_id, event_type, created_at, loan_applications(id, requested_amount, borrower_id, users:users!loan_applications_borrower_id_fkey(full_name))")
                .in("actor_id", values: officerIDs)
                .in("event_type", values: ["approved", "rejected", "sent_to_manager", "review_started"])
                .order("created_at", ascending: false)
                .execute()
            let events = try decoder.decode([DBEventWithApp].self, from: evResp.data)

            var eventsByOfficer: [UUID: [DBEventWithApp]] = [:]
            for event in events {
                guard let id = event.actor_id else { continue }
                eventsByOfficer[id, default: []].append(event)
            }

            officerPerformance = officers.map { officer in
                let officerEvents = eventsByOfficer[officer.id] ?? []
                let processed = officerEvents.count
                let forwardedOrApproved = officerEvents.filter {
                    ["approved", "recommended", "sent_to_manager"].contains($0.event_type)
                }.count
                let rate = processed > 0 ? Double(forwardedOrApproved) / Double(processed) : 0

                let recentDecisions = officerEvents.prefix(3).compactMap { event -> OfficerDecisionRecord? in
                    guard let kind = actionKind(from: event.event_type) else { return nil }
                    let name = event.loan_applications?.users?.full_name ?? "Applicant"
                    let amount = event.loan_applications?.requested_amount.map { Formatting.currency($0) } ?? "—"
                    return OfficerDecisionRecord(applicantName: name, amount: amount, action: kind, date: event.created_at)
                }

                let name = officer.full_name ?? "Officer"
                let initials = name.split(separator: " ")
                    .compactMap { $0.first.map(String.init) }.prefix(2).joined().uppercased()
                return OfficerPerformanceData(
                    name: name, initials: initials,
                    applicationsProcessed: processed, approvalRate: rate,
                    avgDecisionTime: "—", recoveryRate: 0,
                    recentDecisions: recentDecisions
                )
            }
        } catch { /* keep existing state */ }
    }

    // MARK: Private — Load: Audit Logs

    private func loadAuditLogs() async {
        guard let managerID = currentUserID else { return }
        do {
            let resp = try await supabase
                .from("loan_application_events")
                .select("id, application_id, actor_id, event_type, created_at, loan_applications(id)")
                .eq("actor_id", value: managerID.uuidString)
                .in("event_type", values: ["approved", "rejected", "sent_to_manager"])
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
            let events = try decoder.decode([DBEventWithApp].self, from: resp.data)
            auditLogs = events.map { event in
                let appID = event.loan_applications?.id ?? event.application_id
                let refCode = "LN-" + appID.uuidString.replacingOccurrences(of: "-", with: "").prefix(6).uppercased()
                let action: String
                switch event.event_type {
                case "approved": action = "Approved"
                case "rejected": action = "Rejected"
                case "sent_back", "returned_to_officer": action = "Sent Back"
                default: action = event.event_type.capitalized
                }
                return ManagerAuditLogEntry(
                    loanReferenceCode: refCode, action: action,
                    managerName: currentUserName, timestamp: event.created_at, status: .completed
                )
            }
        } catch { /* keep existing state */ }
    }

    // MARK: Private — Load: Portfolio & Report Data

    private func loadPortfolioAndReports() async {
        do {
            // Loans — include all fields needed for report computations
            let loanResp = try await supabase
                .from("loans")
                .select("id, borrower_id, principal, outstanding_balance, status, disbursement_date")
                .execute()
            let loans = try decoder.decode([DBLoan].self, from: loanResp.data)

            // EMIs — include interest/principal components for revenue accuracy
            let emisResp = try await supabase
                .from("emis")
                .select("loan_id, total_amount, principal_component, interest_component, status, paid_at, due_date")
                .execute()
            let emis = try decoder.decode([DBEMI].self, from: emisResp.data)

            // Portfolio metrics
            let totalLoans = loans.count
            let activeLoans = loans.filter { $0.status == "active" }.count
            let totalDisbursement = loans.reduce(Decimal(0)) { $0 + $1.principal }
            let paidEMIs = emis.filter { $0.status == "paid" }
            let overdueEMIs = emis.filter { $0.status == "overdue" }
            let paidCount = paidEMIs.count
            let overdueCount = overdueEMIs.count
            let totalEMIs = emis.count
            let collEff = (paidCount + overdueCount) > 0
                ? Double(paidCount) / Double(paidCount + overdueCount) : 0
            let overdueLoansSet = Set(overdueEMIs.map(\.loan_id))
            let overdueLoans = overdueLoansSet.count
            let npaRatio = totalLoans > 0 ? Double(overdueLoans) / Double(totalLoans) : 0
            let paidPct = totalEMIs > 0 ? Double(paidCount) / Double(totalEMIs) : 0

            portfolioSummary = PortfolioSummaryData(
                totalLoans: totalLoans, totalDisbursement: totalDisbursement,
                collectionEfficiency: collEff, npaRatio: npaRatio,
                activeLoans: activeLoans, overdueLoans: overdueLoans,
                recoveryRate: collEff, paidEMIPercent: paidPct
            )

            let approved = recentActions.filter { $0.kind == .approve }.count
            let rejected = recentActions.filter { $0.kind == .reject }.count
            let decisionTotal = approved + rejected
            approvalRate = decisionTotal > 0 ? Double(approved) / Double(decisionTotal) : 0

            let now = Date.now
            let atRiskLoans = Set(overdueEMIs.compactMap { emi -> UUID? in
                let days = Calendar.current.dateComponents([.day], from: emi.due_date, to: now).day ?? 0
                return (days > 0 && days <= 30) ? emi.loan_id : nil
            })
            atRiskPercent = totalLoans > 0 ? Double(atRiskLoans.count) / Double(totalLoans) : 0

            branchPerformanceItems = [
                BranchPerformanceItem(
                    branchName: branchName, approvalRate: approvalRate,
                    avgDecisionTime: avgDecisionTime,
                    totalApplications: applications.count, npaRatio: npaRatio
                )
            ]

            // Loan category breakdown via product names
            let loanProdResp = try await supabase
                .from("loans")
                .select("principal, loan_applications!inner(loan_products!inner(name))")
                .execute()
            let loansWithProd = try decoder.decode([DBLoanWithProduct].self, from: loanProdResp.data)
            var catMap: [LoanType: (Int, Decimal)] = [:]
            for loan in loansWithProd {
                let lt = loanType(fromProductName: loan.loan_applications?.loan_products?.name)
                catMap[lt, default: (0, 0)].0 += 1
                catMap[lt, default: (0, 0)].1 += loan.principal
            }
            let totalAmt = catMap.values.reduce(Decimal(0)) { $0 + $1.1 }
            loanCategories = catMap.map { type, data in
                let pct = totalAmt > 0
                    ? NSDecimalNumber(decimal: data.1 / totalAmt).doubleValue : 0
                return LoanCategoryBreakdown(loanType: type, count: data.0, amount: data.1, percentage: pct)
            }.sorted { $0.amount > $1.amount }

            // Build a map from loan_id → borrower_id for top-payer computations
            let loanBorrowerMap: [UUID: UUID] = loans.reduce(into: [:]) {
                $0[$1.id] = $1.borrower_id
            }

            // ── Daily ────────────────────────────────────────────────────
            let todayStart = Calendar.current.startOfDay(for: .now)
            let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: .now)

            let disbursedToday = loans.filter {
                guard let d = $0.disbursement_date else { return false }
                let dc = Calendar.current.dateComponents([.year, .month, .day], from: d)
                return dc.year == todayComponents.year
                    && dc.month == todayComponents.month
                    && dc.day == todayComponents.day
            }
            let totalDisbursedToday = disbursedToday.reduce(Decimal(0)) { $0 + $1.principal }

            let todayPaid = paidEMIs.filter { ($0.paid_at ?? .distantPast) >= todayStart }
            let emiCollectedToday = todayPaid.reduce(Decimal(0)) { $0 + $1.total_amount }

            // All outstanding overdue (full overdue book — relevant for daily snapshot)
            let pendingCollections = overdueEMIs.reduce(Decimal(0)) { $0 + $1.total_amount }

            // EMIs due today that are not yet paid
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: todayStart)!
            let dueToday = emis.filter { $0.due_date >= todayStart && $0.due_date < tomorrow }
            let missedToday = dueToday.filter { $0.status != "paid" }.count

            // New borrowers registered today
            var newCustomers = 0
            if let borrowerResp = try? await supabase
                .from("users")
                .select("id, created_at")
                .eq("role", value: "borrower")
                .gte("created_at", value: ISO8601DateFormatter().string(from: todayStart))
                .execute(),
               let borrowers = try? decoder.decode([DBBorrower].self, from: borrowerResp.data) {
                newCustomers = borrowers.count
            }

            dailyReportData = DailyReportData(
                loansApproved: disbursedToday.count,
                totalDisbursedToday: totalDisbursedToday,
                activeLoans: activeLoans,
                emiCollected: emiCollectedToday,
                pendingCollections: pendingCollections,
                newCustomers: newCustomers,
                missedPayments: missedToday
            )

            // ── Weekly ───────────────────────────────────────────────────
            let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
            let prevWeekStart = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now

            let thisWeekDisb = loans.filter {
                guard let d = $0.disbursement_date else { return false }
                return d >= weekStart
            }.count
            let prevWeekDisb = loans.filter {
                guard let d = $0.disbursement_date else { return false }
                return d >= prevWeekStart && d < weekStart
            }.count
            let weeklyGrowth: Double = prevWeekDisb > 0
                ? Double(thisWeekDisb - prevWeekDisb) / Double(prevWeekDisb) * 100
                : (thisWeekDisb > 0 ? 100.0 : 0.0)

            let weekPaid = paidEMIs.filter { ($0.paid_at ?? .distantPast) >= weekStart }
            let weekCollected = weekPaid.reduce(Decimal(0)) { $0 + $1.total_amount }
            let weekOverdue = overdueEMIs.filter { $0.due_date >= weekStart }.count
            let weekDue = emis.filter { $0.due_date >= weekStart }.count
            let weekRecovery = weekDue > 0 ? Double(weekPaid.count) / Double(weekDue) * 100 : 0

            let topPayerIDs = Set(weekPaid.compactMap { loanBorrowerMap[$0.loan_id] })

            let overdueSnapshots = riskAlerts.prefix(5).map {
                OverdueAccountSnapshot(id: $0.id, title: $0.title, loanReferenceCode: $0.loanReferenceCode)
            }

            weeklyReportData = WeeklyReportData(
                weeklyLoanGrowth: weeklyGrowth,
                totalRepaymentCollected: weekCollected,
                numberOfDefaults: weekOverdue,
                recoveryPerformance: weekRecovery,
                topPayingCustomers: topPayerIDs.count,
                overdueAccounts: Array(overdueSnapshots)
            )

            // ── Monthly ──────────────────────────────────────────────────
            let monthStart = Calendar.current.date(
                from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
            let monthPaid = paidEMIs.filter { ($0.paid_at ?? .distantPast) >= monthStart }
            let monthDue = emis.filter { $0.due_date >= monthStart }.count
            let monthRecovery = monthDue > 0 ? Double(monthPaid.count) / Double(monthDue) * 100 : 0

            // Revenue = interest collected, not total EMI amount (avoids inflating with principal)
            let interestEarned = monthPaid.reduce(Decimal(0)) { $0 + $1.interest_component }
            let monthlyRevenue = interestEarned  // best signal from available data
            let totalProfit = interestEarned       // no separate expense data available

            let bestCat = loanCategories.first?.loanType.rawValue.capitalized.appending(" Loans") ?? "—"
            let analytics = loanCategories.prefix(3).map { cat in
                LoanTypeAnalytics(id: UUID(), loanType: cat.loanType, percentage: cat.percentage * 100)
            }
            monthlyReportData = MonthlyReportData(
                monthlyRevenue: monthlyRevenue, totalDistributed: totalDisbursement,
                loanRecoveryRate: monthRecovery, totalProfit: totalProfit,
                interestEarned: interestEarned, penaltyCollected: 0, processingFees: 0,
                bestPerformingCategory: bestCat, loanTypeAnalytics: Array(analytics)
            )

            // ── NPA ──────────────────────────────────────────────────────
            let overdueWithDays = overdueEMIs.map { emi -> (DBEMI, Int) in
                let days = Calendar.current.dateComponents([.day], from: emi.due_date, to: now).day ?? 0
                return (emi, max(0, days))
            }
            let criticalAccounts = overdueWithDays.filter { $0.1 > 90 }.count
            let highRiskAccounts = overdueWithDays.filter { $0.1 > 30 && $0.1 <= 90 }.count
            let mediumRiskAccounts = overdueWithDays.filter { $0.1 > 0 && $0.1 <= 30 }.count
            let overdueAmount = overdueEMIs.reduce(Decimal(0)) { $0 + $1.total_amount }
            let npaLoansAmount = loans
                .filter { overdueLoansSet.contains($0.id) }
                .reduce(Decimal(0)) { $0 + $1.outstanding_balance }

            npaReportData = NPAReportData(
                totalNPALoans: overdueLoans,
                npaRatio: npaRatio,
                totalNPAAmount: npaLoansAmount,
                totalOverdueEMIs: overdueEMIs.count,
                overdueAmount: overdueAmount,
                criticalAccounts: criticalAccounts,
                highRiskAccounts: highRiskAccounts,
                mediumRiskAccounts: mediumRiskAccounts
            )
        } catch { /* keep existing state */ }
    }

    private func loanType(fromProductName name: String?) -> LoanType {
        let n = (name ?? "").lowercased()
        if n.contains("home") { return .home }
        if n.contains("business") { return .business }
        if n.contains("vehicle") || n.contains("auto") || n.contains("car") { return .vehicle }
        if n.contains("education") || n.contains("student") { return .education }
        return .personal
    }


    // MARK: Derived — Applications

    func application(id: UUID) -> ManagerApplication? {
        applications.first { $0.id == id }
    }

    var pendingReviewCount: Int {
        applications.filter { $0.status == .submitted || $0.status == .underReview }.count
    }

    var sentBackCount: Int {
        applications.filter { $0.status == .additionalInfoRequired }.count
    }

    var highRiskCount: Int {
        applications.filter { $0.riskLevel == .high }.count
    }

    var escalatedCount: Int {
        applications.filter { $0.status == .escalated }.count
    }

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var urgentNotifications: [OfficerNotification] {
        notifications.filter { $0.priority == 1 && !$0.isRead }
    }

    var approvalRateText: String { Formatting.percent(approvalRate, fractionDigits: 0) }

    var greetingDateText: String {
        "Today, " + Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    // MARK: Derived — Risk Alerts

    var unreadRiskAlertCount: Int {
        riskAlerts.filter { !$0.isRead }.count
    }

    // MARK: Derived — Reports

    var reportsStorageSizeString: String {
        var bytes: Double = 0
        for report in reportHistory where report.status == .completed {
            let parts = report.size.split(separator: " ")
            if parts.count == 2, let val = Double(parts[0]) {
                switch parts[1].uppercased() {
                case "GB": bytes += val * 1024 * 1024 * 1024
                case "MB": bytes += val * 1024 * 1024
                case "KB": bytes += val * 1024
                default: bytes += val
                }
            }
        }
        if bytes == 0 { return "0 KB" }
        if bytes >= 1024 * 1024 * 1024 { return String(format: "%.1f GB", bytes / (1024 * 1024 * 1024)) }
        if bytes >= 1024 * 1024 { return String(format: "%.1f MB", bytes / (1024 * 1024)) }
        return String(format: "%.0f KB", bytes / 1024)
    }

    // MARK: Mutations — Decisions

    func decide(_ action: ApplicationActionType, on application: ManagerApplication, remarks: String?) {
        guard let idx = applications.firstIndex(where: { $0.id == application.id }) else { return }
        let existing = applications[idx]
        var updatedApp = existing.base.application
        updatedApp.status = action.resultStatus
        updatedApp.updatedAt = .now

        let rebased = OfficerApplication(
            application: updatedApp,
            borrower: existing.base.borrower,
            profile: existing.base.profile,
            employer: existing.base.employer,
            existingLiabilities: existing.base.existingLiabilities,
            purpose: existing.base.purpose,
            fraudFlag: existing.base.fraudFlag
        )
        applications[idx] = ManagerApplication(
            base: rebased, officerName: existing.officerName,
            recommendation: existing.recommendation, evaluationNote: existing.evaluationNote
        )

        recentActions.insert(
            ManagerRecentAction(kind: action, name: existing.borrowerName,
                                amount: existing.amountText, date: .now,
                                applicationID: existing.id),
            at: 0
        )
        switch action {
        case .approve: approvedToday += 1
        case .reject: rejectedToday += 1
        case .sendBack: break
        }

        auditLogs.insert(
            ManagerAuditLogEntry(
                loanReferenceCode: existing.referenceCode, action: action.verb,
                managerName: currentUserName, timestamp: .now, status: .completed
            ),
            at: 0
        )

        if let environment {
            Task {
                try? await environment.loans.updateStatus(
                    applicationID: updatedApp.id, to: action.resultStatus, note: remarks
                )
            }
        }
    }

    func disburseLoan(application: ManagerApplication) {
        guard let idx = applications.firstIndex(where: { $0.id == application.id }) else { return }
        let existing = applications[idx]
        var updatedApp = existing.base.application
        updatedApp.status = .disbursed
        updatedApp.updatedAt = .now

        let rebased = OfficerApplication(
            application: updatedApp,
            borrower: existing.base.borrower,
            profile: existing.base.profile,
            employer: existing.base.employer,
            existingLiabilities: existing.base.existingLiabilities,
            purpose: existing.base.purpose,
            fraudFlag: existing.base.fraudFlag
        )
        applications[idx] = ManagerApplication(
            base: rebased, officerName: existing.officerName,
            recommendation: existing.recommendation, evaluationNote: existing.evaluationNote
        )

        auditLogs.insert(
            ManagerAuditLogEntry(
                loanReferenceCode: existing.referenceCode, action: "Disbursed",
                managerName: currentUserName, timestamp: .now, status: .completed
            ),
            at: 0
        )

        if let environment {
            Task {
                try? await environment.loans.disburseLoan(applicationID: updatedApp.id)
            }
        }
    }

    // MARK: Mutations — Notifications

    func markAllNotificationsRead() {
        for i in notifications.indices { notifications[i].isRead = true }
    }

    func markNotificationRead(_ notification: OfficerNotification) {
        guard let idx = notifications.firstIndex(of: notification) else { return }
        notifications[idx].isRead = true
    }

    func dismissNotification(_ notification: OfficerNotification) {
        notifications.removeAll { $0.id == notification.id }
    }

    // MARK: Mutations — Reports

    func generateReport(type: ReportKind, format: ReportFormat) {
        let name: String
        switch type {
        case .daily:   name = "Daily Report — \(Date.now.formatted(.dateTime.month().day()))"
        case .weekly:  name = "Weekly Report — W\(Calendar.current.component(.weekOfYear, from: .now))"
        case .monthly: name = "Monthly Report — \(Date.now.formatted(.dateTime.month(.wide)))"
        case .npa:     name = "NPA Analysis — \(Date.now.formatted(.dateTime.month(.abbreviated).year()))"
        case .collectionEfficiency: name = "Collection Report — \(Date.now.formatted(.dateTime.month(.abbreviated)))"
        }

        let snapshot: ReportSnapshot = switch type {
        case .daily:              .daily(dailyReportData)
        case .weekly:             .weekly(weeklyReportData)
        case .monthly:            .monthly(monthlyReportData)
        case .npa:                .npa(npaReportData)
        case .collectionEfficiency: .weekly(weeklyReportData)
        }

        let report = ReportItem(name: name, type: type, format: format,
                                size: "—", generatedAt: .now, status: .generating,
                                snapshot: snapshot)
        reportHistory.insert(report, at: 0)
        saveReportHistory()

        let reportID = report.id
        Task {
            do {
                let url = try await Task.detached(priority: .userInitiated) {
                    switch format {
                    case .pdf: return try ReportGenerator.generatePDF(snapshot: snapshot, name: name)
                    case .csv: return try ReportGenerator.generateCSV(snapshot: snapshot, name: name)
                    }
                }.value

                let bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
                let sizeStr = ReportGenerator.formatFileSize(bytes)

                if let idx = reportHistory.firstIndex(where: { $0.id == reportID }) {
                    reportHistory[idx] = ReportItem(
                        id: reportID, name: name, type: type, format: format,
                        size: sizeStr, generatedAt: reportHistory[idx].generatedAt,
                        status: .completed, snapshot: snapshot, fileName: url.lastPathComponent
                    )
                    saveReportHistory()
                }
            } catch {
                if let idx = reportHistory.firstIndex(where: { $0.id == reportID }) {
                    reportHistory[idx].status = .failed
                    saveReportHistory()
                }
            }
        }
    }

    func deleteReport(_ report: ReportItem) {
        if let url = report.fileURL {
            try? FileManager.default.removeItem(at: url)
        }
        reportHistory.removeAll { $0.id == report.id }
        saveReportHistory()
    }

    func clearOldReports() {
        let cutoff = Date.now.addingTimeInterval(-60 * 60 * 24 * 90)
        let old = reportHistory.filter { $0.generatedAt < cutoff }
        for report in old {
            if let url = report.fileURL { try? FileManager.default.removeItem(at: url) }
        }
        reportHistory.removeAll { $0.generatedAt < cutoff }
        saveReportHistory()
    }

    // MARK: Report Persistence

    private var reportHistoryURL: URL {
        ReportGenerator.reportsDirectory.appendingPathComponent("history.json")
    }

    private func saveReportHistory() {
        guard let data = try? JSONEncoder().encode(reportHistory) else { return }
        try? data.write(to: reportHistoryURL)
    }

    private func loadReportHistory() {
        guard let data = try? Data(contentsOf: reportHistoryURL),
              let history = try? JSONDecoder().decode([ReportItem].self, from: data) else { return }
        // Drop any in-flight items that never completed (app was killed mid-generation)
        reportHistory = history.filter { $0.status != .generating }
    }

    // MARK: Mutations — Risk Alerts

    func markRiskAlertRead(_ alert: RiskAlert) {
        guard let idx = riskAlerts.firstIndex(where: { $0.id == alert.id }) else { return }
        riskAlerts[idx].isRead = true
    }

    func dismissRiskAlert(_ alert: RiskAlert) {
        riskAlerts.removeAll { $0.id == alert.id }
    }

    // MARK: Mutations — Loan Policies

    func updatePolicy(_ policy: LoanPolicyConfig) {
        guard let idx = loanPolicies.firstIndex(where: { $0.id == policy.id }) else { return }
        loanPolicies[idx] = policy
        auditLogs.insert(
            ManagerAuditLogEntry(
                loanReferenceCode: "POLICY-\(policy.loanType.rawValue.uppercased())",
                action: "Policy Updated", managerName: currentUserName,
                timestamp: .now, status: .completed
            ),
            at: 0
        )
    }

#if DEBUG
    static var preview: ManagerStore {
        let store = ManagerStore()
        store.applications = MockManagerData.applications()
        store.recentActions = MockManagerData.recentActions()
        store.notifications = MockManagerData.notifications()
        store.officerPerformance = MockManagerData.officerPerformance()
        store.auditLogs = MockManagerData.auditLogs()
        store.reportHistory = MockManagerData.reportHistory()
        store.riskAlerts = MockManagerData.riskAlerts()
        store.loanPolicies = MockManagerData.loanPolicies()
        store.dailyReportData = MockManagerData.dailyReportData()
        store.weeklyReportData = MockManagerData.weeklyReportData()
        store.monthlyReportData = MockManagerData.monthlyReportData()
        store.npaReportData = MockManagerData.npaReportData()
        store.portfolioSummary = MockManagerData.portfolioSummary()
        store.loanCategories = MockManagerData.loanCategories()
        store.branchPerformanceItems = MockManagerData.branchPerformance()
        return store
    }
#endif
}
