# Loan Management System (iOS)

Two-app SwiftUI scaffold for the LMS described in `SRS Loan Management System.pdf`.

## Targets

- **BorrowerApp** — customer-facing app for borrowers (apply, track, EMI dashboard, KYC, messaging).
- **StaffApp** — internal app with role-based UI for Loan Officer, Manager, and Admin.
- **Shared** — local Swift Package containing `LMSCore` (models, services, networking, persistence) and `LMSDesignSystem` (tokens, components).

## Architecture

- SwiftUI + MVVM with Swift Concurrency
- iOS 26+, Swift 6 with strict concurrency
- `@Observable` view models, `@Environment` for dependency injection
- Service layer defined as protocols in `LMSCore/Services` — provide live/mock implementations at app bootstrap
- Designed for Passkeys, role-based access, and GDPR compliance per the SRS

## Opening the project

```bash
open LMS.xcodeproj
```

`LMS.xcodeproj` is committed to source control. Add/move/delete files through Xcode (drag into the navigator, ⌥⌘A, etc.) so `project.pbxproj` stays in sync.

The two app targets (`BorrowerApp`, `StaffApp`) depend on the local Swift Package at `Shared/`. Xcode resolves it automatically on open.

## File structure

```
LMS/
├── LMS.xcodeproj                    # Xcode project (committed)
├── BorrowerApp/
│   ├── App/
│   │   ├── BorrowerApp.swift        # @main entry
│   │   └── RootView.swift           # Tab container
│   ├── Views/                       # one file per screen
│   │   ├── LoginView.swift
│   │   ├── HomeDashboardView.swift
│   │   ├── KYCView.swift
│   │   ├── NewLoanApplicationView.swift
│   │   ├── ApplicationTrackingView.swift
│   │   ├── EMICalculatorView.swift
│   │   ├── RepaymentDashboardView.swift
│   │   ├── NotificationsView.swift
│   │   ├── BorrowerMessagingView.swift
│   │   └── BorrowerProfileView.swift
│   └── ViewModels/
│       ├── AuthViewModel.swift
│       └── LoanApplicationViewModel.swift
├── StaffApp/
│   ├── App/
│   │   ├── StaffApp.swift           # @main entry
│   │   └── StaffRootView.swift      # role-aware router
│   └── Views/                       # one file per screen
│       ├── StaffLoginView.swift
│       ├── RoleTabViews.swift       # OfficerTabView / ManagerTabView / AdminTabView
│       ├── OfficerApplicationQueueView.swift
│       ├── CreditAssessmentView.swift
│       ├── SanctionLetterListView.swift
│       ├── PortfolioDashboardView.swift
│       ├── ApprovalsQueueView.swift
│       ├── ReportsView.swift
│       ├── ProductConfigView.swift
│       ├── UserManagementView.swift
│       ├── SystemSettingsView.swift
│       ├── AuditTrailView.swift
│       ├── StaffMessagingView.swift
│       └── StaffProfileView.swift
└── Shared/
    ├── Package.swift
    └── Sources/
        ├── LMSCore/
        │   ├── Models.swift         # ALL data models in one file
        │   ├── Services/            # Auth, Loan, Document, Notification, Messaging, Admin, Keychain protocols
        │   ├── Networking/          # APIClient + Endpoints
        │   ├── Persistence/         # PersistenceController protocol
        │   ├── Concurrency/         # AppEnvironment, SessionStore
        │   └── Utilities/           # EMICalculator, Validators, Formatting
        └── LMSDesignSystem/
            ├── Tokens/              # Colors, Typography, Spacing
            └── Components/          # PrimaryButton, StatusBadge, SectionCard
```

## Next steps

1. Open `LMS.xcodeproj` in Xcode and pick a scheme (`BorrowerApp` or `StaffApp`).
2. Provide concrete service implementations (`URLSession`-backed `APIClient`, Keychain-backed token store, etc.).
3. Wire `AppEnvironment` into each app's `@main` and pass through `.environment(...)`.
4. Replace `TODO` markers in feature views with view-model bindings.
5. Add asset catalog colors, app icons, and launch screen assets.
6. Configure code signing, App Group / Keychain access group if Borrower and Staff apps should share session storage.
