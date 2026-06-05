# 2FA & Authentication Flow Design

## 1. Overview
Implement proper 2-Factor Authentication (Email + Password -> Email OTP) across both the Borrower and Staff apps. Introduce biometric session persistence for Borrowers while strictly enforcing zero persistence for Staff. Finally, handle forced password changes for new Staff accounts and upgrade Supabase email templates.

## 2. 2FA Client Orchestration Flow
- **Step 1:** User signs in with Email and Password using `signInWithPassword`.
- **Step 2:** On success, the app securely holds the state in the background without updating the global `SessionStore`.
- **Step 3:** The app immediately triggers an OTP email by calling `signInWithOTP(email)`.
- **Step 4:** The UI transitions to the OTP entry screen.
- **Step 5:** The user enters the 6-digit OTP, and the app calls `verifyEmailOTP`. 
- **Step 6:** Upon success, `SessionStore.currentUser` is populated, and the user enters the app.

## 3. Session Persistence & Biometrics
- **Borrower App:** 
  - The Supabase client is configured with a custom `KeychainStorage` adapter to securely store the session token.
  - On app launch, if a session exists, Apple's `LocalAuthentication` (Face ID / Touch ID) is triggered.
  - **Success:** The session is restored seamlessly.
  - **Failure/Cancel:** The Keychain session is wiped, and the user must perform a full 2FA login.
- **Staff App:** 
  - Uses in-memory storage (or explicitly clears any Keychain storage on launch/exit), ensuring that closing the app instantly kills the session. 
  - Staff must complete the full 2FA login every time the app is launched.

## 4. Staff Forced Password Change
- **Admin Creation:** When an Admin creates a manager or loan officer, a temporary password is generated. This password is injected into the Supabase `user_metadata` (e.g., as `temp_password`) so the email template can render it using `{{ .Data.temp_password }}`.
- **Enforcement:** A `must_change_password` boolean column in the `users` table tracks whether a user needs to change their password.
- **Client Handling:** After completing 2FA, if `must_change_password` is `true`, the Staff App routes the user to a mandatory `ForcePasswordChangeView`. The dashboard remains inaccessible until the user successfully updates their password via the Supabase Auth update endpoint.
- **Resetting Flag:** Once the password is changed, the `must_change_password` flag is updated to `false` in the database.

## 5. Email Templates
- Custom, professionally styled HTML templates will be built and injected into Supabase Auth settings.
- **OTP Template:** Used during the 2FA flow to securely deliver the 6-digit code.
- **Invite Template (Staff):** Welcomes the new staff member, extracts their temporary password from metadata, and instructs them to log in and change it immediately.
- **Confirmation Template (Borrowers):** Used during standard borrower registration with a magic link or token.
