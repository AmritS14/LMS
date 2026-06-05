import SwiftUI

// HIG primary action button: full-width borderedProminent control,
// large size, system-managed corner radius and tint.
struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let role: ButtonRole?
    private let action: () -> Void

    init(_ title: String,
         isLoading: Bool = false,
         role: ButtonRole? = nil,
         action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            ZStack {
                Text(title)
                    .font(.headline)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.white)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 28)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
        .controlSize(.large)
        .disabled(isLoading)
        .accessibilityLabel(isLoading ? "Loading" : title)
    }
}

// Secondary action — bordered (tinted outline).
struct SecondaryButton: View {
    private let title: String
    private let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 28)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle(radius: CornerRadius.button))
        .controlSize(.large)
    }
}
