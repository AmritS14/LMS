# Loan Management System (iOS)

Two-app SwiftUI scaffold for the LMS described in `SRS Loan Management System.pdf`.

## Targets

- **BorrowerApp** — customer-facing app for borrowers (apply, track, EMI dashboard, KYC, messaging).
- **StaffApp** — internal app with role-based UI for Loan Officer, Manager, and Admin.

Both targets compile the same files from `Shared/` directly — there is no separate framework or Swift Package.

## Architecture

- SwiftUI + MVVM with Swift Concurrency
- iOS 26+, Swift 6 with strict concurrency
- `@Observable` view models, `@Environment` for dependency injection
- Service layer defined as protocols in `Shared/Services/` — provide live/mock implementations at app bootstrap
- Designed for Passkeys, role-based access, and GDPR compliance per the SRS

## Opening the project

```bash
open LMS.xcodeproj
```

`LMS.xcodeproj` is committed. Add/move/delete files through Xcode so `project.pbxproj` stays in sync.

## File structure

```
LMS/
├── LMS.xcodeproj                    # Xcode project (committed)
├── BorrowerApp/
│   ├── App/                         # @main entry + RootView
│   ├── Views/                       # one file per screen
│   └── ViewModels/
├── StaffApp/
│   ├── App/                         # @main entry + role-aware root
│   └── Views/                       # one file per screen
└── Shared/                          # compiled into BOTH targets
    ├── Models.swift                 # every data model in one file
    ├── SessionStore.swift
    ├── AppEnvironment.swift
    ├── Services/                    # protocol-only definitions
    ├── Networking/
    ├── Utilities/
    └── DesignSystem/                # tokens + components
```

## Next steps

1. Open `LMS.xcodeproj` in Xcode and pick a scheme (`BorrowerApp` or `StaffApp`).
2. Provide concrete service implementations (`URLSession`-backed `APIClient`, Keychain-backed token store, etc.).
3. Wire `AppEnvironment` into each app's `@main` and pass through `.environment(...)`.
4. Replace `TODO` markers in feature views with view-model bindings.
5. Add asset catalog colors, app icons, and launch screen assets.
6. Configure code signing, App Group / Keychain access group if Borrower and Staff apps should share session storage.
