import SwiftUI

struct AadhaarKYCResult: Codable, Sendable, Hashable {
    var fullName: String
    var dob: String
    var gender: String
    var address: String
    var maskedAadhaar: String
}

struct KYCView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.appEnvironment) private var env
    @Environment(\.dismiss) private var dismiss

    enum KYCStep {
        case enterAadhaar
        case enterOTP
        case success(AadhaarKYCResult)
    }

    @State private var currentStep: KYCStep = .enterAadhaar
    @State private var aadhaarNumber: String = ""
    @State private var otpCode: String = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var timerCount = 30
    @State private var timerRunning = false
    @State private var timer: Timer? = nil

    var body: some View {
        VStack {
            switch currentStep {
            case .enterAadhaar:
                enterAadhaarView
            case .enterOTP:
                enterOTPView
            case .success(let result):
                successView(result: result)
            }
        }
        .background(Color.lmsBackground.ignoresSafeArea())
        .navigationTitle("Aadhaar e-KYC")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if session.borrowerProfile?.kycStatus == .verified {
                // If already verified, show a mock success screen
                let result = AadhaarKYCResult(
                    fullName: session.currentUser?.fullName ?? "Naman Gupta",
                    dob: "15/08/1998",
                    gender: "Male",
                    address: "402, Signature Towers, Sector 30, Gurugram, Haryana - 122001",
                    maskedAadhaar: "XXXX XXXX " + (session.borrowerProfile?.aadhaarLast4 ?? "1234")
                )
                currentStep = .success(result)
            }
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    // MARK: - Enter Aadhaar View
    private var enterAadhaarView: some View {
        ScrollView {
            VStack(spacing: Spacing.ml) {
                // Header Illustration
                VStack(spacing: Spacing.s) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, Spacing.l)
                    
                    Text("Verify your Identity")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("To comply with regulations and keep your account secure, please verify your identity using Aadhaar-based e-KYC.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.m)
                }
                
                // Form Card
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("Aadhaar Number")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "personalhotspot.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter 12-digit Aadhaar Number", text: $aadhaarNumber)
                            .keyboardType(.numberPad)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .onChange(of: aadhaarNumber) { _, newValue in
                                let digits = newValue.filter(\.isNumber)
                                if digits.count > 12 {
                                    aadhaarNumber = String(digits.prefix(12))
                                } else {
                                    aadhaarNumber = digits
                                }
                            }
                    }
                    .padding()
                    .background(Color.lmsBackground, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                    )
                    
                    HStack(alignment: .top, spacing: Spacing.xs) {
                        Image(systemName: "lock.shield.fill")
                            .font(.caption)
                            .foregroundStyle(Color.lmsSuccess)
                        Text("Your details are securely fetched via UIDAI and will never be shared without your explicit consent.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Spacing.ml)
                .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .shadow(color: .black.opacity(0.02), radius: 8, y: 4)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.lmsDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Submit Button
                PrimaryButton("Send OTP", isLoading: isLoading) {
                    guard aadhaarNumber.count == 12 else {
                        errorMessage = "Please enter a valid 12-digit Aadhaar number."
                        return
                    }
                    errorMessage = nil
                    isLoading = true
                    
                    Task {
                        do {
                            try await sendAadhaarOTP(aadhaar: aadhaarNumber)
                            isLoading = false
                            startTimer()
                            withAnimation(.easeInOut) {
                                currentStep = .enterOTP
                            }
                        } catch {
                            isLoading = false
                            errorMessage = error.localizedDescription
                        }
                    }
                }
                .disabled(aadhaarNumber.count != 12)
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    // MARK: - Enter OTP View
    private var enterOTPView: some View {
        ScrollView {
            VStack(spacing: Spacing.ml) {
                // Header Illustration
                VStack(spacing: Spacing.s) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                        .padding(.top, Spacing.l)
                    
                    Text("Enter Verification Code")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("A 6-digit verification code has been sent to the mobile number registered with Aadhaar ending in \(session.currentUser?.phone.suffix(4) ?? "XXXX").")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.m)
                }
                
                // Form Card
                VStack(alignment: .leading, spacing: Spacing.m) {
                    Text("One-Time Password (OTP)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: Spacing.s) {
                        Image(systemName: "key.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        
                        TextField("Enter 6-digit OTP", text: $otpCode)
                            .keyboardType(.numberPad)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .tracking(4)
                            .onChange(of: otpCode) { _, newValue in
                                let digits = newValue.filter(\.isNumber)
                                if digits.count > 6 {
                                    otpCode = String(digits.prefix(6))
                                } else {
                                    otpCode = digits
                                }
                            }
                    }
                    .padding()
                    .background(Color.lmsBackground, in: RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.medium, style: .continuous)
                            .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                    )
                    
                    HStack {
                        Spacer()
                        if timerRunning {
                            Text("Resend OTP in \(timerCount)s")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Resend OTP") {
                                timerCount = 30
                                startTimer()
                                Task {
                                    try? await sendAadhaarOTP(aadhaar: aadhaarNumber)
                                }
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tint)
                        }
                        Spacer()
                    }
                }
                .padding(Spacing.ml)
                .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .shadow(color: .black.opacity(0.02), radius: 8, y: 4)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.lmsDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Buttons
                VStack(spacing: Spacing.s) {
                    PrimaryButton("Verify & Submit", isLoading: isLoading) {
                        guard otpCode.count == 6 else {
                            errorMessage = "Please enter the 6-digit verification code."
                            return
                        }
                        errorMessage = nil
                        isLoading = true
                        
                        Task {
                            do {
                                let result = try await verifyAadhaarOTP(otp: otpCode)
                                isLoading = false
                                stopTimer()
                                
                                // Update session store (this mimics real database update)
                                if var profile = session.borrowerProfile {
                                    profile.kycStatus = .verified
                                    profile.aadhaarLast4 = String(aadhaarNumber.suffix(4))
                                    session.borrowerProfile = profile
                                }
                                
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    currentStep = .success(result)
                                }
                            } catch {
                                isLoading = false
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .disabled(otpCode.count != 6)
                    
                    Button("Go Back") {
                        errorMessage = nil
                        otpCode = ""
                        stopTimer()
                        withAnimation(.easeInOut) {
                            currentStep = .enterAadhaar
                        }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, Spacing.xs)
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    // MARK: - Success View
    private func successView(result: AadhaarKYCResult) -> some View {
        ScrollView {
            VStack(spacing: Spacing.l) {
                // Success Badge
                VStack(spacing: Spacing.xs) {
                    ZStack {
                        Circle()
                            .fill(Color.lmsSuccess.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(Color.lmsSuccess)
                    }
                    .padding(.top, Spacing.l)
                    
                    Text("KYC Verified Successfully")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Your identity has been verified via Aadhaar e-KYC.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Profile Details Card
                VStack(spacing: 0) {
                    // Header with avatar
                    HStack(spacing: Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 60, height: 60)
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(Color.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.fullName)
                                .font(.headline)
                            Text("Aadhaar: \(result.maskedAadhaar)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(Spacing.m)
                    
                    Divider()
                    
                    // Detailed Rows
                    VStack(spacing: Spacing.m) {
                        detailRow(title: "Date of Birth", value: result.dob)
                        detailRow(title: "Gender", value: result.gender)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(result.address)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(Spacing.m)
                }
                .background(Color.lmsSurface, in: RoundedRectangle(cornerRadius: CornerRadius.card, style: .continuous))
                .shadow(color: .black.opacity(0.02), radius: 8, y: 4)
                
                Spacer(minLength: 40)
                
                PrimaryButton("Done") {
                    dismiss()
                }
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - API Calls (Mocks easily connected to backend)
    
    private func sendAadhaarOTP(aadhaar: String) async throws {
        // --- BACKEND DEVELOPER INTEGRATION POINT ---
        // To connect the backend, replace the mock code below with a real API call:
        // try await env.auth.sendAadhaarOTP(aadhaarNumber: aadhaar)
        
        try await Task.sleep(for: .seconds(1.2)) // Simulating network latency
    }
    
    private func verifyAadhaarOTP(otp: String) async throws -> AadhaarKYCResult {
        // --- BACKEND DEVELOPER INTEGRATION POINT ---
        // To connect the backend, replace the mock code below with a real API call:
        // return try await env.auth.verifyAadhaarOTP(otp: otp)
        
        try await Task.sleep(for: .seconds(1.5)) // Simulating network latency
        
        if otp == "123456" || otp.count == 6 {
            return AadhaarKYCResult(
                fullName: session.currentUser?.fullName ?? "Naman Gupta",
                dob: "15/08/1998",
                gender: "Male",
                address: "402, Signature Towers, Sector 30, Gurugram, Haryana - 122001",
                maskedAadhaar: "XXXX XXXX " + String(aadhaarNumber.suffix(4))
            )
        } else {
            throw NSError(domain: "KYCError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid OTP. Please enter the correct 6-digit code."])
        }
    }
    
    // MARK: - Timer Helpers
    private func startTimer() {
        timerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timerCount > 0 {
                timerCount -= 1
            } else {
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    NavigationStack {
        KYCView()
            .environment(SessionStore(
                currentUser: MockAuthService.seedBorrower,
                borrowerProfile: MockAuthService.seedBorrowerProfile
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
}
