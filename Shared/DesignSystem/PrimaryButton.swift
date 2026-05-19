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
            HStack {
                if isLoading { ProgressView().controlSize(.small) }
                Text(title).font(.lmsHeadline)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(isLoading)
    }
}
