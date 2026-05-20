import SwiftUI

struct LOSuccessConfirmationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: Spacing.l) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.lmsSuccess.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 1 : 0)
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.lmsSuccess)
                    .scaleEffect(animate ? 1 : 0.01)
            }
            
            VStack(spacing: Spacing.s) {
                Text("Recommendation Submitted")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Application #APP-991 has been forwarded to the Manager queue.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(animate ? 1 : 0)
            .offset(y: animate ? 0 : 20)
            
            Spacer()
            
            PrimaryButton("Back to Dashboard") {
                dismiss()
            }
            .padding()
            .opacity(animate ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                animate = true
            }
        }
    }
}
