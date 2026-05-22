import SwiftUI

struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.s) {
                if isLoading { ProgressView().controlSize(.small).tint(.white) }
                Text(title).font(.lmsHeadline)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundColor(.white)
            .background(Color.lmsNavyBlue)
            .clipShape(Capsule())
        }
        .disabled(isLoading)
    }
}

#Preview {
    PrimaryButton("Test") {}
}
