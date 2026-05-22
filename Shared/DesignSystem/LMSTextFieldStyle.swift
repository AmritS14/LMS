import SwiftUI

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
