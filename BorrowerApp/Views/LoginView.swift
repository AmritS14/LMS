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

    var body: some View {
        NavigationStack {
            ZStack {
                // Light blue → white gradient background
                LinearGradient.lmsBackgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer().frame(height: 72)

                    // MARK: Header
                    VStack(spacing: 12) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(.blue)

                        Text("Loan Management System")
                            .font(.lmsTitle)
                            .foregroundStyle(.primary)

                        Text("Secure Borrower & Staff Portal")
                            .font(.lmsSubheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 36)

                    // MARK: Card
                    VStack(spacing: 14) {
                        // Email field
                        TextField("Email Address", text: $viewModel.identifier)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .textFieldStyle(.lmsBordered)

                        // Password field
                        SecureField("Password", text: $password)
                            .textFieldStyle(.lmsBordered)

                        // Error message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                        }

                        // Login button
                        PrimaryButton("Login", isLoading: viewModel.isBusy) {
                            guard let auth = env?.auth else { return }
                            Task {
                                await viewModel.requestOTP(authService: auth)
                                if viewModel.showOTPField {
                                    navigateToOTP = true
                                }
                            }
                        }
                        .disabled(viewModel.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)
                        .padding(.top, 2)

                        // Register / Forgot Password
                        HStack {
                            Button("Register") {
                                navigateToRegister = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.blue)

                            Spacer()

                            Button("Forgot Password?") {
                                navigateToForgotPassword = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.blue)
                        }
                        .padding(.top, 2)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: CornerRadius.large)
                            .fill(Color.lmsSurface)
                    )
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
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
}

// MARK: - OTP Verification Screen

struct OTPVerificationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    var viewModel: AuthViewModel

    // MARK: - Timer constants
    private let totalSeconds = 120 // 2 minutes

    // MARK: - State
    @State private var otpDigits: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedIndex: Int?
    @State private var isVerified = false
    @State private var showCheckmark = false

    // Timer state
    @State private var secondsRemaining: Int = 120
    @State private var isExpired = false
    @State private var timerTask: Task<Void, Never>? = nil

    private var fullOTP: String { otpDigits.joined() }

    // MM:SS formatted time
    private var timeString: String {
        let m = secondsRemaining / 60
        let s = secondsRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    // Progress 1.0 → 0.0 as time runs out
    private var timerProgress: Double {
        Double(secondsRemaining) / Double(totalSeconds)
    }

    // Color shifts red as time runs low
    private var timerColor: Color {
        if secondsRemaining > 60 { return .blue }
        if secondsRemaining > 30 { return .orange }
        return .red
    }

    var body: some View {
        ZStack {
            Color.lmsSurface.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 48)

                // MARK: Shield icon (animates to checkmark on success)
                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.extraLarge, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: showCheckmark
                                    ? [Color.green, Color.green.opacity(0.75)]
                                    : [Color.blue, Color.blue.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(
                            color: showCheckmark
                                ? Color.green.opacity(0.35)
                                : Color.blue.opacity(0.35),
                            radius: 12, x: 0, y: 6
                        )
                        .animation(.easeInOut(duration: 0.3), value: showCheckmark)

                    Image(systemName: showCheckmark ? "checkmark" : "lock.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(.white)
                        .animation(.easeInOut(duration: 0.2), value: showCheckmark)
                }
                .padding(.bottom, 20)

                // MARK: Header text
                Text(showCheckmark ? "Verified!" : "Two-Factor Authentication")
                    .font(.lmsTitle)
                    .foregroundStyle(.primary)
                    .animation(.easeInOut, value: showCheckmark)
                    .padding(.bottom, 6)

                Text(showCheckmark
                     ? "Taking you to your dashboard…"
                     : "Enter the 6-digit verification code\nsent to your email")
                    .font(.lmsSubheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut, value: showCheckmark)
                    .padding(.bottom, 24)

                // MARK: Countdown Timer Ring
                if !showCheckmark {
                    ZStack {
                        // Background track
                        Circle()
                            .stroke(Color(.systemGray5), lineWidth: 5)
                            .frame(width: 72, height: 72)

                        // Animated progress arc
                        Circle()
                            .trim(from: 0, to: timerProgress)
                            .stroke(
                                timerColor,
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 72, height: 72)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: secondsRemaining)

                        // Time label
                        VStack(spacing: 1) {
                            Text(timeString)
                                .font(.lmsMonoTimer)
                                .foregroundStyle(timerColor)
                                .animation(.easeInOut, value: timerColor)

                            Text("left")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 20)
                }

                // MARK: Expired banner
                if isExpired && !showCheckmark {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .foregroundStyle(.red)
                        Text("OTP expired. Please resend a new code.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.input))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // MARK: 6 OTP Boxes
                HStack(spacing: 10) {
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
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .opacity(showCheckmark ? 0 : 1)
                .animation(.easeOut(duration: 0.2), value: showCheckmark)
                .disabled(isExpired)

                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 12)
                }

                // MARK: Verify button
                PrimaryButton("Verify", isLoading: viewModel.isBusy) {
                    guard let auth = env?.auth else { return }
                    viewModel.otp = fullOTP
                    Task { @MainActor in
                        if let user = await viewModel.verifyOTP(authService: auth) {
                            stopTimer()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showCheckmark = true
                            }
                            try? await Task.sleep(for: .milliseconds(700))
                            withAnimation(.easeInOut(duration: 0.4)) {
                                session.currentUser = user
                            }
                        }
                    }
                }
                .disabled(!isVerifyEnabled)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(showCheckmark ? 0 : 1)
                .animation(.easeOut(duration: 0.2), value: showCheckmark)

                // MARK: Resend Code
                Button {
                    guard let auth = env?.auth else { return }
                    resetTimer()
                    otpDigits = Array(repeating: "", count: 6)
                    viewModel.otp = ""
                    viewModel.errorMessage = nil
                    focusedIndex = 0
                    Task { await viewModel.requestOTP(authService: auth) }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Resend Code")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(isExpired ? .red : .blue)
                }
                .opacity(showCheckmark ? 0 : 1)
                .animation(.easeOut(duration: 0.2), value: showCheckmark)

                // Demo hint
                Text("Demo OTP: 123456")
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.top, 20)
                    .opacity(showCheckmark ? 0 : 1)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(showCheckmark)
        .onAppear {
            focusedIndex = 0
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
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
                // Clear entered digits on expiry
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

    // MARK: - Helpers

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
            focusedIndex = min(5, digits.count - 1)
            return
        }
        if value.isEmpty {
            if index > 0 { focusedIndex = index - 1 }
        } else if value.count == 1 {
            if index < 5 { focusedIndex = index + 1 }
        }
    }
}

// MARK: - Individual OTP Digit Box

struct OTPDigitBox: View {
    @Binding var digit: String
    let isFocused: Bool
    let isExpired: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CornerRadius.medium)
                .fill(Color.lmsSurface)
                .frame(width: 46, height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium)
                        .stroke(
                            isExpired ? Color.red : (isFocused ? Color.blue : Color(.systemGray4)),
                            lineWidth: isFocused || isExpired ? 2 : 1.5
                        )
                )
                .shadow(
                    color: isExpired ? Color.red.opacity(0.15) : (isFocused ? Color.blue.opacity(0.15) : .clear),
                    radius: 6, x: 0, y: 2
                )

            TextField("", text: $digit)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(isExpired ? .red : .primary)
                .frame(width: 46, height: 56)
        }
        .animation(.easeInOut(duration: 0.15), value: isFocused)
        .animation(.easeInOut(duration: 0.15), value: isExpired)
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
    return OTPVerificationView(viewModel: vm)
        .environment(SessionStore(
            currentUser: nil,
            borrowerProfile: nil
        ))
        .environment(\.appEnvironment, AppEnvironment(
            auth: MockAuthService(),
            loans: MockLoanService(),
            documents: MockDocumentService(),
            notifications: MockNotificationService(),
            messaging: MockMessagingService(),
            keychain: MockKeychainService()
        ))
}
