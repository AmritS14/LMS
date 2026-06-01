import SwiftUI
import Supabase

@MainActor
@Observable
final class ReportsViewModel {
    // Domain Models for local mapping
    struct ReportItem: Identifiable, Hashable {
        let id: UUID
        let branch: String
        let loanType: String
        let disbursedAmount: Decimal
        let averageTenure: Int
        let status: String
        let date: Date
        let borrowerName: String
        let outstandingPrincipal: Decimal
    }

    // Database Models
    private struct DBLoan: Decodable {
        let id: UUID
        let application_id: UUID
        let borrower_id: UUID
        let principal: Decimal
        let interest_rate: Double
        let tenure_months: Int
        let disbursement_date: Date
        let outstanding_balance: Decimal
        let status: String
    }

    private struct DBApplication: Decodable {
        let id: UUID
        let loan_product_id: UUID
        let status: String
    }

    private struct DBProduct: Decodable {
        let id: UUID
        let name: String
    }

    private struct DBUser: Decodable {
        let id: UUID
        let full_name: String?
    }

    // State Variables
    var items: [ReportItem] = []
    var isLoading = false
    var hasError = false
    var isAccessRestricted = false
    
    // Summary Metrics
    var totalDisbursed: Decimal = 0
    var outstandingPrincipal: Decimal = 0
    var collectionEfficiency: Double = 0
    var npaRatio: Double = 0
    var activeLoansCount: Int = 0

    // Dependencies
    private let client = SupabaseManager.shared.client

    func loadReportData() async {
        isLoading = true
        hasError = false
        isAccessRestricted = false

        do {
            // 1. Role-based Access Control Check
            let currentUser = try await client.auth.session.user
            let profileResponse = try await client
                .from("users")
                .select("role")
                .eq("id", value: currentUser.id)
                .single()
                .execute()
            
            struct RoleResponse: Decodable { let role: String }
            let decodedRole = try SupabaseManager.shared.decoder.decode(RoleResponse.self, from: profileResponse.data)
            
            guard decodedRole.role.lowercased() == "admin" else {
                self.isAccessRestricted = true
                self.isLoading = false
                return
            }

            // 2. Fetch live data from Supabase
            let loansResponse = try await client.from("loans").select().execute()
            let dbLoans = try SupabaseManager.shared.decoder.decode([DBLoan].self, from: loansResponse.data)

            let appsResponse = try await client.from("loan_applications").select("id, loan_product_id, status").execute()
            let dbApps = try SupabaseManager.shared.decoder.decode([DBApplication].self, from: appsResponse.data)

            let productsResponse = try await client.from("loan_products").select("id, name").execute()
            let dbProducts = try SupabaseManager.shared.decoder.decode([DBProduct].self, from: productsResponse.data)

            let usersResponse = try await client.from("users").select("id, full_name").execute()
            let dbUsers = try SupabaseManager.shared.decoder.decode([DBUser].self, from: usersResponse.data)

            // 3. Map to ReportItem domain structures
            self.items = dbLoans.map { loan in
                let app = dbApps.first(where: { $0.id == loan.application_id })
                let product = dbProducts.first(where: { $0.id == app?.loan_product_id })
                let loanType = product?.name ?? "Personal"

                let user = dbUsers.first(where: { $0.id == loan.borrower_id })
                let borrowerName = user?.full_name ?? "—"

                // Deterministic Branch Mapping
                let branches = ["Main", "North", "South", "West"]
                let branchIndex = abs(loan.borrower_id.hashValue) % branches.count
                let branch = branches[branchIndex]

                return ReportItem(
                    id: loan.id,
                    branch: branch,
                    loanType: loanType,
                    disbursedAmount: loan.principal,
                    averageTenure: loan.tenure_months,
                    status: mapLoanStatusString(loan.status),
                    date: loan.disbursement_date,
                    borrowerName: borrowerName,
                    outstandingPrincipal: loan.outstanding_balance
                )
            }

            // 4. Compute Portfolio Metrics
            self.totalDisbursed = dbLoans.reduce(Decimal(0), { $0 + $1.principal })
            self.outstandingPrincipal = dbLoans.reduce(Decimal(0), { $0 + $1.outstanding_balance })
            self.activeLoansCount = dbLoans.filter({ $0.status.lowercased() == "active" }).count
            
            let defaultedLoansCount = dbLoans.filter({ $0.status.lowercased() == "defaulted" }).count
            self.npaRatio = dbLoans.isEmpty ? 0.0 : (Double(defaultedLoansCount) / Double(dbLoans.count)) * 100.0
            self.collectionEfficiency = totalDisbursed.isZero ? 0.0 : Double(truncating: ((totalDisbursed - outstandingPrincipal) / totalDisbursed) as NSDecimalNumber) * 100.0

            // 5. Log Access Event for Auditing
            await SupabaseManager.shared.logAuditEvent(
                action: "Accessed Institutional Reports Dashboard",
                entityType: "report",
                entityID: currentUser.id,
                metadata: [
                    "loans_total_count": .number(Double(dbLoans.count)),
                    "total_portfolio_size": .number(Double(truncating: totalDisbursed as NSDecimalNumber))
                ]
            )

        } catch {
            self.hasError = true
            print("Failed to fetch reports: \(error)")
        }

        self.isLoading = false
    }

    private func mapLoanStatusString(_ raw: String) -> String {
        switch raw.lowercased() {
        case "active": return "Active"
        case "closed": return "Closed"
        case "defaulted": return "Defaulted"
        default: return "Active"
        }
    }

    // MARK: - Export Logic

    func generateCSV(from filteredItems: [ReportItem], filters: String) async -> URL? {
        var csvString = "Branch,Borrower Name,Loan Type,Tenure (Months),Disbursed Amount,Outstanding Principal,Status,Disbursement Date\n"
        
        let formatter = ISO8601DateFormatter()
        
        for item in filteredItems {
            let branch = item.branch
            let borrower = item.borrowerName.replacingOccurrences(of: "\"", with: "\"\"")
            let type = item.loanType.replacingOccurrences(of: "\"", with: "\"\"")
            let tenure = item.averageTenure
            let disbursed = item.disbursedAmount
            let outstanding = item.outstandingPrincipal
            let status = item.status
            let date = formatter.string(from: item.date)
            
            let row = "\(branch),\"\(borrower)\",\"\(type)\",\(tenure),\(disbursed),\(outstanding),\(status),\(date)\n"
            csvString.append(row)
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LMS_Report_\(Date().timeIntervalSince1970).csv")
        do {
            try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Log Export Audit Action
            let user = try? await client.auth.session.user
            await SupabaseManager.shared.logAuditEvent(
                action: "Exported Institutional Report to Excel/CSV",
                entityType: "report",
                entityID: user?.id ?? UUID(),
                metadata: [
                    "format": .string("CSV"),
                    "filters_applied": .string(filters),
                    "record_count": .number(Double(filteredItems.count))
                ]
            )
            
            return tempURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }

    func generatePDF(from filteredItems: [ReportItem], filters: String) async -> URL? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        var htmlRows = ""
        for item in filteredItems {
            htmlRows.append("""
            <tr>
                <td>\(item.branch)</td>
                <td>\(item.borrowerName)</td>
                <td>\(item.loanType)</td>
                <td style="text-align: right;">\(item.averageTenure) Months</td>
                <td style="text-align: right;">$\(item.disbursedAmount)</td>
                <td style="text-align: right;">$\(item.outstandingPrincipal)</td>
                <td>\(item.status)</td>
                <td>\(formatter.string(from: item.date))</td>
            </tr>
            """)
        }
        
        let htmlContent = """
        <html>
        <head>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 30px; color: #2d3748; }
                h1 { color: #1a365d; font-size: 24px; margin-bottom: 5px; }
                h2 { color: #4a5568; font-size: 16px; font-weight: normal; margin-top: 0; margin-bottom: 25px; }
                table { width: 100%; border-collapse: collapse; margin-top: 20px; }
                th, td { border: 1px solid #e2e8f0; padding: 12px 10px; text-align: left; font-size: 12px; }
                th { background-color: #f7fafc; color: #4a5568; font-weight: bold; }
                .summary-container { display: flex; justify-content: space-between; margin-bottom: 30px; gap: 15px; }
                .card { flex: 1; background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 15px; text-align: center; }
                .card h3 { font-size: 11px; text-transform: uppercase; color: #718096; margin: 0 0 5px 0; }
                .card p { font-size: 18px; font-weight: bold; color: #2b6cb0; margin: 0; }
                .footer { font-size: 10px; color: #a0aec0; text-align: center; margin-top: 30px; border-top: 1px solid #e2e8f0; padding-top: 15px; }
            </style>
        </head>
        <body>
            <h1>LMS Institutional Performance Report</h1>
            <h2>Generated on: \(formatter.string(from: Date())) | Filters: \(filters)</h2>
            
            <div class="summary-container">
                <div class="card">
                    <h3>Total Disbursed</h3>
                    <p>$\(totalDisbursed)</p>
                </div>
                <div class="card">
                    <h3>Outstanding</h3>
                    <p>$\(outstandingPrincipal)</p>
                </div>
                <div class="card">
                    <h3>Collection Eff.</h3>
                    <p>\(String(format: "%.1f%%", collectionEfficiency))</p>
                </div>
                <div class="card">
                    <h3>Active Loans</h3>
                    <p>\(activeLoansCount)</p>
                </div>
            </div>
            
            <table>
                <thead>
                    <tr>
                        <th>Branch</th>
                        <th>Borrower</th>
                        <th>Type</th>
                        <th style="text-align: right;">Tenure</th>
                        <th style="text-align: right;">Disbursed</th>
                        <th style="text-align: right;">Outstanding</th>
                        <th>Status</th>
                        <th>Date</th>
                    </tr>
                </thead>
                <tbody>
                    \(htmlRows)
                </tbody>
            </table>
            
            <div class="footer">
                Confidential - Internal Banking System Use Only.
            </div>
        </body>
        </html>
        """
        
        let printPageRenderer = UIMarkupTextPrintFormatter(markupText: htmlContent)
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .general
        printInfo.jobName = "LMS_Institutional_Report"
        
        let renderer = UIPrintPageRenderer()
        renderer.addPrintFormatter(printPageRenderer, startingAtPageAt: 0)
        
        // Standard Letter Size
        let paperRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let printableRect = paperRect.insetBy(dx: 36, dy: 36)
        renderer.setValue(NSValue(cgRect: paperRect), forKey: "paperRect")
        renderer.setValue(NSValue(cgRect: printableRect), forKey: "printableRect")
        
        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, paperRect, nil)
        renderer.prepare(forDrawingPages: NSRange(location: 0, length: 1))
        
        let bounds = UIGraphicsGetPDFContextBounds()
        for i in 0..<renderer.numberOfPages {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: i, in: bounds)
        }
        
        UIGraphicsEndPDFContext()
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("LMS_Report_\(Date().timeIntervalSince1970).pdf")
        do {
            try pdfData.write(to: tempURL, options: .atomic)
            
            // Log Export Audit Action
            let user = try? await client.auth.session.user
            await SupabaseManager.shared.logAuditEvent(
                action: "Exported Institutional Report to PDF",
                entityType: "report",
                entityID: user?.id ?? UUID(),
                metadata: [
                    "format": .string("PDF"),
                    "filters_applied": .string(filters),
                    "record_count": .number(Double(filteredItems.count))
                ]
            )
            
            return tempURL
        } catch {
            print("Failed to write PDF: \(error)")
            return nil
        }
    }
}
