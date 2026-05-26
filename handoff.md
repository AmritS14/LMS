# LMS Project Handoff

## 1. What Has Been Done
The **BorrowerApp** is now fully functional and integrated with the NestJS backend and Supabase. We have successfully removed the majority of the mock data layers for the core loan lifecycle. 

Key achievements:
- **Loan Applications**: The application flow was completely rewritten. It now successfully creates an application (`POST /applications`), immediately prompts the user to upload their KYC documents, and securely links those documents to the newly created application (`POST /applications/:id/documents-uploaded`).
- **Document Uploads**: `SupabaseDocumentService` correctly uploads files via the NestJS endpoint (`POST /documents/upload`), enforcing proper validation and storing them in the `loan_documents` bucket.
- **EMI Payments**: The repayment dashboard now fetches actual EMI schedules for the user's active loans. The payment sheet executes real payments (`POST /emis/:id/pay`), dynamically updating the outstanding balance and EMI statuses on success.
- **Protocol Expansion**: The `LoanService` protocol was vastly expanded to include all StaffApp workflow actions (Start Review, Request Documents, Approve, Reject, Disburse). All of these are fully implemented in `SupabaseLoanService` and are ready to be called by the StaffApp.
- **Compilation**: Resolved all Swift 6 concurrency and `Sendable` warnings/errors. Specifically, the event fetching was updated to use a strongly-typed `[ApplicationEvent]` array instead of `[[String: Any]]`.

## 2. Affected Files
The following critical files were modified to achieve this state:

### UI & ViewModels (BorrowerApp)
- `BorrowerApp/Views/NewLoanApplicationView.swift`: Rewritten to support the 3-step Apply $\rightarrow$ Upload $\rightarrow$ Link workflow.
- `BorrowerApp/ViewModels/LoanApplicationViewModel.swift`: Updated to manage application state and document ID collection.
- `BorrowerApp/Views/HomeDashboardView.swift`: Updated the `PayEMISheet` integration to support asynchronous API callbacks.
- `BorrowerApp/Views/RepaymentDashboardView.swift`: Wired to the real view model; added outstanding balance metrics.
- `BorrowerApp/ViewModels/RepaymentViewModel.swift`: Integrated with `SupabaseLoanService` to execute real payments.

### Services & Models (Shared)
- `Shared/Services/LoanService.swift`: Added 10 new protocol requirements for payments and workflow transitions.
- `Shared/Services/Supabase/SupabaseLoanService.swift`: Implemented all new REST API calls to the NestJS backend.
- `Shared/Services/Supabase/SupabaseDocumentService.swift`: Mapped document kinds and statuses to the backend enums; configured multipart/form-data uploads.
- `Shared/Services/Mocks/MockLoanService.swift`: Updated to conform to the new protocol requirements so SwiftUI Previews remain functional.
- `Shared/Models.swift`: Added the `ApplicationEvent` model to ensure thread-safe concurrency (`Sendable`).

## 3. What Remains to Be Done
With the Borrower side stabilized, focus should now shift entirely to the **StaffApp**.

### Immediate Next Steps (StaffApp)
1. **Authentication & Routing**: 
   - Ensure the `StaffLoginView` successfully authenticates staff users and routes them to their specific dashboards based on their role (`loan_officer`, `manager`, `admin`).
2. **Loan Officer Dashboard**:
   - Implement views to fetch and display assigned applications (`fetchAssignedApplications(officerID:)`).
   - Wire up UI buttons to trigger the workflow APIs already built in `SupabaseLoanService` (e.g., `startReview`, `requestDocuments`, `sendToManager`).
3. **Manager Dashboard**:
   - Implement views for managers to review escalated applications.
   - Wire up UI buttons to trigger `approveApplication` and `rejectApplication`.
4. **Document Verification**:
   - Build UI in the StaffApp to view borrower documents (via `getSignedUrl`).
   - Implement API calls to `POST /documents/:id/verify` or `reject`.

### Tech Debt / Future Polish
- **Notifications**: `MockNotificationService` needs to be replaced with a real implementation (likely APNs / Supabase Edge Functions).
- **Keychain**: `MockKeychainService` should be replaced with a secure `LocalAuthentication` / Keychain wrapper for secure token storage.
