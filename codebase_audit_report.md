# Compile Audit Report of LMS Codebase

This report compiles the findings of the 5 parallel auditing agents tasked with analyzing every file in the codebase.


# ==========================================
# AUDIT REPORT: Shared Layer (ID: c4eabb9d-3430-4279-a34b-5610a7a4ed02)
# ==========================================

## Shared/ Directory — Full Audit Report (41 files)

---

### `Shared/AppEnvironment.swift`
**Purpose:** Dependency injection container holding all service protocols; injected at app root via `@Environment`.
**Flaws:**
- **Hardcoded/Mock Data:** Default parameter values for `admin` and `aadhaarKYC` use `MockAdminService()` and `MockAadhaarKYCService()` respectively (lines 22–23). Any caller that omits these parameters in production will silently receive mock services, meaning admin features and Aadhaar KYC will run entirely on fake data in production.

---

### `Shared/Models.swift`
**Purpose:** Central domain model file defining all data types: `User`, `BorrowerProfile`, `StaffProfile`, `LoanApplication`, `Loan`, `EMI`, `LoanDocument`, `ChatMessage`, `MessageThread`, `AuditEntry`, reporting models, Aadhaar KYC models, and `PushNotification`.
**Flaws:**
- **Missing Logic:** `LoanProduct.loanType` (lines 106–113) derives the loan type from the product `name` using string-matching heuristics. If the backend renames a product (e.g., "Housing Loan" instead of "Home Loan"), it will silently fallback to `.personal`. This should be a stored field from the backend.
- **Missing Logic:** `PostalAddress.pinCode` is typed as `Int` (line 50), which will drop leading zeros (e.g., pin code "010101" becomes 10101). Indian pin codes are always 6 digits and should be `String`.

---

### `Shared/SessionStore.swift`
**Purpose:** Observable session state holder tracking the current user, borrower/staff profile, and authentication state.
**Flaws:**
- **Missing Logic:** No session persistence. When the app terminates and relaunches, `currentUser` resets to `nil`, forcing re-authentication even if a valid Supabase session token exists in the keychain. There's no `restoreSession()` method.
- **Missing Logic:** No mechanism to handle session expiry or token refresh notifications.

---

### `Shared/DesignSystem/AvatarView.swift`
**Purpose:** Reusable circular avatar component showing initials on a gradient background, with an optional online indicator.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/DesignSystem/Colors.swift`
**Purpose:** Defines semantic color tokens (brand, status, surface, fill colors) that adapt to Light/Dark Mode via UIKit system colors, with macOS fallbacks.
**Flaws:**
- **UI Issue:** `lmsBackgroundGradient` (lines 51–55) is defined as a gradient from `Color.lmsBackground` to `Color.lmsBackground` — two identical colors, making it a flat fill, not a gradient. This is either a placeholder or a bug.

---

### `Shared/DesignSystem/CountBadge.swift`
**Purpose:** Small numeric badge (capped at "99+") and a circular progress ring used in dashboard metrics.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/DesignSystem/DetailRow.swift`
**Purpose:** Label/value row with a tinted icon, used in cards and forms.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/DesignSystem/EmptyStateView.swift`
**Purpose:** Centered empty state component with icon, title, and subtitle for when lists have no data.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/DesignSystem/LMSTextFieldStyle.swift`
**Purpose:** Custom `TextFieldStyle` wrapping the system `.roundedBorder` style for consistent form fields.
**Flaws:**
- **UI Issue:** Uses `_body(configuration:)` (line 6), which is a private/underscored SwiftUI API. This can break without notice in future iOS versions. The public `makeBody(configuration:)` should be used instead.

---

### `Shared/DesignSystem/PrimaryButton.swift`
**Purpose:** Full-width primary and secondary action buttons with loading state support.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/DesignSystem/SectionCard.swift`
**Purpose:** A card container visually matching inset-grouped List sections, with optional title/footer.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/DesignSystem/SectionHeader.swift`
**Purpose:** Section header with title, optional subtitle, icon, and trailing action button.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/DesignSystem/Spacing.swift`
**Purpose:** Design system spacing constants, corner radii, and admin-specific spacing tokens.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/DesignSystem/StatusBadge.swift`
**Purpose:** Pill-shaped status badge with five tonal variants (neutral, info, success, warning, danger) and optional icon.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/DesignSystem/Typography.swift`
**Purpose:** Font extension defining design-system typography tokens mapped to system text styles for Dynamic Type support.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/Networking/APIClient.swift`
**Purpose:** Defines the `APIRequest` struct, `APIError` enum, and `APIClient` protocol for network communication.
**Flaws:**
- **Missing Logic:** The `APIClient` protocol is defined but no concrete implementation exists anywhere in the codebase. All Supabase services use raw `URLSession.shared.data(for:)` directly, bypassing this abstraction entirely. This is dead code.

---

### `Shared/Networking/Endpoints.swift`
**Purpose:** Enum of static endpoint path strings for various API resources.
**Flaws:**
- **Missing Logic:** These endpoint constants are never referenced anywhere in the codebase. All Supabase service files construct URLs by inline string concatenation with `apiBase`. This is dead code.

---

### `Shared/Services/AadhaarKYCService.swift`
**Purpose:** Protocol defining Aadhaar KYC verification and report retrieval operations.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/Services/AdminService.swift`
**Purpose:** Protocols for admin operations (`AdminService`) and reporting (`ReportingService`).
**Flaws:**
- **Missing Logic:** `ReportingService` protocol is defined (lines 25–28) but has no implementation anywhere in the codebase — neither a Supabase nor a mock implementation. Any code trying to use it would fail at runtime.

---

### `Shared/Services/AuthService.swift`
**Purpose:** Protocol defining authentication operations: sign-in, sign-up, OTP, passkey, sign-out, and borrower profile management.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/Services/DocumentService.swift`
**Purpose:** Protocol defining document CRUD, staff review (verify/reject), and signed URL generation.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/Services/KeychainService.swift`
**Purpose:** Protocol for secure key-value storage (set, get, remove).
**Flaws:**
- ✅ No flaws found.

---

### `Shared/Services/LoanService.swift`
**Purpose:** Protocol defining all loan-related operations: products, applications, active loans, EMI schedule, staff workflow actions, and foreclosure.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/Services/MessagingService.swift`
**Purpose:** Protocol for chat messaging: threads, messages, send, mark-read, and ensure-thread operations.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/Services/NotificationService.swift`
**Purpose:** Protocol for push notification management: device registration, authorization, topic subscription, and history.
**Flaws:**
- ✅ No flaws found.

---

### `Shared/Services/SecureKeychainService.swift`
**Purpose:** Production implementation of `KeychainService` using Apple's Security framework (SecItem APIs).
**Flaws:**
- **Security:** Marked `@unchecked Sendable` (line 6) but has no internal synchronization. Multiple concurrent calls could race on `SecItemDelete`/`SecItemAdd` in `set(_:for:)` (lines 18–21) — the delete-then-add is not atomic.
- **Security:** No access control attributes are set (e.g., `kSecAttrAccessible`). Items default to `kSecAttrAccessibleWhenUnlocked`, but for session tokens that need to survive background refresh, a more explicit policy should be set.

---

### `Shared/Services/Mocks/MockAuthService.swift`
**Purpose:** Mock auth service for development. Hardcodes a seed borrower user and always accepts OTP "123456".
**Flaws:**
- **Hardcoded/Mock Data:** Hardcoded mock UUID `11111111-1111-1111-1111-111111111111` (line 10).
- **Hardcoded/Mock Data:** Hardcoded user "Naman Gupta", email "naman@example.com", phone "+91 98765 43210" (lines 11–14).
- **Hardcoded/Mock Data:** Hardcoded address "42 MG Road, Sector 14, Gurugram" (lines 21–23), PAN "ABCDE1234F", credit score 780, monthly income ₹1.2L (lines 25–30).
- **Hardcoded/Mock Data:** OTP is always "123456" (lines 53, 65). Error message "Invalid OTP. Use 123456." (line 67) leaks the mock code to users.
- **Missing Logic:** `signIn` ignores the `email`/`password` parameters entirely and always returns the seed borrower (line 41). No credential validation whatsoever.
- **Missing Logic:** `fetchBorrowerProfile` ignores the `userID` parameter and always returns the same mock profile (line 88).

---

### `Shared/Services/Mocks/MockLoanService.swift`
**Purpose:** Mock loan service with seeded applications, loans (home, education, vehicle, settled personal, settled business) and EMI schedules for development.
**Flaws:**
- **Hardcoded/Mock Data:** Multiple hardcoded UUIDs: `11111111...`, `22222222...`, `aaaaaaaa...`, `bbbbbbbb...`, `cccccccc...` (lines 9–13).
- **Hardcoded/Mock Data:** Hardcoded loan amounts (₹25L, ₹5L, ₹8L, ₹2L, ₹50L), interest rates, and tenure values throughout (lines 27–189).
- **Missing Logic:** `payEMI` throws "Not implemented" (line 276). If mock mode is used for borrower testing, EMI payment will always fail.
- **Missing Logic:** `fetchApplications(for:)` ignores the `borrowerID` parameter and returns all applications (lines 245–249). It should filter by borrowerID.
- **Missing Logic:** Staff workflow methods (`startReview`, `requestDocuments`, `approveApplication`, `rejectApplication`, `disburseLoan`) are all empty no-ops (lines 280–286). They don't update application status, making staff flow testing impossible with mocks.
- **Missing Logic:** `createApplication` always uses `.personal` loan type and hardcoded 10.5% interest rate, ignoring the `productID` parameter (lines 223–228).
- **Hardcoded/Mock Data:** Hardcoded loan products in `fetchLoanProducts` (lines 198–202) — these will shadow backend data if mock service is accidentally used.
- **Bug:** EMI override logic (lines 63–72): the condition `i < 45` marks first 45 EMIs as paid, but then `i == 2` (which is already < 45) tries to set `.overdue`, which is unreachable since it was already set to `.paid`.

---

### `Shared/Services/Mocks/MockSupportServices.swift`
**Purpose:** Mock implementations for AadhaarKYC, Admin, Document, Messaging, Notification, and Keychain services.
**Flaws:**
- **Hardcoded/Mock Data:** `MockAadhaarKYCService.verify` returns hardcoded demographics "Ravi Kumar", DOB "1990-06-15", address "12A MG Road, Bengaluru" (lines 20–32). Always returns `auto_verified` regardless of input.
- **Hardcoded/Mock Data:** `MockMessagingService` uses hardcoded UUIDs (`dddddddd...`, `eeeeeeee...`, `ffffffff...`) and hardcoded chat messages referencing "Naman" and "Sarah" (lines 123–190).
- **Hardcoded/Mock Data:** `MockNotificationService` has hardcoded notification text including specific EMI amount "₹21,653" (line 254) and loan amount "₹25,00,000" (line 267).
- **Missing Logic:** `MockDocumentService.documents(forApplication:)` returns ALL documents regardless of application (line 88), not application-scoped.
- **Missing Logic:** `MockDocumentService.signedURL` returns a fake `https://example.com/mock/...` URL (line 102) — if this is ever opened, it leads nowhere.
- **Missing Logic:** `MockAdminService.listUsers` and `listStaffProfiles` return empty arrays (lines 49–50), making admin user management untestable with mocks.
- **Missing Logic:** `MockNotificationService.requestAuthorization` always returns `true` (line 273) — never tests the denied case.

---

### `Shared/Services/Supabase/SupabaseAadhaarKYCService.swift`
**Purpose:** Production Aadhaar KYC service that uploads zip files to the backend for verification and fetches reports.
**Flaws:**
- **Backend Integration:** `report()` silently returns `nil` on any non-404 error (line 70) instead of propagating the error. A 500 server error is indistinguishable from "no report found".
- **Backend Integration:** `report()` uses `try?` to decode the response (line 72), silently swallowing decoding errors. A malformed response appears as "no report".
- **Security:** Uses raw `URLSession.shared` without certificate pinning or custom configuration for sensitive KYC data transmission.

---

### `Shared/Services/Supabase/SupabaseAdminService.swift`
**Purpose:** Production admin service for user management, staff creation, loan archival/restore, and audit log retrieval.
**Flaws:**
- **Missing Logic / Security:** `updateUserRole` (lines 158–171) and `updateUserStatus` (lines 173–186) perform **direct database mutations** via `client.from("users").update(...)`, bypassing the backend API. This skips any server-side authorization checks and business logic. These should go through the backend API.
- **Missing Logic / Security:** `archiveLoan` and `restoreLoan` (lines 188–216) also mutate the `loans` table directly, bypassing backend validation. Restoring a loan arbitrarily sets status to "active" without checking if it's valid.
- **Hardcoded/Mock Data:** `createStaff` fallback returns `UUID()` (line 155) when the response can't be decoded. This means a random UUID is returned to the caller, completely unrelated to the actual created user.
- **Hardcoded/Mock Data:** `logAuditEvent` in `SupabaseManager` always hardcodes `actor_role` as `"admin"` (line 51 of SupabaseManager.swift), even if the current user is a manager or officer.
- **Missing Logic:** `fetchAuditLogs` falls back to `UUID()` for `id`, `actorID`, and `entityID` when values are nil (lines 236–241). This masks data integrity issues with phantom random UUIDs.

---

### `Shared/Services/Supabase/SupabaseAuthService.swift`
**Purpose:** Production Supabase auth service handling email/password sign-in/sign-up, OTP verification, user profile mapping, and borrower profile CRUD.
**Flaws:**
- **Missing Logic:** `requestOTP` and `verifyOTP` both throw "not implemented" errors (lines 47, 52). If any UI code path tries to use phone-based OTP, it will crash.
- **Missing Logic:** `signInWithPasskey` throws `URLError(.unsupportedURL)` (line 57). Not a meaningful error for "feature not implemented".
- **Hardcoded/Mock Data:** Fallback user name is "Supabase User" (line 90). If metadata lookup fails, the user sees this placeholder string.
- **Missing Logic:** `mapDBBorrowerProfileToLocal` uses `Date()` as default for `dateOfBirth` when `db.date_of_birth` is nil (line 211). This sets today's date as the birth date, which is nonsensical and would break age validation.
- **Missing Logic:** Error handling in `fetchBorrowerProfile` (lines 234–240) uses fragile string matching on error messages ("empty", "0 rows", "decoding", "json", "406") to decide if the error is benign. This is brittle and locale-dependent.

---

### `Shared/Services/Supabase/SupabaseDocumentService.swift`
**Purpose:** Production document service handling uploads (multipart), listing, deletion (storage + DB), status updates, and staff review actions via backend.
**Flaws:**
- **Hardcoded/Mock Data:** `toDomainDocument` always sets `mimeType` to `"application/octet-stream"` (line 75) because the DB model doesn't include a `mime_type` column. The actual mime type from upload is lost.
- **Missing Logic:** `delete` method constructs storage path using `url.lastPathComponent` (line 162), which may not match the actual storage path structure if the URL contains query parameters or nested paths.

---

### `Shared/Services/Supabase/SupabaseLoanService.swift`
**Purpose:** Production loan service: product CRUD, application lifecycle, EMI payments, staff workflow actions, and foreclosure — the largest service file (698 lines).
**Flaws:**
- **Performance / N+1 Query:** `fetchActiveLoans` (lines 370–401) fetches all loans, then loops through each loan to call `fetchEMISchedule` (line 383) AND `loanTypeForApplication` (line 385) individually. For a borrower with N loans, this makes 2N+1 database queries. Should use a joined query.
- **Missing Logic:** `submitApplication` throws "Not implemented" (line 300). If any UI calls this method, it will fail.
- **Security:** `calculateForeclosure` (lines 625–648) performs the entire foreclosure calculation client-side with hardcoded penalty rate (2%) and GST (18%) (lines 636–638). These financial parameters should come from the backend to prevent tampering.
- **Security:** `forecloseLoan` (lines 650–696) performs **direct database mutations** — updates `loans` table, bulk-updates `emis` table, and inserts `audit_entries` — all client-side, bypassing any backend validation, authorization, or transaction integrity. This is a critical security issue for a financial operation.
- **Missing Logic:** `forecloseLoan` stores `"closed"` as the DB status (line 653) but then maps it to `.foreclosed` in the domain model (line 691). The DB won't distinguish between a normally closed and foreclosed loan.
- **Hardcoded/Mock Data:** Debug print statement left in production code: `print("SUPABASE_DEBUG_JSON: \(str)")` in `fetchApplications(statuses:)` (line 339). This leaks full JSON response data to console logs.
- **Missing Logic:** `productCache` (line 134) is never invalidated after product deletion/update from a different device/session. Stale cache will cause incorrect loan type mapping.
- **Backend Integration:** `Decimal` amounts are converted to `Double` via `NSDecimalNumber.doubleValue` for `AnyJSON` encoding (lines 202–203, 228–235, 280). This loses precision for large financial amounts (Decimal can represent exact values, Double cannot).

---

### `Shared/Services/Supabase/SupabaseManager.swift`
**Purpose:** Singleton manager that initializes the Supabase client with URL/key and provides a shared JSON decoder with custom date parsing.
**Flaws:**
- **Security:** Supabase URL and anon key are hardcoded in source code (lines 39–40). While the anon key is publishable, it's better practice to load from configuration/environment for flexibility across staging/production.
- **Hardcoded/Mock Data:** `logAuditEvent` always hardcodes `actor_role` as `"admin"` (line 51), regardless of the actual user's role. Audit logs will misattribute actions.
- **Missing Logic:** `logAuditEvent` silently swallows errors with `print()` (line 62). Audit logging failures should at minimum be reported to an error tracking system, especially for a financial application.
- **Missing Logic:** No retry logic or error recovery if the Supabase client fails to initialize.

---

### `Shared/Services/Supabase/SupabaseMessagingService.swift`
**Purpose:** Production messaging service using Supabase for thread management and chat messages.
**Flaws:**
- **Missing Logic:** `markRead` (lines 107–118) marks ALL unread messages in a thread as read, not just messages from other senders. A user's own sent messages shouldn't need to be marked as read.
- **Missing Logic:** No real-time subscription setup. Messages are only fetched on-demand; there's no Supabase Realtime channel subscription for live chat updates.

---

### `Shared/Utilities/EMICalculator.swift`
**Purpose:** Standard reducing-balance EMI calculator that generates a full amortization schedule.
**Flaws:**
- **Missing Logic:** EMI calculation converts `Decimal` principal to `Double` (line 24), performs all arithmetic in `Double`, then converts back to `Decimal` (lines 65–67). This introduces floating-point rounding errors for financial calculations. The entire calculation should stay in `Decimal`.
- **Missing Logic:** The status assignment logic (lines 53–60) auto-marks past-due EMIs as `.paid` (line 55 comment says "Past EMIs treated as paid in mock"). This is mock behavior leaking into a shared utility — in production, past-due EMIs could be overdue, not paid.
- **Missing Logic:** `Decimal(emi.rounded(.toNearestOrAwayFromZero))` (line 37) rounds the EMI to the nearest integer, losing paise/cents. The last EMI in the schedule should absorb the rounding difference to ensure total paid equals total payable exactly.

---

### `Shared/Utilities/Formatting.swift`
**Purpose:** Utility formatters for currency (INR with Indian locale), percentage, date, and compact Indian rupee amounts (L/Cr).
**Flaws:**
- **Performance:** `NumberFormatter` is created on every call to `currency()` and `compactIndianRupee()` (lines 5, 43). `NumberFormatter` is expensive to instantiate; these should be cached as static properties.

---

### `Shared/Utilities/PersistenceController.swift`
**Purpose:** Protocol for generic local persistence (save, load, delete by key).
**Flaws:**
- **Missing Logic:** No concrete implementation exists anywhere in the codebase. This protocol is dead code — nothing conforms to it.

---

### `Shared/Utilities/Validators.swift`
**Purpose:** Basic input validators for email, phone, and PAN number.
**Flaws:**
- **Security / Missing Logic:** `isValidEmail` (lines 4–6) only checks for `@` and `.` presence. Strings like `"@."`, `"a@b."`, or `"user @domain.com"` would pass. Should use a proper regex or `NSDataDetector`.
- **Missing Logic:** No Aadhaar number validation (even for last-4 digits format).
- **Missing Logic:** No password strength validation helper, despite the app having password-based auth.

---

## Summary of Critical Issues

| Category | Count |
|---|---|
| Hardcoded/Mock Data leaking to production | 12 |
| Missing Logic / Dead Code | 18 |
| Security Issues | 7 |
| Performance Issues | 3 |
| Backend Integration Issues | 4 |
| UI Issues | 2 |

**Top 5 most critical findings:**
1. **`SupabaseLoanService.forecloseLoan`** — Direct client-side DB mutations for a financial transaction (no backend API, no transaction, no authorization check)
2. **`SupabaseAdminService`** — Direct DB mutations for role/status changes and loan archive/restore bypassing backend authorization
3. **`AppEnvironment.swift`** — Default mock services for admin and Aadhaar KYC can silently slip into production
4. **`SupabaseLoanService.fetchActiveLoans`** — N+1 query pattern (2N+1 queries per borrower)
5. **`SupabaseManager.logAuditEvent`** — Always logs `actor_role` as "admin", corrupting the audit trail



# ==========================================
# AUDIT REPORT: BorrowerApp (ID: 503b6eff-bbea-4a97-8547-22c3ca7c159d)
# ==========================================

## Audit Report – BorrowerApp (23 files)

---

### `BorrowerApp/App/BorrowerApp.swift`
**Purpose:** App entry point that configures the `SessionStore`, injects all service dependencies via `AppEnvironment`, and sets up `UIPageControl` appearance.
**Flaws:**
- **Backend Integration / Mock Data (line 15):** `MockNotificationService()` is used in production `appEnvironment`. All other services are real Supabase implementations, but notifications remain mock — push notification history and device registration will never work in production.
- **Hardcoded/Mock Data (lines 7–8):** Commented-out lines seed a mock borrower into the session. Not a runtime issue, but leftover debug code that could be accidentally un-commented.

---

### `BorrowerApp/App/RootView.swift`
**Purpose:** Chooses between `LoginView` (unauthenticated) and `BorrowerTabView` (authenticated), restores session on launch, and handles the `lms://reset-password` deep link.
**Flaws:**
- **Hardcoded/Mock Data (line 16):** `"mock_device_token"` is used as a literal string for push notification device token registration. A real device token from APNs is never obtained — production notifications will fail silently.
- **Missing Logic:** No actual APNs delegate or `UIApplication.shared.registerForRemoteNotifications()` call exists; the entire push-notification registration is a no-op stub with a hardcoded string.

---

### `BorrowerApp/ViewModels/AuthViewModel.swift`
**Purpose:** Handles sign-in (email+password), sign-up, email OTP verification, and passkey sign-in, surfacing `errorMessage` and `isBusy` state.
**Flaws:**
- ✅ No flaws found.

---

### `BorrowerApp/ViewModels/DashboardViewModel.swift`
**Purpose:** Fetches active loans and applications for the borrower, and loads officer "document-requested" notes for applications in `additionalInfoRequired` status.
**Flaws:**
- **Performance / N+1 pattern (lines 42–53):** `loadRequestNotes` issues one `fetchApplicationEvents` network call per pending application inside a sequential `for` loop. With many pending applications this is an N+1 problem — should use a batch query or `TaskGroup`.
- **Missing Logic (line 28):** `errorMessage` is set via `String(describing: error)` rather than `error.localizedDescription`, which may surface raw Swift error internals to the user (e.g., `"DecodingError.keyNotFound…"`).

---

### `BorrowerApp/ViewModels/LoanApplicationViewModel.swift`
**Purpose:** Manages the loan application form state (product selection, amount, tenure), submission, document linking, and reset.
**Flaws:**
- ✅ No flaws found.

---

### `BorrowerApp/ViewModels/MessagingViewModel.swift`
**Purpose:** Fetches message threads, loads/selects a thread's messages, marks as read, and sends new messages.
**Flaws:**
- **Missing Logic:** No real-time subscription (e.g., Supabase Realtime) — new incoming messages from the officer won't appear until the user manually navigates away and back.

---

### `BorrowerApp/ViewModels/RepaymentViewModel.swift`
**Purpose:** Loads EMI schedule for a loan, processes EMI payment, and refreshes loan/EMI state after payment.
**Flaws:**
- **Missing Logic / Potential data inconsistency (lines 49–53):** After paying an EMI, the code fetches *all* active loans just to find the refreshed version of the current loan. If the loan's status changed to `settled` after the last EMI, `fetchActiveLoans` may not return it (since it filters for active), and `self.activeLoan` won't update, leaving stale data.

---

### `BorrowerApp/Views/AadhaarKYCView.swift`
**Purpose:** Allows borrowers to upload a UIDAI Offline e-KYC ZIP file with a share phrase for Aadhaar XML signature verification.
**Flaws:**
- **Security (line 253):** When creating a fallback `BorrowerProfile`, it uses `UUID()` as a fallback ID if `session.currentUser?.id` is nil, creating an orphaned profile record.
- **Missing Logic:** The `sharePhrase` length is not validated (UIDAI share phrases are exactly 4 characters) — the `canSubmit` check only ensures it is non-empty.

---

### `BorrowerApp/Views/ApplicationTrackingView.swift`
**Purpose:** Shows a list of all the borrower's loan applications with status badges and a pipeline tracker visualization.
**Flaws:**
- **Missing Logic (line 87):** The `PipelineTrackerView` pipeline order is `[.draft, .submitted, .underReview, .approved, .disbursed]` but does not account for `.additionalInfoRequired`, `.recommended`, `.escalated`, or `.rejected` statuses. An application in `.additionalInfoRequired` or `.recommended` won't highlight any step as current — it falls through with no visual indicator.
- **Missing Sort Order:** Applications are rendered in whatever order the backend returns them (`viewModel.applications`). No explicit sort by date or status.

---

### `BorrowerApp/Views/BorrowerMessagingView.swift`
**Purpose:** Thread list and chat detail for borrower-to-officer messaging, organized by loan application.
**Flaws:**
- **UI Issue (line 270):** `Formatting.date(msg.sentAt)` uses a date formatter, but chat messages typically need time-of-day display (e.g., "10:32 AM"), not just date. Depending on the `Formatting.date` implementation, messages from today may show today's date instead of the time.

---

### `BorrowerApp/Views/BorrowerProfileView.swift`
**Purpose:** Profile screen showing account info, employment details, credit score, KYC status, loan history, and sign-out.
**Flaws:**
- **Hardcoded/Mock Data – Credit Score (lines 536–538):** `verifyPANAndFetchScore` is a **fully mock function** in production code — it sleeps 2 seconds then returns `Int.random(in: 710...820)`. No actual credit bureau API (CIBIL/Experian) integration exists. This fake score is saved to the backend profile as real data.
- **Hardcoded/Mock Data (line 498):** Fallback `BorrowerProfile` uses `dateOfBirth: Date()` (today's date) which is incorrect.
- **Security (line 501):** PAN number is saved to the backend profile after only a format check — no actual PAN verification with a government database.
- **UI Issue (lines 696–716):** `KYCOptionsView` exposes a "Mock KYC Simulator" navigation link labeled "Testing purposes only" in production UI — this should be hidden or behind a debug flag.

---

### `BorrowerApp/Views/EMICalculatorView.swift`
**Purpose:** Standalone EMI calculator with principal, rate, and tenure inputs showing monthly EMI, total interest, and total payable.
**Flaws:**
- ✅ No flaws found.

---

### `BorrowerApp/Views/ForgotPasswordView.swift`
**Purpose:** Password reset flow that sends a Supabase magic-link reset email with a `lms://reset-password` redirect.
**Flaws:**
- **Backend Integration (line 69):** Directly calls `SupabaseManager.shared.client.auth.resetPasswordForEmail` rather than going through the `AuthService` protocol/abstraction, breaking the dependency injection pattern used everywhere else.

---

### `BorrowerApp/Views/HomeDashboardView.swift`
**Purpose:** Main borrower dashboard showing action-required cards, pending application tracker, active loan hero cards with EMI progress, and pay-EMI sheets.
**Flaws:**
- **Missing Logic (line 233):** `let _ = nextUpcomingEMI(for: loan)` computes the next EMI but discards the result (assigned to `_`). Appears to be dead/incomplete code — the upcoming EMI info is never shown on the hero card.
- **Missing Logic (lines 372–407):** The pipeline tracker in `statusTrackerCard` duplicates the same limited `[.draft, .submitted, .underReview, .approved, .disbursed]` order from `ApplicationTrackingView`, again failing to represent `.additionalInfoRequired`, `.recommended`, `.escalated`, or `.rejected` statuses.

---

### `BorrowerApp/Views/KYCView.swift`
**Purpose:** Mock Aadhaar e-KYC flow with Aadhaar number entry → OTP entry → success, entirely stubbed with fake backend calls.
**Flaws:**
- **Hardcoded/Mock Data – Entire file (lines 418–448):** Both `sendAadhaarOTP` and `verifyAadhaarOTP` are fully mocked with `Task.sleep`. Any 6-digit OTP is accepted (line 433). No real UIDAI/backend integration.
- **Hardcoded/Mock Data (line 53):** Fallback name `"Naman Gupta"` is hardcoded as a default if `session.currentUser?.fullName` is nil.
- **Hardcoded/Mock Data (lines 283–287):** Address is hardcoded to `city: "Bengaluru"`, `state: "Karnataka"`, `pinCode: 560001` regardless of the user's actual Aadhaar address.
- **Hardcoded/Mock Data (line 57):** Fallback masked Aadhaar uses `"1234"` as the last 4 digits.
- **Security (line 433):** Any 6-digit OTP is accepted — no server-side validation.
- **UI Issue:** This "Mock KYC Simulator" is exposed to production users from `KYCOptionsView` in `BorrowerProfileView`.

---

### `BorrowerApp/Views/LoginView.swift`
**Purpose:** Email+password login screen with navigation to registration, forgot password, and OTP verification.
**Flaws:**
- **Hardcoded/Mock Data (line 209):** The OTP verification screen displays `"Demo OTP: 123456"` in the UI. This leaks test/demo information to production users.

---

### `BorrowerApp/Views/NewLoanApplicationView.swift`
**Purpose:** Multi-step loan application flow: select product → configure amount/tenure → submit → upload documents (salary slips, bank statements) → completion.
**Flaws:**
- **Missing Logic:** Only two document kinds are offered for upload after submission (`incomeProof` and `bankStatement`, lines 166–168). Identity proof, address proof, and collateral documents are not offered, though they may be required for certain loan types (e.g., home or vehicle loans).
- **Missing Logic:** No validation that `requestedAmount` is within `amountBounds` before submission — the user can type an out-of-range value in the text field and submit.

---

### `BorrowerApp/Views/NotificationsView.swift`
**Purpose:** Lists push notification history fetched from the notification service.
**Flaws:**
- **Backend Integration:** Since `BorrowerApp.swift` injects `MockNotificationService()`, this view will only ever show mock/empty notification data in production. The entire notification feature is non-functional.

---

### `BorrowerApp/Views/ProductComparisonView.swift`
**Purpose:** Side-by-side comparison of loan products showing interest rates, amount limits, tenure ranges, benchmark EMIs, and "Best For" descriptions.
**Flaws:**
- ✅ No flaws found.

---

### `BorrowerApp/Views/RegisterView.swift`
**Purpose:** Registration form with full name, email, phone, DOB, and password (with strength requirements), leading to OTP verification.
**Flaws:**
- **Missing Logic:** No email format validation — the form only checks the email field is non-empty, allowing submission of clearly invalid emails (e.g., "abc").
- **Missing Logic:** No phone number format/length validation — any non-empty string is accepted.

---

### `BorrowerApp/Views/RepaymentDashboardView.swift`
**Purpose:** Detailed repayment view for a loan with next-payment card, loan details, full EMI schedule, and foreclosure flow.
**Flaws:**
- **Missing Logic (line 56):** `catch {}` silently swallows errors when fetching active loans as fallback. If the fetch fails, the user sees an empty "No Loan Data" state with no error message.

---

### `BorrowerApp/Views/UpdatePasswordView.swift`
**Purpose:** Allows the user to set a new password (after a reset link) with validation, then signs them out.
**Flaws:**
- **Backend Integration (lines 83, 86):** Directly calls `SupabaseManager.shared.client.auth.update` and `SupabaseManager.shared.client.auth.signOut()` instead of using the `AuthService` protocol abstraction, breaking DI.
- **Missing Logic:** After `signOut()` is called (line 86), the session store (`SessionStore`) is never cleared (`session.currentUser = nil`). The user may remain in an "authenticated" state in the UI despite being signed out on the backend.

---

### `BorrowerApp/Views/UploadRequestedDocumentsView.swift`
**Purpose:** Lets a borrower upload documents requested by a loan officer for an application in `additionalInfoRequired` status, then calls `documentsUploaded` to move the application back into review.
**Flaws:**
- **Missing Logic (lines 30–51):** The `requestedDocumentKind` computed property uses naive keyword matching on the officer's note to infer the document type. Ambiguous notes could match the wrong kind (e.g., a note saying "please upload your Aadhaar card and bank statement" would match `.bankStatement` first, ignoring the identity proof request). A structured field from the backend would be more reliable.

---

### Summary of Critical Issues

| Severity | Count | Key Examples |
|----------|-------|-------------|
| **Mock data in production** | 5 | Credit score RNG, mock device token, mock notification service, mock KYC simulator exposed in UI, hardcoded "Demo OTP: 123456" |
| **Hardcoded fallback data** | 4 | `"Naman Gupta"` name, `"Bengaluru"` address, `"1234"` Aadhaar digits, `dateOfBirth: Date()` |
| **DI bypass** | 2 | `ForgotPasswordView` & `UpdatePasswordView` call `SupabaseManager.shared` directly |
| **Missing validation** | 3 | Email format, phone format, Aadhaar share phrase length |
| **N+1 query** | 1 | `DashboardViewModel.loadRequestNotes` sequential loop |
| **Session state bug** | 1 | `UpdatePasswordView` signs out on backend but never clears `SessionStore` |
| **Silent error swallowing** | 2 | `RepaymentDashboardView` empty catch, `BorrowerProfileView.loadData` catch ignored |



# ==========================================
# AUDIT REPORT: LoanOfficer (ID: 343aa76a-e799-431e-acce-f6d53441318b)
# ==========================================

Audit complete for all 20 files in `StaffApp/Views/LoanOfficer/`. Here is the full report:

---

### `AadhaarVerificationReportCard.swift`
**Purpose:** A pure-presentation SwiftUI card that renders an Aadhaar/UIDAI verification report including signature validity, mobile/email hash matches, demographics, and an auto-decision badge.
**Flaws:**
- **Performance:** `ISO8601DateFormatter` and `DateFormatter` are re-created on every call to `formattedDate(_:)`. These should be static/cached.
- **Hardcoded/Mock Data:** The `#Preview` block contains hardcoded Indian personal data (name "Ravi Kumar", DOB, gender, care-of, address). This is in a preview block only, so low severity.
- ✅ No production-path flaws found.

---

### `AllApplicationsView.swift`
**Purpose:** Displays a filterable, searchable list of all loan applications assigned to the officer, with status chips and navigation to the loan review screen.
**Flaws:**
- **UI Issue:** The risk-level status badge is commented out (lines 290-295) — risk level information is hidden from the user in the applications list.
- **Missing Sort Order:** `filteredApplications` does not apply any sort order; items appear in whatever order `viewModel.filteredApplications` provides, which may be inconsistent.

---

### `ChatView.swift`
**Purpose:** A chat UI allowing the loan officer to view and send messages within a `BorrowerConversation`. Supports both pushed and modal presentation.
**Flaws:**
- **Missing Logic (Critical):** The `sendMessage()` function (line 141-150) only prints the message to the console and clears the text field. It does **not** append the message to `conversation.messages`, call any backend API, or update any state. Messages sent by the officer are silently discarded.
- **Missing Logic:** No error handling or user feedback if sending fails.
- **UI Issue:** Messages are never persisted or reflected in the conversation list; `sendMessage` doesn't update `viewModel.conversations`.

---

### `CommunicationsMainView.swift`
**Purpose:** Lists all borrower conversations with avatars, last-message previews, unread counts, and online indicators. Tapping opens a `ChatView` sheet.
**Flaws:**
- ✅ No flaws found. Data is driven entirely by `viewModel.conversations` populated from backend.

---

### `ContentView.swift`
**Purpose:** Root navigation view for the Loan Officer module; maps `AppDestination` enum cases to their corresponding views via `navigationDestination`.
**Flaws:**
- **Missing Logic / Bug:** The `.fraudAlerts` destination (line 17) navigates to `LoanReviewView()` instead of a dedicated fraud alerts screen. This is incorrect — fraud alerts will show a generic loan review with no fraud-specific context.

---

### `DashboardView.swift`
**Purpose:** Main dashboard showing the officer's profile header, notification bell with unread count, and a 2-column KPI grid with today's activity metrics.
**Flaws:**
- ✅ No flaws found. All data is driven from `viewModel` properties populated by `refreshAll()`.

---

### `DocumentReviewSheet.swift`
**Purpose:** A modal sheet allowing the officer to review a single document — displaying a preview card (with Aadhaar UIDAI report when applicable), and options to verify, flag for review, or reject with notes.
**Flaws:**
- **Hardcoded/Mock Data:** Line 127 displays a hardcoded file size string `"2.4 MB"` for all non-Aadhaar documents regardless of actual file size.
- **Hardcoded/Mock Data:** Line 136 shows a hardcoded OCR confidence `"98%"` string (`"OCR Match: 98% (Verified Security Hash)"`) — this is not derived from any actual OCR result.
- **Missing Logic:** The document preview section (lines 111-156) shows a fabricated filename constructed from the document name (line 116), not the actual backend file URL. There is no ability to view the actual uploaded document/PDF.

---

### `DocumentsView.swift`
**Purpose:** Displays a categorized vault of digital documents (sanction letters, reports, policies) with filtering chips and a detail sheet.
**Flaws:**
- **Missing Logic:** Document category filtering (lines 17-27) is based on `localizedCaseInsensitiveContains` on the title string — this is fragile. A document titled "Final Report on Sanction" would match both "Reports" and "Sanction Letters".
- **UI Issue:** The `DocumentDetailSheet` subtitle is hardcoded to `"Loan officer document record"` (line 212) regardless of the document's actual context.

---

### `LoanOfficerProfileView.swift`
**Purpose:** Displays the officer's full profile including avatar, performance metrics grid, collapsible branch details, app settings (notifications/biometrics/cellular sync toggles), a digital signature pad, and a sign-out button.
**Flaws:**
- **Hardcoded/Mock Data (Critical):** The "Disbursed Value" metric card shows `"₹45.8 Cr"` hardcoded (line 171) with subtitle `"FY 2025-26"` — not computed from any data source.
- **Hardcoded/Mock Data:** The "Industry avg: 65%" subtitle (line 156) for approval rate is hardcoded.
- **Hardcoded/Mock Data:** Branch details section has entirely hardcoded content: branch subtitle `"Mumbai Central office information"` (line 249), branch code `"BR-MUM-01"` (line 270), region `"Western India"` (line 272), branch manager `"Anil Deshmukh"` (line 274), phone `"+91 22 6678 9100"` (line 276), and address `"BKC Capital Towers, G Block, Bandra East, Mumbai, 400051"` (line 278). None of this comes from the backend.
- **Missing Logic:** The settings toggles (`enableNotifications`, `enableBiometrics`, `syncOnCellular`) are purely local `@State`; they are not persisted anywhere (UserDefaults, backend) and reset on every view appearance.
- **Missing Logic:** The digital signature pad "Save Signature" button (line 445-460) only flips a local boolean `isSignatureSaved`. The signature drawing is never serialized, uploaded, or persisted in any way.
- **Performance:** The `PerformanceGridView` accesses `viewModel.kpiData` by hardcoded indices `[0]` and `[1]` (lines 144, 162). If `kpiData` order changes, the wrong values will display. Uses bounds-checking but couples tightly to array ordering.

---

### `LoanOfficerStore.swift`
**Purpose:** A one-line typealias mapping `LoanOfficerStore` to `AppViewModel` for naming compatibility with the manager stack.
**Flaws:**
- ✅ No flaws found.

---

### `LoanReviewView.swift`
**Purpose:** The most complex view — a full loan application review screen with segmented tabs (Overview, Documents, Actions), borrower profile card, validation checklist, loan details with repayment summary, document KYC section, collateral details, application timeline, and action buttons (approve/reject/escalate/request documents).
**Flaws:**
- **Missing Logic:** The `currentApplication` computed property (line 53-54) force-unwraps `application!` — while guarded by a conditional branch, this pattern is fragile. If the guard structure changes, it will crash.
- **Missing Logic:** The collateral section (lines 788-838) reads from `viewModel.collateral`, a single global collateral object, rather than from the specific application under review. If there are multiple applications, they all show the same (empty) collateral data.
- **Missing Logic:** The escalation level selector (line 1152) is hardcoded to always show "Branch Manager" as selected with no ability to pick other levels. The `isSelected: true` is always true.
- **UI Issue:** The "Send Back for Revision" action (line 158-163) uses a hardcoded remark string `"Application sent back for revision."` instead of including the officer's typed remarks.
- **Missing Logic:** The `messageBorrowerButton` fallback (line 452-458) matches conversations by `borrowerName` string comparison, which is unreliable if two borrowers share the same name.

---

### `LOAppViewModel.swift`
**Purpose:** The central `@Observable` view model driving all Loan Officer screens. Handles data fetching from backend services, KPI computation, application lifecycle actions (approve/reject/escalate/send-back), document requests, notification management, and conversation threading.
**Flaws:**
- **Hardcoded/Mock Data:** `selectedBranch` is initialized to `"Mumbai Central"` (line 20) and the `branches` array (line 88) is hardcoded to 6 specific branch names. These should come from the backend.
- **Hardcoded/Mock Data:** `pendingCount`, `approvedCount`, `escalatedCount` private vars are initialized to `47`, `132`, `8` respectively (lines 66-68). Although they are overwritten by `recalculateKPIs()`, if `refreshAll()` fails they remain at these stale values.
- **Hardcoded/Mock Data:** The fallback `officerID` on line 129 falls back to `MockOfficerData.officerUserID` (a hardcoded test UUID `22222222-2222-2222-2222-222222222222`), which could leak into production if auth fails.
- **Hardcoded/Mock Data:** KPI `trend` values in `updateKPIs()` (lines 445-448) are hardcoded constants (12.3, 8.7, -3.2, -5.1) and `chartData` arrays are hardcoded sparkline values — not computed from real data.
- **Missing Logic:** The `refreshAll()` catch block (lines 280-282) silently swallows all errors with a comment "Keep the seeded sample data." There's no user-facing error state, no retry mechanism, and no logging.
- **Missing Logic:** `makeOfficerApplication` hardcodes `riskLevel: .low` (line 338), `fraudFlag: false` (line 340), `employer: "—"` (line 347), `existingLiabilities: 0` (line 349), and `purpose: "—"` (line 355) for all backend-sourced applications. These fields are never populated from the backend.
- **Missing Logic:** The `eligibilityScore` calculation (line 350) is a naive ternary: `creditScore > 700 ? 85 : 50`. This is not a real eligibility computation.
- **Missing Logic:** The `emiAmount` calculation (line 351) is `amount / tenure` — a simple division that ignores interest entirely. Real EMI = P×r×(1+r)^n / ((1+r)^n - 1).
- **Performance:** `refreshAll()` performs N+1 queries: for each application, it fetches events and documents individually inside `withTaskGroup`. While parallelized, this is still O(N) network calls per application.
- **Missing Logic:** Notification `isRead` is always set to `false` (line 274) even for notifications that may have been read on the server.
- **Missing Logic:** `collateral` is initialized to an empty struct and never populated from any backend data source anywhere in the file.
- **Security:** Backend sync errors in `updateDocumentReview` (line 853), `syncStatus` (lines 434-438), and `requestDocument` (line 667) are silently caught with `try?` or `print()`, leaving the local state out of sync with the backend with no recovery.

---

### `LOConversationView.swift`
**Purpose:** A real-time chat view bound to the actual backend messaging thread for an application. Loads messages from the backend, supports sending new messages, and marks threads as read.
**Flaws:**
- **Missing Logic:** There is no real-time/polling mechanism to receive new incoming messages after the initial load. The view loads once via `.task` but never refreshes, so new messages from the borrower won't appear until the view is re-opened.
- **Missing Logic:** If `send()` fails (`try? await` returns nil on line 134), the draft text is restored but no error message is shown to the user.

---

### `LOModels.swift`
**Purpose:** Defines all data models, enums, and formatters used across the Loan Officer module — including risk levels, loan/document/KYC statuses, loan applications, documents, collateral, overdue borrowers, field visits, notifications, chat messages, conversations, activities, digital documents, quick actions, app destinations, and currency/date formatters.
**Flaws:**
- **Performance:** `AppFormatters.currencyFormatter` creates a `NumberFormatter` as a static let — this is fine, but `formatDate` and `formatTime` (lines 863-873) create new `DateFormatter` instances on every call. These should be static.
- **Missing Logic:** `LOLoanApplication` generates a new random `UUID()` for `id` on every initialization (line 516). Since the struct is not persisted and conforms to `Hashable`, this means two instances created from the same backend data will never be equal by `id`.
- **Missing Logic:** `CollateralInfo.revaluationHistory` is typed as `[(date: Date, value: Double)]` — a tuple array that doesn't conform to `Codable`, preventing serialization.
- **UI Issue:** `LOLoanApplication.address` (line 555) is a single `String` field, but addresses are typically multi-part. The flat string may render poorly in the UI compared to structured address display.

---

### `LOSharedComponents.swift`
**Purpose:** A library of reusable UI components used throughout the LO module: premium card, glass card, gradient card, status badge, circular progress, section header, avatar, floating action button, empty state, shimmer effect, detail row, and count badge.
**Flaws:**
- **UI Issue (Dark Mode):** `LOPremiumCard` (line 45) hardcodes the fill color to `Color(.white)`. This will look incorrect in dark mode — the card background will remain white instead of adapting to the system's dark background colors.
- **UI Issue:** `LOShimmerModifier` uses a hardcoded `phase = 300` (line 315) which may not work correctly for all view widths — narrow views will see no shimmer, wide views may have a too-fast shimmer.
- **UI Issue:** `LOGlassCardModifier` uses `.ultraThinMaterial` with a white stroke overlay (line 17, `Color.white.opacity(0.15)`), which may be invisible or look wrong in dark mode.

---

### `MockOfficerData.swift`
**Purpose:** Contains a fallback mock officer UUID for offline/testing and a commented-out officer profile. The `OfficerProfileSummary` struct provides a simple name/employeeID/branch profile type.
**Flaws:**
- **Hardcoded/Mock Data:** The hardcoded UUID `22222222-2222-2222-2222-222222222222` (line 18) is used as a fallback officer ID in `LOAppViewModel.refreshAll()`, which could leak to production if auth is unavailable.
- **Hardcoded/Mock Data:** The commented-out block still contains mock officer name "Sarah Mehta", employee ID "LO-2041", branch "Bengaluru — MG Road".

---

### `NotificationsTabView.swift`
**Purpose:** Displays a filterable list of notifications (All/Alerts/Activity) with swipe actions for mark-read/delete, an unread summary card, and deep-linking to specific loan applications on tap.
**Flaws:**
- **Missing Logic:** The notification deep-link (lines 247-253) matches by borrower name substring in the title/message. This is fragile — it will fail for system notifications that don't contain a borrower name, and may match the wrong application if names are substrings of each other.
- **UI Issue:** The priority "Urgent" badge (line 232) only shows for `priority == 1`, but notifications fetched from the backend are all set to `priority: 2` (line 274 in LOAppViewModel). So the "Urgent" badge will never appear for backend-sourced notifications.
- **Missing Logic:** The "Mark All Read" toolbar button is commented out (lines 124-135).

---

### `OfficerCompatibilityModels.swift`
**Purpose:** Defines seed/mock borrower data and sample loan applications used as fallback data for offline development and previews. Also provides `OfficerApplication` and `OfficerNotification` compatibility models.
**Flaws:**
- **Hardcoded/Mock Data (Critical):** Contains 4 fully hardcoded seed borrowers with names (Priya Sharma, Arjun Mehta, Anita Desai, Rahul Sharma), hardcoded UUIDs, addresses, PAN numbers, Aadhaar last-4, credit scores, and full profiles. Also contains 4 hardcoded `LoanApplication` objects with fixed UUIDs and amounts.
- **Security:** Hardcoded PAN numbers (`ABCDE1234F`, etc.) and Aadhaar last-4 digits are present in the source code. Even though these are mock, they follow real PAN format patterns.
- **Missing Logic:** The `OfficerApplication` struct and `OfficerNotification` struct appear to be unused legacy compatibility models — they duplicate functionality in `LOLoanApplication` and `AppNotification`.
- **Hardcoded/Mock Data:** `creditScore` fallback is `720` (line 52) when profile has no credit score — this is an arbitrary "good" score that could mask missing data.

---

### `RecoveryManagementMainView.swift`
**Purpose:** Shows a filtered list of applications needing recovery attention (pending status or critical risk), with message and view-details action buttons per borrower.
**Flaws:**
- **Missing Logic:** The recovery filter (line 48-49) shows applications with `status == .pending || riskLevel == .critical`. This is a very coarse filter — it doesn't use the `overdueBorrowers` array which has actual overdue data. Pending applications are not necessarily recovery cases.
- **UI Issue:** Each card shows `emiAmount` labeled as "Pending EMI" (line 95), but `emiAmount` is the regular monthly EMI, not the overdue/pending amount. This is misleading.
- **Missing Logic:** The "Message" button (lines 124-136) tries to match a conversation by `borrowerName`, navigates to `AppDestination.communications` (the full communications list) instead of opening a direct chat, and silently does nothing if no matching conversation exists.

---

### `RecoveryVerificationView.swift`
**Purpose:** A detailed recovery screen showing an overall collection efficiency gauge, priority breakdown, and expandable overdue borrower cards with contact/follow-up/note logging actions.
**Flaws:**
- **Missing Logic:** The "Log Call" button (lines 426-439) directly calls `viewModel.markBorrowerContacted(borrower)` which only updates `lastContactDate` and increments `contactAttempts` locally. It doesn't persist the call log to any backend, doesn't record the outcome, and doesn't use the call log sheet.
- **Missing Logic:** The "Schedule" follow-up sheet (lines 597-665) saves by calling `viewModel.markBorrowerContacted(borrower)` — it does NOT actually schedule a follow-up. The `followUpDate`, `followUpOutcome`, and `followUpNotes` state values are collected but never used or persisted.
- **Missing Logic:** The "Add Note" call log sheet (lines 537-592) similarly discards `callLogNotes` and `callLogOutcome` — save just calls `markBorrowerContacted()`.
- **Missing Logic:** `collectionEfficiency` for all backend-sourced overdue borrowers is initialized to `0.0` in `LOAppViewModel` (line 201), making the overall collection efficiency gauge always show 0%.
- **Missing Logic:** No backend integration — all recovery actions (log call, add note, schedule follow-up) are purely local state modifications with no persistence.

---

## Summary of Critical Issues

| Severity | Count | Key Examples |
|----------|-------|-------------|
| **Critical** | 5 | Chat `sendMessage()` is a no-op; mock UUID fallback in production; hardcoded "₹45.8 Cr" disbursed value; all branch details hardcoded; recovery actions discard user input |
| **High** | 8 | EMI calculated without interest; eligibility score is fake ternary; collateral is never populated; fraudAlerts navigates to wrong view; KPI trends are hardcoded |
| **Medium** | 10 | Dark mode broken in LOPremiumCard; date formatters not cached; settings not persisted; no real-time chat refresh; notification priority mismatch |
| **Low** | 5 | Preview-only mock data; commented-out code; unused compatibility models |



# ==========================================
# AUDIT REPORT: Manager (ID: ef0b4944-46e5-4cfc-8792-fb240fc0fe36)
# ==========================================

Here is the complete audit of all 29 files in `StaffApp/Views/Manager/`:

---

### `ApplicationReviewView.swift`
**Purpose:** Full-screen review of a single loan application, displaying borrower summary, loan details, risk metrics, officer recommendation, documents, timeline, and an action bar for approve/reject/send-back/disburse decisions.
**Flaws:**
- **Missing Logic (document verification not persisted):** Toggling document verification (lines 308-309) updates only local `verifiedDocs` set; changes are never saved back to the backend. The manager could verify all docs, leave the screen, and the state is lost.
- **Missing Error Handling:** `documents` fetch in `.task` (line 58) silently swallows errors with `(try? await …) ?? []`; the user gets no feedback if document loading fails.
- **UI Issue (Timeline accuracy):** The "Under Review" step (line 230) shows hardcoded subtitle `"Risk assessment completed"` regardless of the actual assessment state.

---

### `ApproveModalView.swift`
**Purpose:** Modal sheet for confirming loan approval with optional remarks and a "Notify Borrower" toggle.
**Flaws:**
- **Hardcoded/Mock Data:** The remarks text field is pre-populated with `"Excellent credit profile, approved for full amount."` (line 8). This placeholder text will be submitted as actual approval remarks if the manager doesn't change it, leaking mock copy into production audit trails.
- **Missing Logic (`notifyBorrower` toggle is cosmetic):** The `notifyBorrower` state (line 9) is never passed to `onComplete` or used anywhere — toggling it has no effect.

---

### `AuditLogsView.swift`
**Purpose:** Displays a searchable, filterable list of audit log entries grouped by date, showing the manager's actions (approved, rejected, sent back, etc.).
**Flaws:**
- **Performance (force unwrap in sort):** Line 31 uses `$0.value.first!.timestamp` — if `Dictionary(grouping:)` ever produces an empty group (shouldn't normally, but fragile), this will crash.
- **Missing Logic:** No pagination; the store loads up to 50 logs, but the view has no "load more" mechanism for managers with extensive histories.

---

### `DailyReportPreviewView.swift`
**Purpose:** Read-only preview of a generated daily report, showing KPI cards (loans disbursed, amount, EMI collected, pending collections) and activity summaries.
**Flaws:**
- ✅ No flaws found.

---

### `LoanPoliciesView.swift`
**Purpose:** Lists active and inactive loan product policies (interest rates, tenure, max amount) with tap-to-edit navigation.
**Flaws:**
- ✅ No flaws found.

---

### `LoanPolicyEditSheet.swift`
**Purpose:** A Form-based sheet allowing the manager to edit interest rates, tenure, and active status of a loan policy, with save confirmation.
**Flaws:**
- **Missing Logic (validation):** There is no validation that `interestRateMin <= interestRateMax`. A manager can set min > max (e.g., min 15%, max 10%), and the invalid policy will be saved to the backend.
- **UI Issue:** The "Max Amount" field (line 75-78) is read-only (`LabeledContent`) with no way to edit it, but the user might expect to change it since everything else is editable.

---

### `ManagerApplicationsTabView.swift`
**Purpose:** The primary "Applications" tab root view, showing a priority queue (pending/escalated/sent-back counts), a "Review Applications" CTA, recent decisions feed, and a smart insight banner.
**Flaws:**
- **Hardcoded/Mock Data:** The smart insight banner (line 198) shows hardcoded text `"Approval rate increased 2.5% this week"` — this is a placeholder string that does not come from any computed or backend data.

---

### `ManagerApplicationsView.swift`
**Purpose:** Scrollable, filterable list of all loan applications showing applicant cards with risk badges, amounts, officers, and status.
**Flaws:**
- **Missing Error Handling (quick actions):** Context menu "Quick Approve" and "Quick Reject" (lines 147, 155) use `try? await` — errors are silently discarded. The user gets no feedback if the action fails.
- **Missing Logic:** Quick approve/reject from the context menu uses hardcoded remarks strings `"Quick approved from list."` / `"Quick rejected from list."` (lines 147, 155), which may not meet audit/compliance requirements for documenting reasons.

---

### `ManagerDashboardView.swift`
**Purpose:** An alternative dashboard view (separate from the tab view) showing priority actions, today's summary (approved/rejected counts), branch performance metrics, and a smart insight banner.
**Flaws:**
- **UI Issue (redundant text):** The smart insights section (lines 223-226) shows two nearly identical lines: `"\(store.highRiskCount) high-risk applications need attention"` and `"\(store.highRiskCount) applications need urgent review"` — appears to be a copy-paste leftover.
- **Missing Logic:** All three priority cards (lines 86-97) navigate to the same route `ManagerRoute.applications` without passing a filter, unlike `ManagerApplicationsTabView` which passes `.pending`, `.escalated`, `.sentBack`. Tapping "Escalated" or "Sent Back" just opens the unfiltered list.

---

### `ManagerModels.swift`
**Purpose:** Defines all view models, enums, and data structs used across the Manager module: `ManagerApplication`, `ApplicationActionType`, `ManagerRecentAction`, navigation routes, portfolio models, officer performance data, audit logs, reports, risk alerts, and loan policies.
**Flaws:**
- **Missing Logic (ManagerRecentAction ID stability):** `ManagerRecentAction.id` uses `let id = UUID()` (line 155), generating a new ID each time the struct is created. This means list identity breaks on every refresh, causing unnecessary re-renders and losing scroll position.
- **Missing Logic (same for OfficerDecisionRecord, ManagerAuditLogEntry, etc.):** Multiple model structs (`OfficerDecisionRecord` line 239, `ManagerAuditLogEntry` line 250, `RiskAlert` line 354, `LoanCategoryBreakdown` line 207, `BranchPerformanceItem` line 217, `OfficerPerformanceData` line 227) all use `let id = UUID()` — these are regenerated on each decode/refresh cycle, which harms SwiftUI list diffing.
- **Hardcoded/Mock Data (reference code):** `ManagerApplication.referenceCode` (line 70) generates a display code by slicing the UUID: `"LN-" + prefix(6)`. This is fragile and could collide across applications.

---

### `ManagerNavigation.swift`
**Purpose:** Provides `ManagerNavigationStack`, a generic NavigationStack wrapper that resolves all `ManagerRoute` destinations, plus a `ManagerNotificationsView` for the notification feed.
**Flaws:**
- **Missing Logic (notification read persistence):** `markNotificationRead` and `dismissNotification` (lines 78, 85) only update local state in the store — the backend `notifications` table `is_read` column is never updated. Reopening the app will show previously-read notifications as unread again.

---

### `ManagerPortfolioView.swift`
**Purpose:** The "Dashboard" / portfolio tab showing summary cards (total loans, disbursement, collection, NPA), portfolio health bar, loan categories, officer performance list, branch performance, collection health, and NPA monitoring.
**Flaws:**
- **Missing Logic (Officer Performance "See All" is a no-op):** The `SectionHeader` action for "Officer Performance" → "See All" (lines 320-322) has an empty closure `{}`. Tapping "See All" does nothing.
- **Missing Logic (Branch Performance "Officers" is a no-op):** Similarly, the `SectionHeader` for "Branch Performance" → "Officers" (lines 267-270) also has an empty closure.

---

### `ManagerProfileSubViews.swift`
**Purpose:** Intended to hold sub-views for the manager profile screen.
**Flaws:**
- **Missing Logic (empty file):** The file is completely empty (0 bytes). It is either unused dead code or represents unfinished/abandoned work.

---

### `ManagerProfileView.swift`
**Purpose:** Manager's profile settings screen with notification preferences, security options, help links, app version, and sign-out.
**Flaws:**
- **Hardcoded/Mock Data:** App version is hardcoded as `"1.0.0 (Build 42)"` (line 118). This should use the actual bundle version.
- **Missing Logic (preferences are not persisted):** Toggles for `notificationsEnabled`, `emailAlerts`, `riskAlerts`, `biometricEnabled` (lines 8-11) are all local `@State` — changes are lost when leaving the screen. They are never saved to UserDefaults or backend.
- **Missing Logic (placeholder screens):** "Change Password", "Two-Factor Authentication", "Help & FAQ", and "Contact Support" all navigate to a `placeholderDetail()` view (lines 83-115) that just shows the title text — these features are completely unimplemented.
- **Security:** `try? await env?.auth.signOut()` (line 146) silently ignores sign-out errors, which could leave the session in an inconsistent state.

---

### `ManagerRecentDecisionsView.swift`
**Purpose:** Full "Recent Decisions" screen with summary metric cards (approved/rejected/returned counts), filter chips, and a scrollable list of decision rows linking to application reviews.
**Flaws:**
- ✅ No flaws found.

---

### `ManagerReportsView.swift`
**Purpose:** The "Reports" tab allowing generation of Daily/Weekly/Monthly/NPA reports in PDF or CSV format, with report history list, preview sheets, share functionality, and storage management.
**Flaws:**
- **Hardcoded/Mock Data:** `reportPeriod` helper (line 287) has a hardcoded `"Q1 2026"` for NPA and collection-efficiency report types instead of computing the actual quarter.
- **Missing Logic:** The `reportPeriod` function (lines 282-289) is defined but never called anywhere in the file — dead code.

---

### `ManagerStore.swift`
**Purpose:** The central `@Observable` data store for all Manager screens, handling Supabase data fetching, application decisions, disbursement, notifications, report generation/persistence, risk alerts, loan policies, and portfolio/report computations.
**Flaws:**
- **Missing Error Handling (silent catch blocks):** Nearly every `load*` function catches errors with `/* keep existing state */` (lines 241, 362, 437, 472, 511, 564, 596, 813). Failures are invisible to both the user and the developer in production.
- **Missing Logic (sendBack handling):** The `decide()` function (lines 891-948) has abandoned comment scaffolding (lines 901-906) about `sendBack` not being supported by `updateStatus`, but proceeds to call `updateStatus` anyway. If the backend doesn't support `additionalInfoRequired` status, it will throw, and the user will see a raw error.
- **Missing Logic (notification mutations not persisted to backend):** `markAllNotificationsRead`, `markNotificationRead`, `dismissNotification` (lines 990-1001) only mutate local arrays — the `is_read` field in the `notifications` table is never updated.
- **Missing Logic (risk alert mutations not persisted):** `markRiskAlertRead` and `dismissRiskAlert` (lines 1097-1104) are purely local; there is no backend persistence.
- **Performance (N+1-like pattern in loadApplications):** `loadApplications` (lines 278-293) uses `withTaskGroup` to fetch borrower profiles individually for each unique borrower ID. For branches with many borrowers, this fires many concurrent Supabase queries.
- **Missing Logic (minCreditScore, maxDTIRatio defaults):** `defaultMinCreditScore` and `defaultMaxDTI` (lines 365-377) use hardcoded fallback values rather than reading from the loan_products table, which may not have these columns. If the backend adds these fields later, these defaults will silently override them.
- **Hardcoded/Mock Data (loan type inference):** `loanType(fromProductName:)` (lines 816-823) uses string-contains matching (`"home"`, `"business"`, etc.) to infer loan types from product names. This is fragile and will misclassify any product whose name doesn't contain the expected substring.
- **Performance:** `loadPortfolioAndReports` (lines 601-813) fetches the entire `loans` and `emis` tables with no filters — as the database grows, this will become extremely slow and memory-intensive.
- **Missing Logic (report history encoder/decoder mismatch):** `saveReportHistory` uses a bare `JSONEncoder()` (line 1084) while loading uses `JSONDecoder()` (line 1090). The store's Supabase decoder uses a custom `SupabaseManager.shared.decoder` with date strategies. If `ReportItem.generatedAt` date encoding differs between the two, history loading may silently fail.
- **Security:** `loadOfficerPerformance` (line 519) fetches all users with `role = "loan_officer"` across the entire system, not scoped to the manager's branch. A manager could see officers from other branches.

---

### `MockManagerData.swift`
**Purpose:** DEBUG-only seed data factory providing realistic mock applications, recent actions, notifications, portfolio metrics, officer performance, audit logs, report history, risk alerts, and loan policies for SwiftUI previews.
**Flaws:**
- **Hardcoded/Mock Data (by design, but guarded):** Entire file is wrapped in `#if DEBUG`, so mock data cannot leak into production builds. This is correct.
- ✅ No production flaws found (file is properly gated behind `#if DEBUG`).

---

### `MonthlyReportPreviewView.swift`
**Purpose:** Read-only preview of a monthly report with KPIs (interest earned, total profit), revenue/profit section, loan performance, and a donut chart of loan type analytics.
**Flaws:**
- ✅ No flaws found.

---

### `NPAReportPreviewView.swift`
**Purpose:** Read-only preview of an NPA (Non-Performing Assets) analysis report showing NPA loans, ratio, amounts, overdue EMIs, and risk segmentation.
**Flaws:**
- ✅ No flaws found.

---

### `OfficerDetailView.swift`
**Purpose:** Detail screen for a specific loan officer, showing avatar/name, performance metrics (applications processed, approval rate, avg time, recovery rate), and their recent decisions.
**Flaws:**
- **Missing Logic (recovery rate always "—" or 0):** In `ManagerStore.loadOfficerPerformance()`, `recoveryRate` is hardcoded to `0` (line 561) and `avgDecisionTime` to `"—"` (line 560) because they are never computed from real data. The metric tiles will always show `0%` recovery and `—` avg time in production.

---

### `OfficerPerformanceView.swift`
**Purpose:** Searchable list of all loan officers with team summary metrics (officer count, total processed, avg approval rate) and per-officer rows showing stats.
**Flaws:**
- **Missing Logic (avgDecisionTime always "—"):** Same underlying issue as OfficerDetailView — the store never computes per-officer average decision time, so it always displays "—".

---

### `RejectModalView.swift`
**Purpose:** Modal sheet for rejecting a loan application, allowing the manager to select a primary reason (Credit Risk/Income Risk/Documentation/Other) and add optional remarks.
**Flaws:**
- ✅ No flaws found.

---

### `ReportComponents.swift`
**Purpose:** Reusable SwiftUI components for report previews: `ReportSectionCard`, `ReportDetailRow`, `ReportKPICard`, and `OverdueCustomerRow`.
**Flaws:**
- **Missing Logic (unused component):** `OverdueCustomerRow` (lines 82-110) references the `OverdueCustomer` model but is never used anywhere in any report preview view. It appears to be dead code.

---

### `ReportGenerator.swift`
**Purpose:** Generates PDF and CSV report files on disk from report snapshots, with proper A4 layout, section headers, data rows, and footer.
**Flaws:**
- **Performance/Threading:** PDF generation uses `UIGraphicsPDFRenderer` which requires UIKit and implicitly relies on the main thread for some operations. Although it's dispatched via `Task.detached` (line 1032 in ManagerStore), `UIGraphicsPDFRenderer` may not be fully thread-safe on all iOS versions.
- **Missing Logic (no page overflow handling):** The PDF drawing functions don't check if `y` exceeds the page height (`842` points). For reports with many rows (e.g., many overdue accounts), content will be drawn off-page and be invisible.

---

### `RiskAlertsView.swift`
**Purpose:** Filterable list of risk alerts (critical/high/medium) with swipe-to-read and swipe-to-dismiss actions.
**Flaws:**
- **Missing Logic (dismiss/read not persisted):** As noted in ManagerStore, marking alerts read or dismissing them is purely local — no backend persistence. Alerts reappear on next app launch.

---

### `SendBackModalView.swift`
**Purpose:** Modal sheet for sending an application back to the originating loan officer, with multi-select reasons (Missing Documents, Incorrect Data, etc.) and optional remarks.
**Flaws:**
- ✅ No flaws found.

---

### `SuccessStateView.swift`
**Purpose:** Full-screen success confirmation shown after a decision (approve/reject/send-back), with a hero icon, title/subtitle, and "Done" / "Review Next Application" buttons.
**Flaws:**
- **Missing Logic:** The "Review Next Application" button (lines 47-56) calls the same `onFinish()` as "Done" — it doesn't actually navigate to the next application. It just dismisses the view.

---

### `WeeklyReportPreviewView.swift`
**Purpose:** Read-only preview of a weekly report showing loan growth, recovery performance, repayment collection metrics, and overdue/defaulter accounts.
**Flaws:**
- ✅ No flaws found.

---

**Summary of Critical Issues Across the Module:**

| Category | Count | Key Files |
|---|---|---|
| Missing Logic | 18 | ManagerStore, ManagerProfileView, ManagerPortfolioView, ManagerNavigation, OfficerDetailView, etc. |
| Hardcoded/Mock Data | 5 | ApproveModalView, ManagerApplicationsTabView, ManagerDashboardView, ManagerProfileView, ManagerReportsView |
| Missing Error Handling | 4 | ManagerStore, ApplicationReviewView, ManagerApplicationsView |
| Performance | 3 | ManagerStore (full table scans, N+1 profiles), AuditLogsView, ReportGenerator |
| Security | 2 | ManagerStore (cross-branch officer visibility), ManagerProfileView (silent sign-out failure) |
| UI Issue | 3 | ManagerDashboardView (redundant text), LoanPolicyEditSheet (read-only field), ApplicationReviewView (hardcoded timeline) |



# ==========================================
# AUDIT REPORT: Admin & Staff Core (ID: a126dd24-bec1-4eed-8c13-675b4a35ac39)
# ==========================================

## Audit Report — StaffApp (30 files)

---

### `StaffApp/App/StaffApp.swift`
**Purpose:** The @main entry point for the Staff app. Initializes the `SessionStore`, `AppEnvironment` (with real Supabase services), and injects them as environment values into `StaffRootView`.
**Flaws:**
- **Hardcoded/Mock Data:** Uses `MockNotificationService()` in production `AppEnvironment` (line 28). Notifications will be non-functional in production.
- **Hardcoded/Mock Data:** Commented-out block (lines 8–21) contains hardcoded mock user data (`sarah.mehta@example.com`, `MockOfficerData`). While commented out, it signals mock-data coupling and risks accidental re-enablement.

---

### `StaffApp/App/StaffRootView.swift`
**Purpose:** Root navigation view that switches between role-based tab views (Officer, Manager, Admin) or the login screen based on session role.
**Flaws:**
- **Missing Logic:** `AdminTabView()` (line 30) is the only role that receives no environment stores (no `officerStore`/`managerStore` injection, no `.task` configuration call). Unlike Officer and Manager, there's no `configure()` call ensuring the admin environment is wired.
- **UI Issue:** A `[DEBUG]` print statement is left in production code (line 25): `print("[DEBUG] manager .task fired, env=...")`.
- **Missing Logic:** For Manager and Officer, `appEnvironment` is optionally unwrapped (`if let appEnvironment`), but if it's nil, the stores are silently never configured — no error feedback to the user.

---

### `StaffApp/Views/ReportsView.swift`
**Purpose:** A reports listing screen with quick-action tiles (Daily, Weekly, Monthly, NPA) and a list of recent exports with file sizes and dates.
**Flaws:**
- **Hardcoded/Mock Data:** The entire view is driven by hardcoded static mock data (`recentExports` on lines 203–209): file names ("Daily Report — May 25"), sizes ("1.2 MB"), and dates ("2h ago") are all static strings, not fetched from any backend.
- **Hardcoded/Mock Data:** Storage size "12.4 MB" is hardcoded (line 78).
- **Missing Logic (Stubbed):** Report generation button action at line 101 is a TODO (`// TODO: trigger actual report generation`) — tapping a quick action does nothing.
- **Missing Logic (Stubbed):** Share/download button action at line 166 is a TODO (`// TODO: share / download`) — tapping share does nothing.
- **Missing Logic (Stubbed):** "Clear Old Exports" button action at line 83 is a TODO (`// TODO: clear old exports`) — the button does nothing.

---

### `StaffApp/Views/RoleTabViews.swift`
**Purpose:** Defines the tab bar views for Officer, Manager, and Admin roles. Includes `OfficerNavigationStack` with shared navigation destinations.
**Flaws:**
- **Missing Logic:** `OfficerNavigationStack` has `.fraudAlerts` destination routing to `LoanReviewView()` (line 45), which appears to be a placeholder — fraud alerts should go to a dedicated fraud alerts view.
- **Missing Logic:** `AdminTabView` calls `userManagementViewModel.load()` and `loanConfigViewModel.load()` in its `.task`, but does NOT call `templateViewModel.configure(environment:)` or load templates, nor `dashboardViewModel.configure()` — dashboard configuration happens in `AdminDashboardView` itself, which is fine, but templates are never loaded at startup so `TemplateListView` starts empty.

---

### `StaffApp/Views/StaffLoginView.swift`
**Purpose:** Login view with email/password fields that authenticates against the Supabase auth service and sets the session user on success.
**Flaws:**
- **Security:** Email validation is minimal — only checks `!email.isEmpty`. There's no regex or format validation for email; `email.contains("@")` is not checked here (though AddStaffSheet does check it).
- **Missing Logic:** No "Forgot Password" flow or link — common for staff portals.
- **UI Issue:** The preview at line 79 (`#Preview { StaffLoginView() }`) will crash or be blank because `SessionStore` is not injected into the environment.

---

### `StaffApp/Views/StaffProfileView.swift`
**Purpose:** Minimal profile screen showing name/email/role from session and a sign-out button.
**Flaws:**
- **Missing Logic:** `signOut()` silently swallows errors with `try?` (line 22). If sign-out fails, the user gets no error feedback but the session is still cleared locally — potential desync.
- **Missing Logic:** No confirmation dialog before sign-out — the destructive action executes immediately on tap.
- **UI Issue:** The dismiss environment is declared (line 6) but never used — the sheet is never dismissed after sign-out.

---

### `StaffApp/Views/TwoFactorAuthView.swift.swift`
**Purpose:** Intended to be a Two-Factor Authentication view.
**Flaws:**
- **Missing Logic:** The file is completely empty (0 bytes, 1 blank line). The entire 2FA feature is unimplemented.
- **UI Issue:** The filename has a double `.swift.swift` extension — likely a naming error.

---

### `StaffApp/Views/Admin/AddLoanProductSheet.swift`
**Purpose:** A form sheet for admins to create new loan products with name, category, amounts, interest rate, and tenure.
**Flaws:**
- **Missing Logic:** Duplicate check (line 135) only compares by name (case-insensitive) within the in-memory `productsByCategory`. If the backend has products not yet loaded, duplicates could slip through.
- **UI Issue:** After a save failure, `isSaving` is set back to false (line 156), but the user stays on the sheet with just an alert — no way to distinguish between a transient error and a permanent one.
- ✅ Otherwise well-structured with proper validation.

---

### `StaffApp/Views/Admin/AddReminderScheduleSheet.swift`
**Purpose:** A form sheet for creating or editing EMI reminder schedules with timing, delivery channels, and a template body with live preview.
**Flaws:**
- **Hardcoded/Mock Data:** Live preview uses hardcoded sample values (lines 51–55): "Naman Gupta", "₹8,452", "25 May 2026" — these are baked into the UI preview and not fetched from any source.
- **Hardcoded/Mock Data:** Conflict detection logic (lines 36–38) is a fake simulation (`hasPotentialConflict`) that checks for hardcoded conditions (`timingType == .on || timingDays == 5`) instead of actually checking against existing schedules.
- **Missing Logic:** The `onSave` callback creates a `ReminderSchedule` with a local `UUID()` (line 290) but there is no backend persistence — the data only lives in local `@State`.

---

### `StaffApp/Views/Admin/AddStaffSheet.swift`
**Purpose:** Admin form to create a new staff member (loan officer or manager) with name, email, employee ID, role, and temporary password.
**Flaws:**
- **Security:** The temporary password is transmitted as plain text through `viewModel.createStaff(temporaryPassword:)` (line 98). No client-side hashing is done.
- **Missing Logic:** The `creatableRoles` array (line 19) excludes `.admin`, but there's no UI message explaining why "Admin" isn't an option — could confuse admins.
- **UI Issue:** Email validation only checks `email.contains("@")` (line 23) — very loose validation; "a@" would pass.

---

### `StaffApp/Views/Admin/AddTemplateSheet.swift`
**Purpose:** A sheet for creating new notification templates with trigger event, title, delivery channels, and message body.
**Flaws:**
- **Missing Logic:** `handleCreateTemplate()` (line 129) calls `viewModel.createTemplate()` which only appends to the local in-memory `templates` array — no backend persistence. Templates are lost on app restart.
- **Hardcoded/Mock Data:** Default body text (line 16) is a hardcoded generic congratulations message.

---

### `StaffApp/Views/Admin/AdminApplicationDetailView.swift`
**Purpose:** Displays detailed loan application info with a processing timeline, showing borrower, assigned officer, manager, and loan events.
**Flaws:**
- **Performance / N+1 Pattern:** `fetchUser()` (lines 459–463, 471, 482) is called individually for borrower, loan officer, and manager — up to 4 separate DB round-trips for user lookups. Should batch these into a single query.
- **Hardcoded/Mock Data (DEBUG):** `loadMockDetails()` (lines 534–548) contains hardcoded names ("Priya Sharma", "Sarah Mehta", "Aditi Rao") in a `#if DEBUG` block. Safe from production leak, but coupled to mock data.
- **Missing Logic:** The `DateFormatter` (lines 146–148) is created inside `computeStages()` which is called on every re-render — should be a static/cached formatter for performance.

---

### `StaffApp/Views/Admin/AdminDashboardView.swift`
**Purpose:** The admin overview dashboard showing total distribution amount, key stats (users, active loans, applications), and recent applications list.
**Flaws:**
- **UI Issue:** Stat column label "Total user" (line 117) should be "Total Users" (missing plural).
- **UI Issue:** Stat column label "Application" (line 125) should be "Applications" (missing plural).
- **Missing Logic:** `StatusBadge` tone logic (line 190–191) only differentiates `approved` → success, everything else → warning. Rejected applications should show `.danger` tone.
- **Missing Logic:** The `refreshable` block (line 69) uses `try?` which silently swallows refresh errors — user gets no feedback on failed pull-to-refresh.

---

### `StaffApp/Views/Admin/AdminFeatureModels.swift`
**Purpose:** Central file containing all admin domain models (`NotificationTemplate`, `AdminLoanProduct`, `DashboardSnapshot`, `AuditEntry`, etc.), view models (`DashboardViewModel`, `AdminApplicationDetailViewModel`, `UserManagementViewModel`, `TemplateViewModel`, `LoanConfigViewModel`), and seed/mock data.
**Flaws:**
- **Hardcoded/Mock Data:** `AdminSeedData` (lines 151–251) contains hardcoded UUIDs (`90000000-0000-...`), names ("Sarah Jenkins", "Aditi Rao", "Sarah Mehta"), emails, phone numbers, and department strings. While used for seeding, these are accessible to production code.
- **Hardcoded/Mock Data:** `NotificationTemplate.sampleTemplates` (lines 51–82) and `AdminLoanProduct.sampleProducts` (lines 111–127) are static mock data arrays embedded in production model files.
- **Hardcoded/Mock Data:** `TemplateViewModel.previewBodyText` (lines 792–808) contains hardcoded preview names ("Naman Gupta", "APP-1024", "₹3,00,000", "25 May 2026").
- **Missing Logic:** `deleteUser()` (lines 725–732) only removes locally from arrays/dictionaries — does NOT call any backend API. This is a local-only delete that will reappear on next load.
- **Missing Logic:** `updatePermissions()` (lines 734–739) only updates the local `staffProfiles` dictionary — no backend persistence. Permissions reset on app restart.
- **Missing Logic:** `TemplateViewModel` has no backend integration at all — `createTemplate()`, `updateTemplate()`, `deleteTemplates()` all operate purely in-memory. Templates are ephemeral.
- **Performance:** `DashboardViewModel.refreshDashboard()` (lines 328–388) fires 4 concurrent Supabase queries (users count, loans, apps count, recent apps). The users/apps queries fetch full rows just to count them — should use `count` aggregation.
- **Backend Integration:** `DashboardViewModel` directly accesses `SupabaseManager.shared.client` (line 330) bypassing the `AppEnvironment` service layer, creating tight coupling.
- **Backend Integration:** `AdminApplicationDetailViewModel.fetchUser()` (line 494) directly accesses `SupabaseManager.shared.client` bypassing the environment service layer.
- **Missing Logic:** `mapAppStatus()` (lines 254–267) is a free function (not namespaced), and maps "assigned" to `.submitted` which may be semantically incorrect.

---

### `StaffApp/Views/Admin/ArchiveListView.swift`
**Purpose:** Displays a filterable list of closed/settled loans that can be archived or restored, with CSV export capability.
**Flaws:**
- **Hardcoded/Mock Data:** Loan type is hardcoded to `.personal` for all loans (line 83, comment: "Simplification for UI"). The actual loan type from the product is ignored.
- **Missing Logic:** Status mapping (line 87) maps both "archived" and non-archived statuses to `.settled` — the status field is not accurately derived.
- **Missing Logic:** The `isLoading` and `hasError` states (lines 149–150) are local `@State` vars that shadow the view model's own `isLoading`/`error` — the view model's loading state is never reflected in the UI. The local `isLoading` is never set to `true`.
- **Missing Logic:** No `.task` modifier to trigger initial data load — `viewModel.load()` is never called. The list will always be empty.
- **Missing Logic:** `viewModel.configure(environment:)` is never called — the environment is never set on the view model.
- **UI Issue:** Swipe-to-restore action uses `try? await` (line 387) silently swallowing errors.

---

### `StaffApp/Views/Admin/AuditListView.swift`
**Purpose:** Displays a searchable, filterable list of audit log entries with CSV export functionality.
**Flaws:**
- **Missing Logic:** Metadata display (line 120) only shows `entry.metadata.first` — dictionary ordering in Swift is not guaranteed, so which metadata item is shown is nondeterministic.
- **UI Issue:** Audit entries lack a default sort order — they display in whatever order the backend returns them. Should explicitly sort by timestamp descending.

---

### `StaffApp/Views/Admin/DistributionDetailsView.swift`
**Purpose:** Drill-down view from the dashboard showing total distribution header, a loan portfolio breakdown bar chart, links to reports, and application status lists.
**Flaws:**
- **Hardcoded/Mock Data:** The entire `portfolioData` array (lines 68–73) is hardcoded: "₹45L" Home, "₹20.5L" Business, "₹8.5L" Personal, "₹8.2L" Vehicle with static percentages. This is not derived from actual backend data.
- **Hardcoded/Mock Data:** Reports count "7" is hardcoded (line 121, comment: "7 is just matching the mock data count").
- **UI Issue:** `statRow()` receives a `systemImage` parameter (line 148) but never uses it — dead parameter.
- **Missing Logic:** "Active Loans" drilldown (line 134) filters `recentApplications` by `.approved` status, but `recentApplications` only contains the latest 10 — this is not an accurate count of all active loans.

---

### `StaffApp/Views/Admin/EMISchedulerView.swift`
**Purpose:** Manages EMI reminder schedules with create, edit, duplicate, and delete functionality.
**Flaws:**
- **Hardcoded/Mock Data:** Initialized with `ReminderSchedule.sampleSchedules` (line 42) — the view starts with 3 hardcoded sample schedules ("Pre-Due Reminder", "Due Date Alert", "Overdue Notice").
- **Missing Logic:** No backend integration whatsoever — all CRUD operations (add, edit, duplicate, delete) operate purely on local `@State`. Data is lost on navigation away or app restart.
- **Missing Logic:** No confirmation dialog before deleting a schedule (line 82–84) — destructive action executes immediately.

---

### `StaffApp/Views/Admin/LoanConfigFormView.swift`
**Purpose:** Main form view for managing loan product configurations, grouped by category with inline editing and add/delete capabilities.
**Flaws:**
- ✅ No major flaws found. Properly wired to backend via `LoanConfigViewModel`. Has proper `.task` loading, error alerts, and sheet presentations.

---

### `StaffApp/Views/Admin/LoanProductRowView.swift`
**Purpose:** Reusable row component showing loan product summary, plus an editor sheet for modifying product parameters.
**Flaws:**
- ✅ No flaws found. Clean implementation with draft editing pattern and unsaved changes handling.

---

### `StaffApp/Views/Admin/ProfileView.swift`
**Purpose:** Admin profile view with personal info editing, change password, notification settings, language selection, and support ticket submission.
**Flaws:**
- **Hardcoded/Mock Data:** Header displays hardcoded "Sarah Jenkins" and "SYSTEM ADMIN" (lines 75–79) instead of reading from `session.currentUser`.
- **Hardcoded/Mock Data:** `PersonalInfoView` has all fields hardcoded: name "Sarah Jenkins", email "sarah.jenkins@lms.com", phone "+91 98765 43210", Employee ID "EMP-00123", Department "Administration", Office Location "Mumbai Corporate HQ" (lines 147–157, 166–168).
- **Missing Logic:** `PersonalInfoView.Save Changes` (line 198) only updates local `@State` variables — no backend API call. Changes are lost on navigation.
- **Missing Logic:** `ChangePasswordView.handleUpdatePassword()` (lines 359–365) does NOT call any backend API — it only validates passwords match locally, then shows a success alert. The password is never actually changed.
- **Missing Logic:** `NotificationSettingsDetailedView` "Save Preferences" (line 411) only shows a local success alert — no backend persistence.
- **Missing Logic:** `LanguageSelectorView` (lines 428–461) language selection only updates local `@State` — not persisted anywhere.
- **Hardcoded/Mock Data:** `SupportDetailedView` has hardcoded contact info: "1800-419-5959", "support@lms.com" (lines 476–477).
- **Hardcoded/Mock Data:** Support ticket number is randomly generated locally: `Int.random(in: 100000...999999)` (line 515) — not from backend.
- **Missing Logic:** Support ticket submission (line 498–500) doesn't call any backend — the ticket is never actually created.

---

### `StaffApp/Views/Admin/ReportsDashboardView.swift`
**Purpose:** Reports dashboard with KPI metric cards, filterable detailed breakdown of loan data, and PDF/CSV export.
**Flaws:**
- **Hardcoded/Mock Data:** Branch filter options (line 20) are hardcoded: "Main", "North", "South", "West". Should come from backend.
- **Hardcoded/Mock Data:** Loan type filter options (line 21) are hardcoded: "Personal", "Vehicle", "Home", "Education". Should match `LoanType.allCases`.
- **Hardcoded/Mock Data:** Status filter options (line 22) are hardcoded: "Active", "Closed", "Defaulted".

---

### `StaffApp/Views/Admin/ReportsViewModel.swift`
**Purpose:** View model for the reports dashboard — fetches loans, applications, products, and users from Supabase; computes KPIs; generates PDF and CSV exports.
**Flaws:**
- **Hardcoded/Mock Data:** Branch assignment (lines 112–114) uses `abs(loan.borrower_id.hashValue) % branches.count` with hardcoded branches `["Main", "North", "South", "West"]`. Branches are fabricated from a hash, not from actual data.
- **Performance / N+1:** Fetches ALL loans, ALL applications, ALL products, and ALL users (lines 90–100) into memory — no pagination or filtering. Will not scale with large datasets.
- **Performance:** The `items` mapping (line 103) does `dbApps.first(where:)` and `dbProducts.first(where:)` for each loan — O(n²) complexity. Should use dictionaries.
- **UI Issue:** PDF export uses `$` symbol for currency (lines 223–224, 255, 259) instead of `₹` — inconsistent with the rest of the app which uses Indian Rupees.
- **Security:** No XSS protection in PDF generation — `item.borrowerName` and other fields are directly interpolated into HTML (lines 217–228) without escaping.

---

### `StaffApp/Views/Admin/ShareSheet.swift`
**Purpose:** A `UIViewControllerRepresentable` wrapper around `UIActivityViewController` for sharing files.
**Flaws:**
- ✅ No flaws found. Minimal, correct implementation.

---

### `StaffApp/Views/Admin/SystemSettingsView.swift`
**Purpose:** Settings hub with navigation links to Notification Templates, Loan Configurations, EMI Reminders, Loan Archives, and Audit Trail.
**Flaws:**
- ✅ No flaws found. Clean navigation shell.

---

### `StaffApp/Views/Admin/TemplateEditorView.swift`
**Purpose:** Detail editor for notification templates with title editing, channel selection, body text editing with placeholder tokens, and borrower-facing preview.
**Flaws:**
- **Missing Logic:** `updateTemplate()` is called (line 160) but only updates in-memory state — no backend persistence (the issue is in `TemplateViewModel`, but manifests here).
- **UI Issue:** The "Save Template" button is disabled only based on `hasUnsavedChanges` (line 167), but no validation is done on empty title or empty body before saving.

---

### `StaffApp/Views/Admin/TemplateListView.swift`
**Purpose:** List view showing all notification templates with search, add, delete, and navigation to the editor.
**Flaws:**
- **Missing Logic:** Templates start empty (the `TemplateViewModel.templates` array is `[]` by default). There's no `.task` or `.onAppear` to load templates from a backend — the list depends on the parent calling `configure()` and loading data, which isn't done.
- **UI Issue:** `onDelete` (line 40) deletes templates without any confirmation dialog — destructive action executes immediately.

---

### `StaffApp/Views/Admin/TemplateRowView.swift`
**Purpose:** Reusable row component displaying a notification template's icon, title, trigger event, and body preview.
**Flaws:**
- **UI Issue:** The `isSelected` parameter is received but never used in the view's appearance — selected and unselected templates look identical.

---

### `StaffApp/Views/Admin/UserListView.swift`
**Purpose:** Main user management list with search, role-based filtering, and add staff functionality.
**Flaws:**
- ✅ No flaws found. Properly handles loading, error, empty states, and has search + filter. Backend loading and refresh are wired.

---

### `StaffApp/Views/Admin/UserRowView.swift`
**Purpose:** Reusable user row card component, plus `UserDetailsView` (role-specific detail screens with account management), and `PasswordResetSuccessSheet`.
**Flaws:**
- **Hardcoded/Mock Data:** Password reset (lines 200–217) is fully simulated — `resetPassword()` uses `Task.sleep(for: .seconds(1.2))` to fake a network call, always fails on the first attempt (`resetAttempts == 0`), and generates a local random password `"LMS-Temp-\(Int.random(...))"` on the second attempt. No actual backend password reset API is called.
- **Missing Logic:** `deleteUser()` is called (line 171) but as noted in `AdminFeatureModels`, it only removes locally — no backend API call to actually delete the user.
- **Missing Logic:** `updatePermissions()` is called (line 553) but only updates local state — no backend persistence.
- **UI Issue:** EMI status display (line 383) shows only "Paid" or "Overdue" — `.upcoming` status is labeled as "Overdue" which is incorrect.

---

## Summary of Critical Cross-Cutting Issues

| Category | Count | Severity |
|---|---|---|
| **Hardcoded/Mock Data in production paths** | 15+ instances | 🔴 High |
| **Missing backend integration (local-only ops)** | 10 features | 🔴 High |
| **Stubbed/Unimplemented functions** | 5 TODOs | 🟡 Medium |
| **Security concerns** | 3 issues | 🔴 High |
| **Performance / N+1 patterns** | 4 instances | 🟡 Medium |
| **UI label issues** | 8 instances | 🟢 Low |
| **Empty/broken files** | 1 file | 🔴 High |

**Most Critical:** `TemplateViewModel`, `EMISchedulerView`, `ProfileView` subviews, `UserDetailsView.resetPassword()`, and `UserManagementViewModel.deleteUser()/updatePermissions()` all operate purely in-memory with zero backend persistence. `ReportsView.swift` is entirely mock-driven. `TwoFactorAuthView.swift.swift` is completely empty.

