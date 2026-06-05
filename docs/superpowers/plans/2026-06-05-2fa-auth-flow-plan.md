# 2FA Auth Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a unified 2FA (Email -> OTP) login flow for both apps, Face ID session persistence for Borrowers, zero-persistence for Staff, forced password changes on first login for Staff, and styled email templates.

**Architecture:** We use Supabase Auth natively chained together (signInWithPassword -> signInWithOTP -> verifyOTP). The apps determine persistence by injecting a Keychain AuthStorage (Borrower) or Memory Storage (Staff) into the SupabaseClient depending on the bundle identifier.

**Tech Stack:** Swift, SwiftUI, Supabase SDK, LocalAuthentication

---

### Task 1: Update User Model & DB Mapping

**Files:**
- Modify: `Shared/Models/User.swift` (Wait, where is `User.swift`? We assume `Shared/Models/User.swift` or similar)
- Modify: `Shared/Services/Supabase/SupabaseAuthService.swift`

- [ ] **Step 1: Add `mustChangePassword` to User model**
Assuming `User` is in a models file. We add `mustChangePassword: Bool` to the struct.

```swift
// In User struct (find where it is defined, likely Shared/Models/Models.swift or similar)
public struct User: Codable, Identifiable, Sendable {
    // existing properties...
    public var mustChangePassword: Bool = false
    
    // update init...
}
```

- [ ] **Step 2: Update SupabaseAuthService mapping**
In `Shared/Services/Supabase/SupabaseAuthService.swift`, modify `DBUserProfile` to include `must_change_password`.

```swift
    private struct DBUserProfile: Decodable {
        let id: UUID
        let email: String?
        let role: String
        let full_name: String?
        let phone: String?
        let is_active: Bool?
        let must_change_password: Bool?
    }
```
Update `mapSupabaseUserToLocalUser` to map this field.

```swift
        var mustChangePassword = false
        if let profile = try? await fetchUserProfile(id: sbUser.id) {
            // ... existing mapping
            mustChangePassword = profile.must_change_password ?? false
        }

        return User(
            id: sbUser.id,
            fullName: name,
            email: sbUser.email ?? "",
            phone: contactPhone,
            role: role,
            isActive: isActive,
            mustChangePassword: mustChangePassword // assuming init is updated
        )
```

- [ ] **Step 3: Commit**
```bash
git add .
git commit -m "feat: add mustChangePassword to User model and auth mapping"
```

### Task 2: Supabase Storage Configuration (Face ID vs Memory)

**Files:**
- Create: `Shared/Services/Supabase/KeychainAuthStorage.swift`
- Create: `Shared/Services/Supabase/MemoryAuthStorage.swift`
- Modify: `Shared/Services/Supabase/SupabaseManager.swift`

- [ ] **Step 1: Implement custom AuthStorage**
Create `KeychainAuthStorage.swift`:
```swift
import Foundation
import Supabase

struct KeychainAuthStorage: AuthStorage {
    let key = "supabase.auth.token"
    
    func store(key: String, value: Data) throws {
        // Implement generic keychain store
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.key,
            kSecValueData as String: value
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func retrieve(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        if SecItemCopyMatching(query as CFDictionary, &item) == noErr {
            return item as? Data
        }
        return nil
    }
    
    func remove(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: self.key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

Create `MemoryAuthStorage.swift`:
```swift
import Foundation
import Supabase

class MemoryAuthStorage: AuthStorage, @unchecked Sendable {
    private var storage: [String: Data] = [:]
    
    func store(key: String, value: Data) throws { storage[key] = value }
    func retrieve(key: String) throws -> Data? { return storage[key] }
    func remove(key: String) throws { storage.removeValue(forKey: key) }
}
```

- [ ] **Step 2: Update SupabaseManager**
Modify `SupabaseManager.init()` to inject the right storage based on bundle ID.
```swift
        let isBorrowerApp = Bundle.main.bundleIdentifier?.contains("BorrowerApp") == true
        let authStorage: any AuthStorage = isBorrowerApp ? KeychainAuthStorage() : MemoryAuthStorage()

        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://kezcsrprvhzysftopjqd.supabase.co")!,
            supabaseKey: "sb_publishable_kVi_Wh86_lesAuTm6f7kxw_8xshrFgQ",
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(decoder: customDecoder),
                auth: SupabaseClientOptions.AuthOptions(storage: authStorage)
            )
        )
```

- [ ] **Step 3: Commit**
```bash
git add .
git commit -m "feat: configure Supabase auth storage for persistence requirements"
```

### Task 3: AuthViewModel 2FA Support

**Files:**
- Modify: `BorrowerApp/ViewModels/AuthViewModel.swift`

- [ ] **Step 1: Update signIn to trigger OTP**
Instead of returning `User`, `signIn` should verify the password and trigger the OTP, returning a boolean indicating success.

```swift
    func signIn(authService: any AuthService, password: String) async -> Bool {
        isBusy = true
        errorMessage = nil
        do {
            // Verify password (temporarily signs in)
            _ = try await authService.signIn(email: identifier, password: password)
            // Immediately request OTP email
            try await authService.requestOTP(identifier: identifier)
            isBusy = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isBusy = false
            return false
        }
    }
```

*Note: In `SupabaseAuthService.swift`, `requestOTP` currently throws an error. It needs to be updated in the next step to call `client.auth.signInWithOTP(email: identifier)`.*

- [ ] **Step 2: Update SupabaseAuthService `requestOTP`**
Modify `requestOTP` in `Shared/Services/Supabase/SupabaseAuthService.swift`:
```swift
    func requestOTP(identifier: String) async throws {
        try await client.auth.signInWithOTP(email: identifier)
    }
```

- [ ] **Step 3: Commit**
```bash
git add .
git commit -m "feat: wire up AuthViewModel and Service for 2FA chaining"
```

### Task 4: UI Updates (Borrower App)

**Files:**
- Modify: `BorrowerApp/Views/LoginView.swift`
- Modify: `BorrowerApp/App/RootView.swift`

- [ ] **Step 1: Fix LoginView Navigation**
In `LoginView.swift`, `submit()` should set `navigateToOTP = true` on success instead of setting `session.currentUser`.

```swift
    private func submit() {
        guard let auth = env?.auth, isSignInEnabled else { return }
        focusedField = nil
        Task {
            if await viewModel.signIn(authService: auth, password: password) {
                navigateToOTP = true
            }
        }
    }
```

- [ ] **Step 2: Face ID in RootView**
Update `BorrowerApp/App/RootView.swift` to handle Face ID if a session exists on launch.
```swift
import LocalAuthentication

// Inside RootView, add state:
@State private var isAuthenticatingBiometrics = true

// On Appear logic:
.task {
    if let _ = try? KeychainAuthStorage().retrieve(key: "supabase.auth.token") {
        let context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Log in to your account")
                if success, let user = await env?.auth.currentUser {
                    let profile = try? await env?.auth.fetchBorrowerProfile(userID: user.id)
                    withAnimation {
                        session.currentUser = user
                        session.borrowerProfile = profile
                        isAuthenticatingBiometrics = false
                    }
                } else {
                    try? await env?.auth.signOut()
                    isAuthenticatingBiometrics = false
                }
            } catch {
                try? await env?.auth.signOut()
                isAuthenticatingBiometrics = false
            }
        } else {
            isAuthenticatingBiometrics = false
        }
    } else {
        isAuthenticatingBiometrics = false
    }
}
```

- [ ] **Step 3: Commit**
```bash
git add .
git commit -m "feat: implement Face ID and 2FA flow in Borrower UI"
```

### Task 5: UI Updates (Staff App)

**Files:**
- Modify: `StaffApp/Views/StaffLoginView.swift`
- Create: `StaffApp/Views/StaffOTPView.swift`

- [ ] **Step 1: Update StaffLoginView**
`StaffLoginView` needs to act like the Borrower's `LoginView`, holding state and navigating to OTP. Create a generic ViewModel or reuse logic to call `signIn` then `requestOTP`.

- [ ] **Step 2: Create ForcePasswordChangeView**
Create `StaffApp/Views/ForcePasswordChangeView.swift` that forces the user to enter a new password. It calls `client.auth.update(user: UserAttributes(password: newPass))` and updates `must_change_password` to `false`.

- [ ] **Step 3: Enforce in StaffRootView**
In `StaffRootView`, if `session.currentUser?.mustChangePassword == true`, overlay the `ForcePasswordChangeView` full screen.

- [ ] **Step 4: Commit**
```bash
git add .
git commit -m "feat: add 2FA and forced password change to Staff App"
```

### Task 6: Email Templates

**Files:**
- Create: `docs/templates/otp_template.html`
- Create: `docs/templates/invite_template.html`

- [ ] **Step 1: Create OTP Template**
Write a clean HTML template using inline CSS for the OTP email. Reference `{{ .Token }}`.

- [ ] **Step 2: Create Invite Template**
Write a clean HTML template for staff invites. Reference `{{ .Data.temp_password }}`.

- [ ] **Step 3: Commit**
```bash
git add docs/templates/
git commit -m "docs: add professional email templates for Supabase Auth"
```
