import SwiftUI

// MARK: - Login Screen

struct LoginView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env

    @State private var viewModel = AuthViewModel()
    @State private var navigateToOTP = false
    @State private var navigateToRegister = false
    @State private var navigateToForgotPassword = false
    @State private var password = ""
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    header
                        .padding(.top, Spacing.xl)

                    credentialsCard

                    HStack {
                        Button("Register") { navigateToRegister = true }
                        Spacer()
                        Button("Forgot Password?") { navigateToForgotPassword = true }
                    }
                    .font(.subheadline)
                    .padding(.horizontal, Spacing.m)
                }
                .padding(.bottom, Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.lmsBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToOTP) {
                OTPVerificationView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $navigateToForgotPassword) {
                ForgotPasswordView()
            }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("Loan Management System")
                .font(.lmsTitle)
                .multilineTextAlignment(.center)

            Text("Secure Borrower Portal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var credentialsCard: some View {
        VStack(spacing: Spacing.m) {
            VStack(spacing: 0) {
                TextField("Email Address", text: $viewModel.identifier)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit { focusedField = .password }
                    .padding(Spacing.m)

                Divider().padding(.leading, Spacing.m)

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .submitLabel(.go)
                    .focused($focusedField, equals: .password)
                    .onSubmit(submit)
                    .padding(Spacing.m)
            }
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(Color.lmsDanger)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton("Sign In", isLoading: viewModel.isBusy, action: submit)
                .disabled(!isSignInEnabled)
        }
        .padding(.horizontal, Spacing.m)
    }

    private var isSignInEnabled: Bool {
        !viewModel.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty &&
        !viewModel.isBusy
    }

    private func submit() {
        guard let auth = env?.auth, isSignInEnabled else { return }
        focusedField = nil
        Task {
            if let user = await viewModel.signIn(authService: auth, password: password) {
                let profile = try? await auth.fetchBorrowerProfile(userID: user.id)
                withAnimation(.easeInOut(duration: 0.4)) { 
                    session.currentUser = user 
                    session.borrowerProfile = profile
                }
            }
        }
    }
}

// MARK: - OTP Verification Screen

struct OTPVerificationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    var viewModel: AuthViewModel

    private let totalSeconds = 120

    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var showCheckmark = false

    @State private var secondsRemaining: Int = 120
    @State private var isExpired = false
    @State private var timerTask: Task<Void, Never>? = nil

    private var fullOTP: String { otpDigits.joined() }

    private var timeString: String {
        String(format: "%02d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    private var timerProgress: Double {
        Double(secondsRemaining) / Double(totalSeconds)
    }

    private var timerColor: Color {
        if secondsRemaining > 60 { return .accentColor }
        if secondsRemaining > 30 { return .lmsWarning }
        return .lmsDanger
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                statusBadgeView
                    .padding(.top, Spacing.l)

                Text(showCheckmark ? "Verified" : "Two-Factor Authentication")
                    .font(.lmsTitle)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut, value: showCheckmark)

                Text(showCheckmark
                     ? "Taking you to your dashboard…"
                     : "Enter the 6-digit verification code\nsent to your email.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if !showCheckmark {
                    timerRing
                }

                if isExpired && !showCheckmark {
                    expiredBanner
                }

                if !showCheckmark {
                    otpBoxes
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Color.lmsDanger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.l)
                    }

                    PrimaryButton("Verify", isLoading: viewModel.isBusy, action: verify)
                        .disabled(!isVerifyEnabled)
                        .padding(.horizontal, Spacing.m)

                    Button(action: resendCode) {
                        Label("Resend Code", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.medium))
                    }
                    .tint(isExpired ? .lmsDanger : .accentColor)
                    .padding(.top, Spacing.xs)

                    Text("Demo OTP: 123456")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, Spacing.m)
                }
            }
            .padding(.bottom, Spacing.xl)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.lmsBackground.ignoresSafeArea())
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(showCheckmark)
        .onAppear {
            focusedIndex = 0
            startTimer()
        }
        .onDisappear { stopTimer() }
    }

    private var statusBadgeView: some View {
        ZStack {
            Circle()
                .fill(showCheckmark ? Color.lmsSuccess : Color.accentColor)
                .frame(width: 72, height: 72)
            Image(systemName: showCheckmark ? "checkmark" : "lock.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
        }
        .animation(.easeInOut(duration: 0.25), value: showCheckmark)
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color.lmsGray5, lineWidth: 4)
                .frame(width: 72, height: 72)
            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(timerColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: secondsRemaining)
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.lmsMonoTimer)
                    .foregroundStyle(timerColor)
                Text("left")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var expiredBanner: some View {
        Label("OTP expired. Please resend a new code.",
              systemImage: "clock.badge.exclamationmark.fill")
            .font(.footnote.weight(.medium))
            .foregroundStyle(Color.lmsDanger)
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, Spacing.s)
            .background(Color.lmsDanger.opacity(0.08), in: Capsule())
            .padding(.horizontal, Spacing.l)
            .transition(.opacity)
    }

    private var otpBoxes: some View {
        HStack(spacing: Spacing.s) {
            ForEach(0..<6, id: \.self) { index in
                OTPDigitBox(
                    digit: $otpDigits[index],
                    isFocused: focusedIndex == index,
                    isExpired: isExpired
                )
                .focused($focusedIndex, equals: index)
                .onChange(of: otpDigits[index]) { _, newVal in
                    handleDigitChange(index: index, value: newVal)
                }
            }
        }
        .padding(.horizontal, Spacing.l)
        .disabled(isExpired)
    }

    // MARK: - Actions

    private func verify() {
        guard let auth = env?.auth else { return }
        viewModel.otp = fullOTP
        Task { @MainActor in
            if let user = await viewModel.verifyEmailOTP(authService: auth) {
                stopTimer()
                withAnimation(.easeInOut(duration: 0.3)) { showCheckmark = true }
                let profile = try? await auth.fetchBorrowerProfile(userID: user.id)
                try? await Task.sleep(for: .milliseconds(700))
                withAnimation(.easeInOut(duration: 0.4)) { 
                    session.currentUser = user 
                    session.borrowerProfile = profile
                }
            }
        }
    }

    private func resendCode() {
        resetTimer()
        otpDigits = Array(repeating: "", count: 6)
        viewModel.otp = ""
        viewModel.errorMessage = nil
        focusedIndex = 0
        // Task { await viewModel.signUp(authService: auth, ...) } // Need password/name to resend via signUp, or Supabase has resend function.
        // For now just leave as empty since resend requires separate Supabase API.
    }

    // MARK: - Timer logic

    private func startTimer() {
        secondsRemaining = totalSeconds
        isExpired = false
        timerTask = Task { @MainActor in
            while secondsRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                secondsRemaining -= 1
            }
            if !Task.isCancelled {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isExpired = true
                }
                otpDigits = Array(repeating: "", count: 6)
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func resetTimer() {
        stopTimer()
        withAnimation {
            isExpired = false
            secondsRemaining = totalSeconds
        }
        startTimer()
    }

    private var isVerifyEnabled: Bool {
        fullOTP.count == 6 && !viewModel.isBusy && !showCheckmark && !isExpired
    }

    private func handleDigitChange(index: Int, value: String) {
        if value.count > 1 {
            let digits = value.filter { $0.isNumber }
            for i in 0..<6 {
                otpDigits[i] = i < digits.count
                    ? String(digits[digits.index(digits.startIndex, offsetBy: i)])
                    : ""
            }
            focusedIndex = min(5, max(0, digits.count - 1))
            return
        }
        if value.isEmpty {
            if index > 0 { focusedIndex = index - 1 }
        } else if value.count == 1 {
            if index < 5 { focusedIndex = index + 1 }
        }
    }
}

// MARK: - OTP Digit Box

struct OTPDigitBox: View {
    @Binding var digit: String
    let isFocused: Bool
    let isExpired: Bool

    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .multilineTextAlignment(.center)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .foregroundStyle(isExpired ? Color.lmsDanger : .primary)
            .frame(width: 46, height: 56)
            .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused || isExpired ? 2 : 1)
            )
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .animation(.easeInOut(duration: 0.15), value: isExpired)
    }

    private var borderColor: Color {
        if isExpired { return .lmsDanger }
        if isFocused { return .accentColor }
        return .lmsSeparator
    }
}

// MARK: - Previews

#Preview("Login Screen") {
    LoginView()
        .environment(SessionStore())
        .environment(\.appEnvironment, AppEnvironment(
            auth: MockAuthService(),
            loans: MockLoanService(),
            documents: MockDocumentService(),
            notifications: MockNotificationService(),
            messaging: MockMessagingService(),
            keychain: MockKeychainService()
        ))
}

#Preview("OTP Screen") {
    let vm = AuthViewModel()
    return NavigationStack {
        OTPVerificationView(viewModel: vm)
    }
    .environment(SessionStore())
    .environment(\.appEnvironment, AppEnvironment(
        auth: MockAuthService(),
        loans: MockLoanService(),
        documents: MockDocumentService(),
        notifications: MockNotificationService(),
        messaging: MockMessagingService(),
        keychain: MockKeychainService()
    ))
}
