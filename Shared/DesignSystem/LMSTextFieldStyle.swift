import SwiftUI

// Thin wrapper around the system rounded-border style so callers can use
// `.textFieldStyle(.lmsBordered)` without having to reach into UIKit.
struct LMSTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .textFieldStyle(.roundedBorder)
            .font(.body)
    }
}

extension TextFieldStyle where Self == LMSTextFieldStyle {
    static var lmsBordered: LMSTextFieldStyle { LMSTextFieldStyle() }
}
