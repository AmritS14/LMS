# Audit Remediation Status

Based on `codebase_audit_report.md`. Last updated: 2026-06-03.

---

## ✅ Addressed

### Mock Data / Production Hygiene

| File | Issue | Fix |
|------|-------|-----|
| `BorrowerApp/App/BorrowerApp.swift` | `MockNotificationService()` injected in production | Replaced with `NoOpNotificationService` (requests real OS auth, returns empty history) |
| `StaffApp/App/StaffApp.swift` | `MockNotificationService()` injected in production | Same — replaced with `NoOpNotificationService` |
| `Shared/AppEnvironment.swift` | `admin` and `aadhaarKYC` params defaulted to mock services | Removed defaults; both are now required params — callers must be explicit |
| `BorrowerApp/App/RootView.swift` | `"mock_device_token"` hardcoded for APNs registration | Removed fake token registration; only OS auth prompt remains |
| `BorrowerApp/Views/LoginView.swift` | `"Demo OTP: 123456"` visible in production UI | Removed; also fixed pre-existing `return` in `@ViewBuilder` in preview |
| `StaffApp/Views/Manager/ApproveModalView.swift` | Remarks pre-filled with `"Excellent credit profile, approved for full amount."` | Changed default to `""` |
| `StaffApp/Views/Admin/ProfileView.swift` | Header hardcoded `"Sarah Jenkins"` / `"SYSTEM ADMIN"` | Now reads `session.currentUser.fullName` and `session.role.displayName` |
| `StaffApp/Views/Admin/ProfileView.swift` `PersonalInfoView` | All fields hardcoded (name, email, phone, employee ID, department) | Seeded from `session.currentUser` and `session.staffProfile` on appear |
| `StaffApp/Views/LoanOfficer/LoanOfficerProfileView.swift` | `"₹45.8 Cr"` disbursed value, `"BR-MUM-01"`, `"Anil Deshmukh"`, full address hardcoded | Replaced all with `"—"` placeholders; removed `"Industry avg: 65%"` subtitle |
| `StaffApp/App/StaffRootView.swift` | `print("[DEBUG] manager .task fired…")` in production path | Removed |

### Broken Backend / Logic

| File | Issue | Fix |
|------|-------|-----|
| `Shared/Services/Supabase/SupabaseManager.swift` | `logAuditEvent` always wrote `actor_role: "admin"` | Now queries the `users` table to resolve the real role; accepts optional `actorRole` override |
| `Shared/Services/Supabase/SupabaseAdminService.swift` | All `logAuditEvent` calls omitted role | Updated all 4 callers to pass `actorRole: "admin"` explicitly |
| `StaffApp/Views/LoanOfficer/LOAppViewModel.swift` | `emiAmount = amount / tenure` (no interest) | Replaced with proper reducing-balance formula: `P×r×(1+r)^n / ((1+r)^n−1)` |
| `StaffApp/Views/LoanOfficer/LOAppViewModel.swift` | `eligibilityScore = creditScore > 700 ? 85 : 50` | Replaced with credit-score tier + DTI ratio computation |
| `StaffApp/Views/LoanOfficer/ChatView.swift` | `sendMessage()` only printed to console; messages discarded | Wired to `AppViewModel.sendOfficerMessage(_:to:)` which updates local state and calls `MessagingService.send(_:)` |
| `StaffApp/Views/LoanOfficer/LOModels.swift` | `BorrowerConversation` had no `threadID` field | Added `var threadID: UUID?`; populated from `MessageThread.id` during refresh |
| `StaffApp/Views/LoanOfficer/LOAppViewModel.swift` | Conversations built from threads didn't carry `threadID` | `threadID: thread.id` now set when building each `BorrowerConversation` |
| `StaffApp/Views/Admin/ArchiveListView.swift` | `viewModel.configure()` and `viewModel.load()` never called — list always empty | Added `.task` to call both on appear; wired `viewModel.isLoading` / `viewModel.error` to UI state |
| `BorrowerApp/Views/UpdatePasswordView.swift` | After backend `signOut()`, `SessionStore` was never cleared | Now calls `env.auth.signOut()` via DI and sets `session.currentUser = nil` |
| `Shared/Services/Supabase/SupabaseLoanService.swift` | `fetchActiveLoans` made 2N+1 queries (per-loan EMI + loan-type fetches) | Refactored to 3 queries total: batch EMI fetch with `.in("loan_id")` + batch app-product fetch |
| `Shared/Services/Supabase/NoOpNotificationService.swift` | No production notification service existed | Created `NoOpNotificationService`: real OS auth request, no fake history data |

---

## ❌ Outstanding

### Critical / High Priority

| File | Issue |
|------|-------|
| `Shared/Services/Supabase/SupabaseLoanService.swift` | `submitApplication` throws `"Not implemented"` — loan submission via the backend API is broken |
| `Shared/Services/Supabase/SupabaseAuthService.swift` | `requestOTP` and `verifyOTP` both throw `"not implemented"` — phone OTP flow is non-functional |
| `Shared/Services/Supabase/SupabaseAuthService.swift` | `signInWithPasskey` throws `URLError(.unsupportedURL)` — not a meaningful error |
| `Shared/Services/Supabase/SupabaseLoanService.swift` | `forecloseLoan` performs direct client-side DB mutations (loans + emis tables) with no backend API, no transaction, no auth check — critical for a financial operation |
| `Shared/Services/Supabase/SupabaseAdminService.swift` | `updateUserRole` and `updateUserStatus` mutate the `users` table directly, bypassing backend authorization |
| `Shared/Services/Supabase/SupabaseAdminService.swift` | `archiveLoan` / `restoreLoan` mutate `loans` table directly; restore arbitrarily sets status to `"active"` |
| `StaffApp/Views/Admin/AdminFeatureModels.swift` | `deleteUser()` removes user from local array only — no backend API call |
| `StaffApp/Views/Admin/AdminFeatureModels.swift` | `updatePermissions()` updates local dict only — no backend persistence |
| `StaffApp/Views/Admin/AdminFeatureModels.swift` | `TemplateViewModel.createTemplate/updateTemplate/deleteTemplates` are all in-memory only — templates lost on restart |
| `StaffApp/Views/Admin/UserRowView.swift` | `resetPassword()` fakes a reset with `Task.sleep` and a locally generated random password — no backend API called |
| `StaffApp/Views/Admin/ProfileView.swift` `ChangePasswordView` | `handleUpdatePassword()` validates locally and shows a success alert — password is never actually changed |
| `BorrowerApp/Views/KYCView.swift` | Entire mock KYC flow: any 6-digit OTP accepted, address hardcoded to Bengaluru, name defaults to `"Naman Gupta"` |
| `BorrowerApp/Views/KYCView.swift` | "Mock KYC Simulator" link exposed to production users in `KYCOptionsView` |
| `BorrowerApp/Views/ForgotPasswordView.swift` | Calls `SupabaseManager.shared.client.auth.resetPasswordForEmail` directly, bypassing `AuthService` DI |
| `StaffApp/Views/LoanOfficer/LOAppViewModel.swift` | `makeOfficerApplication` hardcodes `riskLevel: .low`, `fraudFlag: false`, `employer: "—"`, `existingLiabilities: 0`, `purpose: "—"` — never populated from backend |
| `StaffApp/Views/LoanOfficer/LOAppViewModel.swift` | `officerID` fallback uses `MockOfficerData.officerUserID` (hardcoded UUID `22222222-…`) if auth fails |
| `StaffApp/Views/LoanOfficer/LOAppViewModel.swift` | KPI `trend` values and `chartData` sparklines are hardcoded constants — not computed from real data |
| `StaffApp/Views/LoanOfficer/RecoveryVerificationView.swift` | Log call, add note, and schedule follow-up all call `markBorrowerContacted()` only — data never persisted to backend |
| `StaffApp/Views/Admin/EMISchedulerView.swift` | All CRUD (add, edit, duplicate, delete) is local `@State` only — lost on navigation |
| `StaffApp/Views/Admin/AddReminderScheduleSheet.swift` | Conflict detection is fake (`hasPotentialConflict` checks hardcoded conditions); `onSave` creates a local UUID, no backend persistence |
| `StaffApp/Views/Manager/ManagerStore.swift` | `markAllNotificationsRead`, `markNotificationRead`, `dismissNotification` mutate local arrays only — `is_read` never updated in DB |
| `StaffApp/Views/Manager/ManagerStore.swift` | `markRiskAlertRead` / `dismissRiskAlert` purely local — reappear on next launch |
| `StaffApp/Views/Manager/ManagerStore.swift` | `loadPortfolioAndReports` fetches entire `loans` and `emis` tables with no filters — will not scale |
| `StaffApp/Views/Manager/ManagerStore.swift` | `loadOfficerPerformance` fetches all `loan_officer` users across the entire system, not scoped to manager's branch |
| `StaffApp/Views/Manager/ManagerDashboardView.swift` | Priority cards all navigate to unfiltered `ManagerRoute.applications` — "Escalated" / "Sent Back" cards don't pre-filter |
| `BorrowerApp/Views/BorrowerProfileView.swift` | Credit score uses `Int.random(in: 710...820)` and saves the fake score to the backend (no CIBIL/Experian API yet — kept intentionally) |

### Medium Priority

| File | Issue |
|------|-------|
| `Shared/SessionStore.swift` | No session persistence on relaunch — valid Supabase keychain token is not restored; forces re-auth every cold start |
| `Shared/Services/Supabase/SupabaseMessagingService.swift` | No Supabase Realtime subscription — new messages only appear when the view is re-opened |
| `BorrowerApp/ViewModels/MessagingViewModel.swift` | No real-time subscription for incoming borrower messages |
| `StaffApp/Views/LoanOfficer/LOConversationView.swift` | No polling or Realtime subscription for incoming messages after initial load |
| `StaffApp/Views/LoanOfficer/LoanReviewView.swift` | Escalation level selector always shows "Branch Manager" selected with `isSelected: true` hardcoded |
| `StaffApp/Views/LoanOfficer/LoanReviewView.swift` | "Send Back for Revision" uses hardcoded remark string instead of the officer's typed remarks |
| `StaffApp/Views/LoanOfficer/LoanReviewView.swift` | Collateral section reads from a single global `viewModel.collateral` object — not scoped to the application under review |
| `StaffApp/Views/Manager/SuccessStateView.swift` | "Review Next Application" button calls the same `onFinish()` as "Done" — doesn't navigate to the next application |
| `StaffApp/Views/Manager/ManagerProfileView.swift` | "Change Password", "Two-Factor Authentication", "Help & FAQ", "Contact Support" all navigate to a `placeholderDetail()` stub |
| `StaffApp/Views/Manager/ManagerProfileView.swift` | All preference toggles are local `@State` — not persisted to UserDefaults or backend |
| `StaffApp/Views/Manager/ApplicationReviewView.swift` | Document verification toggle updates local `verifiedDocs` set only — not saved to backend |
| `StaffApp/Views/Admin/DistributionDetailsView.swift` | `portfolioData` array is fully hardcoded (e.g. `"₹45L" Home`) — not derived from backend |
| `StaffApp/Views/Admin/ReportsView.swift` | Entire view driven by hardcoded static mock data; report generation and share buttons are TODOs |
| `StaffApp/Views/Admin/ManagerReportsView.swift` | `reportPeriod` hardcodes `"Q1 2026"` for NPA/collection-efficiency types; the function is defined but never called |
| `BorrowerApp/Views/ApplicationTrackingView.swift` | Pipeline tracker doesn't handle `.additionalInfoRequired`, `.recommended`, `.escalated`, `.rejected` statuses |
| `BorrowerApp/Views/HomeDashboardView.swift` | Same pipeline tracker gap as above; also `nextUpcomingEMI` result is computed then discarded (`let _ = ...`) |
| `BorrowerApp/ViewModels/DashboardViewModel.swift` | `loadRequestNotes` issues one `fetchApplicationEvents` call per pending application sequentially (N+1) |
| `Shared/Utilities/EMICalculator.swift` | All arithmetic done in `Double` (converted from `Decimal`) — loses precision for large financial amounts |
| `Shared/Services/Supabase/SupabaseLoanService.swift` | `Decimal` amounts converted to `Double` via `NSDecimalNumber.doubleValue` for `AnyJSON` encoding — precision loss on large values |
| `Shared/Services/Supabase/SupabaseLoanService.swift` | Debug print `SUPABASE_DEBUG_JSON:` left in `fetchApplications(statuses:)` — leaks full JSON to console |
| `Shared/Services/Supabase/SupabaseAdminService.swift` | `createStaff` returns `UUID()` as fallback when response can't be decoded — random UUID unrelated to the created user |
| `Shared/Services/Supabase/SupabaseAdminService.swift` | `fetchAuditLogs` uses `UUID()` fallback for nil `id`/`actorID`/`entityID` — masks data integrity issues |
| `Shared/Services/Supabase/SupabaseAuthService.swift` | `mapDBBorrowerProfileToLocal` uses `Date()` (today) as default DOB when `date_of_birth` is nil |
| `Shared/Services/Supabase/SupabaseAuthService.swift` | Error handling in `fetchBorrowerProfile` uses fragile string matching (`"empty"`, `"0 rows"`, etc.) |
| `Shared/Services/SecureKeychainService.swift` | `delete`+`add` in `set(_:for:)` is not atomic — concurrent calls can race |
| `Shared/Utilities/Validators.swift` | `isValidEmail` only checks for `@` and `.` — not a proper regex |
| `Shared/Utilities/Validators.swift` | No Aadhaar number validation; no password strength helper |
| `BorrowerApp/Views/AadhaarKYCView.swift` | `sharePhrase` length not validated (UIDAI phrases are exactly 4 characters) |
| `BorrowerApp/Views/NewLoanApplicationView.swift` | `requestedAmount` not validated against `amountBounds` before submission |
| `StaffApp/Views/TwoFactorAuthView.swift.swift` | File is completely empty; filename has double `.swift.swift` extension |
| `StaffApp/Views/Manager/ManagerProfileSubViews.swift` | File is completely empty — dead code |
| `Shared/Networking/APIClient.swift` + `Endpoints.swift` | Dead code — protocol defined but never implemented; endpoints never referenced |
| `Shared/Utilities/PersistenceController.swift` | Dead code — protocol defined but never conformed to |
