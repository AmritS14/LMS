import SwiftUI

struct LOSuccessConfirmationView: View {
    var appID: String = "#APP-991"
    @Environment(\.dismiss) private var dismiss
    @State private var animate = false

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                // Animated checkmark
                ZStack {
                    Circle()
                        .fill(Color.lmsSuccess.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animate ? 1 : 0.3)
                        .opacity(animate ? 1 : 0)

                    Circle()
                        .fill(Color.lmsSuccess.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animate ? 1 : 0.1)
                        .opacity(animate ? 1 : 0)

                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 72, height: 72)
                        .foregroundStyle(Color.lmsSuccess)
                        .scaleEffect(animate ? 1 : 0.01)
                }
                .animation(.spring(response: 0.65, dampingFraction: 0.55).delay(0.1), value: animate)

                // Text
                VStack(spacing: Spacing.s) {
                    Text("Forwarded to Manager!")
                        .font(.lmsTitle)
                        .multilineTextAlignment(.center)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 20)
                        .animation(.easeOut(duration: 0.4).delay(0.3), value: animate)

                    Text("Application \(appID) has been submitted for managerial review with your remarks.")
                        .font(.lmsBody)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)
                        .opacity(animate ? 1 : 0)
                        .offset(y: animate ? 0 : 15)
                        .animation(.easeOut(duration: 0.4).delay(0.45), value: animate)
                }

                // What's Next card
                SectionCard(title: "What happens next?") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        NextStepRow(icon: "1.circle.fill", text: "Manager receives the application in their Approvals queue")
                        NextStepRow(icon: "2.circle.fill", text: "Manager reviews your remarks and makes the final decision")
                        NextStepRow(icon: "3.circle.fill", text: "Borrower is notified of the approval or rejection")
                    }
                }
                .padding(.horizontal, Spacing.m)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.6), value: animate)

                Spacer()

                PrimaryButton("Back to Dashboard") {
                    dismiss()
                }
                .padding(.horizontal, Spacing.m)
                .padding(.bottom, Spacing.l)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.7), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct NextStepRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Image(systemName: icon)
                .foregroundStyle(Color.lmsPrimary)
                .font(.title3)
            Text(text)
                .font(.lmsBody)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    LOSuccessConfirmationView()
}
