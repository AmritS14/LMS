import SwiftUI

struct SuccessStateView: View {
    let actionType: ApplicationActionType
    let applicant: String
    let reference: String
    let officer: String
    var onFinish: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(actionType.themeColor)
                    .frame(width: 100, height: 100)
                Image(systemName: actionType.icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(spacing: Spacing.s) {
                Text(actionType.successTitle())
                    .font(.lmsTitle)
                Text(actionType.successSubtitle(applicant: applicant, reference: reference, officer: officer))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Spacer()

            VStack(spacing: Spacing.m) {
                Button {
                    onFinish()
                } label: {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
                .controlSize(.large)

                Button {
                    onFinish()
                } label: {
                    Label("Review Next Application", systemImage: "arrow.right")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
                .controlSize(.large)
            }
            .padding(.horizontal, Spacing.m)
            .padding(.bottom, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.lmsBackground.ignoresSafeArea())
    }
}

#Preview {
    SuccessStateView(actionType: .approve, applicant: "Sarah Jenkins",
                     reference: "LN-90210", officer: "Marcus Reed", onFinish: {})
}
